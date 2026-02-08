import Foundation
import Testing
@testable import Domain

@Suite
struct ChatMessageTests {
    @Test func textPreviewReturnsFirstTextContent() {
        let message = ChatMessage(
            role: .assistant,
            content: [.text("Hello, world!")]
        )
        #expect(message.textPreview == "Hello, world!")
    }

    @Test func textPreviewTruncatesAt30Characters() {
        let longText = String(repeating: "a", count: 50)
        let message = ChatMessage(
            role: .assistant,
            content: [.text(longText)]
        )
        #expect(message.textPreview == String(repeating: "a", count: 30))
    }

    @Test func textPreviewReturnsNilForEmptyContent() {
        let message = ChatMessage(role: .user, content: [])
        #expect(message.textPreview == nil)
    }

    @Test func textPreviewReturnsNilForNonTextContent() {
        let toolUse = ToolUseItem(id: "t1", name: "Bash", input: ["command": "ls"])
        let message = ChatMessage(
            role: .assistant,
            content: [.toolUse(toolUse)]
        )
        #expect(message.textPreview == nil)
    }

    @Test func textPreviewReturnsFirstTextIgnoringToolUse() {
        let toolUse = ToolUseItem(id: "t1", name: "Bash", input: ["command": "ls"])
        let message = ChatMessage(
            role: .assistant,
            content: [.toolUse(toolUse), .text("After tool")]
        )
        #expect(message.textPreview == "After tool")
    }

    @Test func roleValues() {
        #expect(ChatMessage.Role.user.rawValue == "user")
        #expect(ChatMessage.Role.assistant.rawValue == "assistant")
        #expect(ChatMessage.Role.system.rawValue == "system")
    }

    @Test func codableRoundTrip() throws {
        let message = ChatMessage(
            role: .user,
            content: [.text("Hello")]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(message)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChatMessage.self, from: data)

        #expect(decoded.id == message.id)
        #expect(decoded.role == message.role)
        #expect(decoded.content == message.content)
    }
}
