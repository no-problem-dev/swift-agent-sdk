import Foundation

/// Internal placeholder session for stub implementations.
/// Will be replaced when ClaudeCodeSession is available.
internal struct _PlaceholderSession: AgentSession, Sendable {
    var id: String { "" }

    func send(_ message: String) -> AsyncThrowingStream<AgentMessage, Error> {
        AsyncThrowingStream { $0.finish(throwing: AgentSDKError.notConnected) }
    }

    func interrupt() async throws {
        throw AgentSDKError.notConnected
    }

    func close() async throws {}
}

/// Convenience namespace for Swift Agent SDK.
///
/// Provides DI-free entry points using the default Claude Code implementation.
///
/// ```swift
/// for try await message in AgentSDK.query(prompt: "Hello") {
///     switch message {
///     case .assistant(let info): print(info.content)
///     case .result(let result): print("Cost: $\(result.costUsd)")
///     default: break
///     }
/// }
/// ```
public enum AgentSDK {
    /// Execute a one-shot query using the default Claude Code implementation.
    ///
    /// - Parameters:
    ///   - prompt: The prompt string to send
    ///   - options: Query options (defaults to empty)
    /// - Returns: An async stream of ``AgentMessage`` values
    public static func query(
        prompt: String,
        options: QueryOptions = QueryOptions()
    ) -> AsyncThrowingStream<AgentMessage, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AgentSDKError.notConnected)
        }
    }

    /// Create a new session using the default Claude Code implementation.
    ///
    /// - Parameter options: Session options (defaults to empty)
    /// - Returns: An ``AgentSession`` instance
    /// - Note: Stub implementation. Will be replaced in T19.
    public static func createSession(
        options: SessionOptions = SessionOptions()
    ) async throws -> some AgentSession {
        return try await _throwNotConnected()
    }

    /// Resume an existing session using the default Claude Code implementation.
    ///
    /// - Parameters:
    ///   - id: The session ID to resume
    ///   - options: Session options (defaults to empty)
    /// - Returns: An ``AgentSession`` instance
    /// - Note: Stub implementation. Will be replaced in T19.
    public static func resumeSession(
        id: String,
        options: SessionOptions = SessionOptions()
    ) async throws -> some AgentSession {
        return try await _throwNotConnected()
    }

    // Helper to throw without unreachable code warnings
    private static func _throwNotConnected() async throws -> _PlaceholderSession {
        throw AgentSDKError.notConnected
    }
}
