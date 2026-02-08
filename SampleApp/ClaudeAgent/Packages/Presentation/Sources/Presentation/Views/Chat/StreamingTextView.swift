import SwiftUI

/// ストリーミング中のテキスト表示（カーソルアニメーション付き）
struct StreamingTextView: View {
    let text: String
    @State private var showCursor = true

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(text + (showCursor ? "▌" : " "))
                    .textSelection(.enabled)
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer(minLength: 60)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                showCursor.toggle()
            }
        }
    }
}
