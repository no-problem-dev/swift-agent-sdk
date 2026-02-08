import SwiftUI
import AppKit

/// macOS ネイティブの NSTextView ラッパー
/// - Enter で送信、Shift+Enter で改行
/// - プレースホルダーは SwiftUI 側でオーバーレイ表示
/// - 自動高さ調整
struct ChatTextView: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
    var maxHeight: CGFloat = 120
    var isEnabled: Bool = true
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let textView = scrollView.documentView as! NSTextView
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = isEnabled
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = font
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.textContainer?.lineFragmentPadding = 4
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
        textView.isEditable = isEnabled
        textView.font = font
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatTextView

        init(_ parent: ChatTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                let event = NSApp.currentEvent
                let shiftPressed = event?.modifierFlags.contains(.shift) ?? false

                if shiftPressed {
                    // Shift+Enter → 改行を挿入
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    return true
                } else {
                    // Enter → 送信
                    parent.onSubmit()
                    return true
                }
            }
            return false
        }
    }
}
