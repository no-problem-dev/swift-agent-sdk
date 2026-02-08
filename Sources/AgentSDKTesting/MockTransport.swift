import Foundation
import AgentSDK
import Synchronization

/// Test-purpose ``AgentTransport`` that returns pre-defined responses
/// and records all written messages.
///
/// ```swift
/// let mock = MockTransport(responses: [
///     .system(SystemInfo(sessionId: "test", tools: [], model: "opus", mcpServers: [])),
///     .assistant(AssistantInfo(content: [.text("Hello!")], parentToolUseId: nil)),
///     .result(ResultInfo(result: "Hello!", costUsd: 0.01, durationMs: 100,
///                        inputTokens: 10, outputTokens: 5, sessionId: "test", numTurns: 1))
/// ])
/// let client = ClaudeCodeClient(transport: mock)
/// for try await msg in client.query(prompt: "Test") { ... }
/// let sent = mock.sentMessages
/// ```
///
/// MockTransport can be instantiated in under 12 lines (NFR-007).
public final class MockTransport: AgentTransport, @unchecked Sendable {

    // MARK: - State

    private struct State {
        var sentMessages: [Data] = []
        var connected = false
        var closed = false
        var continuation: AsyncThrowingStream<Data, Error>.Continuation?
        var stream: AsyncThrowingStream<Data, Error>?
        var emitted = false
        var simulatedIsReady = true
    }

    private let state = Mutex(State())
    private let responses: [AgentMessage]

    // MARK: - Init

    /// Create a mock transport with pre-defined responses.
    ///
    /// - Parameter responses: Messages to emit from `messages()` after the first `write()`.
    public init(responses: [AgentMessage] = []) {
        self.responses = responses
    }

    // MARK: - AgentTransport

    public func connect() async throws {
        let ready = state.withLock { $0.simulatedIsReady }
        guard ready else {
            throw AgentSDKError.notConnected
        }
        state.withLock { $0.connected = true }
    }

    public func write(_ message: Data) async throws {
        let shouldEmit = state.withLock { s -> Bool in
            guard s.connected && !s.closed else { return false }
            s.sentMessages.append(message)
            if !s.emitted && !responses.isEmpty {
                s.emitted = true
                return true
            }
            return false
        }
        // Check write validity
        let isValid = state.withLock { $0.connected && !$0.closed }
        if !isValid && !shouldEmit {
            throw AgentSDKError.notConnected
        }
        if shouldEmit {
            emitResponses()
        }
    }

    public func messages() -> AsyncThrowingStream<Data, Error> {
        return state.withLock { s -> AsyncThrowingStream<Data, Error> in
            if let existing = s.stream {
                return existing
            }
            guard s.connected else {
                return AsyncThrowingStream { $0.finish(throwing: AgentSDKError.notConnected) }
            }
            var cont: AsyncThrowingStream<Data, Error>.Continuation!
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                cont = continuation
            }
            s.continuation = cont
            s.stream = stream
            return stream
        }
    }

    public func close() async throws {
        let cont = state.withLock { s -> AsyncThrowingStream<Data, Error>.Continuation? in
            s.closed = true
            let c = s.continuation
            s.continuation = nil
            return c
        }
        cont?.finish()
    }

    public var isReady: Bool {
        get async {
            state.withLock { $0.connected && !$0.closed && $0.simulatedIsReady }
        }
    }

    // MARK: - Test Control

    /// Control whether `isReady` returns true and `connect()` succeeds.
    /// Set to `false` before `connect()` to simulate a failed transport.
    public var simulatedIsReady: Bool {
        get { state.withLock { $0.simulatedIsReady } }
        set { state.withLock { $0.simulatedIsReady = newValue } }
    }

    /// All data written via `write(_:)`.
    public var sentMessages: [Data] {
        state.withLock { $0.sentMessages }
    }

    /// Whether `close()` was called.
    public var isClosed: Bool {
        state.withLock { $0.closed }
    }

    /// Manually yield a single `AgentMessage` into the stream.
    public func yield(_ message: AgentMessage) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        let cont = state.withLock { $0.continuation }
        cont?.yield(data)
    }

    /// Manually finish the message stream.
    public func finishStream() {
        let cont = state.withLock { s -> AsyncThrowingStream<Data, Error>.Continuation? in
            let c = s.continuation
            s.continuation = nil
            return c
        }
        cont?.finish()
    }

    /// Manually finish the stream with an error.
    public func finishStream(throwing error: Error) {
        let cont = state.withLock { s -> AsyncThrowingStream<Data, Error>.Continuation? in
            let c = s.continuation
            s.continuation = nil
            return c
        }
        cont?.finish(throwing: error)
    }

    // MARK: - Private

    private func emitResponses() {
        let cont = state.withLock { $0.continuation }
        guard let cont else { return }
        let encoder = JSONEncoder()
        for response in responses {
            guard let data = try? encoder.encode(response) else { continue }
            cont.yield(data)
        }
        cont.finish()
        state.withLock { $0.continuation = nil }
    }
}
