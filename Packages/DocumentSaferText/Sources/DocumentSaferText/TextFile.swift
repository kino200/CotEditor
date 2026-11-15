// TXT 원본 변경을 검사하고 저장할 바이트만 0600 임시 파일에서 원자 교체한다.
import Foundation
import Darwin

public struct TextFile: Sendable {
    public let url: URL
    public let data: Data
    private let device: dev_t
    private let inode: ino_t

    /// 일반 파일을 크기 제한·심볼릭 링크 거부로 읽고 동일성 검사에 필요한 스냅샷을 반환한다.
    public static func read(_ url: URL) throws -> TextFile {
        let fd = Darwin.open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw TextFailure.destination }
        defer { close(fd) }
        var before = stat()
        guard fstat(fd, &before) == 0, before.st_mode & S_IFMT == S_IFREG,
              before.st_nlink == 1, before.st_size >= 0, before.st_size <= TextBridge.maximumBytes else { throw TextFailure.malformed }
        var data = Data(count: Int(before.st_size))
        var offset = 0
        while offset < data.count {
            let remaining = data.count - offset
            let count = data.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress?.advanced(by: offset), remaining) }
            guard count > 0 else { throw TextFailure.changed }
            offset += count
        }
        var after = stat()
        guard fstat(fd, &after) == 0, before.st_size == after.st_size,
              before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
              before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec else { throw TextFailure.changed }
        return TextFile(url: url.standardizedFileURL, data: data, device: before.st_dev, inode: before.st_ino)
    }

    /// 현재 경로의 장치·inode·바이트가 원본과 일치하는지 확인한다.
    public func verify() throws {
        let current = try Self.read(url)
        guard current.device == device, current.inode == inode, current.data == data else { throw TextFailure.changed }
    }

    /// 목적지와 최종 저장 바이트를 받아 새 파일 또는 검증된 원본을 교체한다. 실패하면 원본을 유지한다.
    public static func write(_ bytes: Data, to url: URL, replacing original: TextFile?) throws -> TextFile {
        guard url.isFileURL, url.pathExtension.lowercased() == "txt", bytes.count <= TextBridge.maximumBytes else { throw TextFailure.destination }
        if let original {
            guard original.url == url.standardizedFileURL else { throw TextFailure.destination }
            try original.verify()
        } else {
            var info = stat()
            guard lstat(url.path, &info) != 0, errno == ENOENT else { throw TextFailure.destination }
        }
        let temporary = url.deletingLastPathComponent().appendingPathComponent(".documentsafer-" + UUID().uuidString)
        let fd = Darwin.open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw TextFailure.destination }
        defer { close(fd); unlink(temporary.path) }
        var offset = 0
        while offset < bytes.count {
            let count = bytes.withUnsafeBytes { Darwin.write(fd, $0.baseAddress?.advanced(by: offset), bytes.count - offset) }
            guard count > 0 else { throw TextFailure.destination }
            offset += count
        }
        guard fsync(fd) == 0 else { throw TextFailure.destination }
        try original?.verify()
        let flags = original == nil ? UInt32(RENAME_EXCL) : 0
        guard renameatx_np(AT_FDCWD, temporary.path, AT_FDCWD, url.path, flags) == 0 else { throw TextFailure.changed }
        return try Self.read(url)
    }

    /// 문서 앞부분으로 DocumentSafer 암호문 계열인지 판별한다. 실제 인증은 관리앱이 수행한다.
    public static func isEncrypted(_ data: Data) -> Bool {
        ["<DOCUMENTSAFER_", "<MARKANY_DOCUMENTSAFER", "<DOCUMENT SAFER", "MONADNOCK__SODS"].contains { data.starts(with: $0.utf8) }
    }
}
