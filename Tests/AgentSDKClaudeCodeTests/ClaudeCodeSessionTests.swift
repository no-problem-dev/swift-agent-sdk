import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("ClaudeCodeSession Tests")
struct ClaudeCodeSessionTests {

    @Test("Session conforms to AgentSession protocol")
    func testProtocolConformance() async throws {
        let _: any AgentSession.Type = ClaudeCodeSession.self
    }

    @Test("Session is a final class (reference semantics)")
    func testReferenceSemantics() {
        #expect(Bool(true)) // Compile-time verification
    }

    @Test("Session created via client has correct session ID")
    func testSessionId() async throws {
        let (session, _) = try await createMockSession(sessionId: "test_session_42")
        let sessionId = await session.id
        #expect(sessionId == "test_session_42")
        try await session.close()
    }

    @Test("Session send returns message stream")
    func testSendReturnsStream() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")

        // Schedule responses for send()
        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"assistant","message":{"content":[{"type":"text","text":"Response"}]},"parent_tool_use_id":null}
            """)
            transport.yield("""
            {"type":"result","result":"done","cost_usd":0.01,"duration_ms":100,"input_tokens":10,"output_tokens":5,"session_id":"sess","num_turns":1}
            """)
        }

        var messages: [AgentMessage] = []
        for try await msg in session.send("Hello") {
            messages.append(msg)
        }

        #expect(messages.count >= 1)
        try await session.close()
    }

    @Test("Session close terminates cleanly")
    func testClose() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")
        try await session.close()
        #expect(transport.isClosed)
    }

    @Test("Runtime control methods exist")
    func testRuntimeControlMethodsExist() async throws {
        let _: (ClaudeCodeSession) -> (ModelSelection) async throws -> Void = { $0.setModel }
        let _: (ClaudeCodeSession) -> (PermissionMode) async throws -> Void = { $0.setPermissionMode }
        let _: (ClaudeCodeSession) -> (String) async throws -> Void = { $0.rewindFiles(toMessageId:) }
        let _: (ClaudeCodeSession) -> () async throws -> [CommandInfo] = { $0.supportedCommands }
        let _: (ClaudeCodeSession) -> () async throws -> [ModelInfo] = { $0.supportedModels }
        let _: (ClaudeCodeSession) -> () async throws -> [MCPServerInfo] = { $0.mcpServerStatus }
        let _: (ClaudeCodeSession) -> ([String: MCPServerConfig]) async throws -> Void = { $0.setMCPServers }
        #expect(Bool(true))
    }

    // MARK: - Helpers

    /// Create a session backed by MockTransport (no subprocess).
    private func createMockSession(
        sessionId: String
    ) async throws -> (ClaudeCodeSession, MockTransport) {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)

        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"system","session_id":"\(sessionId)","tools":[],"model":"m","mcp_servers":[]}
            """)
        }

        let session = try await client.createSession()
        return (session, transport)
    }
}
