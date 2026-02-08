import SwiftUI
import SwiftMarkdownView
import DesignSystem

/// ストリーミング中のテキスト表示（カーソルアニメーション付き）
struct StreamingTextView: View {
    let text: String
    @State private var cursorOpacity: Double = 1.0
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: spacing.sm) {
            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundStyle(colors.primary)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: spacing.xs) {
                if text.isEmpty {
                    typingIndicator
                } else {
                    MarkdownView(text)
                        .textSelection(.enabled)
                    Text("▌")
                        .foregroundStyle(colors.primary)
                        .opacity(cursorOpacity)
                }
            }
            .padding(spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.surfaceVariant.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: radius.lg))

            Spacer(minLength: 40)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                cursorOpacity = 0.0
            }
        }
        .accessibilityLabel("AI が応答を生成中")
        .accessibilityValue(text.isEmpty ? "入力中" : text)
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(colors.onSurfaceVariant.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .offset(y: reduceMotion ? 0 : dotOffset(for: index))
                    .animation(
                        reduceMotion ? nil :
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: cursorOpacity
                    )
            }
        }
        .padding(.vertical, spacing.sm)
    }

    private func dotOffset(for index: Int) -> CGFloat {
        cursorOpacity < 0.5 ? -4 : 0
    }
}
