// CotEditor의 편집·한글 입력을 재사용하면서 본문 복사·서비스·드래그·접근성 반출을 차단한다.
import AppKit

final class ProtectedEditorTextView: EditorTextView {
    /// CotEditor 텍스트 저장소와 개행 스캐너를 받아 외부 텍스트 처리를 끈 편집기를 만든다.
    required init(frame frameRect: NSRect = .zero, textStorage: NSTextStorage, lineEndingScanner: LineEndingScanner) {
        super.init(frame: frameRect, textStorage: textStorage, lineEndingScanner: lineEndingScanner)
        isAutomaticTextCompletionEnabled = false
        isContinuousSpellCheckingEnabled = false
        isGrammarCheckingEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticDataDetectionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        writingToolsBehavior = .none
        usesFindBar = false
        usesFindPanel = false
        setAccessibilityElement(false)
        setAccessibilityChildren([])
    }

    /// 보호 편집기는 선택 본문을 내보낼 Pasteboard 형식을 제공하지 않는다.
    override var writablePasteboardTypes: [NSPasteboard.PasteboardType] { [] }
    /// 보호 편집기는 Pasteboard에서 문서를 가져오지 않는다.
    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] { [] }
    /// 단일 형식 본문 출력 요청을 거부한다.
    override func writeSelection(to pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool { false }
    /// 다중 형식 본문 출력 요청을 거부한다.
    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool { false }
    /// 붙여넣기·파일 드래그 경로를 거부한다.
    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool { false }
    /// 외부 서비스의 본문 요청 대상으로 등록하지 않는다.
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? { nil }
    /// 선택 본문을 드래그 이미지나 Pasteboard로 내보내지 않는다.
    override func dragSelection(with event: NSEvent, offset mouseOffset: NSSize, slideBack: Bool) -> Bool { false }
    /// 문서의 컨텍스트 메뉴에서 공유·검색·쓰기 도구가 노출되지 않게 한다.
    override func menu(for event: NSEvent) -> NSMenu? { nil }
    /// 텍스트 후보와 외부 처리 기능이 있는 Touch Bar를 만들지 않는다.
    override func makeTouchBar() -> NSTouchBar? { nil }
    /// 직접 호출된 인쇄도 본문 출력을 수행하지 않는다.
    override func printView(_ sender: Any?) {}
    /// 스타일 복사 구현의 직접 Pasteboard 쓰기도 차단한다.
    override func copyWithStyle(_ sender: Any?) {}
    /// 직접 호출된 붙여넣기도 처리하지 않는다.
    override func pasteAsIs(_ sender: Any?) {}
    /// 직접 호출된 시스템 읽기·검색 명령이 본문을 다른 프로세스로 전달하지 않게 한다.
    override func startSpeaking(_ sender: Any?) {}
    /// Quick Look으로 선택 본문을 전달하지 않는다.
    override func quickLookPreviewItems(_ sender: Any?) {}
    /// 압력·세 손가락 조회 제스처의 사전/Quick Look 반출을 차단한다.
    override func quickLook(with event: NSEvent) {}
    /// 시스템 후보 생성 서비스에 본문을 전달하지 않는다.
    override func updateCandidates() {}
    /// 명시적 완성 명령으로 외부 텍스트 서비스를 호출하지 않는다.
    override func complete(_ sender: Any?) {}
    /// 시스템 찾기 패널의 공유 검색 기록에 본문을 남기지 않는다.
    override func performTextFinderAction(_ sender: Any?) {}
    /// CotEditor 찾기 패널의 공유 검색 기록에 본문을 남기지 않는다.
    override func performEditorTextFinderAction(_ sender: Any?) {}
    /// 직접 호출된 증분 검색·이전/다음 찾기를 공유 검색 상태와 연결하지 않는다.
    override func incrementalSearch(_ sender: Any?) {}
    /// 이전 검색 상태를 보호 본문에 적용하지 않는다.
    override func matchPrevious(_ sender: Any?) {}
    /// 다음 검색 상태를 보호 본문에 적용하지 않는다.
    override func matchNext(_ sender: Any?) {}
    /// 보호 본문은 접근성의 매개변수 조회나 수정 명령 대상으로 노출하지 않는다.
    override func isAccessibilitySelectorAllowed(_ selector: Selector) -> Bool { false }
    /// 범위를 지정한 접근성 조회에도 평문을 반환하지 않는다.
    override func accessibilityString(for range: NSRange) -> String? { nil }
    /// 서식 있는 접근성 조회에도 평문을 반환하지 않는다.
    override func accessibilityAttributedString(for range: NSRange) -> NSAttributedString? { nil }
    /// 접근성 RTF 출력 요청을 거부한다.
    override func accessibilityRTF(for range: NSRange) -> Data? { nil }
    /// 외부 본문 범위 조회에 실제 문자 수를 노출하지 않는다.
    override func accessibilityNumberOfCharacters() -> Int { 0 }
    /// 접근성에서 문서 본문을 반환하지 않는다.
    override func accessibilityValue() -> String? { nil }
    /// 접근성 선택 본문을 반환하지 않는다.
    override func accessibilitySelectedText() -> String? { nil }
    /// 원격 접근성으로 본문을 수정하지 않는다.
    override func setAccessibilityValue(_ accessibilityValue: Any?) {}
    /// 본문·선택 영역을 복원 상태에 기록하지 않는다.
    override func encodeRestorableState(with coder: NSCoder, backgroundQueue queue: OperationQueue) {}
}

final class ProtectedTextWindow: NSWindow {
    /// 인자 없이 보호 본문과 접근성 하위 트리의 외부 조회를 차단한다.
    func protect() {
        sharingType = .none
        isRestorable = false
        tabbingMode = .disallowed
        setAccessibilityChildren([])
        contentView?.setAccessibilityChildren([])
    }
}
