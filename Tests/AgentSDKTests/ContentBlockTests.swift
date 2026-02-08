import Testing
import Foundation
@testable import AgentSDK

@Suite("ContentBlock Tests")
struct ContentBlockTests {

    // MARK: - Text Content Block Tests

    @Test("Text content block Codable round-trip")
    func textContentBlockRoundTrip() throws {
        let original = ContentBlock.text("Hello, world!")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .text(let decodedText) = decoded else {
            Issue.record("Expected text content block")
            return
        }

        #expect(decodedText == "Hello, world!")
    }

    @Test("Empty text content block")
    func emptyTextContentBlock() throws {
        let original = ContentBlock.text("")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .text(let decodedText) = decoded else {
            Issue.record("Expected text content block")
            return
        }

        #expect(decodedText == "")
    }

    @Test("Text with special characters")
    func textWithSpecialCharacters() throws {
        let specialText = "Line 1\nLine 2\tTabbed\r\nWindows line\n\"Quoted\" and 'single quoted'\n🎉 Emoji"
        let original = ContentBlock.text(specialText)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .text(let decodedText) = decoded else {
            Issue.record("Expected text content block")
            return
        }

        #expect(decodedText == specialText)
    }

    // MARK: - ToolUse Content Block Tests

    @Test("ToolUse Codable round-trip with simple input")
    func toolUseRoundTripSimpleInput() throws {
        let original = ContentBlock.toolUse(ToolUse(
            id: "tool-use-abc123",
            name: "Read",
            input: [
                "path": .string("/path/to/file.txt"),
                "encoding": .string("utf-8")
            ]
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolUse(let decodedToolUse) = decoded else {
            Issue.record("Expected toolUse content block")
            return
        }

        #expect(decodedToolUse.id == "tool-use-abc123")
        #expect(decodedToolUse.name == "Read")
        #expect(decodedToolUse.input.count == 2)
        #expect(decodedToolUse.input["path"] == .string("/path/to/file.txt"))
        #expect(decodedToolUse.input["encoding"] == .string("utf-8"))
    }

    @Test("ToolUse with complex nested input")
    func toolUseComplexNestedInput() throws {
        let original = ContentBlock.toolUse(ToolUse(
            id: "tool-complex",
            name: "ComplexTool",
            input: [
                "config": .object([
                    "enabled": .bool(true),
                    "count": .integer(42),
                    "threshold": .number(3.14)
                ]),
                "items": .array([
                    .string("item1"),
                    .string("item2"),
                    .integer(3)
                ]),
                "metadata": .null
            ]
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolUse(let decodedToolUse) = decoded else {
            Issue.record("Expected toolUse content block")
            return
        }

        #expect(decodedToolUse.id == "tool-complex")
        #expect(decodedToolUse.name == "ComplexTool")
        #expect(decodedToolUse.input.count == 3)

        // Verify nested object
        guard case .object(let config) = decodedToolUse.input["config"] else {
            Issue.record("Expected config to be object")
            return
        }
        #expect(config["enabled"] == .bool(true))
        #expect(config["count"] == .integer(42))
        #expect(config["threshold"] == .number(3.14))

        // Verify array
        guard case .array(let items) = decodedToolUse.input["items"] else {
            Issue.record("Expected items to be array")
            return
        }
        #expect(items.count == 3)
        #expect(items[0] == .string("item1"))
        #expect(items[2] == .integer(3))

        // Verify null
        #expect(decodedToolUse.input["metadata"] == .null)
    }

    @Test("ToolUse with empty input")
    func toolUseEmptyInput() throws {
        let original = ContentBlock.toolUse(ToolUse(
            id: "empty-tool",
            name: "EmptyTool",
            input: [:]
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolUse(let decodedToolUse) = decoded else {
            Issue.record("Expected toolUse content block")
            return
        }

        #expect(decodedToolUse.id == "empty-tool")
        #expect(decodedToolUse.name == "EmptyTool")
        #expect(decodedToolUse.input.isEmpty)
    }

    @Test("ToolUse id, name, and input fields survive round-trip")
    func toolUseFieldsSurviveRoundTrip() throws {
        let toolUse = ToolUse(
            id: "unique-id-12345",
            name: "TestTool",
            input: [
                "param1": .string("value1"),
                "param2": .integer(100)
            ]
        )

        let original = ContentBlock.toolUse(toolUse)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolUse(let decodedToolUse) = decoded else {
            Issue.record("Expected toolUse content block")
            return
        }

        #expect(decodedToolUse.id == toolUse.id)
        #expect(decodedToolUse.name == toolUse.name)
        #expect(decodedToolUse.input == toolUse.input)
    }

    // MARK: - ToolResult Content Block Tests

    @Test("ToolResult Codable round-trip")
    func toolResultRoundTrip() throws {
        let original = ContentBlock.toolResult(ToolResult(
            toolUseId: "tool-use-xyz",
            content: "Tool execution completed successfully",
            isError: false
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolResult(let decodedToolResult) = decoded else {
            Issue.record("Expected toolResult content block")
            return
        }

        #expect(decodedToolResult.toolUseId == "tool-use-xyz")
        #expect(decodedToolResult.content == "Tool execution completed successfully")
        #expect(decodedToolResult.isError == false)
    }

    @Test("ToolResult with error")
    func toolResultWithError() throws {
        let original = ContentBlock.toolResult(ToolResult(
            toolUseId: "tool-error-123",
            content: "Error: File not found",
            isError: true
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolResult(let decodedToolResult) = decoded else {
            Issue.record("Expected toolResult content block")
            return
        }

        #expect(decodedToolResult.toolUseId == "tool-error-123")
        #expect(decodedToolResult.content == "Error: File not found")
        #expect(decodedToolResult.isError == true)
    }

    @Test("ToolResult default isError is false")
    func toolResultDefaultIsError() throws {
        let toolResult = ToolResult(
            toolUseId: "default-test",
            content: "Default behavior test"
        )

        #expect(toolResult.isError == false)

        let original = ContentBlock.toolResult(toolResult)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolResult(let decodedToolResult) = decoded else {
            Issue.record("Expected toolResult content block")
            return
        }

        #expect(decodedToolResult.isError == false)
    }

    @Test("ToolResult toolUseId, content, isError fields survive round-trip")
    func toolResultFieldsSurviveRoundTrip() throws {
        let toolResult = ToolResult(
            toolUseId: "verify-fields-123",
            content: "Content to verify",
            isError: true
        )

        let original = ContentBlock.toolResult(toolResult)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolResult(let decodedToolResult) = decoded else {
            Issue.record("Expected toolResult content block")
            return
        }

        #expect(decodedToolResult.toolUseId == toolResult.toolUseId)
        #expect(decodedToolResult.content == toolResult.content)
        #expect(decodedToolResult.isError == toolResult.isError)
    }

    @Test("ToolResult with empty content")
    func toolResultEmptyContent() throws {
        let original = ContentBlock.toolResult(ToolResult(
            toolUseId: "empty-content",
            content: "",
            isError: false
        ))

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ContentBlock.self, from: data)

        guard case .toolResult(let decodedToolResult) = decoded else {
            Issue.record("Expected toolResult content block")
            return
        }

        #expect(decodedToolResult.content == "")
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching all content block types")
    func patternMatchingAllTypes() {
        let blocks: [ContentBlock] = [
            .text("text"),
            .toolUse(ToolUse(id: "1", name: "Tool", input: [:])),
            .toolResult(ToolResult(toolUseId: "1", content: "result"))
        ]

        for block in blocks {
            let matched: Bool
            switch block {
            case .text: matched = true
            case .toolUse: matched = true
            case .toolResult: matched = true
            }
            #expect(matched)
        }
    }

    @Test("Extract associated values from each case")
    func extractAssociatedValues() {
        let textBlock = ContentBlock.text("test text")
        if case .text(let text) = textBlock {
            #expect(text == "test text")
        } else {
            Issue.record("Failed to extract text")
        }

        let toolUseBlock = ContentBlock.toolUse(ToolUse(
            id: "id1",
            name: "name1",
            input: ["key": "value"]
        ))
        if case .toolUse(let toolUse) = toolUseBlock {
            #expect(toolUse.id == "id1")
            #expect(toolUse.name == "name1")
        } else {
            Issue.record("Failed to extract toolUse")
        }

        let toolResultBlock = ContentBlock.toolResult(ToolResult(
            toolUseId: "id2",
            content: "content2",
            isError: true
        ))
        if case .toolResult(let toolResult) = toolResultBlock {
            #expect(toolResult.toolUseId == "id2")
            #expect(toolResult.content == "content2")
            #expect(toolResult.isError == true)
        } else {
            Issue.record("Failed to extract toolResult")
        }
    }

    // MARK: - JSON Structure Tests

    @Test("Text block JSON structure")
    func textBlockJSONStructure() throws {
        let block = ContentBlock.text("sample text")
        let data = try JSONEncoder().encode(block)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "text")
        #expect(json?["text"] as? String == "sample text")
    }

    @Test("ToolUse block JSON structure")
    func toolUseBlockJSONStructure() throws {
        let block = ContentBlock.toolUse(ToolUse(
            id: "tool-id",
            name: "ToolName",
            input: ["param": .string("value")]
        ))
        let data = try JSONEncoder().encode(block)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "tool_use")
        #expect(json?["id"] as? String == "tool-id")
        #expect(json?["name"] as? String == "ToolName")
        #expect(json?["input"] != nil)
    }

    @Test("ToolResult block JSON structure")
    func toolResultBlockJSONStructure() throws {
        let block = ContentBlock.toolResult(ToolResult(
            toolUseId: "use-id",
            content: "result content",
            isError: true
        ))
        let data = try JSONEncoder().encode(block)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["type"] as? String == "tool_result")
        #expect(json?["tool_use_id"] as? String == "use-id")
        #expect(json?["content"] as? String == "result content")
        #expect(json?["is_error"] as? Bool == true)
    }

    // MARK: - Mixed Content Block Arrays

    @Test("Array of mixed content blocks round-trip")
    func mixedContentBlocksArray() throws {
        let blocks: [ContentBlock] = [
            .text("Introduction"),
            .toolUse(ToolUse(id: "t1", name: "Read", input: ["file": .string("test.txt")])),
            .toolResult(ToolResult(toolUseId: "t1", content: "File contents", isError: false)),
            .text("Conclusion")
        ]

        let data = try JSONEncoder().encode(blocks)
        let decoded = try JSONDecoder().decode([ContentBlock].self, from: data)

        #expect(decoded.count == 4)

        guard case .text(let intro) = decoded[0] else {
            Issue.record("Expected text at index 0")
            return
        }
        #expect(intro == "Introduction")

        guard case .toolUse(let toolUse) = decoded[1] else {
            Issue.record("Expected toolUse at index 1")
            return
        }
        #expect(toolUse.name == "Read")

        guard case .toolResult(let toolResult) = decoded[2] else {
            Issue.record("Expected toolResult at index 2")
            return
        }
        #expect(toolResult.content == "File contents")

        guard case .text(let conclusion) = decoded[3] else {
            Issue.record("Expected text at index 3")
            return
        }
        #expect(conclusion == "Conclusion")
    }
}
