import Foundation

/// Messages returned by the SDK during agent execution.
///
/// These messages are backend-independent and represent different stages of agent interaction:
/// - `system`: Initial session information
/// - `assistant`: Agent responses with content blocks
/// - `partial`: Streaming partial responses
/// - `result`: Final execution result with metrics
public enum AgentMessage: Sendable, Codable {
    case system(SystemInfo)
    case assistant(AssistantInfo)
    case partial(PartialInfo)
    case result(ResultInfo)
}

/// Information about the agent session and available tools.
public struct SystemInfo: Sendable, Codable, Hashable {
    /// Unique session identifier.
    public let sessionId: String

    /// Available tools in this session.
    public let tools: [ToolInfo]

    /// Model being used for this session.
    public let model: String

    /// Active MCP servers.
    public let mcpServers: [MCPServerInfo]

    public init(sessionId: String, tools: [ToolInfo], model: String, mcpServers: [MCPServerInfo]) {
        self.sessionId = sessionId
        self.tools = tools
        self.model = model
        self.mcpServers = mcpServers
    }
}

/// Information about an available tool.
public struct ToolInfo: Sendable, Codable, Hashable {
    /// Tool name.
    public let name: String

    /// Tool description.
    public let description: String?

    public init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
    }
}

/// Information about an MCP server.
public struct MCPServerInfo: Sendable, Codable, Hashable {
    /// Server name.
    public let name: String

    /// Server status (e.g., "connected", "disconnected").
    public let status: String

    public init(name: String, status: String) {
        self.name = name
        self.status = status
    }
}

/// Agent response with content blocks.
public struct AssistantInfo: Sendable, Codable {
    /// Content blocks in this response.
    public let content: [ContentBlock]

    /// Parent tool use ID if this is a sub-agent response.
    public let parentToolUseId: String?

    public init(content: [ContentBlock], parentToolUseId: String? = nil) {
        self.content = content
        self.parentToolUseId = parentToolUseId
    }
}

/// Partial streaming response from the agent.
public struct PartialInfo: Sendable, Codable {
    /// Partial content blocks.
    public let content: [ContentBlock]

    public init(content: [ContentBlock]) {
        self.content = content
    }
}

/// Final execution result with metrics.
public struct ResultInfo: Sendable, Codable {
    /// Final result text.
    public let result: String

    /// Total cost in USD.
    public let costUsd: Double

    /// Total duration in milliseconds.
    public let durationMs: Int

    /// Input tokens consumed.
    public let inputTokens: Int

    /// Output tokens generated.
    public let outputTokens: Int

    /// Session ID.
    public let sessionId: String

    /// Number of conversation turns.
    public let numTurns: Int

    public init(result: String, costUsd: Double, durationMs: Int, inputTokens: Int, outputTokens: Int, sessionId: String, numTurns: Int) {
        self.result = result
        self.costUsd = costUsd
        self.durationMs = durationMs
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.sessionId = sessionId
        self.numTurns = numTurns
    }
}

/// Information about an available CLI command.
public struct CommandInfo: Sendable, Codable, Hashable {
    /// Command name.
    public let name: String

    /// Command description.
    public let description: String

    public init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

/// Information about an available model.
public struct ModelInfo: Sendable, Codable, Hashable {
    /// Model identifier.
    public let id: String

    /// Human-readable model name.
    public let name: String?

    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

// MARK: - Custom Codable Implementation

extension AgentMessage {
    private enum CodingKeys: String, CodingKey {
        case type
        case sessionId
        case tools
        case model
        case mcpServers
        case content
        case parentToolUseId
        case result
        case costUsd
        case durationMs
        case inputTokens
        case outputTokens
        case numTurns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "system":
            let sessionId = try container.decode(String.self, forKey: .sessionId)
            let tools = try container.decode([ToolInfo].self, forKey: .tools)
            let model = try container.decode(String.self, forKey: .model)
            let mcpServers = try container.decode([MCPServerInfo].self, forKey: .mcpServers)
            self = .system(SystemInfo(sessionId: sessionId, tools: tools, model: model, mcpServers: mcpServers))

        case "assistant":
            let content = try container.decode([ContentBlock].self, forKey: .content)
            let parentToolUseId = try container.decodeIfPresent(String.self, forKey: .parentToolUseId)
            self = .assistant(AssistantInfo(content: content, parentToolUseId: parentToolUseId))

        case "partial":
            let content = try container.decode([ContentBlock].self, forKey: .content)
            self = .partial(PartialInfo(content: content))

        case "result":
            let result = try container.decode(String.self, forKey: .result)
            let costUsd = try container.decode(Double.self, forKey: .costUsd)
            let durationMs = try container.decode(Int.self, forKey: .durationMs)
            let inputTokens = try container.decode(Int.self, forKey: .inputTokens)
            let outputTokens = try container.decode(Int.self, forKey: .outputTokens)
            let sessionId = try container.decode(String.self, forKey: .sessionId)
            let numTurns = try container.decode(Int.self, forKey: .numTurns)
            self = .result(ResultInfo(
                result: result,
                costUsd: costUsd,
                durationMs: durationMs,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                sessionId: sessionId,
                numTurns: numTurns
            ))

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown AgentMessage type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .system(let info):
            try container.encode("system", forKey: .type)
            try container.encode(info.sessionId, forKey: .sessionId)
            try container.encode(info.tools, forKey: .tools)
            try container.encode(info.model, forKey: .model)
            try container.encode(info.mcpServers, forKey: .mcpServers)

        case .assistant(let info):
            try container.encode("assistant", forKey: .type)
            try container.encode(info.content, forKey: .content)
            try container.encodeIfPresent(info.parentToolUseId, forKey: .parentToolUseId)

        case .partial(let info):
            try container.encode("partial", forKey: .type)
            try container.encode(info.content, forKey: .content)

        case .result(let info):
            try container.encode("result", forKey: .type)
            try container.encode(info.result, forKey: .result)
            try container.encode(info.costUsd, forKey: .costUsd)
            try container.encode(info.durationMs, forKey: .durationMs)
            try container.encode(info.inputTokens, forKey: .inputTokens)
            try container.encode(info.outputTokens, forKey: .outputTokens)
            try container.encode(info.sessionId, forKey: .sessionId)
            try container.encode(info.numTurns, forKey: .numTurns)
        }
    }
}
