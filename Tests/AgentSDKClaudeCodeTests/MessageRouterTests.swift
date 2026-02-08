import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("MessageRouter Tests")
struct MessageRouterTests {

    // MARK: - Helpers

    private func mockWriteCapture() -> (@Sendable (Data) async throws -> Void, WrittenDataCapture) {
        let capture = WrittenDataCapture()

        let writeFn: @Sendable (Data) async throws -> Void = { data in
            capture.append(data)
        }

        return (writeFn, capture)
    }

    /// Collect all messages from a stream into an array
    private func collectMessages(
        from stream: AsyncThrowingStream<AgentMessage, Error>
    ) async throws -> [AgentMessage] {
        var messages: [AgentMessage] = []
        for try await msg in stream {
            messages.append(msg)
        }
        return messages
    }

    /// Parse a written Data blob as JSON dictionary
    private func parseWrittenJSON(_ data: Data) throws -> [String: Any] {
        let trimmed = data.last == 0x0A ? Data(data.dropLast()) : data
        return try JSONSerialization.jsonObject(with: trimmed) as! [String: Any]
    }

    // MARK: - Message Routing Tests

    @Test("Assistant message is yielded to stream")
    func testAssistantMessageRouting() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        // Route an assistant message with text content
        let cliMsg = CLIMessage.assistant(CLIAssistantMessage(
            message: .init(content: [
                .object(["type": .string("text"), "text": .string("Hello, world!")])
            ]),
            parentToolUseId: nil
        ))
        await router.route(cliMsg)
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 1)

        guard case .assistant(let info) = messages[0] else {
            Issue.record("Expected assistant message")
            return
        }
        #expect(info.content.count == 1)
        guard case .text(let text) = info.content[0] else {
            Issue.record("Expected text content block")
            return
        }
        #expect(text == "Hello, world!")
        #expect(info.parentToolUseId == nil)
    }

    @Test("Assistant message with parentToolUseId preserves it")
    func testAssistantWithParentToolUseId() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        let cliMsg = CLIMessage.assistant(CLIAssistantMessage(
            message: .init(content: [
                .object(["type": .string("text"), "text": .string("Sub-agent response")])
            ]),
            parentToolUseId: "tool_use_abc"
        ))
        await router.route(cliMsg)
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 1)
        guard case .assistant(let info) = messages[0] else {
            Issue.record("Expected assistant message"); return
        }
        #expect(info.parentToolUseId == "tool_use_abc")
    }

    @Test("Result message is yielded to stream with all fields")
    func testResultMessageRouting() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        let cliMsg = CLIMessage.result(CLIResultMessage(
            result: "Task completed",
            costUsd: 0.05,
            durationMs: 1500,
            inputTokens: 100,
            outputTokens: 50,
            sessionId: "sess_test",
            numTurns: 3
        ))
        await router.route(cliMsg)
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 1)

        guard case .result(let info) = messages[0] else {
            Issue.record("Expected result message"); return
        }
        #expect(info.result == "Task completed")
        #expect(info.costUsd == 0.05)
        #expect(info.durationMs == 1500)
        #expect(info.inputTokens == 100)
        #expect(info.outputTokens == 50)
        #expect(info.sessionId == "sess_test")
        #expect(info.numTurns == 3)
    }

    @Test("System message converts tools and mcpServers from JSONValue")
    func testSystemMessageRouting() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        let cliMsg = CLIMessage.system(CLISystemMessage(
            sessionId: "sess_sys",
            tools: [
                .object(["name": .string("Bash"), "description": .string("Run commands")]),
                .object(["name": .string("Read")])
            ],
            model: "claude-opus-4-6",
            mcpServers: [
                .object(["name": .string("server1"), "status": .string("connected")]),
                .object(["name": .string("server2")])
            ]
        ))
        await router.route(cliMsg)
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 1)

        guard case .system(let info) = messages[0] else {
            Issue.record("Expected system message"); return
        }
        #expect(info.sessionId == "sess_sys")
        #expect(info.model == "claude-opus-4-6")

        // Tools
        #expect(info.tools.count == 2)
        #expect(info.tools[0].name == "Bash")
        #expect(info.tools[0].description == "Run commands")
        #expect(info.tools[1].name == "Read")
        #expect(info.tools[1].description == nil)

        // MCP servers
        #expect(info.mcpServers.count == 2)
        #expect(info.mcpServers[0].name == "server1")
        #expect(info.mcpServers[0].status == "connected")
        #expect(info.mcpServers[1].name == "server2")
        #expect(info.mcpServers[1].status == "unknown") // default
    }

    @Test("Partial assistant message is yielded to stream")
    func testPartialMessageRouting() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        let cliMsg = CLIMessage.partialAssistant(CLIPartialAssistantMessage(
            message: .init(content: [
                .object(["type": .string("text"), "text": .string("Partial...")])
            ])
        ))
        await router.route(cliMsg)
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 1)

        guard case .partial(let info) = messages[0] else {
            Issue.record("Expected partial message"); return
        }
        #expect(info.content.count == 1)
        guard case .text(let text) = info.content[0] else {
            Issue.record("Expected text content"); return
        }
        #expect(text == "Partial...")
    }

    @Test("Multiple messages are yielded in order")
    func testMultipleMessagesOrder() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        await router.route(.assistant(CLIAssistantMessage(
            message: .init(content: [.object(["type": .string("text"), "text": .string("First")])]),
            parentToolUseId: nil
        )))
        await router.route(.assistant(CLIAssistantMessage(
            message: .init(content: [.object(["type": .string("text"), "text": .string("Second")])]),
            parentToolUseId: nil
        )))
        await router.route(.result(CLIResultMessage(
            result: "Done", costUsd: 0.01, durationMs: 500,
            inputTokens: 10, outputTokens: 5, sessionId: "sess", numTurns: 1
        )))
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 3)

        guard case .assistant = messages[0] else { Issue.record("Expected assistant #1"); return }
        guard case .assistant = messages[1] else { Issue.record("Expected assistant #2"); return }
        guard case .result = messages[2] else { Issue.record("Expected result"); return }
    }

    @Test("Unknown messages are silently ignored")
    func testUnknownMessageIgnored() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        await router.route(.unknown(type: "some_future_type"))
        await router.route(.initializeReady) // Also ignored during normal routing
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.isEmpty)
    }

    // MARK: - can_use_tool Tests

    @Test("can_use_tool with allow handler sends allow response")
    func testCanUseToolAllow() async throws {
        let (writeFn, capture) = mockWriteCapture()
        let router = MessageRouter(
            write: writeFn,
            canUseTool: { toolName, input, _ in
                #expect(toolName == "Bash")
                return .allow
            }
        )
        let _ = await router.makeStream()

        let request = CLIControlRequest(
            requestId: "req_test_1",
            request: .init(subtype: "can_use_tool", toolName: "Bash", toolInput: ["command": .string("ls")])
        )
        await router.route(.controlRequest(request))

        // Allow async write to complete
        try await Task.sleep(for: .milliseconds(100))

        let written = capture.getAll()
        #expect(written.count == 1)

        let json = try parseWrittenJSON(written[0])
        let response = json["response"] as? [String: Any]
        #expect(response?["request_id"] as? String == "req_test_1")
        #expect(response?["subtype"] as? String == "success")

        let respPayload = response?["response"] as? [String: Any]
        #expect(respPayload?["allowed"] as? Bool == true)
    }

    @Test("can_use_tool with deny handler sends deny response with reason")
    func testCanUseToolDeny() async throws {
        let (writeFn, capture) = mockWriteCapture()
        let router = MessageRouter(
            write: writeFn,
            canUseTool: { toolName, _, _ in
                return .deny(reason: "File writes not allowed")
            }
        )
        let _ = await router.makeStream()

        let request = CLIControlRequest(
            requestId: "req_test_2",
            request: .init(subtype: "can_use_tool", toolName: "Write", toolInput: nil)
        )
        await router.route(.controlRequest(request))

        try await Task.sleep(for: .milliseconds(100))

        let written = capture.getAll()
        #expect(written.count == 1)

        let json = try parseWrittenJSON(written[0])
        let response = json["response"] as? [String: Any]
        #expect(response?["request_id"] as? String == "req_test_2")

        let respPayload = response?["response"] as? [String: Any]
        #expect(respPayload?["allowed"] as? Bool == false)
        #expect(respPayload?["reason"] as? String == "File writes not allowed")
    }

    @Test("can_use_tool without handler defaults to allow")
    func testCanUseToolDefaultAllow() async throws {
        let (writeFn, capture) = mockWriteCapture()
        // No canUseTool handler
        let router = MessageRouter(write: writeFn)
        let _ = await router.makeStream()

        let request = CLIControlRequest(
            requestId: "req_test_3",
            request: .init(subtype: "can_use_tool", toolName: "Bash", toolInput: nil)
        )
        await router.route(.controlRequest(request))

        try await Task.sleep(for: .milliseconds(100))

        let written = capture.getAll()
        #expect(written.count == 1)

        let json = try parseWrittenJSON(written[0])
        let response = json["response"] as? [String: Any]
        let respPayload = response?["response"] as? [String: Any]
        #expect(respPayload?["allowed"] as? Bool == true)
    }

    // MARK: - SDK → CLI Control Request Tests

    @Test("SDK to CLI control request receives matching response")
    func testControlRequestResponse() async throws {
        let (writeFn, capture) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let _ = await router.makeStream()

        try await withThrowingTaskGroup(of: Void.self) { group in
            // Task 1: Send control request
            group.addTask {
                let result = try await router.sendControlRequest(
                    payload: .init(
                        subtype: "interrupt",
                        supportedCapabilities: nil, hooks: nil,
                        permissionMode: nil, model: nil,
                        userMessageUuid: nil, mcpServers: nil
                    ),
                    timeoutSeconds: 5
                )
                #expect(result.response.subtype == "success")
            }

            // Task 2: Route the matching response
            group.addTask {
                // Wait for the request to be written
                try await Task.sleep(for: .milliseconds(200))

                let written = capture.getAll()
                guard let lastWritten = written.last else {
                    Issue.record("No data written"); return
                }

                // Extract requestId from written data
                let trimmed = lastWritten.last == 0x0A ? Data(lastWritten.dropLast()) : lastWritten
                let json = try JSONSerialization.jsonObject(with: trimmed) as! [String: Any]
                let requestId = json["request_id"] as! String

                // Route matching response
                await router.route(.controlResponse(CLIControlResponse(
                    response: .init(subtype: "success", requestId: requestId, response: nil)
                )))
            }

            try await group.waitForAll()
        }
    }

    @Test("SDK to CLI control request times out")
    func testControlRequestTimeout() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let _ = await router.makeStream()

        // Short timeout, no response routed → should time out
        await #expect(throws: AgentSDKError.self) {
            try await router.sendControlRequest(
                payload: .init(
                    subtype: "test_timeout",
                    supportedCapabilities: nil, hooks: nil,
                    permissionMode: nil, model: nil,
                    userMessageUuid: nil, mcpServers: nil
                ),
                timeoutSeconds: 1
            )
        }
    }

    // MARK: - Finish Tests

    @Test("finish() ends the stream")
    func testFinishEndsStream() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.isEmpty)
    }

    @Test("finish(throwing:) ends the stream with error")
    func testFinishWithErrorEndsStream() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        await router.finish(throwing: AgentSDKError.notConnected)

        do {
            for try await _ in stream {
                Issue.record("Should not yield any messages")
            }
            Issue.record("Should have thrown")
        } catch {
            #expect(error is AgentSDKError)
        }
    }

    @Test("Content blocks with tool_use are converted correctly")
    func testToolUseContentConversion() async throws {
        let (writeFn, _) = mockWriteCapture()
        let router = MessageRouter(write: writeFn)
        let stream = await router.makeStream()

        let cliMsg = CLIMessage.assistant(CLIAssistantMessage(
            message: .init(content: [
                .object([
                    "type": .string("tool_use"),
                    "id": .string("tool_1"),
                    "name": .string("Bash"),
                    "input": .object(["command": .string("ls -la")])
                ])
            ]),
            parentToolUseId: nil
        ))
        await router.route(cliMsg)
        await router.finish()

        let messages = try await collectMessages(from: stream)
        #expect(messages.count == 1)

        guard case .assistant(let info) = messages[0] else {
            Issue.record("Expected assistant message"); return
        }
        guard case .toolUse(let toolUse) = info.content[0] else {
            Issue.record("Expected tool_use content block"); return
        }
        #expect(toolUse.id == "tool_1")
        #expect(toolUse.name == "Bash")
        #expect(toolUse.input["command"] == .string("ls -la"))
    }
}

// MARK: - Thread-safe Written Data Capture

/// Thread-safe array for capturing written data in concurrent test contexts.
/// Sendable so it can be safely captured across isolation boundaries.
final class WrittenDataCapture: @unchecked Sendable {
    private var storage: [Data] = []
    private let lock = NSLock()

    func append(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(data)
    }

    func getAll() -> [Data] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
