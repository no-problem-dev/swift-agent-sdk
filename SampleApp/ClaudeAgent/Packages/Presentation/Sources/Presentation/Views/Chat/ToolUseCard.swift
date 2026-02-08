import SwiftUI
import Domain
import DesignSystem

/// ツール使用表示カード
struct ToolUseCard: View {
    let toolUse: ToolUseItem
    @State private var isExpanded = false
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } } label: {
                HStack(spacing: spacing.sm) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 12))
                        .foregroundStyle(colors.primary)
                        .frame(width: 20, height: 20)
                        .background(colors.primaryContainer)
                        .clipShape(RoundedRectangle(cornerRadius: radius.xs))

                    Text(toolUse.name)
                        .typography(.labelLarge)
                        .foregroundStyle(colors.onSurface)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(colors.onSurfaceVariant)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, spacing.md)
                .padding(.vertical, spacing.sm)
            }
            .buttonStyle(.plain)

            // Parameters
            if isExpanded {
                Divider()
                    .foregroundStyle(colors.outlineVariant)

                VStack(alignment: .leading, spacing: spacing.xs) {
                    ForEach(toolUse.input.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top, spacing: spacing.sm) {
                            Text(key)
                                .typography(.labelSmall, design: .monospaced)
                                .foregroundStyle(colors.onSurfaceVariant)
                                .frame(minWidth: 60, alignment: .trailing)

                            Text(value)
                                .typography(.bodySmall, design: .monospaced)
                                .foregroundStyle(colors.onSurface)
                                .lineLimit(5)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(colors.surfaceVariant.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: radius.md)
                .stroke(colors.outlineVariant.opacity(0.5), lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ツール使用: \(toolUse.name)")
    }
}
