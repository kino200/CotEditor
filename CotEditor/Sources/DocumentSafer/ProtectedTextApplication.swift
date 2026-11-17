// CotEditor 편집기를 전용 TXT 메모리 문서 창으로 실행하고 원격·복구·스크립트 경로를 사용하지 않는다.
import AppKit
import UniformTypeIdentifiers
import Defaults
import DocumentSaferText

@main
@MainActor final class DocumentSaferTextApplicationDelegate: NSObject, NSApplicationDelegate {
    private var editors: [ProtectedTextWindowController] = []

    /// 앱을 원본 CotEditor의 storyboard·NSDocument 복구 경로 없이 실행한다.
    static func main() {
        let app = ProtectedTextApplication.shared
        let defaults = DefaultSettings.defaults.compactMapValues(\.self).mapKeys(\.rawValue)
        UserDefaults.standard.register(defaults: defaults)
        let delegate = DocumentSaferTextApplicationDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
        withExtendedLifetime(delegate) {}
    }

    /// 허용된 TXT 명령만 가진 메뉴를 구성한다.
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        let menu = NSMenu()
        for (title, items) in [
            ("maEditor", [("maEditor 정보", "about:", ""), ("오픈소스 라이선스…", "showLicenses:", ""), ("종료", "terminate:", "q")]),
            ("파일", [("새 문서", "newText:", "n"), ("열기…", "openText:", "o"), ("저장", "saveText:", "s"), ("닫기", "performClose:", "w")]),
            ("편집", [("실행 취소", "undo:", "z"), ("다시 실행", "redo:", "Z"), ("모두 선택", "selectAll:", "a")]),
        ] {
            let item = NSMenuItem()
            let submenu = NSMenu(title: title)
            for (label, action, key) in items {
                submenu.addItem(withTitle: label, action: NSSelectorFromString(action), keyEquivalent: key)
            }
            item.submenu = submenu
            menu.addItem(item)
        }
        NSApp.mainMenu = menu
    }

    /// 시작 알림을 받아 문서 이벤트가 없으면 현재 환경에 맞는 새 TXT 초안을 표시한다.
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.editors.isEmpty else { return }
            self.newText(nil)
        }
    }

    /// 원본 암호문 URL 열기 이벤트를 받아 TXT 전용 창으로 전달한다.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { show(url: url) }
    }

    /// 파일명 열기 이벤트를 URL로 바꾸고 성공 여부를 반환한다.
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for name in filenames { show(url: URL(fileURLWithPath: name)) }
        sender.reply(toOpenOrPrint: .success)
    }

    /// 문서 복구 없이 명시적인 새 문서 경로만 사용한다.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    /// 보호 본문을 앱 복구 아카이브에 저장하지 않는다.
    func applicationShouldSaveApplicationState(_ app: NSApplication) -> Bool { false }
    /// 이전 상태의 문서·창 복원을 허용하지 않는다.
    func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool { false }

    /// 종료 전 미저장 창을 확인한다. 사용자가 취소하면 편집 내용을 유지한다.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for editor in editors where editor.isDirty {
            editor.window?.makeKeyAndOrderFront(nil)
            editor.window?.performClose(nil)
            return .terminateCancel
        }
        return .terminateNow
    }

    /// 현재 정책을 확인해 새 문서를 만든다.
    @objc func newText(_ sender: Any?) { show(url: nil) }

    /// 사용자가 선택한 TXT 파일을 메모리 편집 창으로 연다.
    @objc func openText(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { show(url: url) }
    }

    /// 현재 TXT 창의 원본 경로 또는 새 경로에 저장한다.
    @objc func saveText(_ sender: Any?) {
        (NSApp.mainWindow?.windowController as? ProtectedTextWindowController)?.save()
    }

    /// 배포본 이름과 원본 소스의 저작권·라이선스를 안내한다.
    @objc func about(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "maEditor",
            .credits: NSAttributedString(string: "CotEditor 기반 TXT 편집기. CotEditor 소스는 Apache License 2.0입니다. 라이선스와 수정·리소스 고지는 앱 Resources/Licenses에 포함됩니다."),
        ])
    }

    /// 사용자가 요청한 배포 라이선스 폴더를 Finder에서 연다. sender는 메뉴 발신자이며 반환값은 없다.
    @objc func showLicenses(_ sender: Any?) {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Licenses", isDirectory: true) else { return }
        NSWorkspace.shared.open(url)
    }

    /// 선택 경로의 중복 창을 피하고 초기화 실패 시 본문 없는 오류만 표시한다.
    private func show(url: URL?) {
        if let url, let existing = editors.first(where: { $0.fileURL == url.standardizedFileURL }) {
            existing.showWindow(nil)
            return
        }
        do {
            let editor = try ProtectedTextWindowController(session: TextSession(url: url))
            editor.onClose = { [weak self, weak editor] in self?.editors.removeAll { $0 === editor } }
            editors.append(editor)
            editor.showWindow(nil)
            editor.window?.makeKeyAndOrderFront(nil)
        } catch {
            let alert = NSAlert()
            alert.messageText = "문서를 열 수 없습니다."
            alert.informativeText = (error as? TextFailure)?.localizedDescription ?? "문서 또는 연결 상태를 확인해 주세요."
            alert.runModal()
        }
    }
}

@objc(DocumentSaferTextApplication)
@MainActor final class ProtectedTextApplication: NSApplication {
    /// 문서 편집 창에서 본문을 외부로 전달하는 시스템 명령을 거부한다.
    override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
        let blocked: Set<String> = ["copy:", "cut:", "paste:", "pasteAsPlainText:", "copyWithStyle:", "pasteAsIs:",
            "print:", "printDocument:", "shareDocument:", "startSpeaking:", "speakSelection:",
            "quickLookPreviewItems:", "orderFrontSubstitutionsPanel:", "showGuessPanel:",
            "performFindPanelAction:", "performTextFinderAction:", "showFindPanel:", "showCharacterPalette:"]
        if keyWindow is ProtectedTextWindow, blocked.contains(NSStringFromSelector(action)) { return false }
        return super.sendAction(action, to: target, from: sender)
    }
}
