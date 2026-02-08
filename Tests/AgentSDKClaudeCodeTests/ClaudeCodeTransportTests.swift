import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("ClaudeCodeTransport Tests")
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
        // Should not throw
    }

    // MARK: - Mock CLI Integration Tests

    @Test("Connect with mock CLI completes handshake")
    func testConnectWithMockCLI() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"initialize_ready"}'
        read -r input
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

    @Test("Connect yields system message in messages stream")
    func testConnectYieldsSystemMessage() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"initialize_ready"}'
        read -r input
        echo '{"type":"system","session_id":"test_sess","tools":[],"model":"test-model","mcp_servers":[]}'
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(cliPath: scriptURL.path)
        try await transport.connect()

        var messages: [Data] = []
        for try await data in transport.messages() {
            messages.append(data)
        }

        // Should have the system message
        #expect(messages.count == 1)

        // Verify it's a system message
        let codec = JSONLCodec()
        let msg: CLIMessage = try codec.decode(messages[0])
        guard case .system(let sysMsg) = msg else {
            Issue.record("Expected system message"); return
        }
        #expect(sysMsg.sessionId == "test_sess")
        #expect(sysMsg.model == "test-model")

        try await transport.close()
    }

    @Test("Post-handshake messages are forwarded")
    func testPostHandshakeMessages() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"initialize_ready"}'
        read -r input
        echo '{"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}'
        echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Hello"}]},"parent_tool_use_id":null}'
        echo '{"type":"result","result":"done","cost_usd":0.01,"duration_ms":100,"input_tokens":10,"output_tokens":5,"session_id":"sess","num_turns":1}'
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

    @Test("write sends data to process stdin")
    func testWriteSendsData() async throws {
        // Script waits for a user message after handshake, then responds
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"initialize_ready"}'
        read -r input
        echo '{"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}'
        read -r user_msg
        echo '{"type":"assistant","message":{"content":[{"type":"text","text":"Got it"}]},"parent_tool_use_id":null}'
        echo '{"type":"result","result":"done","cost_usd":0.01,"duration_ms":100,"input_tokens":10,"output_tokens":5,"session_id":"sess","num_turns":1}'
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(cliPath: scriptURL.path)
        try await transport.connect()

        // Send a user message
        let codec = JSONLCodec()
        let userMsg = try codec.encode(SDKMessage.userMessage(content: "Hello"))
        try await transport.write(userMsg)

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

    @Test("Connect twice throws error")
    func testConnectTwice() async throws {
        let scriptURL = try createMockScript("""
        #!/bin/sh
        echo '{"type":"initialize_ready"}'
        read -r input
        echo '{"type":"system","session_id":"sess","tools":[],"model":"m","mcp_servers":[]}'
        sleep 5
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(cliPath: scriptURL.path)
        try await transport.connect()

        await #expect(throws: AgentSDKError.self) {
            try await transport.connect()
        }

        try await transport.close()
    }

    @Test("Additional CLI arguments are passed to process")
    func testAdditionalArguments() async throws {
        // Script echoes its arguments as part of the session_id
        let scriptURL = try createMockScript("""
        #!/bin/sh
        ARGS="$*"
        echo '{"type":"initialize_ready"}'
        read -r input
        echo "{\\"type\\":\\"system\\",\\"session_id\\":\\"$ARGS\\",\\"tools\\":[],\\"model\\":\\"m\\",\\"mcp_servers\\":[]}"
        """)
        defer { try? FileManager.default.removeItem(at: scriptURL) }

        let transport = ClaudeCodeTransport(
            cliPath: scriptURL.path,
            arguments: ["--verbose", "--max-turns", "5"]
        )
        try await transport.connect()

        var messages: [Data] = []
        for try await data in transport.messages() {
            messages.append(data)
        }

        #expect(messages.count == 1)

        // Verify the arguments were passed (embedded in session_id)
        let codec = JSONLCodec()
        let msg: CLIMessage = try codec.decode(messages[0])
        guard case .system(let sysMsg) = msg else {
            Issue.record("Expected system message"); return
        }
        #expect(sysMsg.sessionId.contains("--verbose"))
        #expect(sysMsg.sessionId.contains("--max-turns"))

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
