// 실제 설치·실행된 DocumentSafer를 확인하고 개발 백업 등록과 남은 연결 도구를 구분한다.
import AppKit
import Darwin

internal enum DocumentSaferInstallation {
    /// 표준 Applications 설치본과 실행 중인 관리앱을 확인한다. 관리 신호가 있으면 true를 반환한다.
    static func isPresent() -> Bool {
        let identifiers = ["com.markany.securedocs.app", "com.markany.securedocs.daemon.app"]
        let roots = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
            + FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)
        return isPresent(applicationDirectories: roots,
                         registeredApplications: identifiers.flatMap { NSWorkspace.shared.urlsForApplications(withBundleIdentifier: $0) },
                         isRunning: identifiers.contains { !NSRunningApplication.runningApplications(withBundleIdentifier: $0).isEmpty })
    }

    /// 설치 루트·등록 경로·실행 여부를 받아 존재하는 설치본만 판별한다. 루트 밖 미실행 백업은 제외한다.
    static func isPresent(applicationDirectories roots: [URL], registeredApplications: [URL], isRunning: Bool) -> Bool {
        if isRunning { return true }
        let known = roots.flatMap { root in
            ["DocumentSafer.app", "DocumentSafer Local Policy Test.app", "MarkAny/SafeX/DocumentSafer.app"].map {
                root.appendingPathComponent($0)
            }
        }
        let installed = registeredApplications.filter { application in
            roots.contains { application.standardizedFileURL.path.hasPrefix($0.standardizedFileURL.path + "/") }
        }
        return (known + installed).contains { url in
            var info = stat()
            // 접근 오류는 미설치로 취급하지 않아 권한 문제로 일반 저장이 허용되는 것을 막는다.
            return lstat(url.path, &info) == 0 || (errno != ENOENT && errno != ENOTDIR)
        }
    }
}
