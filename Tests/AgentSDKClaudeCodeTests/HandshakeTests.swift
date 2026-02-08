import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("Handshake Tests", .serialized)
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

    @Test("Normal flow: wait for system message (CLI v2.x)")
    func testNormalFlow() async throws {
        let handshake = Handshake(timeoutSeconds: 60)

        // CLI v2.x sends system message directly
        let messages = [
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

        // No initialize request should be sent in v2.x
        let written = getWritten()
        #expect(written.count == 0)
    }

    @Test("Timeout: stream never yields system message")
    func testTimeout() async throws {
        let handshake = Handshake(timeoutSeconds: 1) // Short timeout for test
        let stream = emptyStream()
        let (writeFn, _) = mockWriteCapture()

        // Expect timeout error
        await #expect(throws: AgentSDKError.self) {
            try await handshake.perform(stream: stream, write: writeFn)
        }
    }

    @Test("Missing system message: stream ends without system message")
    func testMissingSystemMessage() async throws {
        let handshake = Handshake(timeoutSeconds: 60)

        // Stream ends without a system message
        let messages: [String] = []
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

    @Test("System message with subtype init (CLI v2.x native)")
    func testSystemMessageWithSubtype() async throws {
        let handshake = Handshake(timeoutSeconds: 60)

        let messages = [
            #"{"type":"system","subtype":"init","uuid":"uuid-123","session_id":"sess_789","tools":[],"model":"claude-opus-4-6","mcp_servers":[]}"#
        ]
        let stream = mockStream(messages: messages)
        let (writeFn, _) = mockWriteCapture()

        let result = try await handshake.perform(stream: stream, write: writeFn)

        #expect(result.sessionId == "sess_789")
        #expect(result.model == "claude-opus-4-6")
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
