import Testing
@testable import Domain

@Suite
struct AgentEventTests {
    @Test func initializedCase() {
        let event = AgentEvent.initialized(sessionId: "session-123")
        if case .initialized(let id) = event {
            #expect(id == "session-123")
        } else {
            Issue.record("Expected initialized case")
        }
    }

    @Test func partialTextCase() {
        let event = AgentEvent.partialText("Hello, ")
        if case .partialText(let text) = event {
            #expect(text == "Hello, ")
        } else {
            Issue.record("Expected partialText case")
        }
    }

    @Test func assistantMessageCase() {
        let content: [ContentItem] = [.text("Hello")]
        let event = AgentEvent.assistantMessage(content: content)
        if case .assistantMessage(let items) = event {
            #expect(items.count == 1)
        } else {
            Issue.record("Expected assistantMessage case")
        }
    }

    @Test func turnCompletedCase() {
        let event = AgentEvent.turnCompleted(costUsd: 0.05, inputTokens: 100, outputTokens: 200)
        if case .turnCompleted(let cost, let input, let output) = event {
            #expect(cost == 0.05)
            #expect(input == 100)
            #expect(output == 200)
        } else {
            Issue.record("Expected turnCompleted case")
        }
    }
}
