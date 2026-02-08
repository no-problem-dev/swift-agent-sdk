import Foundation
import AgentSDK

extension AgentSDK {

    /// Execute a one-shot query using the default Claude Code implementation.
    ///
    /// Creates a ``ClaudeCodeTransport`` and ``ClaudeCodeClient`` internally,
    /// connects to the CLI subprocess, sends the prompt, and streams responses.
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
    ///
    /// - Parameters:
    ///   - prompt: The prompt string to send
    ///   - options: Query options (defaults to empty)
    /// - Returns: An async stream of ``AgentMessage`` values
    public static func query(
        prompt: String,
        options: QueryOptions = QueryOptions()
    ) -> AsyncThrowingStream<AgentMessage, Error> {
        let args = CLIArgBuilder.buildArguments(from: options)
        let transport = ClaudeCodeTransport(
            arguments: args,
            workingDirectory: options.cwd
        )
        let client = ClaudeCodeClient(transport: transport)
        return client.query(prompt: prompt, options: options)
    }

    /// Create a new session using the default Claude Code implementation.
    ///
    /// ```swift
    /// let session = try await AgentSDK.createSession()
    /// for try await msg in session.send("First question") { ... }
    /// for try await msg in session.send("Follow-up") { ... }
    /// try await session.close()
    /// ```
    ///
    /// - Parameter options: Session options (defaults to empty)
    /// - Returns: A ``ClaudeCodeSession`` instance
    public static func createSession(
        options: SessionOptions = SessionOptions()
    ) async throws -> ClaudeCodeSession {
        let args = CLIArgBuilder.buildArguments(from: options)
        let transport = ClaudeCodeTransport(
            arguments: args,
            workingDirectory: options.cwd
        )
        let client = ClaudeCodeClient(transport: transport)
        return try await client.createSession(options: options)
    }

    /// Resume an existing session using the default Claude Code implementation.
    ///
    /// - Parameters:
    ///   - id: The session ID to resume
    ///   - options: Session options (defaults to empty)
    /// - Returns: A ``ClaudeCodeSession`` instance
    public static func resumeSession(
        id: String,
        options: SessionOptions = SessionOptions()
    ) async throws -> ClaudeCodeSession {
        let args = CLIArgBuilder.buildArguments(from: options, resumeSessionId: id)
        let transport = ClaudeCodeTransport(
            arguments: args,
            workingDirectory: options.cwd
        )
        let client = ClaudeCodeClient(transport: transport)
        return try await client.resumeSession(id: id, options: options)
    }
}
