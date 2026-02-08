import Foundation
import AgentSDK

/// JavaScript runtime for executing Claude Code CLI.
public enum JSRuntime: String, Sendable {
    case node = "node"
    case bun = "bun"
    case deno = "deno"
}

/// Claude Code CLI subprocess transport implementing ``AgentTransport``.
///
/// Manages the full lifecycle of a Claude Code CLI subprocess:
/// - CLI binary discovery via ``CLILocator``
/// - Process management via ``CLIProcess``
/// - Initialization handshake protocol
/// - Bidirectional JSONL message streaming
///
/// ```swift
/// let transport = ClaudeCodeTransport(runtime: .node)
/// try await transport.connect()
/// let stream = transport.messages()
/// try await transport.write(someData)
/// try await transport.close()
/// ```
public struct ClaudeCodeTransport: AgentTransport {

    private let core: TransportCore
    private let streamHolder: StreamHolder

    /// Create a new Claude Code transport.
    ///
    /// - Parameters:
    ///   - cliPath: Explicit path to the CLI binary (nil = auto-discover)
    ///   - runtime: JavaScript runtime to use for `.js` CLI entries
    ///   - additionalEnvironment: Extra environment variables for the subprocess
    ///   - arguments: Additional CLI arguments (e.g. from ``CLIArgBuilder``)
    ///   - workingDirectory: Working directory for the subprocess
    public init(
        cliPath: String? = nil,
        runtime: JSRuntime = .node,
        additionalEnvironment: [String: String] = [:],
        arguments: [String] = [],
        workingDirectory: String? = nil
    ) {
        self.core = TransportCore(
            cliPath: cliPath,
            runtime: runtime,
            additionalEnvironment: additionalEnvironment,
            arguments: arguments,
            workingDirectory: workingDirectory
        )
        self.streamHolder = StreamHolder()
    }

    public func connect() async throws {
        let stream = try await core.connect()
        streamHolder.set(stream)
    }

    public func write(_ message: Data) async throws {
        try await core.write(message)
    }

    public func messages() -> AsyncThrowingStream<Data, Error> {
        guard let stream = streamHolder.get() else {
            return AsyncThrowingStream { $0.finish(throwing: AgentSDKError.notConnected) }
        }
        return stream
    }

    public func close() async throws {
        await core.close()
    }

    public var isReady: Bool {
        get async { await core.isReady }
    }
}

// MARK: - Internal Transport Core

