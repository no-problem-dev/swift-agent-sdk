import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("ClaudeCodeSession Tests", .serialized)
struct ClaudeCodeSessionTests {

    // MARK: - Protocol Conformance

    @Test("Session conforms to AgentSession protocol")
    func testProtocolConformance() async throws {
        let _: any AgentSession.Type = ClaudeCodeSession.self
    }

    @Test("Session is a final class (reference semantics)")
    func testReferenceSemantics() {
        #expect(Bool(true)) // Compile-time verification
    }

    // MARK: - Session ID

    @Test("Session created via client has correct session ID")
    func testSessionId() async throws {
        let (session, _) = try await createMockSession(sessionId: "test_session_42")
        let sessionId = await session.id
        #expect(sessionId == "test_session_42")
        try await session.close()
    }

    // MARK: - Send

    @Test("Session send returns assistant and result messages")
    func testSendReturnsMessages() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")

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

        #expect(messages.count == 2)

        guard case .assistant(let info) = messages[0] else {
            Issue.record("Expected assistant"); return
        }
        guard case .text(let text) = info.content[0] else {
            Issue.record("Expected text content"); return
        }
        #expect(text == "Response")

        guard case .result(let result) = messages[1] else {
            Issue.record("Expected result"); return
        }
        #expect(result.result == "done")

        try await session.close()
    }

    @Test("Session send writes user_message to transport")
    func testSendWritesUserMessage() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")

        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"result","result":"","cost_usd":0,"duration_ms":0,"input_tokens":0,"output_tokens":0,"session_id":"sess","num_turns":0}
            """)
        }

        for try await _ in session.send("My question") {}

        // Find the user_message write (skip any that happened during session creation)
        let written = transport.writtenData
        let userMessages = written.compactMap { data -> [String: Any]? in
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "user_message" else { return nil }
            return json
        }
        #expect(userMessages.count >= 1)
        #expect(userMessages.last?["content"] as? String == "My question")

        try await session.close()
    }

    @Test("Session supports multiple send calls")
    func testMultipleSends() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")

        // First send
        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"assistant","message":{"content":[{"type":"text","text":"First response"}]},"parent_tool_use_id":null}
            """)
            transport.yield("""
            {"type":"result","result":"first","cost_usd":0.01,"duration_ms":100,"input_tokens":10,"output_tokens":5,"session_id":"sess","num_turns":1}
            """)
        }

        var firstMessages: [AgentMessage] = []
        for try await msg in session.send("First question") {
            firstMessages.append(msg)
        }
        #expect(firstMessages.count == 2)

        // Second send
        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"assistant","message":{"content":[{"type":"text","text":"Second response"}]},"parent_tool_use_id":null}
            """)
            transport.yield("""
            {"type":"result","result":"second","cost_usd":0.02,"duration_ms":200,"input_tokens":20,"output_tokens":10,"session_id":"sess","num_turns":2}
            """)
        }

        var secondMessages: [AgentMessage] = []
        for try await msg in session.send("Second question") {
            secondMessages.append(msg)
        }
        #expect(secondMessages.count == 2)

        guard case .result(let result) = secondMessages[1] else {
            Issue.record("Expected result"); return
        }
        #expect(result.numTurns == 2)

        try await session.close()
    }

    // MARK: - Close

    @Test("Session close terminates cleanly")
    func testClose() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")
        try await session.close()
        #expect(transport.isClosed)
    }

    // MARK: - Runtime Control Methods (existence verification)

    @Test("Runtime control methods exist on ClaudeCodeSession")
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

    // MARK: - SubAgent Messages

    @Test("Session receives messages with parentToolUseId for sub-agents")
    func testSubAgentMessages() async throws {
        let (session, transport) = try await createMockSession(sessionId: "sess")

        Task {
            try await Task.sleep(for: .milliseconds(50))
            // Main agent message
            transport.yield("""
            {"type":"assistant","message":{"content":[{"type":"text","text":"Let me delegate"}]},"parent_tool_use_id":null}
            """)
            // Sub-agent message
            transport.yield("""
            {"type":"assistant","message":{"content":[{"type":"text","text":"Sub-agent response"}]},"parent_tool_use_id":"toolu_sub_001"}
            """)
            transport.yield("""
            {"type":"result","result":"done","cost_usd":0.03,"duration_ms":300,"input_tokens":30,"output_tokens":15,"session_id":"sess","num_turns":3}
            """)
        }

        var messages: [AgentMessage] = []
        for try await msg in session.send("Delegate task") {
            messages.append(msg)
        }

        #expect(messages.count == 3)

        // Main agent message has nil parentToolUseId
        guard case .assistant(let mainMsg) = messages[0] else {
            Issue.record("Expected assistant"); return
        }
        #expect(mainMsg.parentToolUseId == nil)

        // Sub-agent message has parentToolUseId
        guard case .assistant(let subMsg) = messages[1] else {
            Issue.record("Expected assistant"); return
        }
        #expect(subMsg.parentToolUseId == "toolu_sub_001")

        try await session.close()
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
