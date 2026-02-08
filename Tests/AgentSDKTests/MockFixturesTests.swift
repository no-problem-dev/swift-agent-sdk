import Testing
import Foundation
import AgentSDK
import AgentSDKTesting

@Suite("MockFixtures Tests")
struct MockFixturesTests {

    // MARK: - simpleSuccess

    @Test("simpleSuccess returns system -> assistant -> result")
    func testSimpleSuccess() {
        let messages = MockFixtures.simpleSuccess()
        #expect(messages.count == 3)

        guard case .system(let sys) = messages[0] else {
            Issue.record("Expected system"); return
        }
        #expect(sys.sessionId == "mock-session")
        #expect(sys.tools.isEmpty)

        guard case .assistant(let asst) = messages[1] else {
            Issue.record("Expected assistant"); return
        }
        #expect(asst.content.count == 1)
        guard case .text(let text) = asst.content[0] else {
            Issue.record("Expected text content"); return
        }
        #expect(text == "Hello!")

        guard case .result(let result) = messages[2] else {
            Issue.record("Expected result"); return
        }
        #expect(result.result == "Hello!")
        #expect(result.costUsd > 0)
        #expect(result.numTurns == 1)
    }

    @Test("simpleSuccess with custom text")
    func testSimpleSuccessCustomText() {
        let messages = MockFixtures.simpleSuccess(text: "Custom response")

        guard case .assistant(let asst) = messages[1] else {
            Issue.record("Expected assistant"); return
        }
        guard case .text(let text) = asst.content[0] else {
            Issue.record("Expected text content"); return
        }
        #expect(text == "Custom response")

        guard case .result(let result) = messages[2] else {
            Issue.record("Expected result"); return
        }
        #expect(result.result == "Custom response")
    }

    // MARK: - withToolUse

    @Test("withToolUse returns system -> assistant(toolUse) -> assistant(toolResult) -> result")
    func testWithToolUse() {
        let messages = MockFixtures.withToolUse(toolName: "Read", result: "file contents")
        #expect(messages.count == 4)

        guard case .system(let sys) = messages[0] else {
            Issue.record("Expected system"); return
        }
        #expect(sys.tools.count == 1)
        #expect(sys.tools[0].name == "Read")

        guard case .assistant(let toolUseMsg) = messages[1] else {
            Issue.record("Expected assistant with toolUse"); return
        }
        guard case .toolUse(let toolUse) = toolUseMsg.content[0] else {
            Issue.record("Expected toolUse content"); return
        }
        #expect(toolUse.name == "Read")
        #expect(!toolUse.id.isEmpty)

        guard case .assistant(let toolResultMsg) = messages[2] else {
            Issue.record("Expected assistant with toolResult"); return
        }
        guard case .toolResult(let toolResult) = toolResultMsg.content[0] else {
            Issue.record("Expected toolResult content"); return
        }
        #expect(toolResult.toolUseId == toolUse.id)
        #expect(toolResult.content == "file contents")
        #expect(toolResult.isError == false)

        guard case .result(let result) = messages[3] else {
            Issue.record("Expected result"); return
        }
        #expect(result.result == "file contents")
        #expect(result.numTurns == 2)
    }

    @Test("withToolUse default parameters")
    func testWithToolUseDefaults() {
        let messages = MockFixtures.withToolUse()
        #expect(messages.count == 4)

        guard case .assistant(let toolUseMsg) = messages[1] else {
            Issue.record("Expected assistant"); return
        }
        guard case .toolUse(let toolUse) = toolUseMsg.content[0] else {
            Issue.record("Expected toolUse"); return
        }
        #expect(toolUse.name == "Bash")
    }

    // MARK: - protocolError

    @Test("protocolError returns system -> empty result")
    func testProtocolError() {
        let messages = MockFixtures.protocolError()
        #expect(messages.count == 2)

        guard case .system = messages[0] else {
            Issue.record("Expected system"); return
        }

        guard case .result(let result) = messages[1] else {
            Issue.record("Expected result"); return
        }
        #expect(result.result.isEmpty)
        #expect(result.costUsd == 0.0)
        #expect(result.numTurns == 0)
    }

    // MARK: - Codable

    @Test("All fixtures are JSON-encodable")
    func testAllFixturesEncodable() throws {
        let encoder = JSONEncoder()

        for msg in MockFixtures.simpleSuccess() {
            let data = try encoder.encode(msg)
            #expect(!data.isEmpty)
        }

        for msg in MockFixtures.withToolUse() {
            let data = try encoder.encode(msg)
            #expect(!data.isEmpty)
        }

        for msg in MockFixtures.protocolError() {
            let data = try encoder.encode(msg)
            #expect(!data.isEmpty)
        }
    }
}
