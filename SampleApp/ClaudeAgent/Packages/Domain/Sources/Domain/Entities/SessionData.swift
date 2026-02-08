import Foundation

/// セッションの永続化データ
public struct SessionData: Codable, Sendable, Identifiable {
    public let id: String
    public let config: SessionConfig
    public let createdAt: Date
    public var lastActiveAt: Date
    public var messages: [ChatMessage]
    public var totalCostUsd: Double

    public init(
        id: String,
        config: SessionConfig,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        messages: [ChatMessage] = [],
        totalCostUsd: Double = 0
    ) {
        self.id = id
        self.config = config
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.messages = messages
        self.totalCostUsd = totalCostUsd
    }
}
