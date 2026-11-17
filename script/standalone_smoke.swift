// 실제 설치 판별과 기본 서비스로 단독 TXT 왕복·암호문 거부를 시험한다.
import Foundation

@main
struct StandaloneSmoke {
    enum Failure: Error { case managerPresent, mismatch, encryptionAllowed }

    /// 인자 없이 기본 서비스의 일반 저장과 암복호화 거부를 검증하며 만든 시험 파일만 정리한다.
    static func main() throws {
        guard !DocumentSaferInstallation.isPresent() else { throw Failure.managerPresent }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("maeditor-standalone-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("plain.txt")
        let text = "MAEDITOR-STANDALONE\r\n한글 TXT"
        let session = try TextSession()
        try session.save(text, to: url)
        guard !session.isProtected, try Data(contentsOf: url) == Data(text.utf8) else { throw Failure.mismatch }
        let opened = try TextSession(url: url)
        guard opened.initialText == text else { throw Failure.mismatch }
        try opened.save(text + "\nEDITED", to: url)
        guard try TextSession(url: url).initialText == text + "\nEDITED" else { throw Failure.mismatch }
        let encrypted = folder.appendingPathComponent("encrypted.txt")
        let opaque = Data("<DOCUMENTSAFER_0>synthetic ciphertext".utf8)
        try opaque.write(to: encrypted)
        do {
            _ = try TextSession(url: encrypted)
            throw Failure.encryptionAllowed
        } catch TextFailure.requiresDocumentSafer {}
        do {
            _ = try DocumentSaferService().encrypt(Data(text.utf8), original: nil, name: "blocked.txt")
            throw Failure.encryptionAllowed
        } catch TextFailure.requiresDocumentSafer {}
        guard try Data(contentsOf: encrypted) == opaque else { throw Failure.mismatch }
        print("Standalone default-service smoke passed: plain TXT round trip; encrypted input and encryption rejected.")
    }
}
