import Foundation

/// Operation layer abstraction providing query and session management.
///
/// `AgentClient` represents the main interface for interacting with an AI agent backend.
/// It supports both one-shot queries and stateful session-based conversations.
/// The client manages the lifecycle of sessions and provides a high-level API
/// for sending prompts and receiving agent responses.
public protocol AgentClient: Sendable {
    /// The type of session managed by this client.
    associatedtype Session: AgentSession

    /// Execute a one-shot query and return a stream of messages.
    ///
    /// This method sends a single prompt to the agent and returns a stream of
    /// response messages. It's suitable for stateless interactions where no
    /// conversation history needs to be maintained.
    ///
    /// - Parameters:
    ///   - prompt: The user's input prompt to send to the agent.
    ///   - options: Configuration options for the query, such as model parameters,
    ///              temperature, or other backend-specific settings.
    /// - Returns: An async throwing stream of agent messages comprising the response.
    func query(prompt: String, options: QueryOptions) -> AsyncThrowingStream<AgentMessage, Error>

    /// Create a new session.
    ///
    /// Initializes a new conversation session with the agent. The session maintains
    /// conversation history and state across multiple turns.
    ///
    /// - Parameter options: Configuration options for the session, such as system prompts,
    ///                      model selection, or session-specific parameters.
    /// - Returns: A new session instance ready for multi-turn interaction.
    /// - Throws: An error if the session cannot be created.
    func createSession(options: SessionOptions) async throws -> Session

    /// Resume an existing session.
    ///
    /// Reconnects to a previously created session using its identifier. This allows
    /// continuing a conversation that was interrupted or accessing historical sessions.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the session to resume.
    ///   - options: Configuration options for resuming the session.
    /// - Returns: The resumed session instance.
    /// - Throws: An error if the session cannot be found or resumed.
    func resumeSession(id: String, options: SessionOptions) async throws -> Session
}
