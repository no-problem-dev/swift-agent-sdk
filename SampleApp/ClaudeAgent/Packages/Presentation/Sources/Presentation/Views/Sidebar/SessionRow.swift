import SwiftUI
import Domain
import DesignSystem

/// セッション一覧の各行
struct SessionRow: View {
    let session: SessionState
    @State private var isHovering = false
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            HStack(spacing: spacing.sm) {
                Text(session.displayName)
                    .typography(.bodyMedium)
                    .foregroundStyle(colors.onSurface)
                    .lineLimit(1)
                Spacer()
                StatusBadge(status: session.status)
            }

            // Last message preview
            if let preview = session.messages.last?.textPreview {
                Text(preview)
                    .typography(.bodySmall)
                    .foregroundStyle(colors.onSurfaceVariant.opacity(0.6))
                    .lineLimit(1)
            }

            HStack(spacing: spacing.sm) {
                Text(session.config.model.displayName)
                    .typography(.labelSmall)
                    .foregroundStyle(colors.primary.opacity(0.7))
                    .padding(.horizontal, spacing.xs)
                    .padding(.vertical, 1)
                    .background(colors.primaryContainer.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Text(DateFormatting.relative(session.lastActiveAt))
                    .typography(.labelSmall)
                    .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))
            }
        }
        .padding(.vertical, spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(session.displayName), \(session.config.model.displayName)"))
    }
}