internal actor TransportCore {

    private let cliPath: String?
    private let runtime: JSRuntime
    private let additionalEnvironment: [String: String]
    private let arguments: [String]
    private let workingDirectory: String?

    private var process: CLIProcess?
    private var _isReady = false
    private var readerTask: Task<Void, Never>?
    private var outputContinuation: AsyncThrowingStream<Data, Error>.Continuation?

    var isReady: Bool { _isReady }

    init(
        cliPath: String?,
        runtime: JSRuntime,
        additionalEnvironment: [String: String],
        arguments: [String],
        workingDirectory: String?
    ) {
        self.cliPath = cliPath
        self.runtime = runtime
        self.additionalEnvironment = additionalEnvironment
        self.arguments = arguments
        self.workingDirectory = workingDirectory
    }

    /// Connect to the CLI subprocess and perform handshake.
    /// Returns the post-handshake message stream.
    func connect() async throws -> AsyncThrowingStream<Data, Error> {
        guard !_isReady else {
            throw AgentSDKError.processLaunchFailed(
                underlying: NSError(
                    domain: "ClaudeCodeTransport", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Already connected"]
                )
            )
        }

        // 1. Locate CLI binary
        let cliURL = try CLILocator.locate(userPath: cliPath)

        // 2. Resolve executable and base arguments
        let (executable, baseArgs) = resolveExecutable(cliURL: cliURL)
        let fullArgs = baseArgs + arguments

        // 3. Start subprocess
        let process = CLIProcess()
        let env = additionalEnvironment.isEmpty ? nil : additionalEnvironment
        try await process.start(
            executable: executable,
            arguments: fullArgs,
            environment: env,
            cwd: workingDirectory
        )
        self.process = process

        // 4. Get stdout stream
        let stdoutStream = await process.stdoutStream()

        // 5. Create output stream (post-handshake messages will be yielded here)
        let (messageStream, msgCont) = AsyncThrowingStream.makeStream(of: Data.self)
        self.outputContinuation = msgCont

        // 6. Perform handshake within a reader task
        let codec = JSONLCodec()
        let flag = HandshakeFlag()
        let timeoutSeconds = 60

        try await withCheckedThrowingContinuation { (handshakeCont: CheckedContinuation<Void, Error>) in
            let timeoutTask = Task {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                if flag.tryComplete() {
                    handshakeCont.resume(
                        throwing: AgentSDKError.initializationTimeout(seconds: timeoutSeconds)
                    )
                    msgCont.finish()
                }
            }

            self.readerTask = Task { [process, codec] in
                var phase = 0 // 0 = waiting for initialize_ready, 1 = waiting for system
                do {
                    for try await line in stdoutStream {
                        if !flag.isCompleted {
                            let msg: CLIMessage = try codec.decode(line)

                            if phase == 0, case .initializeReady = msg {
                                let initReq = SDKMessage.controlRequest(SDKControlRequest(
                                    requestId: "req_1_init",
                                    request: .init(
                                        subtype: "initialize",
                                        supportedCapabilities: ["mcp"],
                                        hooks: [],
                                        permissionMode: nil, model: nil,
                                        userMessageUuid: nil, mcpServers: nil
                                    )
                                ))
                                let data = try codec.encode(initReq)
                                try await process.writeToStdin(data)
                                phase = 1
                            } else if phase == 1, case .system = msg {
                                timeoutTask.cancel()
                                if flag.tryComplete() {
                                    handshakeCont.resume()
                                }
                                msgCont.yield(line)
                            }
                        } else {
                            msgCont.yield(line)
                        }
                    }
                    // Stream ended
                    if !flag.isCompleted {
                        timeoutTask.cancel()
                        if flag.tryComplete() {
                            handshakeCont.resume(throwing: AgentSDKError.protocolError(
                                message: "Stream ended before handshake completed",
                                rawData: nil
                            ))
                        }
                    }
                    msgCont.finish()
                } catch {
                    if !flag.isCompleted {
                        timeoutTask.cancel()
                        if flag.tryComplete() {
                            handshakeCont.resume(throwing: error)
                        }
                    }
                    msgCont.finish(throwing: error)
                }
            }
        }

        self._isReady = true
        return messageStream
    }

    func write(_ data: Data) async throws {
        guard _isReady, let process else {
            throw AgentSDKError.notConnected
        }
        try await process.writeToStdin(data)
    }

    func close() async {
        _isReady = false
        readerTask?.cancel()
        outputContinuation?.finish()
        outputContinuation = nil
        if let process {
            await process.terminate()
        }
        process = nil
    }

    // MARK: - Private

    private func resolveExecutable(cliURL: URL) -> (URL, [String]) {
        if cliURL.pathExtension == "js" {
            // Use JS runtime via /usr/bin/env
            return (URL(fileURLWithPath: "/usr/bin/env"), [runtime.rawValue, cliURL.path])
        } else {
            // Direct binary (e.g. `claude` from PATH)
            return (cliURL, [])
        }
    }
}

// MARK: - Thread-safe Handshake Flag

/// Ensures the handshake continuation is resumed exactly once.
private final class HandshakeFlag: @unchecked Sendable {
    private var _completed = false
    private let lock = NSLock()

    var isCompleted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _completed
    }

    /// Attempt to mark as completed. Returns `true` only on the first call.
    func tryComplete() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if _completed { return false }
        _completed = true
        return true
    }
}

// MARK: - Thread-safe Stream Holder

/// Holds an ``AsyncThrowingStream`` for synchronous access from ``messages()``.
private final class StreamHolder: @unchecked Sendable {
    private var stream: AsyncThrowingStream<Data, Error>?
    private let lock = NSLock()

    func set(_ stream: AsyncThrowingStream<Data, Error>) {
        lock.lock()
        defer { lock.unlock() }
        self.stream = stream
    }

    func get() -> AsyncThrowingStream<Data, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return stream
    }
}
