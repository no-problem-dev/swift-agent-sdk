import Foundation

/// Definition of a sub-agent that can be invoked during execution.
///
/// Sub-agents are specialized agents with their own prompts and tool access that can be
/// called by the main agent to handle specific tasks.
public struct AgentDefinition: Sendable, Codable {
    /// Description of what this agent does.
    public let description: String

    /// System prompt for this agent.
    public let prompt: String

    /// Tools this agent has access to. If nil, inherits from parent.
    public let tools: [String]?

    /// Model to use for this agent. If nil, uses default.
    public let model: ModelSelection?

    public init(
        description: String,
        prompt: String,
        tools: [String]? = nil,
        model: ModelSelection? = nil
    ) {
        self.description = description
        self.prompt = prompt
        self.tools = tools
        self.model = model
    }
}
