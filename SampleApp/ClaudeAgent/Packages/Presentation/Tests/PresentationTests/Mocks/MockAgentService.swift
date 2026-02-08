import Foundation
import Domain

final class MockAgentService: AgentServiceProtocol, @unchecked Sendable {
    var createSessionResult: Result<(sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>), Error>!
    var sendResult: Result<AsyncThrowingStream<AgentEvent, Error>, Error>!
    var resumeResult: Result<AsyncThrowingStream<AgentEvent, Error>, Error>!
    var interruptCallCount = 0
    var closeCallCount = 0
    var setModelCallCount = 0
    var lastSetModel: ModelSelection?

    func createSession(
        config: SessionConfig
    ) async throws -> (sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>) {
        try createSessionResult.get()
    }

    func resumeSession(
        id: String,
        config: SessionConfig
    ) async throws -> AsyncThrowingStream<AgentEvent, Error> {
        try resumeResult.get()
    }

    func send(
        sessionId: String,
        message: String
    ) async throws -> AsyncThrowingStream<AgentEvent, Error> {
        try sendResult.get()
    }

    func interrupt(sessionId: String) async throws {
        interruptCallCount += 1
    }

    func close(sessionId: String) async throws {
        closeCallCount += 1
    }

    func setModel(sessionId: String, model: ModelSelection) async throws {
        setModelCallCount += 1
        lastSetModel = model
    }
}
