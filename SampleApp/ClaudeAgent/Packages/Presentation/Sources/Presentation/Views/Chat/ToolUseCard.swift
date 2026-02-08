import SwiftUI
import Domain
import DesignSystem

/// ツール使用表示カード
struct ToolUseCard: View {
    let toolUse: ToolUseItem
    @State private var isExpanded = false

    var body: some View {
        Card(elevation: .level1, allSides: 8) {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(toolUse.input.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top) {
                            Text(key)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .trailing)
                            Text(value)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(3)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.top, 4)
            } label: {
                Label(toolUse.name, systemImage: "wrench")
                    .font(.subheadline.weight(.medium))
            }
        }
    }
}
