import Foundation

/// Public error type for Swift Agent SDK. Every case carries a message with resolution guidance.
///
/// This type represents all error states that can occur in the Swift Agent SDK.
/// Each case includes detailed information to help diagnose and resolve the issue.
public enum AgentSDKError: Error, Sendable {
    /// CLI binary was not found.
    ///
    /// - Parameter searchedPaths: All paths that were searched.
    ///
    /// The Claude Code CLI could not be found on this system.
    /// Install it with: `npm install -g @anthropic-ai/claude-agent-sdk`
    case cliNotFound(searchedPaths: [String])

    /// JavaScript runtime (Node.js / Bun / Deno) was not found.
    ///
    /// - Parameter runtime: The runtime name that was searched.
    ///
    /// The specified JavaScript runtime was not found in PATH.
    /// Node.js 18 or later is recommended.
    case runtimeNotFound(runtime: String)

    /// Failed to launch the CLI process.
    ///
    /// - Parameter underlying: The underlying error that caused the launch failure.
    ///
    /// `Process.run()` for the CLI process failed.
    /// Check permissions, the executable path, and runtime configuration.
    case processLaunchFailed(underlying: any Error)

    /// CLI process exited abnormally.
    ///
    /// - Parameters:
    ///   - exitCode: The process exit code.
    ///   - stderr: Standard error output from the process.
    ///
    /// The CLI process terminated with a non-zero exit code.
    /// This may indicate an authentication error or version mismatch.
    case processExited(exitCode: Int32, stderr: String)

    /// JSONL protocol error (malformed JSON or unexpected message).
    ///
    /// - Parameters:
    ///   - message: Detailed error message.
    ///   - rawData: The raw data that failed to parse, if available.
    ///
    /// Parsing or validation of a JSONL message from the CLI failed.
    /// Ensure the SDK and CLI versions are compatible.
    case protocolError(message: String, rawData: Data?)

    /// Initialization timed out.
    ///
    /// - Parameter seconds: The timeout duration in seconds.
    ///
    /// The CLI process did not return an initialization message within the allotted time.
    /// Check network connectivity and CLI responsiveness.
    case initializationTimeout(seconds: Int)

    /// Control request timed out.
    ///
    /// - Parameters:
    ///   - subtype: The type of control request that timed out.
    ///   - seconds: The timeout duration in seconds.
    ///
    /// A control request (createSession, closeSession, etc.) did not complete within the allotted time.
    /// Check CLI load and network conditions.
    case controlRequestTimeout(subtype: String, seconds: Int)

    /// Session has expired.
    ///
    /// - Parameter sessionId: The ID of the expired session.
    ///
    /// The session exceeded the inactivity timeout (default: 10 minutes).
    /// Create a new session or use `resumeSession()`.
    case sessionExpired(sessionId: String)

    /// Session is already closed.
    ///
    /// - Parameter sessionId: The ID of the closed session.
    ///
    /// An operation was attempted on a session that has already been closed.
    /// Create a new session to continue.
    case sessionClosed(sessionId: String)

    /// Transport is not connected.
    ///
    /// A message send was attempted while the transport is not connected.
    /// Call `connect()` before sending messages.
    case notConnected

    /// Operation was cancelled.
    ///
    /// The task or operation was cancelled by the caller.
    /// This is expected behavior when using `Task.cancel()` or `interrupt()`.
    case cancelled
}

extension AgentSDKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cliNotFound(let paths):
            return """
            Claude Code CLI not found. \
            Searched paths: \(paths.joined(separator: ", ")). \
            Install with: npm install -g @anthropic-ai/claude-agent-sdk
            """
        case .runtimeNotFound(let runtime):
            return """
            JavaScript runtime '\(runtime)' not found. \
            Install Node.js 18+ from https://nodejs.org or specify an alternative runtime.
            """
        case .processLaunchFailed(let underlying):
            return """
            Failed to launch CLI process: \(underlying.localizedDescription). \
            Verify the CLI is installed and the path is correct.
            """
        case .processExited(let exitCode, let stderr):
            return """
            CLI process exited with code \(exitCode). \
            stderr: \(stderr.isEmpty ? "(empty)" : stderr). \
            Check the Claude Code CLI installation and authentication.
            """
        case .protocolError(let message, _):
            return """
            JSONL protocol error: \(message). \
            This may indicate a version mismatch between the SDK and CLI.
            """
        case .initializationTimeout(let seconds):
            return """
            CLI initialization timed out after \(seconds) seconds. \
            Ensure the CLI is responsive and the network is available.
            """
        case .controlRequestTimeout(let subtype, let seconds):
            return """
            Control request '\(subtype)' timed out after \(seconds) seconds. \
            The CLI may be unresponsive or overloaded.
            """
        case .sessionExpired(let sessionId):
            return """
            Session '\(sessionId)' has expired. \
            Sessions expire after 10 minutes of inactivity. Create a new session or use resumeSession().
            """
        case .sessionClosed(let sessionId):
            return """
            Session '\(sessionId)' is already closed. \
            Create a new session to continue.
            """
        case .notConnected:
            return """
            Transport is not connected. \
            Call connect() before sending messages.
            """
        case .cancelled:
            return """
            Operation was cancelled. \
            This is expected when using Task.cancel() or interrupt().
            """
        }
    }
}
