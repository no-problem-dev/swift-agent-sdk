import Foundation
import Testing
import Domain
@testable import Presentation

@Suite(.serialized)
@MainActor
struct SessionStateTests {

    private func makeSession(service: MockAgentService = MockAgentService()) -> SessionState {
        SessionState(
            id: "sess-1",
            config: SessionConfig(model: .sonnet, workingDirectory: "/tmp"),
            agentService: service
        )
    }

    // MARK: - send

    @Test func sendAddsUserMessageAndProcessesStream() async {
        let mockService = MockAgentService()
        let stream = AsyncThrowingStream<AgentEvent, Error> { continuation in
            continuation.yield(.assistantMessage(content: [.text("Hello!")]))
            continuation.yield(.turnCompleted(costUsd: 0.01, inputTokens: 10, outputTokens: 5))
            continuation.finish()
        }
        mockService.sendResult = .success(stream)

        let session = makeSession(service: mockService)
        session.status = .connected
        await session.send("Hi")

        #expect(session.messages.count == 2)
        #expect(session.messages[0].role == .user)
        #expect(session.messages[1].role == .assistant)
        #expect(session.isProcessing == false)
        #expect(session.totalCostUsd == 0.01)
    }

    @Test func sendSetsErrorOnServiceFailure() async {
        let mockService = MockAgentService()
        mockService.sendResult = .failure(AppError.notConnected)

        let session = makeSession(service: mockService)
        session.status = .connected
        await session.send("Hi")

        #expect(session.messages.count == 1) // user message only
        #expect(session.status == .error)
        #expect(session.isProcessing == false)
    }

    // MARK: - interrupt

    @Test func interruptStopsProcessing() async {
        let mockService = MockAgentService()
        let session = makeSession(service: mockService)
        session.isProcessing = true

        await session.interrupt()

        #expect(session.isProcessing == false)
        #expect(mockService.interruptCallCount == 1)
    }

    // MARK: - disconnect

    @Test func disconnectSetsStatusToDisconnected() async {
        let mockService = MockAgentService()
        let session = makeSession(service: mockService)
        session.status = .connected

        await session.disconnect()

        #expect(session.status == .disconnected)
        #expect(mockService.closeCallCount == 1)
    }

    // MARK: - reconnect

    @Test func reconnectSetsStatusToConnected() async throws {
        let mockService = MockAgentService()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.resumeResult = .success(stream)

        let session = makeSession(service: mockService)
        try await session.reconnect()

        #expect(session.status == .connected)
    }

    @Test func reconnectSetsErrorOnFailure() async {
        let mockService = MockAgentService()
        mockService.resumeResult = .failure(AppError.notConnected)

        let session = makeSession(service: mockService)
        do {
            try await session.reconnect()
            Issue.record("Expected error")
        } catch {
            #expect(session.status == .error)
        }
    }

    // MARK: - displayName

    @Test func displayNameUsesConfigName() {
        let mockService = MockAgentService()
        let session = SessionState(
            id: "sess-1",
            config: SessionConfig(model: .sonnet, workingDirectory: "/tmp", name: "My Session"),
            agentService: mockService
        )
        #expect(session.displayName == "My Session")
    }

    @Test func displayNameFallsBackToMessagePreview() {
        let mockService = MockAgentService()
        let session = SessionState(
            id: "sess-1",
            config: SessionConfig(model: .sonnet, workingDirectory: "/tmp"),
            messages: [ChatMessage(role: .user, content: [.text("Hello world")])],
            agentService: mockService
        )
        #expect(session.displayName == "Hello world")
    }

    @Test func displayNameFallsBackToDefault() {
        let session = makeSession()
        #expect(session.displayName == "New Session")
    }

    // MARK: - stream processing

    @Test func streamUpdatesPartialTextThenClears() async {
        let mockService = MockAgentService()
        let stream = AsyncThrowingStream<AgentEvent, Error> { continuation in
            continuation.yield(.partialText("Hello"))
            continuation.yield(.assistantMessage(content: [.text("Hello world")]))
            continuation.yield(.turnCompleted(costUsd: 0.001, inputTokens: 5, outputTokens: 3))
            continuation.finish()
        }
        mockService.sendResult = .success(stream)

        let session = makeSession(service: mockService)
        session.status = .connected
        await session.send("Hi")

        #expect(session.streamingText == "")
        #expect(session.messages.count == 2)
    }

    @Test func toSessionDataConvertsCorrectly() {
        let mockService = MockAgentService()
        let session = SessionState(
            id: "sess-1",
            config: SessionConfig(model: .sonnet, workingDirectory: "/tmp"),
            messages: [ChatMessage(role: .user, content: [.text("test")])],
            agentService: mockService
        )

        let data = session.toSessionData()

        #expect(data.id == "sess-1")
        #expect(data.messages.count == 1)
        #expect(data.config.model == .sonnet)
    }
}
