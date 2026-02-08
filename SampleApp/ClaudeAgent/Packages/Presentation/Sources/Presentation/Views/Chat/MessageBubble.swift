import SwiftUI
import Domain
import SwiftMarkdownView

/// メッセージバブル（role に応じた左右寄せ）
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                ForEach(Array(message.content.enumerated()), id: \.offset) { _, item in
                    contentView(for: item)
                }
            }
            .padding(12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if message.role != .user { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private func contentView(for item: ContentItem) -> some View {
        switch item {
        case .text(let text):
            MarkdownView(text)
        case .toolUse(let toolUse):
            ToolUseCard(toolUse: toolUse)
        case .toolResult(let toolResult):
            ToolResultCard(toolResult: toolResult)
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user: Color.accentColor.opacity(0.15)
        case .assistant: Color(.controlBackgroundColor)
        case .system: Color.orange.opacity(0.1)
        }
    }
}
