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
    /// - Parameters:
    ///   - stream: Stream of JSONL Data lines from CLI stdout
    ///   - write: Closure to write data to CLI stdin
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

            // Main handshake task
            group.addTask {
                try await self.executeHandshake(stream: stream, write: write)
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

    /// Execute the three-phase handshake protocol
    private func executeHandshake(
        stream: AsyncThrowingStream<Data, Error>,
        write: @escaping @Sendable (Data) async throws -> Void
    ) async throws -> HandshakePhase {
        var iterator = stream.makeAsyncIterator()

        // Phase 1: Wait for initialize_ready
        var readyReceived = false
        while let line = try await iterator.next() {
            let msg: CLIMessage = try codec.decode(line)
            if case .initializeReady = msg {
                readyReceived = true
                break
            }
        }

        guard readyReceived else {
            throw AgentSDKError.protocolError(
                message: "Stream ended before receiving initialize_ready",
                rawData: nil
            )
        }

        // Phase 2: Send InitializeRequest
        let initRequest = SDKMessage.controlRequest(SDKControlRequest(
            requestId: "req_1_init",
            request: SDKControlRequest.RequestPayload(
                subtype: "initialize",
                supportedCapabilities: ["mcp"],
                hooks: [],
                permissionMode: nil,
                model: nil,
                userMessageUuid: nil,
                mcpServers: nil
            )
        ))
        let requestData = try codec.encode(initRequest)
        try await write(requestData)

        // Phase 3: Wait for SystemMessage
        while let line = try await iterator.next() {
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
            message: "Expected system message after initialize request, but stream ended",
            rawData: nil
        )
    }
}

/// Internal enum to represent handshake phases
private enum HandshakePhase: Sendable {
    case timeout
    case success(Handshake.Result)
}
