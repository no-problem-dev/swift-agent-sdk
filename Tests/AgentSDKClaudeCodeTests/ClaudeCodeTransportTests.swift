import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("ClaudeCodeTransport Tests", .serialized)
struct ClaudeCodeTransportTests {

    // MARK: - JSRuntime Tests

    @Test("JSRuntime raw values")
    func testJSRuntimeRawValues() {
        #expect(JSRuntime.node.rawValue == "node")
        #expect(JSRuntime.bun.rawValue == "bun")
        #expect(JSRuntime.deno.rawValue == "deno")
    }

    @Test("JSRuntime init from raw value")
    func testJSRuntimeFromRawValue() {
        #expect(JSRuntime(rawValue: "node") == .node)
        #expect(JSRuntime(rawValue: "bun") == .bun)
        #expect(JSRuntime(rawValue: "deno") == .deno)
        #expect(JSRuntime(rawValue: "invalid") == nil)
    }

    // MARK: - Pre-connect State Tests

    @Test("isReady is false before connect")
    func testIsReadyBeforeConnect() async {
        let transport = ClaudeCodeTransport()
        let ready = await transport.isReady
        #expect(ready == false)
    }

    @Test("write before connect throws notConnected")
    func testWriteBeforeConnect() async throws {
        let transport = ClaudeCodeTransport()
        let data = "test".data(using: .utf8)!
        await #expect(throws: AgentSDKError.self) {
            try await transport.write(data)
        }
    }

    @Test("messages before connect returns error stream")
    func testMessagesBeforeConnect() async throws {
        let transport = ClaudeCodeTransport()
        let stream = transport.messages()
        do {
            for try await _ in stream {
                Issue.record("Should not yield any messages")
            }
            Issue.record("Should have thrown")
        } catch {
            #expect(error is AgentSDKError)
        }
    }

    @Test("close before connect is safe")
    func testCloseBeforeConnect() async throws {
        let transport = ClaudeCodeTransport()
        try await transport.close()
    }

    // MARK: - Mock CLI Integration Tests

    @Test("Connect with mock CLI completes handshake", .timeLimit(.minutes(1)))
    func testConnectWithMockCLI() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"system","session_id":"test_sess","tools":[],"model":"test-model","mcp_servers":[]}'
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(cliPath: scriptURL.path)
        #expect(await transport.isReady == false)

        try await transport.connect()
        #expect(await transport.isReady == true)

        try await transport.close()
        #expect(await transport.isReady == false)
    }

    @Test("Post-handshake messages are forwarded", .timeLimit(.minutes(1)))
    func testPostHandshakeMessages() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}'
        echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Hello"}]},"parent_tool_use_id":null}'
        echo '{"type":"result","result":"done","total_cost_usd":0.01,"duration_ms":100,"usage":{"input_tokens":10,"output_tokens":5},"session_id":"sess","num_turns":1}'
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(cliPath: scriptURL.path)
        try await transport.connect()

        var messages: [Data] = []
        for try await data in transport.messages() {
            messages.append(data)
        }

        // system + assistant + result
        #expect(messages.count == 3)

        try await transport.close()
    }

    @Test("Connect with invalid CLI path throws cliNotFound")
    func testConnectInvalidPath() async throws {
        let transport = ClaudeCodeTransport(cliPath: "/nonexistent/path/to/cli")
        await #expect(throws: AgentSDKError.self) {
            try await transport.connect()
        }
    }

    @Test("Connect twice throws error", .timeLimit(.minutes(1)))
    func testConnectTwice() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}'
        sleep 1
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(cliPath: scriptURL.path)
        try await transport.connect()

        await #expect(throws: AgentSDKError.self) {
            try await transport.connect()
        }

        try await transport.close()
    }

    // MARK: - Helpers

    private func createMockScript(_ content: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let scriptPath = tempDir.appendingPathComponent("mock_cli_\(UUID().uuidString).sh")
        try content.write(to: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptPath.path
        )
        return scriptPath
    }
}
