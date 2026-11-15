// 원본 스냅샷·TXT 인코딩·현재 정책을 결합해 평문 임시 파일 없는 편집 세션을 관리한다.
import Foundation

public protocol TextService {
    func automaticEncryption() throws -> Bool
    func decrypt(_ ciphertext: Data) throws -> Data
    func encrypt(_ plaintext: Data, original: Data?, name: String) throws -> Data
}

public struct DocumentSaferService: TextService {
    /// 인자 없이 고정 서명 브리지를 사용하는 서비스 값을 만든다.
    public init() {}
    /// 현재 로그인·TXT 자동암호화 정책을 반환한다. 연결 실패는 거부한다.
    public func automaticEncryption() throws -> Bool { try TextBridge().automaticEncryption() }
    /// 암호문을 받아 새 인증 채널에서 복호화한 TXT 바이트를 반환한다.
    public func decrypt(_ ciphertext: Data) throws -> Data { try TextBridge().open(ciphertext) }
    /// 편집 바이트·선택적 원본·파일명을 받아 매번 재인증한 암호문을 반환한다.
    public func encrypt(_ plaintext: Data, original: Data?, name: String) throws -> Data {
        let bridge = try TextBridge()
        if let original {
            var before = try bridge.open(original)
            before.resetBytes(in: 0..<before.count)
            return try bridge.save(plaintext)
        }
        return try bridge.create(name: name, plaintext: plaintext)
    }
}

public final class TextSession {
    public private(set) var file: TextFile?
    public private(set) var codec: TextCodec = .utf8
    public private(set) var isProtected: Bool
    public private(set) var initialText: String = ""
    private let service: any TextService

    /// 새 문서 또는 TXT 경로와 서비스로 세션을 만든다. 암호문은 메모리에서만 복호화한다.
    public init(url: URL? = nil, service: any TextService = DocumentSaferService()) throws {
        self.service = service
        isProtected = try service.automaticEncryption()
        if let url {
            guard url.pathExtension.lowercased() == "txt" else { throw TextFailure.destination }
            let file = try TextFile.read(url)
            let encrypted = TextFile.isEncrypted(file.data)
            var plaintext = encrypted ? try service.decrypt(file.data) : file.data
            defer { plaintext.resetBytes(in: 0..<plaintext.count) }
            (initialText, codec) = try TextCodec.decode(plaintext)
            self.file = file
            isProtected = isProtected || encrypted
        }
    }

    /// 현재 문자열과 목적지를 받아 정책을 재검사하고 원본 경로 또는 새 TXT에 저장한다.
    public func save(_ text: String, to url: URL) throws {
        if let file {
            guard file.url == url.standardizedFileURL else { throw TextFailure.destination }
            try file.verify()
        }
        var plaintext = try codec.encode(text)
        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
        let automatic = try service.automaticEncryption()
        let protected = isProtected || automatic
        let bytes: Data
        if protected {
            bytes = try service.encrypt(plaintext, original: file.flatMap { TextFile.isEncrypted($0.data) ? $0.data : nil }, name: url.lastPathComponent)
            guard bytes.starts(with: Data("<DOCUMENTSAFER_0>".utf8)) else { throw TextFailure.malformed }
        } else {
            bytes = plaintext
        }
        file = try TextFile.write(bytes, to: url, replacing: file)
        isProtected = protected
    }
}
