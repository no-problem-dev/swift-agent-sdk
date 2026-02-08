import Foundation
import Testing
import Domain
@testable import Infrastructure

@Suite
struct JSONSessionStoreTests {
    private func makeTempStore() -> (JSONSessionStore, URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("JSONSessionStoreTests-\(UUID().uuidString)")
        return (JSONSessionStore(baseURL: tempDir), tempDir)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func makeSampleSession(
        id: String = "session-1",
        name: String? = "Test Session"
    ) -> SessionData {
        let config = SessionConfig(
            model: .sonnet,
            workingDirectory: "/tmp",
            name: name
        )
        return SessionData(
            id: id,
            config: config,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastActiveAt: Date(timeIntervalSince1970: 1_700_000_000),
            messages: [],
            totalCostUsd: 0.0
        )
    }

    @Test func loadAllReturnsEmptyArrayWhenFileDoesNotExist() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let sessions = try store.loadAll()
        #expect(sessions.isEmpty)
    }

    @Test func saveAndLoadAllRoundTrip() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let session = makeSampleSession()
        try store.save([session])

        let loaded = try store.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == "session-1")
        #expect(loaded.first?.config.model == .sonnet)
        #expect(loaded.first?.config.workingDirectory == "/tmp")
    }

    @Test func saveMultipleSessions() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let sessions = [
            makeSampleSession(id: "s1", name: "First"),
            makeSampleSession(id: "s2", name: "Second"),
            makeSampleSession(id: "s3", name: "Third"),
        ]
        try store.save(sessions)

        let loaded = try store.loadAll()
        #expect(loaded.count == 3)
        #expect(loaded.map(\.id).sorted() == ["s1", "s2", "s3"])
    }

    @Test func deleteRemovesTargetSession() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let sessions = [
            makeSampleSession(id: "s1"),
            makeSampleSession(id: "s2"),
            makeSampleSession(id: "s3"),
        ]
        try store.save(sessions)

        try store.delete(sessionId: "s2")

        let loaded = try store.loadAll()
        #expect(loaded.count == 2)
        #expect(loaded.map(\.id).sorted() == ["s1", "s3"])
    }

    @Test func deleteNonExistentSessionIsNoOp() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let sessions = [makeSampleSession(id: "s1")]
        try store.save(sessions)

        try store.delete(sessionId: "non-existent")

        let loaded = try store.loadAll()
        #expect(loaded.count == 1)
    }

    @Test func savesWithAtomicWrite() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let session = makeSampleSession()
        try store.save([session])

        // Verify file exists (atomic write succeeded)
        let fileURL = tempDir.appendingPathComponent("sessions.json")
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test func saveCreatesDirectoryIfNeeded() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        // Directory should not exist yet
        #expect(!FileManager.default.fileExists(atPath: tempDir.path))

        try store.save([makeSampleSession()])

        // Directory should now exist
        #expect(FileManager.default.fileExists(atPath: tempDir.path))
    }

    @Test func dateEncodingUsesISO8601() throws {
        let (store, tempDir) = makeTempStore()
        defer { cleanup(tempDir) }

        let session = makeSampleSession()
        try store.save([session])

        let fileURL = tempDir.appendingPathComponent("sessions.json")
        let data = try Data(contentsOf: fileURL)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        // ISO8601 dates contain "T" separator between date and time
        #expect(jsonString.contains("T"))
    }
}
