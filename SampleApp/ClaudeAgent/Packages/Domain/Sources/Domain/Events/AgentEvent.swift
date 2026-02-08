import Foundation

/// SDK の AgentMessage を Domain レベルに変換した型
public enum AgentEvent: Sendable {
    /// セッション初期化完了
    case initialized(sessionId: String)

    /// ストリーミングテキスト（部分応答）
    case partialText(String)

    /// 完成したアシスタント応答
    case assistantMessage(content: [ContentItem])

    /// ターン完了（コスト・トークン情報）
    case turnCompleted(costUsd: Double, inputTokens: Int, outputTokens: Int)
}
