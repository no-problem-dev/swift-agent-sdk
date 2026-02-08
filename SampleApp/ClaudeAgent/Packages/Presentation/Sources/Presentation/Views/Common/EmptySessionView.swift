import SwiftUI

/// セッション未選択時のプレースホルダー
struct EmptySessionView: View {
    var body: some View {
        ContentUnavailableView {
            Label("セッション未選択", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("⌘N で新規セッションを作成")
        }
    }
}
