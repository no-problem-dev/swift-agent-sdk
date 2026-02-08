import Foundation

/// Options for creating or resuming agent sessions.
///
/// These options configure how the agent session behaves, including model selection,
/// tool access, permission handling, and execution limits.
public struct SessionOptions: Sendable {
    /// Model to use for this session.
    public var model: ModelSelection?

    /// System prompt to prepend to the conversation.
    public var systemPrompt: String?

    /// Specific tools to allow. If nil, all tools are allowed.
    public var allowedTools: [String]?

    /// Specific tools to disallow.
    public var disallowedTools: [String]?

    /// Sub-agents that can be invoked during execution.
    public var agents: [String: AgentDefinition]?

    /// MCP servers to connect for additional tools.
    public var mcpServers: [String: MCPServerConfig]?

    /// Permission mode for tool execution.
    public var permissionMode: PermissionMode?

    /// Callback to check if a tool can be used.
    ///
    /// - Parameters:
    ///   - toolName: Name of the tool
    ///   - input: Tool input parameters
    ///   - metadata: Optional metadata about the tool usage
    /// - Returns: Permission decision
    public var canUseTool: (@Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision)?

    /// Maximum number of conversation turns per message.
    public var maxTurns: Int?

    /// Maximum budget in USD for this session.
    public var maxBudgetUsd: Double?

    /// Working directory for tool execution.
    public var cwd: String?

    public init(
        model: ModelSelection? = nil,
        systemPrompt: String? = nil,
        allowedTools: [String]? = nil,
        disallowedTools: [String]? = nil,
        agents: [String: AgentDefinition]? = nil,
        mcpServers: [String: MCPServerConfig]? = nil,
        permissionMode: PermissionMode? = nil,
        canUseTool: (@Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision)? = nil,
        maxTurns: Int? = nil,
        maxBudgetUsd: Double? = nil,
        cwd: String? = nil
    ) {
        self.model = model
        self.systemPrompt = systemPrompt
        self.allowedTools = allowedTools
        self.disallowedTools = disallowedTools
        self.agents = agents
        self.mcpServers = mcpServers
        self.permissionMode = permissionMode
        self.canUseTool = canUseTool
        self.maxTurns = maxTurns
        self.maxBudgetUsd = maxBudgetUsd
        self.cwd = cwd
    }
}
