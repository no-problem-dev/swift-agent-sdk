import Foundation
import AgentSDK
@testable import AgentSDKClaudeCode

/// In-memory transport for unit tests. No subprocess involved.
final class MockTransport: AgentTransport, @unchecked Sendable {

    private let lock = NSLock()
    private var _connected = false
    private var _closed = false
    private var _written: [Data] = []
    private var _messageContinuation: AsyncThrowingStream<Data, Error>.Continuation?
    private var _messageStream: AsyncThrowingStream<Data, Error>?

    /// Lines to emit from `messages()` after connect.
    /// Each string is a JSON line (no newline needed).
    let scheduledResponses: [String]

    init(responses: [String] = []) {
        self.scheduledResponses = responses
    }

    /// Set to true to make connect() throw an error.
    var simulatedConnectFailure = false

    // MARK: - AgentTransport

    func connect() async throws {
        if simulatedConnectFailure {
            throw AgentSDKError.notConnected
        }
        lock.withLock { _connected = true }
    }

    func write(_ message: Data) async throws {
        lock.withLock { _written.append(message) }
        // After the first write (user_message), emit scheduled responses
        let count = lock.withLock { _written.count }
        if count == 1 && !scheduledResponses.isEmpty {
            emitScheduledResponses()
        }
    }

    func messages() -> AsyncThrowingStream<Data, Error> {
        let stream: AsyncThrowingStream<Data, Error>
        lock.lock()
        if let existing = _messageStream {
            lock.unlock()
            return existing
        }
        var cont: AsyncThrowingStream<Data, Error>.Continuation!
        stream = AsyncThrowingStream { continuation in
            cont = continuation
        }
        _messageContinuation = cont
        _messageStream = stream
        lock.unlock()

        // Emit handshake responses immediately
        emitHandshakeResponses()
        return stream
    }

    func close() async throws {
        lock.withLock {
            _closed = true
            _messageContinuation?.finish()
            _messageContinuation = nil
        }
    }

    var isReady: Bool {
        get async { lock.withLock { _connected && !_closed } }
    }

    // MARK: - Test Inspection

    var writtenData: [Data] {
        lock.withLock { _written }
    }

    var isClosed: Bool {
        lock.withLock { _closed }
    }

    // MARK: - Private

    /// Emit the handshake lines: initialize_ready (read by transport/client connect flow)
    /// and system message (after first write).
    private func emitHandshakeResponses() {
        // The connect() flow in ClaudeCodeTransport reads initialize_ready,
        // but for MockTransport used with ClaudeCodeClient directly,
        // we emit the system message as the first message in the stream.
        // The Client reads it via MessageRouter.
    }

    private func emitScheduledResponses() {
        lock.lock()
        let cont = _messageContinuation
        lock.unlock()
        guard let cont else { return }
        for line in scheduledResponses {
            if let data = (line + "\n").data(using: .utf8) {
                cont.yield(data)
            }
        }
        cont.finish()
    }

    /// Manually yield a single line into the message stream.
    func yield(_ json: String) {
        lock.lock()
        let cont = _messageContinuation
        lock.unlock()
        if let data = (json + "\n").data(using: .utf8) {
            cont?.yield(data)
        }
    }

    /// Manually finish the message stream.
    func finishStream() {
        lock.lock()
        let cont = _messageContinuation
        _messageContinuation = nil
        lock.unlock()
        cont?.finish()
    }
}
