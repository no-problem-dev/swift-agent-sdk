import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("Handshake Tests")
struct HandshakeTests {

    // MARK: - Helper Functions

    /// Create a stream from an array of JSONL strings
    private func mockStream(messages: [String]) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            for msg in messages {
                continuation.yield(Data(msg.utf8))
            }
            continuation.finish()
        }
    }

    /// Create a stream that never yields (for timeout testing)
    private func emptyStream() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            // Never yield anything, never finish
        }
    }

    /// Mock write function that captures written data
    private func mockWriteCapture() -> (@Sendable (Data) async throws -> Void, () -> [Data]) {
        let writtenData = ThreadSafeArray<Data>()

        let writeFn: @Sendable (Data) async throws -> Void = { data in
            writtenData.append(data)
        }

        let getData: () -> [Data] = {
            writtenData.getAll()
        }

        return (writeFn, getData)
    }

    // MARK: - Tests

    @Test("Normal flow: initialize_ready → initialize request → system message")
    func testNormalFlow() async throws {
        let handshake = Handshake(timeoutSeconds: 60)

        // Prepare mock messages
        let messages = [
            #"{"type":"initialize_ready"}"#,
            #"{"type":"system","session_id":"sess_123","tools":[],"model":"claude-opus-4-6","mcp_servers":[]}"#
        ]
        let stream = mockStream(messages: messages)

        let (writeFn, getWritten) = mockWriteCapture()

        // Perform handshake
        let result = try await handshake.perform(stream: stream, write: writeFn)

        // Verify result
        #expect(result.sessionId == "sess_123")
        #expect(result.model == "claude-opus-4-6")
        #expect(result.tools.isEmpty)
        #expect(result.mcpServers.isEmpty)

        // Verify that initialize request was sent
        let written = getWritten()
        #expect(written.count == 1)

        // Parse and verify the initialize request JSON
        let trimmed = written[0].last == 0x0A ? written[0].dropLast() : written[0][...]
        let json = try JSONSerialization.jsonObject(with: Data(trimmed)) as? [String: Any]
        #expect(json != nil)
        #expect(json?["type"] as? String == "control_request")
        #expect(json?["request_id"] as? String == "req_1_init")

        if let request = json?["request"] as? [String: Any] {
            #expect(request["subtype"] as? String == "initialize")
            #expect(request["supported_capabilities"] as? [String] == ["mcp"])
        } else {
            Issue.record("Expected request object in JSON")
        }
    }

    @Test("Timeout: stream never yields initialize_ready")
    func testTimeout() async throws {
        let handshake = Handshake(timeoutSeconds: 1) // Short timeout for test
        let stream = emptyStream()
        let (writeFn, _) = mockWriteCapture()

        // Expect timeout error
        await #expect(throws: AgentSDKError.self) {
            try await handshake.perform(stream: stream, write: writeFn)
        }
    }

    @Test("Missing system message: stream ends after initialize_ready")
    func testMissingSystemMessage() async throws {
        let handshake = Handshake(timeoutSeconds: 60)

        // Stream only contains initialize_ready, then ends
        let messages = [
            #"{"type":"initialize_ready"}"#
        ]
        let stream = mockStream(messages: messages)
        let (writeFn, _) = mockWriteCapture()

        // Expect protocol error
        await #expect(throws: AgentSDKError.self) {
            try await handshake.perform(stream: stream, write: writeFn)
        }
    }

    @Test("System message with non-empty tools and mcp_servers")
    func testSystemMessageWithData() async throws {
        let handshake = Handshake(timeoutSeconds: 60)

        let messages = [
            #"{"type":"initialize_ready"}"#,
            #"{"type":"system","session_id":"sess_456","tools":[{"name":"bash"}],"model":"claude-sonnet-4-5","mcp_servers":[{"name":"server1"}]}"#
        ]
        let stream = mockStream(messages: messages)
        let (writeFn, _) = mockWriteCapture()

        let result = try await handshake.perform(stream: stream, write: writeFn)

        #expect(result.sessionId == "sess_456")
        #expect(result.model == "claude-sonnet-4-5")
        #expect(result.tools.count == 1)
        #expect(result.mcpServers.count == 1)

        // Verify the JSONValue content
        if case .object(let toolDict) = result.tools[0] {
            if case .string(let name) = toolDict["name"] {
                #expect(name == "bash")
            } else {
                Issue.record("Expected string value for tool name")
            }
        } else {
            Issue.record("Expected object in tools array")
        }
    }
}

// MARK: - Thread-safe Array Helper

/// Thread-safe array wrapper for capturing written data in concurrent contexts
private final class ThreadSafeArray<T>: @unchecked Sendable {
    private var storage: [T] = []
    private let lock = NSLock()

    func append(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(element)
    }

    func getAll() -> [T] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
