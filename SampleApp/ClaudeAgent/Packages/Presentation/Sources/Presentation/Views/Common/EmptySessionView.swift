import SwiftUI
import DesignSystem

/// セッション未選択時のプレースホルダー
struct EmptySessionView: View {
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        VStack(spacing: spacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.4))

            VStack(spacing: spacing.sm) {
                Text("セッション未選択")
                    .typography(.titleMedium)
                    .foregroundStyle(colors.onSurfaceVariant)

                Text("新規セッションを作成して会話を始めましょう")
                    .typography(.bodyMedium)
                    .foregroundStyle(colors.onSurfaceVariant.opacity(0.7))
            }

            Button {
                NotificationCenter.default.post(name: .showNewSessionSheet, object: nil)
            } label: {
                Label("新規セッション", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("または  \(Text("⌘N").bold())  で作成")
                .typography(.labelMedium)
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))
        }
        .accessibilityElement(children: .contain)
    }
}
