import SwiftUI
import Domain
import DesignSystem

/// ツール実行結果の折りたたみカード
struct ToolResultCard: View {
    let toolResult: ToolResultItem
    @State private var isExpanded = false
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } } label: {
                HStack(spacing: spacing.sm) {
                    Image(systemName: toolResult.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(toolResult.isError ? colors.error : colors.success)

                    Text(toolResult.isError ? "エラー" : "結果")
                        .typography(.labelMedium)
                        .foregroundStyle(colors.onSurface)

                    Spacer()

                    if !isExpanded {
                        Text(toolResult.content.prefix(50) + (toolResult.content.count > 50 ? "..." : ""))
                            .typography(.labelSmall)
                            .foregroundStyle(colors.onSurfaceVariant)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(colors.onSurfaceVariant)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, spacing.md)
                .padding(.vertical, spacing.sm)
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                Divider()
                    .foregroundStyle(colors.outlineVariant)

                ScrollView(.horizontal, showsIndicators: false) {
                    Text(toolResult.content)
                        .typography(.bodySmall, design: .monospaced)
                        .foregroundStyle(colors.onSurface)
                        .textSelection(.enabled)
                        .padding(spacing.md)
                }
                .frame(maxHeight: 200)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            (toolResult.isError ? colors.errorContainer : colors.surfaceVariant)
                .opacity(0.3)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: radius.md)
                .stroke(
                    (toolResult.isError ? colors.error : colors.outlineVariant).opacity(0.3),
                    lineWidth: 0.5
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(toolResult.isError ? "ツールエラー" : "ツール結果")
        .accessibilityValue(toolResult.content)
    }
}
