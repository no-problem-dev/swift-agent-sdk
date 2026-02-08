import Foundation

/// Session layer abstraction for managing multi-turn conversations.
///
/// `AgentSession` represents a stateful conversation with an AI agent.
/// It maintains the conversation history and context across multiple message exchanges.
/// Sessions can be interrupted, resumed, and closed, providing full lifecycle management
/// for long-running agent interactions.
public protocol AgentSession: Sendable {
    /// Session identifier.
    ///
    /// A unique identifier for this session, which can be used to resume the session
    /// later or to reference it in logging and debugging contexts.
    var id: String { get async }

    /// Send a message and receive a stream of responses.
    ///
    /// Sends a user message to the agent within this session's conversation context.
    /// The response is streamed back as a series of messages, allowing for progressive
    /// display of the agent's reply.
    ///
    /// - Parameter message: The user's message to send to the agent.
    /// - Returns: An async throwing stream of agent messages comprising the response.
    func send(_ message: String) -> AsyncThrowingStream<AgentMessage, Error>

    /// Interrupt the current processing.
    ///
    /// Stops the agent from continuing to process the current request. This is useful
    /// when the user wants to cancel a long-running operation or change direction
    /// in the conversation.
    ///
    /// - Throws: An error if the interruption cannot be performed.
    func interrupt() async throws

    /// Close the session.
    ///
    /// Terminates the session and releases any associated resources. After closing,
    /// the session should not be used for further message exchanges. The session
    /// may still be resumable later if the backend supports session persistence.
    ///
    /// - Throws: An error if the session cannot be closed cleanly.
    func close() async throws
}
