// 인코딩 보존·실패 시 원본 보존·새 문서 자동암호화의 파일 경계를 검증한다.
import XCTest
@testable import DocumentSaferText

final class TextTests: XCTestCase {
    /// BOM·한국어·혼합 개행·마지막 개행과 빈 문서가 바이트 그대로 왕복하는지 검사한다.
    func testEncodingRoundTrips() throws {
        for text in ["", "한글\r\nABC\n끝\r", "trailing\n", "no final newline"] {
            for codec in [TextCodec.utf8, TextCodec(encoding: .utf8, bom: Data([0xef, 0xbb, 0xbf])),
                          TextCodec(encoding: .utf16LittleEndian, bom: Data([0xff, 0xfe])),
                          TextCodec(encoding: .utf16BigEndian, bom: Data([0xfe, 0xff])),
                          TextCodec(encoding: .utf32LittleEndian, bom: Data([0xff, 0xfe, 0, 0])),
                          TextCodec(encoding: TextCodec.korean, bom: Data())] {
                let data = try codec.encode(text)
                let (decoded, detected) = try TextCodec.decode(data)
                XCTAssertEqual(decoded, text)
                XCTAssertEqual(try detected.encode(decoded), data)
            }
        }
        XCTAssertThrowsError(try TextCodec.decode(Data([0xff, 0xfe, 0x41])))
        XCTAssertThrowsError(try TextCodec.decode(Data([0])))
        XCTAssertThrowsError(try TextCodec(encoding: TextCodec.korean, bom: Data()).encode("🙂"))
    }

    /// 암호화 대상은 빈 문서도 암호문만 저장하며 외부 변경·정책 실패 시 파일을 유지한다.
    func testProtectedSaveAndFailurePreservation() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("new.txt")
        let service = FakeService()
        let session = try TextSession(service: service)
        try session.save("", to: url)
        XCTAssertTrue(try TextFile.isEncrypted(Data(contentsOf: url)))
        let reopened = try TextSession(url: url, service: service)
        XCTAssertEqual(reopened.initialText, "")
        try reopened.save("한글\r\n수정", to: url)
        XCTAssertEqual(try TextSession(url: url, service: service).initialText, "한글\r\n수정")
        let saved = try Data(contentsOf: url)
        service.denied = true
        XCTAssertThrowsError(try reopened.save("denied", to: url))
        XCTAssertEqual(try Data(contentsOf: url), saved)
        service.denied = false
        XCTAssertThrowsError(try reopened.save("copy", to: folder.appendingPathComponent("copy.txt")))
        try Data("external".utf8).write(to: url)
        XCTAssertThrowsError(try reopened.save("overwrite", to: url))
        XCTAssertEqual(try Data(contentsOf: url), Data("external".utf8))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), ["new.txt"])
    }

    /// 정책 ON 전환·새 파일 충돌·심볼릭 링크·암호문 아닌 서비스 응답을 검사한다.
    func testPolicyTransitionsAndHostileDestinations() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let service = FakeService()
        service.automatic = false
        let session = try TextSession(service: service)
        service.automatic = true
        let url = folder.appendingPathComponent("new.txt")
        try session.save("secret", to: url)
        let saved = try Data(contentsOf: url)
        XCTAssertTrue(session.isProtected)
        XCTAssertThrowsError(try TextSession(service: service).save("overwrite", to: url))
        let link = folder.appendingPathComponent("link.txt")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: url)
        XCTAssertThrowsError(try TextSession(url: link, service: service))
        service.invalid = true
        XCTAssertThrowsError(try session.save("leak", to: url))
        XCTAssertEqual(try Data(contentsOf: url), saved)
    }
    /// 자동암호화가 해제되어도 보호 초안을 평문 저장하지 않고 인코딩 오류 시 원본을 보존한다.
    func testPolicyDowngradeAndEncodingFailure() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("protected.txt")
        let service = FakeService()
        let draft = try TextSession(service: service)
        service.automatic = false
        XCTAssertThrowsError(try draft.save("protected draft", to: url))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        service.automatic = true
        let codec = TextCodec(encoding: TextCodec.korean, bom: Data())
        let body = try service.encrypt(codec.encode("한글\r\n"), original: nil, name: "protected.txt")
        try body.write(to: url)
        let opened = try TextSession(url: url, service: service)
        XCTAssertThrowsError(try opened.save("🙂", to: url))
        XCTAssertEqual(try Data(contentsOf: url), body)
        service.automatic = false
        try opened.save("수정\r\n", to: url)
        XCTAssertTrue(opened.isProtected)
        XCTAssertEqual(try TextSession(url: url, service: service).initialText, "수정\r\n")
        service.denied = true
        XCTAssertThrowsError(try TextSession(url: url, service: service))
        XCTAssertTrue(TextFile.isEncrypted(Data("MONADNOCK__SODS".utf8)))
    }

}

private final class FakeService: TextService {
    var automatic = true
    var denied = false
    var invalid = false
    private let prefix = Data("<DOCUMENTSAFER_0>".utf8)

    /// 시험용 정책을 반환하거나 거부 상태를 재현한다.
    func automaticEncryption() throws -> Bool {
        if denied { throw TextFailure.unauthorized }
        return automatic
    }
    /// 시험용 프레임을 메모리에서만 해제한다. 제품 암호화로 사용하지 않는다.
    func decrypt(_ ciphertext: Data) throws -> Data { Data(ciphertext.dropFirst(prefix.count)) }
    /// 파일 경계 시험용 프레임을 반환하며 실제 암호화가 아님을 명시한다.
    func encrypt(_ plaintext: Data, original: Data?, name: String) throws -> Data {
        if denied || (!automatic && original == nil) { throw TextFailure.unauthorized }
        return invalid ? plaintext : prefix + plaintext
    }
}
