import Testing
import Foundation
import AgentSDK
import AgentSDKTesting

@Suite("MockTransport Tests")
struct MockTransportTests {

    // MARK: - Protocol Conformance

    @Test("MockTransport conforms to AgentTransport")
    func testProtocolConformance() {
        let _: any AgentTransport = MockTransport()
    }

    // MARK: - Connection

    @Test("connect sets isReady to true")
    func testConnectSetsReady() async throws {
        let mock = MockTransport()
        let readyBefore = await mock.isReady
        #expect(readyBefore == false)

        try await mock.connect()
        let readyAfter = await mock.isReady
        #expect(readyAfter == true)
    }

    @Test("connect with simulatedIsReady=false throws notConnected")
    func testConnectWithSimulatedNotReady() async throws {
        let mock = MockTransport()
        mock.simulatedIsReady = false

        await #expect(throws: AgentSDKError.self) {
            try await mock.connect()
        }
    }

    @Test("close sets isReady to false")
    func testCloseResetsReady() async throws {
        let mock = MockTransport()
        try await mock.connect()
        #expect(await mock.isReady == true)

        try await mock.close()
        #expect(await mock.isReady == false)
        #expect(mock.isClosed == true)
    }

    // MARK: - Responses

    @Test("messages stream yields pre-defined responses after write")
    func testResponsesAfterWrite() async throws {
        let responses: [AgentMessage] = [
            .system(SystemInfo(sessionId: "s", tools: [], model: "m", mcpServers: [])),
            .assistant(AssistantInfo(content: [.text("Hi")], parentToolUseId: nil)),
            .result(ResultInfo(result: "Hi", costUsd: 0.01, durationMs: 100,
                               inputTokens: 10, outputTokens: 5, sessionId: "s", numTurns: 1)),
        ]
        let mock = MockTransport(responses: responses)
        try await mock.connect()

        let stream = mock.messages()

        // Write triggers response emission
        try await mock.write("test".data(using: .utf8)!)

        var received: [Data] = []
        for try await data in stream {
            received.append(data)
        }

        #expect(received.count == 3)

        // Verify each can be decoded back to AgentMessage
        let decoder = JSONDecoder()
        let msg0 = try decoder.decode(AgentMessage.self, from: received[0])
        guard case .system(let info) = msg0 else {
            Issue.record("Expected system message"); return
        }
        #expect(info.sessionId == "s")

        let msg1 = try decoder.decode(AgentMessage.self, from: received[1])
        guard case .assistant = msg1 else {
            Issue.record("Expected assistant message"); return
        }

        let msg2 = try decoder.decode(AgentMessage.self, from: received[2])
        guard case .result = msg2 else {
            Issue.record("Expected result message"); return
        }
    }

    @Test("empty responses produces empty stream after close")
    func testEmptyResponses() async throws {
        let mock = MockTransport(responses: [])
        try await mock.connect()

        let stream = mock.messages()
        try await mock.write("test".data(using: .utf8)!)

        // Close to end the stream
        try await mock.close()

        var count = 0
        for try await _ in stream {
            count += 1
        }
        #expect(count == 0)
    }

    // MARK: - Sent Messages

    @Test("write records messages to sentMessages")
    func testSentMessagesRecorded() async throws {
        let mock = MockTransport()
        try await mock.connect()

        let data1 = "message1".data(using: .utf8)!
        let data2 = "message2".data(using: .utf8)!
        try await mock.write(data1)
        try await mock.write(data2)

        let sent = mock.sentMessages
        #expect(sent.count == 2)
        #expect(sent[0] == data1)
        #expect(sent[1] == data2)
    }

    @Test("write before connect throws notConnected")
    func testWriteBeforeConnect() async throws {
        let mock = MockTransport()
        await #expect(throws: AgentSDKError.self) {
            try await mock.write("test".data(using: .utf8)!)
        }
    }

    @Test("write after close throws notConnected")
    func testWriteAfterClose() async throws {
        let mock = MockTransport()
        try await mock.connect()
        try await mock.close()

        await #expect(throws: AgentSDKError.self) {
            try await mock.write("test".data(using: .utf8)!)
        }
    }

    // MARK: - Manual Control

    @Test("yield manually adds message to stream")
    func testManualYield() async throws {
        let mock = MockTransport()
        try await mock.connect()

        let stream = mock.messages()

        let msg = AgentMessage.assistant(AssistantInfo(content: [.text("Manual")], parentToolUseId: nil))
        mock.yield(msg)
        mock.finishStream()

        var received: [Data] = []
        for try await data in stream {
            received.append(data)
        }

        #expect(received.count == 1)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: received[0])
        guard case .assistant(let info) = decoded else {
            Issue.record("Expected assistant"); return
        }
        guard case .text(let text) = info.content[0] else {
            Issue.record("Expected text"); return
        }
        #expect(text == "Manual")
    }

    @Test("finishStream with error propagates to stream consumer")
    func testFinishStreamWithError() async throws {
        let mock = MockTransport()
        try await mock.connect()

        let stream = mock.messages()
        mock.finishStream(throwing: AgentSDKError.cancelled)

        do {
            for try await _ in stream {
                Issue.record("Should not yield any messages")
            }
            Issue.record("Should have thrown")
        } catch {
            #expect(error is AgentSDKError)
        }
    }

    // MARK: - NFR-007: 12-line instantiation

    @Test("MockTransport can be created in under 12 lines")
    func testConciseCreation() async throws {
        // This test demonstrates NFR-007 compliance
        let mock = MockTransport(responses: MockFixtures.simpleSuccess())
        try await mock.connect()
        let stream = mock.messages()
        try await mock.write("hello".data(using: .utf8)!)
        var count = 0
        for try await _ in stream { count += 1 }
        #expect(count == 3)
        // Total: 6 lines of meaningful code
    }
}
