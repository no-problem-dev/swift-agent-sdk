import SwiftUI
import Domain

/// セッションステータスに対応した色付きバッジ
struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private var color: Color {
        switch status {
        case .connected: .green
        case .connecting: .yellow
        case .disconnected: .gray
        case .error: .red
        }
    }
}
