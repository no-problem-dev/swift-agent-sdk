import SwiftUI
import Domain
import DesignSystem

/// メッセージ入力エリア
struct InputArea: View {
    @Bindable var session: SessionState
    @State private var text: String = ""
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius
    @Environment(\.motion) private var motion

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing.sm) {
            // Text input (NSTextView ベース)
            ZStack(alignment: .topLeading) {
                // プレースホルダー
                if text.isEmpty {
                    Text("Claudeにメッセージを送信...")
                        .font(.body)
                        .foregroundStyle(colors.onSurfaceVariant.opacity(0.4))
                        .padding(.leading, 4)
                        .padding(.top, 4)
                        .allowsHitTesting(false)
                }

                ChatTextView(
                    text: $text,
                    font: .systemFont(ofSize: NSFont.systemFontSize),
                    maxHeight: 120,
                    isEnabled: session.status == .connected,
                    onSubmit: { sendMessage() }
                )
                .frame(minHeight: 36, maxHeight: 120)
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
            .background(colors.surfaceVariant.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: radius.lg)
                    .stroke(colors.outlineVariant.opacity(0.3), lineWidth: 0.5)
            )

            // Send / Stop button
            actionButton
        }
        .padding(.horizontal, spacing.lg)
        .padding(.vertical, spacing.md)
        .background(colors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("メッセージ入力")
    }

    @ViewBuilder
    private var actionButton: some View {
        if session.isProcessing {
            Button {
                Task { await session.interrupt() }
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(colors.error)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("応答を停止")
        } else {
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(cannotSend ? colors.onSurfaceVariant.opacity(0.3) : colors.primary)
            }
            .buttonStyle(.plain)
            .disabled(cannotSend)
            .accessibilityLabel("送信")
            .accessibilityHint(cannotSend ? "メッセージを入力してください" : "メッセージを送信します")
        }
    }

    private var cannotSend: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || session.status != .connected
    }

    private func sendMessage() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, session.status == .connected else { return }
        let message = trimmed
        text = ""
        Task { await session.send(message) }
    }
}
