import Testing
import Foundation
import Synchronization
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("ClaudeCodeClient Tests", .serialized)
struct ClaudeCodeClientTests {

    // MARK: - Protocol Conformance

    @Test("Client conforms to AgentClient protocol")
    func testProtocolConformance() {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)
        let _: ClaudeCodeClient<MockTransport>.Session.Type = ClaudeCodeSession.self
        _ = client
    }

    @Test("query returns AsyncThrowingStream synchronously")
    func testQueryReturnsStream() {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)
        let stream = client.query(prompt: "Hello")
        _ = stream
    }

    // MARK: - One-shot Query

    @Test("query with MockTransport produces system, assistant, result")
    func testQuerySuccess() async throws {
        let transport = MockTransport(responses: [
            """
            {"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}
            """,
            """
            {"type":"assistant","message":{"content":[{"type":"text","text":"Hello!"}]},"parent_tool_use_id":null}
            """,
            """
            {"type":"result","result":"done","total_cost_usd":0.01,"duration_ms":100,"usage":{"input_tokens":10,"output_tokens":5},"session_id":"sess","num_turns":1}
            """,
        ])

        let client = ClaudeCodeClient(transport: transport)

        var messages: [AgentMessage] = []
        for try await msg in client.query(prompt: "Hello") {
            messages.append(msg)
        }

        #expect(messages.count == 3)

        guard case .system(let sys) = messages[0] else {
            Issue.record("Expected system message"); return
        }
        #expect(sys.sessionId == "sess")

        guard case .assistant(let info) = messages[1] else {
            Issue.record("Expected assistant message"); return
        }
        guard case .text(let text) = info.content[0] else {
            Issue.record("Expected text content"); return
        }
        #expect(text == "Hello!")

        guard case .result(let result) = messages[2] else {
            Issue.record("Expected result message"); return
        }
        #expect(result.result == "done")
        #expect(result.costUsd == 0.01)
        #expect(result.numTurns == 1)
    }

    @Test("query with tool use produces 4 messages")
    func testQueryWithToolUse() async throws {
        let transport = MockTransport(responses: [
            """
            {"type":"system","session_id":"sess","tools":[{"name":"Bash","description":"Run commands"}],"model":"m","mcp_servers":[]}
            """,
            """
            {"type":"assistant","message":{"content":[{"type":"tool_use","id":"toolu_001","name":"Bash","input":{"command":"echo hi"}}]},"parent_tool_use_id":null}
            """,
            """
            {"type":"assistant","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_001","content":"hi","is_error":false}]},"parent_tool_use_id":null}
            """,
            """
            {"type":"result","result":"hi","total_cost_usd":0.02,"duration_ms":200,"usage":{"input_tokens":20,"output_tokens":10},"session_id":"sess","num_turns":2}
            """,
        ])

        let client = ClaudeCodeClient(transport: transport)

        var messages: [AgentMessage] = []
        for try await msg in client.query(prompt: "Run echo hi") {
            messages.append(msg)
        }

        #expect(messages.count == 4)

        guard case .system(let sys) = messages[0] else {
            Issue.record("Expected system"); return
        }
        #expect(sys.tools.count == 1)
        #expect(sys.tools[0].name == "Bash")

        guard case .assistant(let toolUseMsg) = messages[1] else {
            Issue.record("Expected assistant with toolUse"); return
        }
        guard case .toolUse(let toolUse) = toolUseMsg.content[0] else {
            Issue.record("Expected toolUse content"); return
        }
        #expect(toolUse.name == "Bash")

        guard case .assistant(let toolResultMsg) = messages[2] else {
            Issue.record("Expected assistant with toolResult"); return
        }
        guard case .toolResult(let toolResult) = toolResultMsg.content[0] else {
            Issue.record("Expected toolResult content"); return
        }
        #expect(toolResult.toolUseId == "toolu_001")
        #expect(toolResult.content == "hi")
        #expect(toolResult.isError == false)

        guard case .result(let result) = messages[3] else {
            Issue.record("Expected result"); return
        }
        #expect(result.numTurns == 2)
    }

    @Test("query writes user message to transport")
    func testQueryWritesUserMessage() async throws {
        let transport = MockTransport(responses: [
            """
            {"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}
            """,
            """
            {"type":"result","result":"","total_cost_usd":0,"duration_ms":0,"usage":{"input_tokens":0,"output_tokens":0},"session_id":"sess","num_turns":0}
            """,
        ])

        let client = ClaudeCodeClient(transport: transport)
        for try await _ in client.query(prompt: "Test prompt") {}

        let written = transport.writtenData
        // Should have at least 1 write (the user_message)
        #expect(written.count >= 1)

        // The last write should be a user message containing our prompt
        let lastWrite = written.last!
        let json = try JSONSerialization.jsonObject(with: lastWrite) as! [String: Any]
        #expect(json["type"] as? String == "user")
        if let messageBody = json["message"] as? [String: Any] {
            #expect(messageBody["role"] as? String == "user")
            if let content = messageBody["content"] as? [[String: Any]] {
                #expect(content.count == 1)
                #expect(content[0]["type"] as? String == "text")
                #expect(content[0]["text"] as? String == "Test prompt")
            } else {
                Issue.record("Expected content array")
            }
        } else {
            Issue.record("Expected message field")
        }
    }

    @Test("query closes transport after completion")
    func testQueryClosesTransport() async throws {
        let transport = MockTransport(responses: [
            """
            {"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}
            """,
            """
            {"type":"result","result":"done","total_cost_usd":0,"duration_ms":0,"usage":{"input_tokens":0,"output_tokens":0},"session_id":"sess","num_turns":0}
            """,
        ])

        let client = ClaudeCodeClient(transport: transport)
        for try await _ in client.query(prompt: "Hello") {}

        // Give a moment for cleanup
        try await Task.sleep(for: .milliseconds(50))
        #expect(transport.isClosed)
    }

    // MARK: - canUseTool Handler

    @Test("query with canUseTool allow handler")
    func testCanUseToolAllow() async throws {
        let transport = MockTransport()
        let handlerCalled = Mutex(false)

        let client = ClaudeCodeClient(transport: transport)
        let options = QueryOptions(
            canUseTool: { toolName, _, _ in
                handlerCalled.withLock { $0 = true }
                #expect(toolName == "Bash")
                return .allow
            }
        )

        // After connect + messages(), we manually emit the flow
        Task {
            try await Task.sleep(for: .milliseconds(50))
            // System message
            transport.yield("""
            {"type":"system","session_id":"sess","tools":[{"name":"Bash"}],"model":"m","mcp_servers":[]}
            """)
            // Control request: can_use_tool
            transport.yield("""
            {"type":"control_request","request_id":"ctrl_001","request":{"subtype":"can_use_tool","tool_name":"Bash","tool_input":{"command":"echo hi"}}}
            """)
            // Wait for the handler to process and write response
            try await Task.sleep(for: .milliseconds(100))
            // Result to end the query
            transport.yield("""
            {"type":"result","result":"done","total_cost_usd":0.01,"duration_ms":100,"usage":{"input_tokens":10,"output_tokens":5},"session_id":"sess","num_turns":1}
            """)
            transport.finishStream()
        }

        var messages: [AgentMessage] = []
        for try await msg in client.query(prompt: "Run something", options: options) {
            messages.append(msg)
        }

        #expect(handlerCalled.withLock { $0 })
        // Check that the response was written back to transport
        let written = transport.writtenData
        // Find the control_response write
        let controlResponses = written.compactMap { data -> [String: Any]? in
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "control_response" else { return nil }
            return json
        }
        #expect(controlResponses.count == 1)
    }

    @Test("query with canUseTool deny handler")
    func testCanUseToolDeny() async throws {
        let transport = MockTransport()

        let client = ClaudeCodeClient(transport: transport)
        let options = QueryOptions(
            canUseTool: { _, _, _ in
                .deny(reason: "Not allowed in tests")
            }
        )

        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}
            """)
            transport.yield("""
            {"type":"control_request","request_id":"ctrl_002","request":{"subtype":"can_use_tool","tool_name":"Bash","tool_input":{}}}
            """)
            try await Task.sleep(for: .milliseconds(100))
            transport.yield("""
            {"type":"result","result":"denied","total_cost_usd":0,"duration_ms":0,"usage":{"input_tokens":0,"output_tokens":0},"session_id":"sess","num_turns":0}
            """)
            transport.finishStream()
        }

        for try await _ in client.query(prompt: "Test", options: options) {}

        // Verify the deny response was written
        let written = transport.writtenData
        let controlResponses = written.compactMap { data -> [String: Any]? in
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["type"] as? String == "control_response" else { return nil }
            return json
        }
        #expect(controlResponses.count == 1)

        // The response should contain allowed=false
        if let resp = controlResponses.first,
           let respPayload = resp["response"] as? [String: Any],
           let inner = respPayload["response"] as? [String: Any] {
            #expect(inner["allowed"] as? Bool == false)
            #expect(inner["reason"] as? String == "Not allowed in tests")
        }
    }

    // MARK: - Session

    @Test("createSession returns session immediately with generated ID")
    func testCreateSessionReturnsImmediately() async throws {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)

        // createSession() no longer waits for system message (CLI v2.x sends
        // system message only after the first user message).
        let session = try await client.createSession()
        let sessionId = await session.id
        #expect(!sessionId.isEmpty) // Has a generated UUID

        try await session.close()
    }

    @Test("createSession session ID is updated from system message on first send")
    func testCreateSessionExtractsSessionId() async throws {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)

        let session = try await client.createSession()

        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"system","session_id":"test-session-123","tools":[],"model":"m","mcp_servers":[]}
            """)
            transport.yield("""
            {"type":"result","result":"done","total_cost_usd":0,"duration_ms":0,"usage":{"input_tokens":0,"output_tokens":0},"session_id":"test-session-123","num_turns":0}
            """)
        }

        for try await _ in session.send("Hello") {}

        let sessionId = await session.id
        #expect(sessionId == "test-session-123")
        try await session.close()
    }

    @Test("resumeSession returns session")
    func testResumeSession() async throws {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)

        let session = try await client.resumeSession(id: "resumed-sess")

        Task {
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"system","session_id":"resumed-sess","tools":[],"model":"m","mcp_servers":[]}
            """)
            transport.yield("""
            {"type":"result","result":"done","total_cost_usd":0,"duration_ms":0,"usage":{"input_tokens":0,"output_tokens":0},"session_id":"resumed-sess","num_turns":0}
            """)
        }

        for try await _ in session.send("Resume") {}

        let sessionId = await session.id
        #expect(sessionId == "resumed-sess")
        try await session.close()
    }

    // MARK: - Error Propagation

    @Test("query propagates transport error")
    func testQueryPropagatesTransportError() async throws {
        let transport = MockTransport()
        transport.simulatedConnectFailure = true

        let client = ClaudeCodeClient(transport: transport)

        do {
            for try await _ in client.query(prompt: "Hello") {
                Issue.record("Should not yield messages")
            }
            Issue.record("Should have thrown")
        } catch {
            // Expected: transport error propagated
            #expect(error is AgentSDKError)
        }
    }
}
