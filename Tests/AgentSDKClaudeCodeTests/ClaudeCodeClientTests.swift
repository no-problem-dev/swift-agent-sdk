import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("ClaudeCodeClient Tests")
struct ClaudeCodeClientTests {

    @Test("Client conforms to AgentClient protocol")
    func testProtocolConformance() {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)
        let _: ClaudeCodeClient<MockTransport>.Session.Type = ClaudeCodeSession.self
        _ = client
    }

    @Test("query returns AsyncThrowingStream")
    func testQueryReturnsStream() {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)
        let stream = client.query(prompt: "Hello")
        _ = stream
    }

    @Test("query with MockTransport produces messages")
    func testQueryWithMockTransport() async throws {
        let transport = MockTransport(responses: [
            """
            {"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}
            """,
            """
            {"type":"assistant","message":{"content":[{"type":"text","text":"Hello!"}]},"parent_tool_use_id":null}
            """,
            """
            {"type":"result","result":"done","cost_usd":0.01,"duration_ms":100,"input_tokens":10,"output_tokens":5,"session_id":"sess","num_turns":1}
            """,
        ])

        let client = ClaudeCodeClient(transport: transport)

        var messages: [AgentMessage] = []
        for try await msg in client.query(prompt: "Hello") {
            messages.append(msg)
        }

        // system + assistant + result
        #expect(messages.count == 3)

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
    }

    @Test("createSession extracts session ID from system message")
    func testCreateSessionExtractsSessionId() async throws {
        let transport = MockTransport()
        let client = ClaudeCodeClient(transport: transport)

        // Emit system message after connect (simulating the handshake flow)
        Task {
            // Wait for messages() to be called and connect to happen
            try await Task.sleep(for: .milliseconds(50))
            transport.yield("""
            {"type":"system","session_id":"test-session-123","tools":[],"model":"m","mcp_servers":[]}
            """)
        }

        let session = try await client.createSession()
        let sessionId = await session.id
        #expect(sessionId == "test-session-123")
        try await session.close()
    }
}
