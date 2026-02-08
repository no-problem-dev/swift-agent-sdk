import SwiftUI
import Domain

/// セッション一覧の各行
struct SessionRow: View {
    let session: SessionState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.displayName)
                    .lineLimit(1)
                Spacer()
                StatusBadge(status: session.status)
            }
            HStack {
                Text(session.config.model.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(DateFormatting.relative(session.lastActiveAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
