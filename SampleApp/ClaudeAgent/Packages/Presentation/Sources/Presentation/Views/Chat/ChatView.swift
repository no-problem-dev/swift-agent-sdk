import SwiftUI
import DesignSystem

/// メッセージ一覧 + 入力エリア
struct ChatView: View {
    @Bindable var session: SessionState
    @State private var isAtBottom = true
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.motion) private var motion

    var body: some View {
        VStack(spacing: 0) {
            // Error banner
            if session.status == .error {
                errorBanner
            }

            // Messages
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: spacing.md) {
                            ForEach(session.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            if session.isProcessing || !session.streamingText.isEmpty {
                                StreamingTextView(text: session.streamingText)
                                    .id("streaming")
                                    .transition(.opacity)
                            }

                            // Bottom anchor
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, spacing.lg)
                        .padding(.vertical, spacing.md)
                    }
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                    .onChange(of: session.messages.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: session.streamingText) {
                        if !session.streamingText.isEmpty {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }

                // Scroll to bottom button
                if !isAtBottom && !session.messages.isEmpty {
                    scrollToBottomButton
                }
            }

            // Input
            Divider().foregroundStyle(colors.outlineVariant.opacity(0.3))
            InputArea(session: session)
        }
    }

    // MARK: - Components

    private var errorBanner: some View {
        HStack(spacing: spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(colors.error)
            Text("接続にエラーが発生しました")
                .typography(.labelMedium)
                .foregroundStyle(colors.onErrorContainer)
            Spacer()
            Button("再接続") {
                Task { try? await session.reconnect() }
            }
            .typography(.labelMedium)
            .foregroundStyle(colors.primary)
        }
        .padding(.horizontal, spacing.lg)
        .padding(.vertical, spacing.sm)
        .background(colors.errorContainer.opacity(0.5))
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("エラー: 接続にエラーが発生しました。再接続ボタンあり")
    }

    private var scrollToBottomButton: some View {
        Button {
            isAtBottom = true
        } label: {
            Image(systemName: "chevron.down.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(colors.primary)
                .background(colors.surface)
                .clipShape(Circle())
                .shadow(color: colors.onSurface.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .padding(spacing.lg)
        .transition(.opacity.combined(with: .scale))
        .accessibilityLabel("最新メッセージに移動")
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard isAtBottom else { return }
        withAnimation(motion.slide) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}
