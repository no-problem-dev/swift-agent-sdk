import Foundation
import AgentSDK

/// Bidirectional message router between CLI process and SDK consumer.
///
/// Responsibilities:
/// - Routes CLI→SDK messages (assistant/result/system/partial) to an AsyncThrowingStream
/// - Handles CLI→SDK control requests (can_use_tool) by calling custom handlers
/// - Manages SDK→CLI control requests with request_id + CheckedContinuation (30s timeout)
internal actor MessageRouter {

    // MARK: - Dependencies

    private let codec = JSONLCodec()
    private let write: @Sendable (Data) async throws -> Void
    private let canUseToolHandler: (@Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision)?

    // MARK: - State

    private var requestCounter: UInt64 = 0
    private var pendingRequests: [String: PendingRequest] = [:]
    private var messageContinuation: AsyncThrowingStream<AgentMessage, Error>.Continuation?
    private var pendingMessages: [AgentMessage] = []

    private struct PendingRequest {
        let continuation: CheckedContinuation<CLIControlResponse, Error>
        var timeoutTask: Task<Void, Never>?
    }

    // MARK: - Init

    init(
        write: @escaping @Sendable (Data) async throws -> Void,
        canUseTool: (@Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision)? = nil
    ) {
        self.write = write
        self.canUseToolHandler = canUseTool
    }

    // MARK: - Message Stream

    /// Create the output message stream.
    ///
    /// Any messages that arrived before this call are flushed immediately.
    /// This allows CLI messages to be buffered when no consumer is listening
    /// (e.g. between session creation and the first ``ClaudeCodeSession/send(_:)``).
    func makeStream() -> AsyncThrowingStream<AgentMessage, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: AgentMessage.self)
        self.messageContinuation = continuation
        // Flush any messages that arrived before the stream was created
        for msg in pendingMessages {
            continuation.yield(msg)
        }
        pendingMessages.removeAll()
        return stream
    }

    // MARK: - Message Routing

    /// Route a single CLIMessage through the router.
    ///
    /// If no consumer stream is active (``makeStream()`` not yet called),
    /// messages are buffered and flushed on the next ``makeStream()`` call.
    func route(_ message: CLIMessage) async {
        switch message {
        case .system(let sysMsg):
            yieldOrBuffer(convertSystemMessage(sysMsg))

        case .assistant(let asstMsg):
            yieldOrBuffer(convertAssistantMessage(asstMsg))

        case .partialAssistant(let partialMsg):
            yieldOrBuffer(convertPartialMessage(partialMsg))

        case .result(let resultMsg):
            yieldOrBuffer(convertResultMessage(resultMsg))

        case .controlRequest(let ctrlReq):
            await handleControlRequest(ctrlReq)

        case .controlResponse(let ctrlResp):
            handleControlResponse(ctrlResp)

        case .streamEvent(let event):
            yieldOrBuffer(convertStreamEvent(event))

        case .unknown:
            // Ignore unknown message types
            break
        }
    }

    /// Yield a message to the active stream, or buffer it if no stream exists.
    private func yieldOrBuffer(_ message: AgentMessage) {
        if let cont = messageContinuation {
            cont.yield(message)
        } else {
            pendingMessages.append(message)
        }
    }

    /// Finish the message stream normally.
    func finish() {
        messageContinuation?.finish()
        messageContinuation = nil
        cancelAllPendingRequests()
    }

    /// Finish the message stream with an error.
    func finish(throwing error: Error) {
        messageContinuation?.finish(throwing: error)
        messageContinuation = nil
        cancelAllPendingRequests()
    }

    // MARK: - Control Requests (SDK → CLI)

    /// Send a control request to CLI and wait for matching response.
    ///
    /// - Parameters:
    ///   - payload: The request payload (subtype + fields)
    ///   - timeoutSeconds: Maximum seconds to wait for response (default: 30)
    /// - Returns: The CLI control response
    /// - Throws: `AgentSDKError.controlRequestTimeout` on timeout
    func sendControlRequest(
        payload: SDKControlRequest.RequestPayload,
        timeoutSeconds: Int = 30
    ) async throws -> CLIControlResponse {
        let requestId = nextRequestId()
        let request = SDKControlRequest(requestId: requestId, request: payload)
        let data = try codec.encode(SDKMessage.controlRequest(request))

        // Use withCheckedThrowingContinuation directly on the actor so the
        // closure can access actor-isolated state (pendingRequests).
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLIControlResponse, Error>) in
            // Spawn an unstructured task to write and handle timeout.
            // The write closure is @Sendable, callable from any isolation domain.
            let timeoutTask = Task { [write] in
                do {
                    try await write(data)
                } catch {
                    await self.failPendingRequest(requestId, error: error)
                    return
                }
                do {
                    try await Task.sleep(for: .seconds(timeoutSeconds))
                    await self.timeoutPendingRequest(
                        requestId, subtype: payload.subtype, seconds: timeoutSeconds
                    )
                } catch {
                    // Sleep cancelled (response arrived), which is expected
                }
            }

            // Store continuation synchronously on the actor BEFORE suspending.
            // This guarantees route() can always find the continuation.
            pendingRequests[requestId] = PendingRequest(
                continuation: continuation,
                timeoutTask: timeoutTask
            )
        }
    }

    // MARK: - Private: Request ID Generation

    private func nextRequestId() -> String {
        requestCounter += 1
        let hex = String(UInt32.random(in: 0...UInt32.max), radix: 16)
        return "req_\(requestCounter)_\(hex)"
    }

    // MARK: - Private: Control Request Handling (CLI → SDK)

    private func handleControlRequest(_ request: CLIControlRequest) async {
        switch request.request.subtype {
        case ControlSubtype.canUseTool.rawValue:
            await handleCanUseTool(request)
        default:
            // Unknown control request subtype from CLI, ignore
            break
        }
    }

    private func handleCanUseTool(_ request: CLIControlRequest) async {
        let toolName = request.request.toolName ?? ""
        let toolInput = request.request.toolInput ?? [:]

        let decision: PermissionDecision
        if let handler = canUseToolHandler {
            decision = await handler(toolName, toolInput, nil)
        } else {
            // Default: allow all tool usage
            decision = .allow
        }

        let responsePayload: JSONValue
        switch decision {
        case .allow:
            responsePayload = .object(["allowed": .bool(true)])
        case .deny(let reason):
            responsePayload = .object(["allowed": .bool(false), "reason": .string(reason)])
        }

        let response = SDKControlResponse(response: .init(
            subtype: "success",
            requestId: request.requestId,
            response: responsePayload
        ))

        if let data = try? codec.encode(SDKMessage.controlResponse(response)) {
            try? await write(data)
        }
    }

    // MARK: - Private: Control Response Handling

    private func handleControlResponse(_ response: CLIControlResponse) {
        let reqId = response.response.requestId
        guard let pending = pendingRequests.removeValue(forKey: reqId) else {
            return // Unknown requestId, ignore
        }
        pending.timeoutTask?.cancel()
        pending.continuation.resume(returning: response)
    }

    private func failPendingRequest(_ requestId: String, error: Error) {
        guard let pending = pendingRequests.removeValue(forKey: requestId) else {
            return
        }
        pending.continuation.resume(throwing: error)
    }

    private func timeoutPendingRequest(_ requestId: String, subtype: String, seconds: Int) {
        guard let pending = pendingRequests.removeValue(forKey: requestId) else {
            return // Already resolved
        }
        pending.continuation.resume(
            throwing: AgentSDKError.controlRequestTimeout(subtype: subtype, seconds: seconds)
        )
    }

    private func cancelAllPendingRequests() {
        for (_, pending) in pendingRequests {
            pending.timeoutTask?.cancel()
            pending.continuation.resume(throwing: AgentSDKError.cancelled)
        }
        pendingRequests.removeAll()
    }

    // MARK: - Private: Message Conversion

    private func convertSystemMessage(_ msg: CLISystemMessage) -> AgentMessage {
        let tools = msg.tools.compactMap(convertToolInfo)
        let servers = msg.mcpServers.compactMap(convertMCPServerInfo)
        return .system(SystemInfo(
            sessionId: msg.sessionId,
            tools: tools,
            model: msg.model,
            mcpServers: servers
        ))
    }

    private func convertAssistantMessage(_ msg: CLIAssistantMessage) -> AgentMessage {
        let content = convertContentBlocks(msg.message.content)
        return .assistant(AssistantInfo(
            content: content,
            parentToolUseId: msg.parentToolUseId
        ))
    }

    private func convertPartialMessage(_ msg: CLIPartialAssistantMessage) -> AgentMessage {
        let content = convertContentBlocks(msg.message.content)
        return .partial(PartialInfo(content: content))
    }

    private func convertResultMessage(_ msg: CLIResultMessage) -> AgentMessage {
        .result(ResultInfo(
            result: msg.result,
            costUsd: msg.totalCostUsd,
            durationMs: msg.durationMs,
            inputTokens: msg.usage.inputTokens,
            outputTokens: msg.usage.outputTokens,
            sessionId: msg.sessionId,
            numTurns: msg.numTurns
        ))
    }

    private func convertStreamEvent(_ event: CLIStreamEvent) -> AgentMessage {
        // Map stream events to partial messages for streaming support
        .partial(PartialInfo(content: []))
    }

    private func convertToolInfo(_ value: JSONValue) -> ToolInfo? {
        switch value {
        // CLI v2.x sends tools as plain strings: ["Bash", "Task", ...]
        case .string(let name):
            return ToolInfo(name: name, description: nil)
        // Older format or extended info: [{"name": "Bash", "description": "..."}]
        case .object(let dict):
            guard case .string(let name) = dict["name"] else { return nil }
            let description: String?
            if case .string(let d) = dict["description"] {
                description = d
            } else {
                description = nil
            }
            return ToolInfo(name: name, description: description)
        default:
            return nil
        }
    }

    private func convertMCPServerInfo(_ value: JSONValue) -> MCPServerInfo? {
        guard case .object(let dict) = value,
              case .string(let name) = dict["name"] else {
            return nil
        }
        let status: String
        if case .string(let s) = dict["status"] {
            status = s
        } else {
            status = "unknown"
        }
        return MCPServerInfo(name: name, status: status)
    }

    private func convertContentBlocks(_ values: [JSONValue]) -> [ContentBlock] {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        return values.compactMap { value in
            guard let data = try? encoder.encode(value),
                  let block = try? decoder.decode(ContentBlock.self, from: data) else {
                return nil
            }
            return block
        }
    }
}
