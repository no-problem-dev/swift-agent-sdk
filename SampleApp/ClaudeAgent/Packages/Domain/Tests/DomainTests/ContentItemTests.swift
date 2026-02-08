import Testing
import Foundation
@testable import Domain

@Suite
struct ContentItemTests {
    @Test func textCaseCodable() throws {
        let item = ContentItem.text("Hello")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ContentItem.self, from: data)
        #expect(decoded == item)
    }

    @Test func toolUseCaseCodable() throws {
        let toolUse = ToolUseItem(id: "t1", name: "Bash", input: ["command": "ls"])
        let item = ContentItem.toolUse(toolUse)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ContentItem.self, from: data)
        #expect(decoded == item)
    }

    @Test func toolResultCaseCodable() throws {
        let toolResult = ToolResultItem(toolUseId: "t1", content: "output", isError: false)
        let item = ContentItem.toolResult(toolResult)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ContentItem.self, from: data)
        #expect(decoded == item)
    }

    @Test func hashableConformance() {
        let item1 = ContentItem.text("Hello")
        let item2 = ContentItem.text("Hello")
        let item3 = ContentItem.text("World")
        #expect(item1 == item2)
        #expect(item1 != item3)
    }

    @Test func toolResultWithError() throws {
        let toolResult = ToolResultItem(toolUseId: "t1", content: "error message", isError: true)
        let item = ContentItem.toolResult(toolResult)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ContentItem.self, from: data)
        if case .toolResult(let result) = decoded {
            #expect(result.isError == true)
            #expect(result.content == "error message")
        } else {
            Issue.record("Expected toolResult case")
        }
    }
}
