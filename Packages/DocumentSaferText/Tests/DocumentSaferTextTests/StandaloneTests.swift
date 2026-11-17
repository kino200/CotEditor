// 단독 일반 TXT 파일 왕복과 암복호화 미호출·관리 환경의 저장 거부 경계를 검증한다.
import XCTest
@testable import DocumentSaferText

final class StandaloneTests: XCTestCase {
    private var folder: URL!

    /// 각 시험의 임시 폴더를 만든다. 실제 사용자 파일은 사용하지 않는다.
    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    /// 시험이 만든 임시 폴더만 정리한다. 인자·반환값은 없다.
    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: folder)
    }

    /// 새 빈 TXT와 기존 UTF-16 TXT가 관리 서비스 호출 없이 일반 파일로 왕복하는지 확인한다.
    func testStandalonePlainTextRoundTripsWithoutManagerCalls() throws {
        let backend = RecordingService()
        let service = DocumentSaferService(managerIsPresent: { false }, managed: backend)
        let url = folder.appendingPathComponent("new.txt")
        let session = try TextSession(service: service)
        try session.save("", to: url)
        XCTAssertEqual(try Data(contentsOf: url), Data())
        try session.save("단독 편집\r\n", to: url)
        XCTAssertEqual(try Data(contentsOf: url), Data("단독 편집\r\n".utf8))
        XCTAssertFalse(session.isProtected)
        let encoded = folder.appendingPathComponent("utf16.txt")
        let codec = TextCodec(encoding: .utf16LittleEndian, bom: Data([0xff, 0xfe]))
        try codec.encode("원본\r\n").write(to: encoded)
        let reopened = try TextSession(url: encoded, service: service)
        XCTAssertEqual(reopened.initialText, "원본\r\n")
        try reopened.save("원본\r\n수정", to: encoded)
        XCTAssertEqual(try Data(contentsOf: encoded), try codec.encode("원본\r\n수정"))
        XCTAssertEqual(backend.calls, 0)
    }

    /// 암호문 계열을 일반 텍스트로 읽지 않고 단독 서비스의 암복호화 요청도 호출 전에 거부한다.
    func testStandaloneRejectsEncryptedDocumentsAndEncryption() throws {
        let backend = RecordingService()
        let service = DocumentSaferService(managerIsPresent: { false }, managed: backend)
        for marker in ["<DOCUMENTSAFER_0>", "<MARKANY_DOCUMENTSAFER", "<DOCUMENT SAFER", "MONADNOCK__SODS"] {
            let url = folder.appendingPathComponent(UUID().uuidString + ".txt")
            let bytes = Data((marker + "synthetic ciphertext").utf8)
            try bytes.write(to: url)
            XCTAssertThrowsError(try TextSession(url: url, service: service)) { error in
                guard case TextFailure.requiresDocumentSafer = error else { return XCTFail("Expected DocumentSafer requirement") }
            }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
        XCTAssertThrowsError(try service.encrypt(Data("text".utf8), original: nil, name: "new.txt"))
        XCTAssertThrowsError(try service.decrypt(Data("opaque".utf8)))
        XCTAssertEqual(backend.calls, 0)
    }

    /// 설치된 관리앱의 연결·인증 실패가 기존 일반 파일의 평문 저장으로 우회되지 않는지 확인한다.
    func testInstalledManagerFailuresPreservePlainOriginal() throws {
        var present = false
        let backend = RecordingService()
        let service = DocumentSaferService(managerIsPresent: { present }, managed: backend)
        let url = folder.appendingPathComponent("plain.txt")
        let session = try TextSession(service: service)
        try session.save("before", to: url)
        present = true
        for failure in [TextFailure.unavailable, .unauthorized] {
            backend.failure = failure
            XCTAssertThrowsError(try session.save("must not write", to: url))
            XCTAssertEqual(try Data(contentsOf: url), Data("before".utf8))
            XCTAssertThrowsError(try TextSession(service: service))
        }
        present = false
        XCTAssertThrowsError(try session.save("still managed", to: url))
        XCTAssertEqual(try Data(contentsOf: url), Data("before".utf8))
    }

    /// 단독 편집 중 관리앱이 설치되면 자동암호화를 적용하고 이후 제거 시 암호문을 보존한다.
    func testInstallationDuringEditingAndRemovalPreserveProtection() throws {
        var present = false
        let backend = RecordingService()
        let service = DocumentSaferService(managerIsPresent: { present }, managed: backend)
        let url = folder.appendingPathComponent("transition.txt")
        let session = try TextSession(service: service)
        present = true
        try session.save("protected", to: url)
        XCTAssertTrue(session.isProtected)
        XCTAssertTrue(TextFile.isEncrypted(try Data(contentsOf: url)))
        backend.automatic = false
        try session.save("still protected", to: url)
        let encrypted = try Data(contentsOf: url)
        XCTAssertTrue(TextFile.isEncrypted(encrypted))
        present = false
        XCTAssertThrowsError(try session.save("must not downgrade", to: url))
        XCTAssertEqual(try Data(contentsOf: url), encrypted)
        XCTAssertTrue(session.isProtected)
    }

    /// 아직 저장하지 않은 보호 초안도 관리앱이 제거되면 일반 파일로 생성하지 않는지 확인한다.
    func testManagedDraftCannotBecomeStandalone() throws {
        var present = true
        let backend = RecordingService()
        let service = DocumentSaferService(managerIsPresent: { present }, managed: backend)
        let draft = try TextSession(service: service)
        present = false
        let url = folder.appendingPathComponent("draft.txt")
        XCTAssertThrowsError(try draft.save("protected draft", to: url))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(backend.calls, 1)
    }

    /// Applications의 설치본·실행 신호와 루트 밖 백업·없어진 등록 경로를 구분한다.
    func testInstallationDetectionIgnoresInactiveBackups() throws {
        let applications = folder.appendingPathComponent("Applications")
        let backup = folder.appendingPathComponent("ApplicationsBackup/DocumentSafer.app")
        let installed = applications.appendingPathComponent("Renamed Manager.app")
        try FileManager.default.createDirectory(at: backup, withIntermediateDirectories: true)
        XCTAssertFalse(DocumentSaferInstallation.isPresent(applicationDirectories: [applications], registeredApplications: [backup, installed], isRunning: false))
        XCTAssertTrue(DocumentSaferInstallation.isPresent(applicationDirectories: [applications], registeredApplications: [backup], isRunning: true))
        try FileManager.default.createDirectory(at: installed, withIntermediateDirectories: true)
        XCTAssertTrue(DocumentSaferInstallation.isPresent(applicationDirectories: [applications], registeredApplications: [installed], isRunning: false))
        try FileManager.default.removeItem(at: installed)
        let daemon = applications.appendingPathComponent("MarkAny/SafeX/DocumentSafer.app")
        try FileManager.default.createDirectory(at: daemon, withIntermediateDirectories: true)
        XCTAssertTrue(DocumentSaferInstallation.isPresent(applicationDirectories: [applications], registeredApplications: [], isRunning: false))
    }
}

private final class RecordingService: TextService {
    var calls = 0
    var automatic = true
    var failure: TextFailure?
    private let prefix = Data("<DOCUMENTSAFER_0>".utf8)

    /// 호출 수를 기록하고 시험 정책 또는 실패를 반환한다. 실제 관리앱은 호출하지 않는다.
    func automaticEncryption() throws -> Bool {
        calls += 1
        if let failure { throw failure }
        return automatic
    }

    /// 호출 수를 기록하며 시험 프레임의 바이트만 반환한다. 실제 복호화가 아니다.
    func decrypt(_ ciphertext: Data) throws -> Data {
        calls += 1
        if let failure { throw failure }
        return Data(ciphertext.dropFirst(prefix.count))
    }

    /// 시험 본문을 식별용 프레임으로 반환한다. 실제 암호화로 사용하지 않는다.
    func encrypt(_ plaintext: Data, original: Data?, name: String) throws -> Data {
        calls += 1
        if let failure { throw failure }
        return prefix + plaintext
    }
}
