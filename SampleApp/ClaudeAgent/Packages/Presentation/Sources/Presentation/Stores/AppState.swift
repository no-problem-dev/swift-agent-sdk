import Foundation
import Domain

/// アプリ全体の状態管理
@MainActor @Observable
public final class AppState {
    public private(set) var sessions: [SessionState] = []
    public var activeSessionId: String?

    public var activeSession: SessionState? {
        guard let id = activeSessionId else { return nil }
        return sessions.first { $0.id == id }
    }

    public var sortedSessions: [SessionState] {
        sessions.sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    private let agentService: any AgentServiceProtocol
    private let sessionStore: any SessionStoreProtocol

    public init(agentService: any AgentServiceProtocol, sessionStore: any SessionStoreProtocol) {
        self.agentService = agentService
        self.sessionStore = sessionStore
    }

    // MARK: - Actions

    public func createSession(config: SessionConfig) async throws {
        let (sessionId, stream) = try await agentService.createSession(config: config)
        let session = SessionState(
            id: sessionId,
            config: config,
            agentService: agentService
        )
        sessions.append(session)
        activeSessionId = sessionId
        session.status = .connected
        await session.processStream(stream)
        try? sessionStore.save(sessions.map { $0.toSessionData() })
    }

    public func deleteSession(id: String) {
        if let session = sessions.first(where: { $0.id == id }) {
            if session.status == .connected {
                Task { try? await agentService.close(sessionId: id) }
            }
        }
        sessions.removeAll { $0.id == id }
        if activeSessionId == id {
            activeSessionId = sessions.first?.id
        }
        try? sessionStore.delete(sessionId: id)
    }

    public func loadSavedSessions() {
        guard let savedSessions = try? sessionStore.loadAll() else { return }
        sessions = savedSessions.map { data in
            SessionState(
                id: data.id,
                config: data.config,
                createdAt: data.createdAt,
                lastActiveAt: data.lastActiveAt,
                messages: data.messages,
                totalCostUsd: data.totalCostUsd,
                agentService: agentService
            )
        }
    }

    public func saveAllSessions() {
        try? sessionStore.save(sessions.map { $0.toSessionData() })
    }
}
