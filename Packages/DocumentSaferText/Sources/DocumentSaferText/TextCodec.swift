// TXT의 인코딩·BOM·개행을 손실 없이 메모리에서 왕복한다.
import Foundation
import CoreFoundation

public enum TextFailure: Error, LocalizedError {
    case unavailable, unauthorized, malformed, changed, encoding, destination, requiresDocumentSafer

    public var errorDescription: String? {
        switch self {
        case .requiresDocumentSafer: return "암호화 문서를 사용하려면 DocumentSafer를 설치하고 실행해 로그인해 주세요. 단독 실행에서는 일반 TXT만 지원합니다."
        case .unavailable: return "DocumentSafer를 실행해 로그인하고 연결 도구를 업데이트해 주세요."
        case .unauthorized: return "DocumentSafer가 문서 또는 현재 정책·세션을 거부했습니다."
        case .malformed: return "지원되지 않거나 손상된 문서입니다."
        case .changed: return "원본이 외부에서 변경되었습니다. 편집 내용은 유지되며 저장하지 않았습니다."
        case .encoding: return "인코딩을 손실 없이 처리할 수 없습니다. 원본 파일은 변경하지 않았습니다."
        case .destination: return "TXT 파일의 원래 경로 또는 새 파일 경로를 선택해 주세요. 기존 파일을 덮어쓰지 않습니다."
        }
    }
}

public struct TextCodec: Sendable {
    public let encoding: String.Encoding
    public let bom: Data

    public static let utf8 = TextCodec(encoding: .utf8, bom: Data())
    public static let korean = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.dosKorean.rawValue)))

    /// 인코딩과 접두 BOM을 받아 원본 바이트 보존 규칙을 만든다.
    public init(encoding: String.Encoding, bom: Data) {
        self.encoding = encoding
        self.bom = bom
    }

    /// 제한된 TXT 바이트를 받아 문자열과 손실 없는 인코딩을 반환한다. 추측 변환 손실은 거부한다.
    public static func decode(_ data: Data) throws -> (String, TextCodec) {
        guard data.count < TextBridge.maximumBytes else { throw TextFailure.malformed }
        let signatures: [(Data, String.Encoding)] = [
            (Data([0, 0, 0xfe, 0xff]), .utf32BigEndian),
            (Data([0xff, 0xfe, 0, 0]), .utf32LittleEndian),
            (Data([0xef, 0xbb, 0xbf]), .utf8),
            (Data([0xff, 0xfe]), .utf16LittleEndian),
            (Data([0xfe, 0xff]), .utf16BigEndian),
        ]
        let candidates: [TextCodec]
        if let (bom, encoding) = signatures.first(where: { data.starts(with: $0.0) }) {
            candidates = [TextCodec(encoding: encoding, bom: bom)]
        } else {
            candidates = [.utf8, TextCodec(encoding: korean, bom: Data())]
        }
        for codec in candidates {
            let payload = data.dropFirst(codec.bom.count)
            guard let text = String(data: payload, encoding: codec.encoding),
                  !text.unicodeScalars.contains(where: { $0.value == 0 }),
                  try codec.encode(text) == data else { continue }
            return (text, codec)
        }
        throw TextFailure.encoding
    }

    /// 편집 문자열을 원래 인코딩·BOM으로 반환한다. 개행은 변환하지 않고 표현 불가능한 문자는 거부한다.
    public func encode(_ text: String) throws -> Data {
        guard !text.unicodeScalars.contains(where: { $0.value == 0 }),
              let payload = text.data(using: encoding, allowLossyConversion: false),
              String(data: payload, encoding: encoding) == text,
              payload.count + bom.count < TextBridge.maximumBytes else { throw TextFailure.encoding }
        return bom + payload
    }
}
