import Testing
import Foundation
@testable import AgentSDK

@Suite("AgentMessage Tests")
struct AgentMessageTests {

    // MARK: - System Message Tests

    @Test("System message Codable round-trip")
    func systemMessageRoundTrip() throws {
        let original = AgentMessage.system(SystemInfo(
            sessionId: "test-session-123",
            tools: [
                ToolInfo(name: "Read", description: "Read files"),
                ToolInfo(name: "Write", description: nil)
            ],
            model: "claude-opus-4",
            mcpServers: [
                MCPServerInfo(name: "mcp-server-1", status: "connected"),
                MCPServerInfo(name: "mcp-server-2", status: "disconnected")
            ]
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .system(let decodedInfo) = decoded else {
            Issue.record("Expected system message, got \(decoded)")
            return
        }

        #expect(decodedInfo.sessionId == "test-session-123")
        #expect(decodedInfo.tools.count == 2)
        #expect(decodedInfo.tools[0].name == "Read")
        #expect(decodedInfo.tools[0].description == "Read files")
        #expect(decodedInfo.tools[1].name == "Write")
        #expect(decodedInfo.tools[1].description == nil)
        #expect(decodedInfo.model == "claude-opus-4")
        #expect(decodedInfo.mcpServers.count == 2)
        #expect(decodedInfo.mcpServers[0].name == "mcp-server-1")
        #expect(decodedInfo.mcpServers[0].status == "connected")
    }

    @Test("System message with empty collections")
    func systemMessageEmptyCollections() throws {
        let original = AgentMessage.system(SystemInfo(
            sessionId: "empty-session",
            tools: [],
            model: "claude-sonnet",
            mcpServers: []
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .system(let decodedInfo) = decoded else {
            Issue.record("Expected system message")
            return
        }

        #expect(decodedInfo.sessionId == "empty-session")
        #expect(decodedInfo.tools.isEmpty)
        #expect(decodedInfo.mcpServers.isEmpty)
    }

    // MARK: - Assistant Message Tests

    @Test("Assistant message Codable round-trip")
    func assistantMessageRoundTrip() throws {
        let original = AgentMessage.assistant(AssistantInfo(
            content: [
                .text("Hello, world!"),
                .toolUse(ToolUse(
                    id: "tool-use-123",
                    name: "Read",
                    input: ["path": "/test/file.txt"]
                ))
            ],
            parentToolUseId: "parent-tool-456"
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .assistant(let decodedInfo) = decoded else {
            Issue.record("Expected assistant message")
            return
        }

        #expect(decodedInfo.content.count == 2)
        #expect(decodedInfo.parentToolUseId == "parent-tool-456")

        guard case .text(let text) = decodedInfo.content[0] else {
            Issue.record("Expected text content block")
            return
        }
        #expect(text == "Hello, world!")

        guard case .toolUse(let toolUse) = decodedInfo.content[1] else {
            Issue.record("Expected toolUse content block")
            return
        }
        #expect(toolUse.id == "tool-use-123")
        #expect(toolUse.name == "Read")
    }

    @Test("Assistant message without parent tool use ID")
    func assistantMessageNoParent() throws {
        let original = AgentMessage.assistant(AssistantInfo(
            content: [.text("No parent")],
            parentToolUseId: nil
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .assistant(let decodedInfo) = decoded else {
            Issue.record("Expected assistant message")
            return
        }

        #expect(decodedInfo.parentToolUseId == nil)
        #expect(decodedInfo.content.count == 1)
    }

    // MARK: - Partial Message Tests

    @Test("Partial message Codable round-trip")
    func partialMessageRoundTrip() throws {
        let original = AgentMessage.partial(PartialInfo(
            content: [
                .text("Partial response"),
                .toolResult(ToolResult(
                    toolUseId: "tool-123",
                    content: "Result content",
                    isError: false
                ))
            ]
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .partial(let decodedInfo) = decoded else {
            Issue.record("Expected partial message")
            return
        }

        #expect(decodedInfo.content.count == 2)

        guard case .text(let text) = decodedInfo.content[0] else {
            Issue.record("Expected text content block")
            return
        }
        #expect(text == "Partial response")
    }

    @Test("Partial message with empty content")
    func partialMessageEmpty() throws {
        let original = AgentMessage.partial(PartialInfo(content: []))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .partial(let decodedInfo) = decoded else {
            Issue.record("Expected partial message")
            return
        }

        #expect(decodedInfo.content.isEmpty)
    }

    // MARK: - Result Message Tests

    @Test("Result message Codable round-trip")
    func resultMessageRoundTrip() throws {
        let original = AgentMessage.result(ResultInfo(
            result: "Task completed successfully",
            costUsd: 0.0025,
            durationMs: 1500,
            inputTokens: 100,
            outputTokens: 50,
            sessionId: "session-789",
            numTurns: 3
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .result(let decodedInfo) = decoded else {
            Issue.record("Expected result message")
            return
        }

        #expect(decodedInfo.result == "Task completed successfully")
        #expect(decodedInfo.costUsd == 0.0025)
        #expect(decodedInfo.durationMs == 1500)
        #expect(decodedInfo.inputTokens == 100)
        #expect(decodedInfo.outputTokens == 50)
        #expect(decodedInfo.sessionId == "session-789")
        #expect(decodedInfo.numTurns == 3)
    }

    @Test("Result message with zero values")
    func resultMessageZeroValues() throws {
        let original = AgentMessage.result(ResultInfo(
            result: "",
            costUsd: 0.0,
            durationMs: 0,
            inputTokens: 0,
            outputTokens: 0,
            sessionId: "zero-session",
            numTurns: 0
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AgentMessage.self, from: data)

        guard case .result(let decodedInfo) = decoded else {
            Issue.record("Expected result message")
            return
        }

        #expect(decodedInfo.result == "")
        #expect(decodedInfo.costUsd == 0.0)
        #expect(decodedInfo.durationMs == 0)
        #expect(decodedInfo.inputTokens == 0)
        #expect(decodedInfo.outputTokens == 0)
        #expect(decodedInfo.numTurns == 0)
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching exhaustiveness")
    func patternMatchingExhaustive() {
        let messages: [AgentMessage] = [
            .system(SystemInfo(sessionId: "s1", tools: [], model: "m1", mcpServers: [])),
            .assistant(AssistantInfo(content: [], parentToolUseId: nil)),
            .partial(PartialInfo(content: [])),
            .result(ResultInfo(result: "r", costUsd: 0, durationMs: 0, inputTokens: 0, outputTokens: 0, sessionId: "s2", numTurns: 0))
        ]

        for message in messages {
            let matched: Bool
            switch message {
            case .system: matched = true
            case .assistant: matched = true
            case .partial: matched = true
            case .result: matched = true
            }
            #expect(matched)
        }
    }

    @Test("Extract associated values from each case")
    func extractAssociatedValues() {
        let systemMsg = AgentMessage.system(SystemInfo(
            sessionId: "test",
            tools: [],
            model: "model",
            mcpServers: []
        ))
        if case .system(let info) = systemMsg {
            #expect(info.sessionId == "test")
        } else {
            Issue.record("Failed to extract system info")
        }

        let assistantMsg = AgentMessage.assistant(AssistantInfo(
            content: [.text("test")],
            parentToolUseId: "parent"
        ))
        if case .assistant(let info) = assistantMsg {
            #expect(info.parentToolUseId == "parent")
        } else {
            Issue.record("Failed to extract assistant info")
        }

        let partialMsg = AgentMessage.partial(PartialInfo(content: []))
        if case .partial(let info) = partialMsg {
            #expect(info.content.isEmpty)
        } else {
            Issue.record("Failed to extract partial info")
        }

        let resultMsg = AgentMessage.result(ResultInfo(
            result: "done",
            costUsd: 1.0,
            durationMs: 100,
            inputTokens: 10,
            outputTokens: 20,
            sessionId: "s",
            numTurns: 1
        ))
        if case .result(let info) = resultMsg {
            #expect(info.result == "done")
            #expect(info.numTurns == 1)
        } else {
            Issue.record("Failed to extract result info")
        }
    }

    // MARK: - JSON Structure Tests

    @Test("System message JSON structure")
    func systemMessageJSONStructure() throws {
        let message = AgentMessage.system(SystemInfo(
            sessionId: "test",
            tools: [ToolInfo(name: "Tool1")],
            model: "model",
            mcpServers: []
        ))

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "system")
        #expect(json?["sessionId"] as? String == "test")
        #expect(json?["model"] as? String == "model")
        #expect((json?["tools"] as? [[String: Any]])?.count == 1)
    }

    @Test("Assistant message JSON structure")
    func assistantMessageJSONStructure() throws {
        let message = AgentMessage.assistant(AssistantInfo(
            content: [.text("hello")],
            parentToolUseId: "parent"
        ))

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "assistant")
        #expect(json?["parentToolUseId"] as? String == "parent")
        #expect((json?["content"] as? [[String: Any]])?.count == 1)
    }

    @Test("Partial message JSON structure")
    func partialMessageJSONStructure() throws {
        let message = AgentMessage.partial(PartialInfo(content: []))

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "partial")
        #expect(json?["content"] != nil)
    }

    @Test("Result message JSON structure")
    func resultMessageJSONStructure() throws {
        let message = AgentMessage.result(ResultInfo(
            result: "done",
            costUsd: 0.5,
            durationMs: 1000,
            inputTokens: 100,
            outputTokens: 50,
            sessionId: "session",
            numTurns: 2
        ))

        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "result")
        #expect(json?["result"] as? String == "done")
        #expect(json?["costUsd"] as? Double == 0.5)
        #expect(json?["durationMs"] as? Int == 1000)
        #expect(json?["sessionId"] as? String == "session")
        #expect(json?["numTurns"] as? Int == 2)
    }
}
