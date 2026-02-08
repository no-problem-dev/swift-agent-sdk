import SwiftUI
import Domain
import SwiftMarkdownView
import DesignSystem

/// メッセージバブル（role に応じたスタイリング + メタデータ表示）
struct MessageBubble: View {
    let message: ChatMessage
    @State private var isHovering = false
    @State private var showCopied = false
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        HStack(alignment: .top, spacing: spacing.sm) {
            if message.role == .user { Spacer(minLength: 40) }

            // AI avatar
            if message.role == .assistant {
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(colors.primary)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: spacing.xs) {
                // Content
                VStack(alignment: .leading, spacing: spacing.sm) {
                    ForEach(Array(message.content.enumerated()), id: \.offset) { _, item in
                        contentView(for: item)
                    }
                }
                .padding(spacing.md)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: radius.lg)
                        .stroke(borderColor, lineWidth: 0.5)
                )

                // Hover actions + timestamp
                if isHovering {
                    HStack(spacing: spacing.sm) {
                        Text(DateFormatting.time(message.timestamp))
                            .typography(.labelSmall)
                            .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))

                        if let textContent = message.fullText {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(textContent, forType: .string)
                                showCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    showCopied = false
                                }
                            } label: {
                                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundStyle(showCopied ? colors.success : colors.onSurfaceVariant.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("コピー")
                        }
                    }
                    .transition(.opacity)
                }
            }

            if message.role != .user { Spacer(minLength: 40) }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message.role == .user ? "あなたのメッセージ" : "Claudeの応答")
    }

    @ViewBuilder
    private func contentView(for item: ContentItem) -> some View {
        switch item {
        case .text(let text):
            MarkdownView(text)
                .textSelection(.enabled)
        case .toolUse(let toolUse):
            ToolUseCard(toolUse: toolUse)
        case .toolResult(let toolResult):
            ToolResultCard(toolResult: toolResult)
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user: colors.primaryContainer
        case .assistant: colors.surfaceVariant.opacity(0.3)
        case .system: colors.secondaryContainer.opacity(0.5)
        }
    }

    private var borderColor: Color {
        switch message.role {
        case .user: colors.primary.opacity(0.15)
        case .assistant: colors.outlineVariant.opacity(0.3)
        case .system: colors.secondary.opacity(0.15)
        }
    }
}

// MARK: - ChatMessage convenience

extension ChatMessage {
    var fullText: String? {
        let texts = content.compactMap { item -> String? in
            if case .text(let text) = item { return text }
            return nil
        }
        return texts.isEmpty ? nil : texts.joined(separator: "\n")
    }
}
