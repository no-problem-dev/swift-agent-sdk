import Foundation
import Domain

final class MockSessionStore: SessionStoreProtocol, @unchecked Sendable {
    var savedSessions: [SessionData] = []
    var deletedSessionIds: [String] = []
    var loadAllResult: [SessionData] = []

    func loadAll() throws -> [SessionData] {
        loadAllResult
    }

    func save(_ sessions: [SessionData]) throws {
        savedSessions = sessions
    }

    func delete(sessionId: String) throws {
        deletedSessionIds.append(sessionId)
    }
}
