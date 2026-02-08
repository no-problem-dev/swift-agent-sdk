import Foundation
import Synchronization
import AgentSDK
import AgentSDKClaudeCode
import Domain

/// AgentServiceProtocol の SDK 連携実装
///
/// セッションごとに新しい ClaudeCodeTransport + ClaudeCodeClient を作成する。
/// CLI に `--output-format stream-json` 等の必須引数を渡すため、
/// 各操作で専用の transport を構築する。
public final class AgentService: AgentServiceProtocol, @unchecked Sendable {
    private let cliPath: String?
    private let state: Mutex<State>

    private struct State: Sendable {
        var sessions: [String: ClaudeCodeSession] = [:]
    }

    public init(cliPath: String? = nil) {
        self.cliPath = cliPath
        self.state = Mutex(State())
    }

    public func createSession(
        config: SessionConfig
    ) async throws -> (sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>) {
        do {
            let options = SessionOptions(
                model: config.model.sdkValue,
                systemPrompt: config.systemPrompt,
                permissionMode: .bypassPermissions,
                cwd: config.workingDirectory
            )
            let client = makeClient(options: options)
            let session = try await client.createSession(options: options)
            let sessionId = await session.id

            state.withLock { $0.sessions[sessionId] = session }

            let stream = AsyncThrowingStream<AgentEvent, Error> { continuation in
                continuation.yield(.initialized(sessionId: sessionId))
                continuation.finish()
            }
            return (sessionId, stream)
        } catch {
            throw mapError(error)
        }
    }

    public func resumeSession(
        id: String,
        config: SessionConfig
    ) async throws -> AsyncThrowingStream<AgentEvent, Error> {
        do {
            let options = SessionOptions(
                model: config.model.sdkValue,
                systemPrompt: config.systemPrompt,
                permissionMode: .bypassPermissions,
                cwd: config.workingDirectory
            )
            let args = Self.buildArguments(from: options, resumeSessionId: id)
            let transport = ClaudeCodeTransport(
                cliPath: cliPath,
                arguments: args,
                workingDirectory: options.cwd
            )
            let client = ClaudeCodeClient(transport: transport)
            let session = try await client.resumeSession(id: id, options: options)
            let sessionId = await session.id

            state.withLock { $0.sessions[sessionId] = session }

            return AsyncThrowingStream<AgentEvent, Error> { continuation in
                continuation.yield(.initialized(sessionId: sessionId))
                continuation.finish()
            }
        } catch {
            throw mapError(error)
        }
    }

    public func send(
        sessionId: String,
        message: String
    ) async throws -> AsyncThrowingStream<AgentEvent, Error> {
        let session = try getSession(sessionId)
        let sdkStream = session.send(message)
        return mapStream(sdkStream)
    }

    public func interrupt(sessionId: String) async throws {
        let session = try getSession(sessionId)
        do {
            try await session.interrupt()
        } catch {
            throw mapError(error)
        }
    }

    public func close(sessionId: String) async throws {
        let session = try getSession(sessionId)
        do {
            try await session.close()
            state.withLock { _ = $0.sessions.removeValue(forKey: sessionId) }
        } catch {
            state.withLock { _ = $0.sessions.removeValue(forKey: sessionId) }
            throw mapError(error)
        }
    }

    public func setModel(sessionId: String, model: Domain.ModelSelection) async throws {
        let session = try getSession(sessionId)
        do {
            try await session.setModel(model.sdkValue)
        } catch {
            throw mapError(error)
        }
    }

    // MARK: - Private

    private func makeClient(
        options: SessionOptions,
        resumeSessionId: String? = nil
    ) -> ClaudeCodeClient<ClaudeCodeTransport> {
        let args = Self.buildArguments(from: options, resumeSessionId: resumeSessionId)
        let transport = ClaudeCodeTransport(
            cliPath: cliPath,
            arguments: args,
            workingDirectory: options.cwd
        )
        return ClaudeCodeClient(transport: transport)
    }

    /// CLIArgBuilder と同等の引数構築（SDK の CLIArgBuilder は internal のため再実装）
    ///
    /// SDK v2.x では CLIArgBuilder に `-p` フラグが含まれるため、
    /// ここでは追加オプションのみ構築する。
    private static func buildArguments(
        from options: SessionOptions,
        resumeSessionId: String? = nil
    ) -> [String] {
        var args: [String] = []

        // 必須引数: 非インタラクティブモード + JSONL ストリーム
        args.append("-p")
        args.append(contentsOf: ["--output-format", "stream-json"])
        args.append(contentsOf: ["--input-format", "stream-json"])
        args.append("--verbose")

        if let systemPrompt = options.systemPrompt {
            args.append(contentsOf: ["--system-prompt", systemPrompt])
        }
        if let mode = options.permissionMode {
            args.append(contentsOf: ["--permission-mode", mode.rawValue])
        }
        if let maxTurns = options.maxTurns {
            args.append(contentsOf: ["--max-turns", String(maxTurns)])
        }
        if let sessionId = resumeSessionId {
            args.append(contentsOf: ["--resume", sessionId])
        }
        if let model = options.model {
            args.append(contentsOf: ["--model", model.rawValue])
        }

        return args
    }

    private func getSession(_ sessionId: String) throws -> ClaudeCodeSession {
        guard let session = state.withLock({ $0.sessions[sessionId] }) else {
            throw AppError.notConnected
        }
        return session
    }

    private func mapStream(
        _ source: AsyncThrowingStream<AgentMessage, Error>
    ) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await message in source {
                        if let event = AgentMessageMapper.map(message) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: mapError(error))
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func mapError(_ error: Error) -> AppError {
        guard let sdkError = error as? AgentSDKError else {
            return .protocolError(error.localizedDescription)
        }
        switch sdkError {
        case .cliNotFound:
            return .cliNotFound
        case .notConnected:
            return .notConnected
        case .sessionExpired:
            return .sessionExpired
        case .sessionClosed:
            return .sessionExpired
        case .initializationTimeout:
            return .connectionTimeout
        case .processExited(let exitCode, _):
            return .processExited(code: Int(exitCode))
        case .protocolError(let message, _):
            return .protocolError(message)
        case .cancelled:
            return .protocolError("Operation cancelled")
        case .runtimeNotFound(let runtime):
            return .protocolError("Runtime not found: \(runtime)")
        case .processLaunchFailed(let underlying):
            return .protocolError("Process launch failed: \(underlying.localizedDescription)")
        case .controlRequestTimeout(_, _):
            return .connectionTimeout
        }
    }
}
