import Foundation
import Testing
import Domain
@testable import Presentation

@Suite(.serialized)
@MainActor
struct AppStateTests {

    @Test func createSessionAddsToSessions() async throws {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.createSessionResult = .success(("sess-1", stream))

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        let config = SessionConfig(model: .sonnet, workingDirectory: "/tmp")
        try await appState.createSession(config: config)

        #expect(appState.sessions.count == 1)
        #expect(appState.sessions.first?.id == "sess-1")
        #expect(appState.activeSessionId == "sess-1")
    }

    @Test func createSessionSavesToStore() async throws {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.createSessionResult = .success(("sess-1", stream))

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        let config = SessionConfig(model: .sonnet, workingDirectory: "/tmp")
        try await appState.createSession(config: config)

        #expect(mockStore.savedSessions.count == 1)
        #expect(mockStore.savedSessions.first?.id == "sess-1")
    }

    @Test func deleteSessionRemovesFromSessions() async throws {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.createSessionResult = .success(("sess-1", stream))

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        let config = SessionConfig(model: .sonnet, workingDirectory: "/tmp")
        try await appState.createSession(config: config)

        appState.deleteSession(id: "sess-1")

        #expect(appState.sessions.isEmpty)
        #expect(appState.activeSessionId == nil)
    }

    @Test func deleteSessionUpdatesStore() async throws {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.createSessionResult = .success(("sess-1", stream))

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        try await appState.createSession(config: SessionConfig(model: .sonnet, workingDirectory: "/tmp"))

        appState.deleteSession(id: "sess-1")

        #expect(mockStore.deletedSessionIds.contains("sess-1"))
    }

    @Test func loadSavedSessionsRestoresSessions() {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        mockStore.loadAllResult = [
            SessionData(id: "sess-1", config: SessionConfig(model: .sonnet, workingDirectory: "/tmp")),
            SessionData(id: "sess-2", config: SessionConfig(model: .opus, workingDirectory: "/home")),
        ]

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        appState.loadSavedSessions()

        #expect(appState.sessions.count == 2)
    }

    @Test func saveAllSessionsPersists() async throws {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.createSessionResult = .success(("sess-1", stream))

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        try await appState.createSession(config: SessionConfig(model: .sonnet, workingDirectory: "/tmp"))

        mockStore.savedSessions = [] // reset
        appState.saveAllSessions()

        #expect(mockStore.savedSessions.count == 1)
    }

    @Test func activeSessionReturnsCorrectSession() async throws {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let stream = AsyncThrowingStream<AgentEvent, Error> { $0.finish() }
        mockService.createSessionResult = .success(("sess-1", stream))

        let appState = AppState(agentService: mockService, sessionStore: mockStore)
        try await appState.createSession(config: SessionConfig(model: .sonnet, workingDirectory: "/tmp"))

        #expect(appState.activeSession?.id == "sess-1")
    }

    @Test func activeSessionReturnsNilWhenNoSelection() {
        let mockService = MockAgentService()
        let mockStore = MockSessionStore()
        let appState = AppState(agentService: mockService, sessionStore: mockStore)

        #expect(appState.activeSession == nil)
    }
}
