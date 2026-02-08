import Foundation

/// ツール使用情報
public struct ToolUseItem: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let input: [String: String]

    public init(id: String, name: String, input: [String: String]) {
        self.id = id
        self.name = name
        self.input = input
    }
}
