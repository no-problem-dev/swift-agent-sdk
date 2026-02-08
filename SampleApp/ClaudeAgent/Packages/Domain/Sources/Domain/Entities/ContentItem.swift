import Foundation

/// メッセージ内のコンテンツブロック
public enum ContentItem: Codable, Sendable, Hashable {
    case text(String)
    case toolUse(ToolUseItem)
    case toolResult(ToolResultItem)
}
