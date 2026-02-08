import Foundation

/// Represents a content block in agent communication.
///
/// Content blocks can be text, tool usage requests, or tool execution results.
public enum ContentBlock: Sendable, Codable {
    case text(String)
    case toolUse(ToolUse)
    case toolResult(ToolResult)
}

/// Represents a tool usage request from the agent.
public struct ToolUse: Sendable, Codable {
    /// Unique identifier for this tool use.
    public let id: String

    /// Name of the tool to execute.
    public let name: String

    /// Input parameters for the tool.
    public let input: [String: JSONValue]

    public init(id: String, name: String, input: [String: JSONValue]) {
        self.id = id
        self.name = name
        self.input = input
    }
}

/// Represents the result of a tool execution.
public struct ToolResult: Sendable, Codable {
    /// The ID of the tool use this result corresponds to.
    public let toolUseId: String

    /// The result content.
    public let content: String

    /// Whether this result represents an error.
    public let isError: Bool

    public init(toolUseId: String, content: String, isError: Bool = false) {
        self.toolUseId = toolUseId
        self.content = content
        self.isError = isError
    }
}

// MARK: - Custom Codable Implementation

extension ContentBlock {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case id
        case name
        case input
        case toolUseId = "tool_use_id"
        case content
        case isError = "is_error"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)

        case "tool_use":
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let input = try container.decode([String: JSONValue].self, forKey: .input)
            self = .toolUse(ToolUse(id: id, name: name, input: input))

        case "tool_result":
            let toolUseId = try container.decode(String.self, forKey: .toolUseId)
            let content = try container.decode(String.self, forKey: .content)
            let isError = try container.decodeIfPresent(Bool.self, forKey: .isError) ?? false
            self = .toolResult(ToolResult(toolUseId: toolUseId, content: content, isError: isError))

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown ContentBlock type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)

        case .toolUse(let toolUse):
            try container.encode("tool_use", forKey: .type)
            try container.encode(toolUse.id, forKey: .id)
            try container.encode(toolUse.name, forKey: .name)
            try container.encode(toolUse.input, forKey: .input)

        case .toolResult(let toolResult):
            try container.encode("tool_result", forKey: .type)
            try container.encode(toolResult.toolUseId, forKey: .toolUseId)
            try container.encode(toolResult.content, forKey: .content)
            try container.encode(toolResult.isError, forKey: .isError)
        }
    }
}
