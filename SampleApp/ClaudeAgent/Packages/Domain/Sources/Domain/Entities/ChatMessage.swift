import Foundation

/// チャットメッセージ（表示用 + 永続化用）
public struct ChatMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let role: Role
    public let timestamp: Date
    public var content: [ContentItem]

    public enum Role: String, Codable, Sendable {
        case user
        case assistant
        case system
    }

    /// サイドバー表示用のテキストプレビュー（先頭 30 文字）
    public var textPreview: String? {
        content.compactMap {
            if case .text(let text) = $0 { return text }
            return nil
        }.first.map { String($0.prefix(30)) }
    }

    public init(role: Role, content: [ContentItem]) {
        self.id = UUID()
        self.role = role
        self.timestamp = Date()
        self.content = content
    }

    public init(id: UUID = UUID(), role: Role, timestamp: Date = Date(), content: [ContentItem]) {
        self.id = id
        self.role = role
        self.timestamp = timestamp
        self.content = content
    }
}
