import Foundation

/// セッションの永続化を抽象化するプロトコル
public protocol SessionStoreProtocol: Sendable {
    func loadAll() throws -> [SessionData]
    func save(_ sessions: [SessionData]) throws
    func delete(sessionId: String) throws
}
