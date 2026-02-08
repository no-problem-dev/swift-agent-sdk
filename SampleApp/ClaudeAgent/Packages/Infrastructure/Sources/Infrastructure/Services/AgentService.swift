import Foundation
import Synchronization
import AgentSDK
import AgentSDKClaudeCode
import Domain

/// AgentServiceProtocol の SDK 連携実装
public final class AgentService<T: AgentTransport>: AgentServiceProtocol, @unchecked Sendable {
    private let client: ClaudeCodeClient<T>
    private let state: Mutex<State>

    private struct State: Sendable {
        var sessions: [String: ClaudeCodeSession] = [:]
    }

    public init(client: ClaudeCodeClient<T>) {
        self.client = client
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
