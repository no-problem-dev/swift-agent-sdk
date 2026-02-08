import Foundation
import AgentSDK

/// Raw JSONL message received from CLI. Internal type.
internal enum CLIMessage: Sendable {
    case initializeReady
    case system(CLISystemMessage)
    case assistant(CLIAssistantMessage)
    case partialAssistant(CLIPartialAssistantMessage)
    case result(CLIResultMessage)
    case controlRequest(CLIControlRequest)
    case controlResponse(CLIControlResponse)
    case unknown(type: String)
}

internal struct CLISystemMessage: Sendable, Codable {
    let sessionId: String
    let tools: [JSONValue]
    let model: String
    let mcpServers: [JSONValue]

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case tools, model
        case mcpServers = "mcp_servers"
    }
}

internal struct CLIAssistantMessage: Sendable, Codable {
    let message: MessageContent
    let parentToolUseId: String?

    struct MessageContent: Sendable, Codable {
        let content: [JSONValue]
    }

    enum CodingKeys: String, CodingKey {
        case message
        case parentToolUseId = "parent_tool_use_id"
    }
}

internal struct CLIPartialAssistantMessage: Sendable, Codable {
    let message: CLIAssistantMessage.MessageContent
}

internal struct CLIResultMessage: Sendable, Codable {
    let result: String
    let costUsd: Double
    let durationMs: Int
    let inputTokens: Int
    let outputTokens: Int
    let sessionId: String
    let numTurns: Int

    enum CodingKeys: String, CodingKey {
        case result
        case costUsd = "cost_usd"
        case durationMs = "duration_ms"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case sessionId = "session_id"
        case numTurns = "num_turns"
    }
}

internal struct CLIControlRequest: Sendable, Codable {
    let requestId: String
    let request: ControlRequestPayload

    struct ControlRequestPayload: Sendable, Codable {
        let subtype: String
        let toolName: String?
        let toolInput: [String: JSONValue]?

        enum CodingKeys: String, CodingKey {
            case subtype
            case toolName = "tool_name"
            case toolInput = "tool_input"
        }
    }

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case request
    }
}

internal struct CLIControlResponse: Sendable, Codable {
    let response: ControlResponsePayload

    struct ControlResponsePayload: Sendable, Codable {
        let subtype: String
        let requestId: String
        let response: JSONValue?

        enum CodingKeys: String, CodingKey {
            case subtype
            case requestId = "request_id"
            case response
        }
    }
}

extension CLIMessage: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type, subtype
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "initialize_ready":
            self = .initializeReady
        case "system":
            self = .system(try CLISystemMessage(from: decoder))
        case "assistant":
            // Check if it has subtype "partial"
            if let subtype = try? container.decode(String.self, forKey: .subtype), subtype == "partial" {
                self = .partialAssistant(try CLIPartialAssistantMessage(from: decoder))
            } else {
                self = .assistant(try CLIAssistantMessage(from: decoder))
            }
        case "result":
            self = .result(try CLIResultMessage(from: decoder))
        case "control_request":
            self = .controlRequest(try CLIControlRequest(from: decoder))
        case "control_response":
            self = .controlResponse(try CLIControlResponse(from: decoder))
        default:
            self = .unknown(type: type)
        }
    }
}
