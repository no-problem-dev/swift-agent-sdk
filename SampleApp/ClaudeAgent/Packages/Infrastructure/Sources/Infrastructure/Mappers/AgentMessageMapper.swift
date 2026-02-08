import Foundation
import AgentSDK
import Domain

/// SDK の AgentMessage を Domain の AgentEvent に変換する Mapper
enum AgentMessageMapper {
    /// AgentMessage → AgentEvent のマッピング
    /// 未知のメッセージタイプの場合は nil を返す
    static func map(_ message: AgentMessage) -> AgentEvent? {
        switch message {
        case .system(let info):
            return .initialized(sessionId: info.sessionId)

        case .partial(let info):
            let text = info.content.compactMap { block -> String? in
                if case .text(let t) = block { return t }
                return nil
            }.joined()
            guard !text.isEmpty else { return nil }
            return .partialText(text)

        case .assistant(let info):
            let items = info.content.compactMap(mapContentBlock)
            return .assistantMessage(content: items)

        case .result(let info):
            return .turnCompleted(
                costUsd: info.costUsd,
                inputTokens: info.inputTokens,
                outputTokens: info.outputTokens
            )
        }
    }

    /// ContentBlock → ContentItem のマッピング
    static func mapContentBlock(_ block: ContentBlock) -> ContentItem? {
        switch block {
        case .text(let text):
            return .text(text)

        case .toolUse(let toolUse):
            let input = toolUse.input.mapValues(stringValue)
            return .toolUse(ToolUseItem(
                id: toolUse.id,
                name: toolUse.name,
                input: input
            ))

        case .toolResult(let result):
            return .toolResult(ToolResultItem(
                toolUseId: result.toolUseId,
                content: result.content,
                isError: result.isError
            ))
        }
    }

    /// JSONValue を表示用文字列に変換する
    private static func stringValue(from value: JSONValue) -> String {
        switch value {
        case .string(let s): return s
        case .number(let d): return String(d)
        case .integer(let i): return String(i)
        case .bool(let b): return String(b)
        case .null: return "null"
        case .array, .object:
            if let data = try? JSONEncoder().encode(value),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return String(describing: value)
        }
    }
}
