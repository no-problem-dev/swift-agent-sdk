import SwiftUI
import Domain
import DesignSystem

/// メッセージ入力エリア
struct InputArea: View {
    @Bindable var session: SessionState
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius
    @Environment(\.motion) private var motion

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing.sm) {
            // Text input
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Claudeにメッセージを送信...")
                        .typography(.bodyMedium)
                        .foregroundStyle(colors.onSurfaceVariant.opacity(0.4))
                        .padding(.horizontal, spacing.xs)
                        .padding(.vertical, spacing.sm)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 36, maxHeight: 120)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused($isFocused)
                    .onKeyPress(.return, phases: .down) { keyPress in
                        if keyPress.modifiers.contains(.shift) {
                            return .ignored
                        }
                        sendMessage()
                        return .handled
                    }
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
            .background(colors.surfaceVariant.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: radius.lg)
                    .stroke(
                        isFocused ? colors.primary.opacity(0.5) : colors.outlineVariant.opacity(0.3),
                        lineWidth: isFocused ? 1.5 : 0.5
                    )
                    .animate(motion.toggle, value: isFocused)
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
