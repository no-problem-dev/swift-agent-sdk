import Foundation
import Testing
import AgentSDK
import Domain
@testable import Infrastructure

@Suite
struct AgentMessageMapperTests {
    // MARK: - AgentMessage → AgentEvent

    @Test func systemMessageMapsToInitialized() {
        let message = AgentMessage.system(SystemInfo(
            sessionId: "session-123",
            tools: [],
            model: "sonnet",
            mcpServers: []
        ))
        let event = AgentMessageMapper.map(message)
        guard case .initialized(let sessionId) = event else {
            Issue.record("Expected .initialized, got \(String(describing: event))")
            return
        }
        #expect(sessionId == "session-123")
    }

    @Test func partialTextMessageMapsToPartialText() {
        let message = AgentMessage.partial(PartialInfo(
            content: [.text("Hello ")]
        ))
        let event = AgentMessageMapper.map(message)
        guard case .partialText(let text) = event else {
            Issue.record("Expected .partialText, got \(String(describing: event))")
            return
        }
        #expect(text == "Hello ")
    }

    @Test func partialWithMultipleTextBlocksConcatenates() {
        let message = AgentMessage.partial(PartialInfo(
            content: [.text("Hello "), .text("World")]
        ))
        let event = AgentMessageMapper.map(message)
        guard case .partialText(let text) = event else {
            Issue.record("Expected .partialText, got \(String(describing: event))")
            return
        }
        #expect(text == "Hello World")
    }

    @Test func partialWithEmptyTextReturnsNil() {
        let message = AgentMessage.partial(PartialInfo(
            content: []
        ))
        let event = AgentMessageMapper.map(message)
        #expect(event == nil)
    }

    @Test func assistantMessageMapsToAssistantMessage() {
        let message = AgentMessage.assistant(AssistantInfo(
            content: [.text("response text")]
        ))
        let event = AgentMessageMapper.map(message)
        guard case .assistantMessage(let content) = event else {
            Issue.record("Expected .assistantMessage, got \(String(describing: event))")
            return
        }
        #expect(content.count == 1)
        if case .text(let text) = content.first {
            #expect(text == "response text")
        } else {
            Issue.record("Expected .text content item")
        }
    }

    @Test func resultMessageMapsToTurnCompleted() {
        let message = AgentMessage.result(ResultInfo(
            result: "done",
            costUsd: 0.05,
            durationMs: 1000,
            inputTokens: 100,
            outputTokens: 200,
            sessionId: "session-123",
            numTurns: 1
        ))
        let event = AgentMessageMapper.map(message)
        guard case .turnCompleted(let cost, let input, let output) = event else {
            Issue.record("Expected .turnCompleted, got \(String(describing: event))")
            return
        }
        #expect(cost == 0.05)
        #expect(input == 100)
        #expect(output == 200)
    }

    // MARK: - ContentBlock → ContentItem

    @Test func textBlockMapsToTextItem() {
        let item = AgentMessageMapper.mapContentBlock(.text("hello"))
        #expect(item == .text("hello"))
    }

    @Test func toolUseBlockMapsToToolUseItem() {
        let toolUse = ToolUse(
            id: "tu-1",
            name: "read_file",
            input: ["path": .string("/tmp/test.txt"), "lines": .integer(10)]
        )
        let item = AgentMessageMapper.mapContentBlock(.toolUse(toolUse))
        guard case .toolUse(let toolUseItem) = item else {
            Issue.record("Expected .toolUse, got \(String(describing: item))")
            return
        }
        #expect(toolUseItem.id == "tu-1")
        #expect(toolUseItem.name == "read_file")
        #expect(toolUseItem.input["path"] == "/tmp/test.txt")
        #expect(toolUseItem.input["lines"] == "10")
    }

    @Test func toolResultBlockMapsToToolResultItem() {
        let result = ToolResult(toolUseId: "tu-1", content: "file content", isError: false)
        let item = AgentMessageMapper.mapContentBlock(.toolResult(result))
        guard case .toolResult(let resultItem) = item else {
            Issue.record("Expected .toolResult, got \(String(describing: item))")
            return
        }
        #expect(resultItem.toolUseId == "tu-1")
        #expect(resultItem.content == "file content")
        #expect(resultItem.isError == false)
    }

    @Test func toolResultWithErrorMapsCorrectly() {
        let result = ToolResult(toolUseId: "tu-2", content: "error message", isError: true)
        let item = AgentMessageMapper.mapContentBlock(.toolResult(result))
        guard case .toolResult(let resultItem) = item else {
            Issue.record("Expected .toolResult, got \(String(describing: item))")
            return
        }
        #expect(resultItem.isError == true)
    }

    // MARK: - JSONValue → String conversion

    @Test func toolUseInputConvertsJsonValues() {
        let toolUse = ToolUse(
            id: "tu-3",
            name: "test_tool",
            input: [
                "str": .string("hello"),
                "num": .number(3.14),
                "int": .integer(42),
                "flag": .bool(true),
                "nothing": .null,
            ]
        )
        let item = AgentMessageMapper.mapContentBlock(.toolUse(toolUse))
        guard case .toolUse(let toolUseItem) = item else {
            Issue.record("Expected .toolUse")
            return
        }
        #expect(toolUseItem.input["str"] == "hello")
        #expect(toolUseItem.input["num"] == "3.14")
        #expect(toolUseItem.input["int"] == "42")
        #expect(toolUseItem.input["flag"] == "true")
        #expect(toolUseItem.input["nothing"] == "null")
    }
}
