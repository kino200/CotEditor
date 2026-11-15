// root 소유의 서명 연결 도구와 상속 소켓으로 TXT 메모리 프레임만 교환한다.
import Foundation
import Security
import Darwin

public final class TextBridge {
    public static let maximumBytes = 64 * 1024 * 1024
    public static let path = "/Library/PrivilegedHelperTools/com.markany.DocumentSaferEditorBridge"
    private var descriptor: Int32 = -1
    private let process = Process()

    /// 고정 root 경로·서명을 확인하고 규약 6의 인증 채널을 만든다. 오류 시 평문 경로로 전환하지 않는다.
    public init() throws {
        var url = URL(fileURLWithPath: Self.path)
        while true {
            var info = stat()
            guard lstat(url.path, &info) == 0, info.st_uid == 0,
                  info.st_mode & 0o022 == 0, info.st_mode & S_IFMT != S_IFLNK else { throw TextFailure.unauthorized }
            if url.path == "/" { break }
            url.deleteLastPathComponent()
        }
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let rule = #"anchor apple generic and certificate leaf[subject.OU] = "9N6VX5RKP7" and identifier "com.markany.DocumentSaferEditorBridge""#
        guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: Self.path) as CFURL, [], &code) == errSecSuccess,
              let code, SecRequirementCreateWithString(rule as CFString, [], &requirement) == errSecSuccess,
              let requirement, SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), requirement) == errSecSuccess else {
            throw TextFailure.unauthorized
        }
        var pair: [Int32] = [-1, -1]
        guard socketpair(AF_UNIX, SOCK_STREAM, 0, &pair) == 0 else { throw TextFailure.unavailable }
        descriptor = pair[0]
        defer { close(pair[1]) }
        _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC)
        var one: Int32 = 1
        guard setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &one, socklen_t(MemoryLayout.size(ofValue: one))) == 0 else {
            close(descriptor); descriptor = -1
            throw TextFailure.unavailable
        }
        process.executableURL = URL(fileURLWithPath: Self.path)
        process.environment = [:]
        process.standardInput = FileHandle(fileDescriptor: pair[1], closeOnDealloc: false)
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            guard try request(0) == Data([6]) else { throw TextFailure.unauthorized }
        } catch {
            close(descriptor); descriptor = -1
            if process.isRunning { process.terminate() }
            throw TextFailure.unavailable
        }
    }

    deinit {
        if descriptor >= 0 { shutdown(descriptor, SHUT_RDWR); close(descriptor) }
        if process.isRunning { process.terminate() }
    }

    /// 현재 TXT 자동암호화 정책을 반환한다. 설치된 서비스의 연결 오류는 거부로 전달한다.
    public func automaticEncryption() throws -> Bool {
        switch try request(3) {
        case Data([0]): return false
        case Data([1]): return true
        default: throw TextFailure.malformed
        }
    }

    /// 암호문을 인증된 관리앱에 전달해 메모리 TXT 본문을 반환한다.
    public func open(_ ciphertext: Data) throws -> Data {
        var response = try request(1, ciphertext)
        defer { response.resetBytes(in: 0..<response.count) }
        guard response.first == 6 else { throw TextFailure.malformed }
        return Data(response.dropFirst())
    }

    /// 기존 세션의 편집 본문을 받아 ID·권한을 보존하는 암호문을 반환한다.
    public func save(_ plaintext: Data) throws -> Data { try request(2, plaintext) }

    /// 새 TXT 기본 파일명과 본문을 받아 현재 자동암호화 정책의 암호문을 반환한다.
    public func create(name: String, plaintext: Data) throws -> Data {
        let bytes = Data(name.utf8)
        guard (1...255).contains(bytes.count), name.lowercased().hasSuffix(".txt"),
              !name.contains("/"), !name.contains("\\"), name.rangeOfCharacter(from: .controlCharacters) == nil else { throw TextFailure.destination }
        var body = Data([UInt8(bytes.count >> 8), UInt8(bytes.count & 255)]) + bytes + plaintext
        defer { body.resetBytes(in: 0..<body.count) }
        return try request(4, body)
    }

    /// 코드·제한 크기 본문을 전송하고 제한 시간 안에 응답만 반환한다. 경로·평문은 로그에 기록하지 않는다.
    private func request(_ code: UInt8, _ body: Data = Data()) throws -> Data {
        guard descriptor >= 0, body.count <= Self.maximumBytes else { throw TextFailure.malformed }
        let count = UInt32(body.count)
        var frame = Data([code, UInt8(truncatingIfNeeded: count >> 24), UInt8(truncatingIfNeeded: count >> 16), UInt8(truncatingIfNeeded: count >> 8), UInt8(truncatingIfNeeded: count)]) + body
        defer { frame.resetBytes(in: 0..<frame.count) }
        let deadline = ProcessInfo.processInfo.systemUptime + 30
        var offset = 0
        while offset < frame.count {
            try wait(for: Int16(POLLOUT), deadline: deadline)
            let sent = frame.withUnsafeBytes { Darwin.send(descriptor, $0.baseAddress?.advanced(by: offset), frame.count - offset, MSG_DONTWAIT) }
            guard sent > 0 else { throw TextFailure.unavailable }
            offset += sent
        }
        let header = try read(5, deadline: deadline)
        let length = header.dropFirst().reduce(0) { ($0 << 8) | Int($1) }
        guard length <= Self.maximumBytes else { throw TextFailure.malformed }
        var response = try read(length, deadline: deadline)
        guard header.first == 0 else {
            response.resetBytes(in: 0..<response.count)
            throw TextFailure.unauthorized
        }
        return response
    }

    /// 소켓이 읽기·쓰기 가능한지 단일 작업 기한 안에서 검사한다.
    private func wait(for event: Int16, deadline: TimeInterval) throws {
        let remaining = deadline - ProcessInfo.processInfo.systemUptime
        guard remaining > 0 else { throw TextFailure.unavailable }
        var item = pollfd(fd: descriptor, events: event, revents: 0)
        guard poll(&item, 1, Int32(min(remaining * 1000, 30_000))) > 0,
              item.revents & event != 0 else { throw TextFailure.unavailable }
    }

    /// 지정 길이만 메모리로 읽는다. 빈 본문은 허용하고 조기 EOF·시간 초과는 거부한다.
    private func read(_ count: Int, deadline: TimeInterval) throws -> Data {
        var bytes = Data(count: count)
        var offset = 0
        while offset < count {
            try wait(for: Int16(POLLIN), deadline: deadline)
            let size = bytes.withUnsafeMutableBytes { Darwin.recv(descriptor, $0.baseAddress?.advanced(by: offset), count - offset, MSG_DONTWAIT) }
            guard size > 0 else { throw TextFailure.unavailable }
            offset += size
        }
        return bytes
    }
}
