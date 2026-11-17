// NSDocument의 평문 자동복구 경로 없이 CotEditor 텍스트 보기와 명시적 암호문 저장을 연결한다.
import AppKit
import UniformTypeIdentifiers
import DocumentSaferText
import LineEnding
import ValueRange

@MainActor final class ProtectedTextWindowController: NSWindowController, NSWindowDelegate, NSTextViewDelegate {
    let session: TextSession
    private let storage: NSTextStorage
    private let scanner: LineEndingScanner
    private let editor: ProtectedEditorTextView
    private let status = NSTextField(labelWithString: "")
    private var savedText: String
    private(set) var isDirty = false
    var onClose: (() -> Void)?
    var fileURL: URL? { session.file?.url }

    /// 메모리 TXT 세션에서 CotEditor 편집기를 만들고 본문 없는 창 상태만 노출한다.
    init(session: TextSession) throws {
        self.session = session
        savedText = session.initialText
        storage = NSTextStorage(string: session.initialText)
        scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        editor = ProtectedEditorTextView(textStorage: storage, lineEndingScanner: scanner)
        let window = ProtectedTextWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 650),
                                         styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.delegate = self
        window.center()
        editor.delegate = self
        editor.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        editor.lineEnding = scanner.lineEndings.first?.value ?? .lf
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = editor
        editor.theme = Theme()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        status.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(scroll)
        content.addSubview(status)
        window.contentView = content
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: content.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: status.topAnchor, constant: -8),
            status.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            status.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            status.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8),
        ])
        editor.frame.size.width = 850
        window.initialFirstResponder = editor
        window.protect()
        refreshStatus()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    /// 사용자 편집을 받아 메모리의 변경 여부와 제목만 갱신한다.
    func textDidChange(_ notification: Notification) {
        isDirty = editor.string != savedText
        window?.isDocumentEdited = isDirty
    }

    /// 현재 메모리 편집 문자열을 원본 경로 또는 새 TXT 경로에 저장한다.
    func save() {
        guard let window else { return }
        if let url = fileURL { save(to: url); return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "새 문서.txt"
        panel.beginSheetModal(for: window) { [weak self] result in
            guard result == .OK, let url = panel.url else { return }
            self?.save(to: url)
        }
    }

    /// 닫기 전에 미저장 문서를 보존하거나 사용자가 명시적으로 버리도록 확인한다.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard isDirty else { return true }
        let alert = NSAlert()
        alert.messageText = "변경 내용을 저장하시겠습니까?"
        alert.addButton(withTitle: "저장")
        alert.addButton(withTitle: "취소")
        alert.addButton(withTitle: "저장하지 않음")
        let result = alert.runModal()
        if result == .alertFirstButtonReturn { save(); return false }
        return result == .alertThirdButtonReturn
    }

    /// 닫힌 창의 메모리 undo·본문을 해제하고 앱의 참조를 제거한다.
    func windowWillClose(_ notification: Notification) {
        editor.undoManager?.removeAllActions()
        storage.setAttributedString(NSAttributedString(string: ""))
        savedText = ""
        onClose?()
    }

    /// 저장 결과를 반영하고 실패 시 입력 본문과 원본 파일을 유지한다.
    private func save(to url: URL) {
        do {
            let text = editor.string
            try session.save(text, to: url)
            savedText = text
            isDirty = false
            window?.isDocumentEdited = false
            if session.isProtected { TextBadge.apply(to: url) }
            refreshStatus(saved: true)
        } catch {
            let alert = NSAlert()
            alert.messageText = "저장하지 않았습니다."
            alert.informativeText = (error as? TextFailure)?.localizedDescription ?? "파일 또는 연결 상태를 확인해 주세요."
            if let window { alert.beginSheetModal(for: window) }
        }
    }

    /// 보호 상태·저장 상태와 본문 없는 창 제목을 갱신한다.
    private func refreshStatus(saved: Bool = false) {
        let name = fileURL?.lastPathComponent ?? "새 문서.txt"
        window?.title = name + " — maEditor"
        let protection = session.isProtected ? "보호 문서 · 암호화 저장" : "일반 문서 · 자동암호화 꺼짐"
        status.stringValue = protection + (saved ? " · 저장 완료" : "")
    }
}

enum TextBadge {
    /// 암호문 파일에 자체 도형의 잠금 배지를 붙인다. 실패는 문서 저장 결과를 바꾸지 않는다.
    @MainActor static func apply(to url: URL) {
        let image = NSImage(size: NSSize(width: 128, height: 128), flipped: false) { _ in
            NSColor.white.setFill()
            NSBezierPath(roundedRect: NSRect(x: 20, y: 8, width: 82, height: 108), xRadius: 8, yRadius: 8).fill()
            NSColor.systemBlue.setFill()
            for y in [84, 68, 52] { NSBezierPath(rect: NSRect(x: 32, y: y, width: 52, height: 5)).fill() }
            NSColor.systemGreen.setStroke()
            let shackle = NSBezierPath(roundedRect: NSRect(x: 76, y: 27, width: 28, height: 34), xRadius: 13, yRadius: 13)
            shackle.lineWidth = 7
            shackle.stroke()
            NSColor.systemGreen.setFill()
            NSBezierPath(roundedRect: NSRect(x: 67, y: 8, width: 46, height: 34), xRadius: 6, yRadius: 6).fill()
            return true
        }
        NSWorkspace.shared.setIcon(image, forFile: url.path, options: [])
    }
}
