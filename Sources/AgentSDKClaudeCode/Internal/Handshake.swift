import Foundation
import AgentSDK

/// Executes the CLI initialization handshake protocol.
internal struct Handshake: Sendable {

    /// Handshake result containing session information.
    struct Result: Sendable {
        let sessionId: String
        let tools: [JSONValue]
        let model: String
        let mcpServers: [JSONValue]
    }

    private let codec = JSONLCodec()
    private let timeoutSeconds: Int

    init(timeoutSeconds: Int = 60) {
        self.timeoutSeconds = timeoutSeconds
    }

    /// Perform the handshake on a message stream.
    ///
    /// CLI v2.x protocol: wait for the first `system` message.
    ///
    /// - Parameters:
    ///   - stream: Stream of JSONL Data lines from CLI stdout
    ///   - write: Closure to write data to CLI stdin (unused in v2.x but kept for API compatibility)
    /// - Returns: Handshake result with session info
    /// - Throws: AgentSDKError.initializationTimeout, .protocolError
    func perform(
        stream: AsyncThrowingStream<Data, Error>,
        write: @escaping @Sendable (Data) async throws -> Void
    ) async throws -> Result {
        try await withThrowingTaskGroup(of: HandshakePhase.self) { group in
            // Timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(self.timeoutSeconds))
                return .timeout
            }

            // Main handshake task: wait for first system message
            group.addTask {
                try await self.waitForSystemMessage(stream: stream)
            }

            // Wait for first result
            guard let firstResult = try await group.next() else {
                throw AgentSDKError.protocolError(
                    message: "Task group unexpectedly empty",
                    rawData: nil
                )
            }

            // Cancel remaining tasks
            group.cancelAll()

            switch firstResult {
            case .timeout:
                throw AgentSDKError.initializationTimeout(seconds: timeoutSeconds)
            case .success(let result):
                return result
            }
        }
    }

    /// Wait for the first system message from CLI v2.x
    private func waitForSystemMessage(
        stream: AsyncThrowingStream<Data, Error>
    ) async throws -> HandshakePhase {
        for try await line in stream {
            let msg: CLIMessage = try codec.decode(line)
            if case .system(let sysMsg) = msg {
                return .success(Result(
                    sessionId: sysMsg.sessionId,
                    tools: sysMsg.tools,
                    model: sysMsg.model,
                    mcpServers: sysMsg.mcpServers
                ))
            }
        }

        throw AgentSDKError.protocolError(
            message: "Stream ended before receiving system message",
            rawData: nil
        )
    }
}

/// Internal enum to represent handshake phases
private enum HandshakePhase: Sendable {
    case timeout
    case success(Handshake.Result)
}
