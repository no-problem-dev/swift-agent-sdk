import SwiftUI
import Domain
import DesignSystem

/// セッションステータスに対応した色付きバッジ（WCAG 2.2 AA 準拠）
struct StatusBadge: View {
    let status: SessionStatus
    @Environment(\.colorPalette) private var colors

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay {
                    if status == .connecting {
                        Circle()
                            .stroke(color.opacity(0.4), lineWidth: 2)
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)
                    }
                }
            Text(label)
                .typography(.labelSmall)
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ステータス: \(label)")
    }

    private var color: Color {
        switch status {
        case .connected: colors.success
        case .connecting: colors.warning
        case .disconnected: colors.onSurfaceVariant
        case .error: colors.error
        }
    }

    private var label: String {
        switch status {
        case .connected: "接続中"
        case .connecting: "接続待ち"
        case .disconnected: "切断"
        case .error: "エラー"
        }
    }

    // MARK: - Connecting pulse animation

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0

    init(status: SessionStatus) {
        self.status = status
    }
}
