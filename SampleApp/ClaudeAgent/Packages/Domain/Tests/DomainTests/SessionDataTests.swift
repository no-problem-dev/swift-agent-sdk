import Testing
import Foundation
@testable import Domain

@Suite
struct SessionDataTests {
    @Test func codableRoundTrip() throws {
        let config = SessionConfig(
            model: .sonnet,
            workingDirectory: "/Users/dev/project",
            systemPrompt: "You are a helper",
            name: "Test Session"
        )
        let message = ChatMessage(
            role: .user,
            content: [.text("Hello")]
        )
        let session = SessionData(
            id: "session-123",
            config: config,
            messages: [message],
            totalCostUsd: 0.0456
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionData.self, from: data)

        #expect(decoded.id == session.id)
        #expect(decoded.config.model == .sonnet)
        #expect(decoded.config.workingDirectory == "/Users/dev/project")
        #expect(decoded.config.systemPrompt == "You are a helper")
        #expect(decoded.config.name == "Test Session")
        #expect(decoded.messages.count == 1)
        #expect(decoded.totalCostUsd == 0.0456)
    }

    @Test func defaultValues() {
        let config = SessionConfig(workingDirectory: "/tmp")
        let session = SessionData(id: "s1", config: config)

        #expect(session.messages.isEmpty)
        #expect(session.totalCostUsd == 0)
    }

    @Test func sessionWithToolUseContent() throws {
        let toolUse = ToolUseItem(id: "t1", name: "Read", input: ["path": "/file.swift"])
        let toolResult = ToolResultItem(toolUseId: "t1", content: "file contents", isError: false)
        let message = ChatMessage(
            role: .assistant,
            content: [
                .text("Let me read the file"),
                .toolUse(toolUse),
                .toolResult(toolResult),
            ]
        )
        let config = SessionConfig(workingDirectory: "/tmp")
        let session = SessionData(id: "s1", config: config, messages: [message])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SessionData.self, from: data)

        #expect(decoded.messages.count == 1)
        #expect(decoded.messages[0].content.count == 3)
    }
}
