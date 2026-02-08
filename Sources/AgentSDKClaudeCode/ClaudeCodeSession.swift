import Foundation
import AgentSDK

/// ``AgentSession`` implementation for Claude Code CLI.
///
/// Maintains a persistent connection to a Claude Code subprocess,
/// enabling multi-turn conversations with session state preservation.
///
/// ```swift
/// let session = try await client.createSession()
/// for try await msg in session.send("First question") { ... }
/// for try await msg in session.send("Follow-up") { ... }
/// try await session.close()
/// ```
public final class ClaudeCodeSession: AgentSession, @unchecked Sendable {

    /// Thread-safe mutable box for the session ID.
    private let sessionIdRef: LockedRef<String>
    private let transport: any AgentTransport
    private let router: MessageRouter
    private let routingTask: Task<Void, Never>
    private let codec = JSONLCodec()

    /// Session identifier.
    ///
    /// Initially a client-generated UUID. Updated to the CLI's real
    /// session ID when the first system message arrives (on the first ``send(_:)``).
    public var id: String {
        get async { sessionIdRef.value }
    }

    internal init(
        sessionId: String,
        transport: any AgentTransport,
        router: MessageRouter,
        routingTask: Task<Void, Never>
    ) {
        self.sessionIdRef = LockedRef(sessionId)
        self.transport = transport
        self.router = router
        self.routingTask = routingTask
    }

    deinit {
        routingTask.cancel()
    }

    /// Send a message and receive a stream of responses.
    ///
    /// ```swift
    /// for try await msg in session.send("What is Swift?") {
    ///     switch msg {
    ///     case .assistant(let info): print(info.content)
    ///     case .result(let result): print("Done")
    ///     default: break
    ///     }
    /// }
    /// ```
    public func send(_ message: String) -> AsyncThrowingStream<AgentMessage, Error> {
        let transport = self.transport
        let codec = self.codec
        let router = self.router
        let idRef = self.sessionIdRef
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Create stream BEFORE sending user message so no messages are dropped
                    let stream = await router.makeStream()

                    // Send user message (triggers CLI to output system + response)
                    let data = try codec.encode(SDKMessage.userMessage(content: message))
                    try await transport.write(data)

                    // Stream responses until result
                    for try await msg in stream {
                        // Capture CLI session ID from system message
                        if case .system(let info) = msg {
                            idRef.value = info.sessionId
                        }
                        continuation.yield(msg)
                        if case .result = msg {
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Interrupt current processing.
    public func interrupt() async throws {
        _ = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.interrupt.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: nil,
                userMessageUuid: nil, mcpServers: nil
            ),
            timeoutSeconds: 10
        )
    }

    /// Close the session and release resources.
    public func close() async throws {
        routingTask.cancel()
        await router.finish()
        try await transport.close()
    }

    // MARK: - Runtime Control

    /// Change the model at runtime.
    public func setModel(_ model: ModelSelection) async throws {
        _ = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.setModel.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: model.rawValue,
                userMessageUuid: nil, mcpServers: nil
            )
        )
    }

    /// Change the permission mode at runtime.
    public func setPermissionMode(_ mode: PermissionMode) async throws {
        _ = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.setPermissionMode.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: mode.rawValue, model: nil,
                userMessageUuid: nil, mcpServers: nil
            )
        )
    }

    /// Rewind files to a specific message state.
    public func rewindFiles(toMessageId messageId: String) async throws {
        _ = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.rewindFiles.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: nil,
                userMessageUuid: messageId, mcpServers: nil
            )
        )
    }

    /// Get the list of supported commands.
    public func supportedCommands() async throws -> [CommandInfo] {
        let response = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.getCommands.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: nil,
                userMessageUuid: nil, mcpServers: nil
            )
        )
        return decodeResponse(response) ?? []
    }

    /// Get the list of supported models.
    public func supportedModels() async throws -> [ModelInfo] {
        let response = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.getModels.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: nil,
                userMessageUuid: nil, mcpServers: nil
            )
        )
        return decodeResponse(response) ?? []
    }

    /// Get MCP server status.
    public func mcpServerStatus() async throws -> [MCPServerInfo] {
        let response = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.getMcpServerStatus.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: nil,
                userMessageUuid: nil, mcpServers: nil
            )
        )
        return decodeResponse(response) ?? []
    }

    /// Update MCP server configuration at runtime.
    public func setMCPServers(_ servers: [String: MCPServerConfig]) async throws {
        let serversJSON = servers.mapValues { config -> JSONValue in
            var dict: [String: JSONValue] = ["command": .string(config.command)]
            if let args = config.args {
                dict["args"] = .array(args.map { .string($0) })
            }
            if let env = config.env {
                dict["env"] = .object(env.mapValues { .string($0) })
            }
            return .object(dict)
        }
        _ = try await router.sendControlRequest(
            payload: .init(
                subtype: ControlSubtype.setMcpServers.rawValue,
                supportedCapabilities: nil, hooks: nil,
                permissionMode: nil, model: nil,
                userMessageUuid: nil, mcpServers: serversJSON
            )
        )
    }

    // MARK: - Private

    private func decodeResponse<T: Decodable>(_ response: CLIControlResponse) -> T? {
        guard let payload = response.response.response else { return nil }
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        guard let data = try? encoder.encode(payload),
              let result = try? decoder.decode(T.self, from: data) else {
            return nil
        }
        return result
    }
}

// MARK: - Thread-safe Value Box

/// Thread-safe mutable value container.
///
/// Uses `NSLock` internally. All property accesses are synchronous
/// to avoid issues with lock/unlock in async contexts.
internal final class LockedRef<T: Sendable>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()

    init(_ value: T) {
        self._value = value
    }

    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}
