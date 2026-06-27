import Foundation

/// Options for one-shot agent queries.
///
/// These options configure how the agent executes a single query, including model selection,
/// tool access, permission handling, and execution limits.
public struct QueryOptions: Sendable {
    /// Model to use for this query.
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

    /// Maximum number of conversation turns.
    public var maxTurns: Int?

    /// Maximum budget in USD for this query.
    public var maxBudgetUsd: Double?

    /// Working directory for tool execution.
    public var cwd: String?

    /// Expected output format (JSON schema).
    ///
    /// - Note: This property is reserved for future use and is not currently forwarded
    ///   to the CLI as a command-line argument.
    public var outputFormat: JSONValue?

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
        cwd: String? = nil,
        outputFormat: JSONValue? = nil
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
        self.outputFormat = outputFormat
    }
}
