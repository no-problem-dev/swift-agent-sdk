import Foundation
import Domain

/// SessionStoreProtocol の JSON ファイル実装
public struct JSONSessionStore: SessionStoreProtocol {
    private let baseURL: URL

    public init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("ClaudeAgent")
    }

    private var fileURL: URL {
        baseURL.appendingPathComponent("sessions.json")
    }

    public func loadAll() throws -> [SessionData] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SessionData].self, from: data)
        } catch {
            throw AppError.persistenceError(error.localizedDescription)
        }
    }

    public func save(_ sessions: [SessionData]) throws {
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            try FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true
            )
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(sessions)
        try data.write(to: fileURL, options: .atomic)
    }

    public func delete(sessionId: String) throws {
        var sessions = try loadAll()
        sessions.removeAll { $0.id == sessionId }
        try save(sessions)
    }
}
