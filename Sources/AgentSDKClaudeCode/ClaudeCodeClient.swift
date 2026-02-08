import Foundation
import AgentSDK

/// ``AgentClient`` implementation for Claude Code CLI.
///
/// Uses a generic ``AgentTransport`` for DI. For each query or session,
/// creates a new transport connection to the CLI subprocess.
///
/// ```swift
/// let transport = ClaudeCodeTransport()
/// let client = ClaudeCodeClient(transport: transport)
/// for try await msg in client.query(prompt: "Hello") { ... }
/// ```
public struct ClaudeCodeClient<T: AgentTransport>: AgentClient {
    public typealias Session = ClaudeCodeSession

    private let transportFactory: @Sendable () -> T
    private let baseTransport: T

    /// Create a client with a transport instance.
    ///
    /// The transport is used as a template. For one-shot queries, a fresh
    /// transport connection is established and torn down per call.
    /// For sessions, the transport stays connected.
    public init(transport: T) {
        self.baseTransport = transport
        self.transportFactory = { transport }
    }

    /// Execute a one-shot query and return a message stream.
    ///
    /// Internally: connect transport → send user message → stream responses → close.
    /// Errors during connect or protocol are thrown from the stream.
    ///
    /// ```swift
    /// for try await msg in client.query(prompt: "Hello") {
    ///     switch msg {
    ///     case .assistant(let info): print(info.content)
    ///     case .result(let result): print("Cost: $\(result.costUsd)")
    ///     default: break
    ///     }
    /// }
    /// ```
    public func query(
        prompt: String,
        options: QueryOptions = QueryOptions()
    ) -> AsyncThrowingStream<AgentMessage, Error> {
        let transport = baseTransport
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // 1. Connect (starts process, no handshake wait)
                    try await transport.connect()

                    // 2. Create MessageRouter
                    let writeFn: @Sendable (Data) async throws -> Void = { data in
                        try await transport.write(data)
                    }
                    let router = MessageRouter(
                        write: writeFn,
                        canUseTool: options.canUseTool
                    )

                    // 3. Create output stream BEFORE sending user message
                    //    so messages are captured as soon as CLI responds
                    let messageStream = await router.makeStream()

                    // 4. Start routing messages from transport
                    let codec = JSONLCodec()
                    let routingTask = Task {
                        do {
                            for try await line in transport.messages() {
                                let cliMsg: CLIMessage = try codec.decode(line)
                                await router.route(cliMsg)
                            }
                            await router.finish()
                        } catch {
                            await router.finish(throwing: error)
                        }
                    }

                    // 5. Send user message (triggers CLI to output system + response)
                    let userMessage = try codec.encode(SDKMessage.userMessage(content: prompt))
                    try await transport.write(userMessage)

                    // 6. Forward messages to the caller's continuation
                    for try await msg in messageStream {
                        continuation.yield(msg)
                    }
                    continuation.finish()

                    routingTask.cancel()
                    try? await transport.close()
                } catch {
                    continuation.finish(throwing: error)
                    try? await transport.close()
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Create a new interactive session.
    ///
    /// Connects the transport and starts message routing. The session is
    /// returned immediately with a placeholder ID. The real CLI session ID
    /// is captured from the system message on the first ``ClaudeCodeSession/send(_:)`` call.
    public func createSession(
        options: SessionOptions = SessionOptions()
    ) async throws -> ClaudeCodeSession {
        let transport = baseTransport

        // Connect transport (starts process, no handshake wait)
        try await transport.connect()

        // Create MessageRouter
        let writeFn: @Sendable (Data) async throws -> Void = { data in
            try await transport.write(data)
        }
        let router = MessageRouter(
            write: writeFn,
            canUseTool: options.canUseTool
        )

        // Start routing messages from transport to router
        let codec = JSONLCodec()
        let routingTask = Task {
            do {
                for try await line in transport.messages() {
                    let cliMsg: CLIMessage = try codec.decode(line)
                    await router.route(cliMsg)
                }
                await router.finish()
            } catch {
                await router.finish(throwing: error)
            }
        }

        // Return session immediately — CLI v2.x sends system message
        // only after the first user message, so we defer session ID extraction.
        return ClaudeCodeSession(
            sessionId: UUID().uuidString,
            transport: transport,
            router: router,
            routingTask: routingTask
        )
    }

    /// Resume an existing session by ID.
    ///
    /// Connects the transport with `--resume` and returns a session
    /// continuing from the previous conversation.
    public func resumeSession(
        id: String,
        options: SessionOptions = SessionOptions()
    ) async throws -> ClaudeCodeSession {
        // For resume, we reuse the same flow as createSession.
        // The --resume flag should already be in the transport's arguments
        // (set by the convenience API or the caller).
        return try await createSession(options: options)
    }
}
