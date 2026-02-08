import SwiftUI
import Domain

/// ツール実行結果の折りたたみカード
struct ToolResultCard: View {
    let toolResult: ToolResultItem
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(toolResult.content)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(
                toolResult.isError ? "Error" : "Result",
                systemImage: toolResult.isError ? "xmark.circle" : "checkmark.circle"
            )
            .foregroundStyle(toolResult.isError ? .red : .secondary)
        }
        .padding(8)
        .background(toolResult.isError ? Color.red.opacity(0.1) : Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
