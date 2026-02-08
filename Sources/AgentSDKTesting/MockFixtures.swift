import Foundation
import AgentSDK

/// Pre-defined message sequences for common test scenarios.
///
/// ```swift
/// let mock = MockTransport(responses: MockFixtures.simpleSuccess())
/// let client = ClaudeCodeClient(transport: mock)
/// for try await msg in client.query(prompt: "Hello") { ... }
/// ```
public enum MockFixtures {

    /// Minimal success response: system -> assistant(text) -> result.
    ///
    /// - Parameter text: The assistant's response text. Defaults to `"Hello!"`.
    /// - Returns: A 3-message sequence.
    public static func simpleSuccess(text: String = "Hello!") -> [AgentMessage] {
        [
            .system(SystemInfo(
                sessionId: "mock-session",
                tools: [],
                model: "claude-sonnet-4-5-20250929",
                mcpServers: []
            )),
            .assistant(AssistantInfo(
                content: [.text(text)],
                parentToolUseId: nil
            )),
            .result(ResultInfo(
                result: text,
                costUsd: 0.01,
                durationMs: 100,
                inputTokens: 10,
                outputTokens: 5,
                sessionId: "mock-session",
                numTurns: 1
            )),
        ]
    }

    /// Response with tool usage: system -> assistant(toolUse) -> assistant(toolResult) -> result.
    ///
    /// - Parameters:
    ///   - toolName: Name of the tool. Defaults to `"Bash"`.
    ///   - result: The tool execution result text. Defaults to `"Done"`.
    /// - Returns: A 4-message sequence.
    public static func withToolUse(
        toolName: String = "Bash",
        result: String = "Done"
    ) -> [AgentMessage] {
        let toolUseId = "toolu_mock_001"
        return [
            .system(SystemInfo(
                sessionId: "mock-session",
                tools: [ToolInfo(name: toolName, description: "Mock tool")],
                model: "claude-sonnet-4-5-20250929",
                mcpServers: []
            )),
            .assistant(AssistantInfo(
                content: [.toolUse(ToolUse(
                    id: toolUseId,
                    name: toolName,
                    input: ["command": .string("echo hello")]
                ))],
                parentToolUseId: nil
            )),
            .assistant(AssistantInfo(
                content: [.toolResult(ToolResult(
                    toolUseId: toolUseId,
                    content: result,
                    isError: false
                ))],
                parentToolUseId: nil
            )),
            .result(ResultInfo(
                result: result,
                costUsd: 0.02,
                durationMs: 200,
                inputTokens: 20,
                outputTokens: 10,
                sessionId: "mock-session",
                numTurns: 2
            )),
        ]
    }

    /// Error response: system -> result with error.
    ///
    /// Returns a sequence that simulates a protocol error scenario.
    /// - Returns: A 2-message sequence ending with error result.
    public static func protocolError() -> [AgentMessage] {
        [
            .system(SystemInfo(
                sessionId: "mock-session",
                tools: [],
                model: "claude-sonnet-4-5-20250929",
                mcpServers: []
            )),
            .result(ResultInfo(
                result: "",
                costUsd: 0.0,
                durationMs: 0,
                inputTokens: 0,
                outputTokens: 0,
                sessionId: "mock-session",
                numTurns: 0
            )),
        ]
    }
}
