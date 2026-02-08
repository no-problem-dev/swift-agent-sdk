import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("CLIMessage Decoding Tests")
struct CLIMessageTests {

    @Test("Decode system message")
    func decodeSystemMessage() throws {
        let json = """
        {
            "type": "system",
            "session_id": "test-session-123",
            "tools": [{"name": "bash"}],
            "model": "claude-3-5-sonnet-20250219",
            "mcp_servers": [{"name": "server1"}]
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .system(let systemMsg) = message else {
            Issue.record("Expected .system, got \(message)")
            return
        }

        #expect(systemMsg.sessionId == "test-session-123")
        #expect(systemMsg.model == "claude-3-5-sonnet-20250219")
        #expect(systemMsg.tools.count == 1)
        #expect(systemMsg.mcpServers.count == 1)
    }

    @Test("Decode system message with subtype init")
    func decodeSystemMessageWithSubtype() throws {
        let json = """
        {
            "type": "system",
            "subtype": "init",
            "uuid": "abc-123",
            "session_id": "test-session-456",
            "tools": [],
            "model": "claude-opus-4-6",
            "mcp_servers": []
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .system(let systemMsg) = message else {
            Issue.record("Expected .system, got \(message)")
            return
        }

        #expect(systemMsg.sessionId == "test-session-456")
        #expect(systemMsg.subtype == "init")
        #expect(systemMsg.uuid == "abc-123")
    }

    @Test("Decode result message")
    func decodeResultMessage() throws {
        let json = """
        {
            "type": "result",
            "result": "success",
            "total_cost_usd": 0.05,
            "duration_ms": 1500,
            "usage": {
                "input_tokens": 100,
                "output_tokens": 200
            },
            "session_id": "session-456",
            "num_turns": 5
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .result(let resultMsg) = message else {
            Issue.record("Expected .result, got \(message)")
            return
        }

        #expect(resultMsg.result == "success")
        #expect(resultMsg.totalCostUsd == 0.05)
        #expect(resultMsg.durationMs == 1500)
        #expect(resultMsg.usage.inputTokens == 100)
        #expect(resultMsg.usage.outputTokens == 200)
        #expect(resultMsg.sessionId == "session-456")
        #expect(resultMsg.numTurns == 5)
    }

    @Test("Decode result message with optional fields")
    func decodeResultMessageWithOptionalFields() throws {
        let json = """
        {
            "type": "result",
            "subtype": "final",
            "uuid": "result-uuid-789",
            "result": "done",
            "total_cost_usd": 0.10,
            "duration_ms": 2000,
            "usage": {
                "input_tokens": 150,
                "output_tokens": 300
            },
            "session_id": "session-789",
            "num_turns": 3,
            "is_error": false,
            "duration_api_ms": 1800
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .result(let resultMsg) = message else {
            Issue.record("Expected .result, got \(message)")
            return
        }

        #expect(resultMsg.subtype == "final")
        #expect(resultMsg.uuid == "result-uuid-789")
        #expect(resultMsg.isError == false)
        #expect(resultMsg.durationApiMs == 1800)
    }

    @Test("Decode control request message")
    func decodeControlRequest() throws {
        let json = """
        {
            "type": "control_request",
            "request_id": "req-123",
            "request": {
                "subtype": "can_use_tool",
                "tool_name": "bash",
                "tool_input": {"command": "ls"}
            }
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .controlRequest(let ctrlReq) = message else {
            Issue.record("Expected .controlRequest, got \(message)")
            return
        }

        #expect(ctrlReq.requestId == "req-123")
        #expect(ctrlReq.request.subtype == "can_use_tool")
        #expect(ctrlReq.request.toolName == "bash")
        #expect(ctrlReq.request.toolInput != nil)
    }

    @Test("Decode unknown message type")
    func decodeUnknownMessage() throws {
        let json = """
        {"type":"foo"}
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .unknown(let type) = message else {
            Issue.record("Expected .unknown, got \(message)")
            return
        }

        #expect(type == "foo")
    }

    @Test("Decode assistant message")
    func decodeAssistantMessage() throws {
        let json = """
        {
            "type": "assistant",
            "message": {
                "content": [{"type": "text", "text": "Hello"}]
            },
            "parent_tool_use_id": "tool-123"
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .assistant(let assistantMsg) = message else {
            Issue.record("Expected .assistant, got \(message)")
            return
        }

        #expect(assistantMsg.parentToolUseId == "tool-123")
        #expect(assistantMsg.message.content.count == 1)
    }

    @Test("Decode partial assistant message")
    func decodePartialAssistantMessage() throws {
        let json = """
        {
            "type": "assistant",
            "subtype": "partial",
            "message": {
                "content": [{"type": "text", "text": "Hello"}]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .partialAssistant(let partialMsg) = message else {
            Issue.record("Expected .partialAssistant, got \(message)")
            return
        }

        #expect(partialMsg.message.content.count == 1)
    }

    @Test("Decode control response message")
    func decodeControlResponse() throws {
        let json = """
        {
            "type": "control_response",
            "response": {
                "subtype": "initialize",
                "request_id": "req-456",
                "response": {"status": "ok"}
            }
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .controlResponse(let ctrlResp) = message else {
            Issue.record("Expected .controlResponse, got \(message)")
            return
        }

        #expect(ctrlResp.response.subtype == "initialize")
        #expect(ctrlResp.response.requestId == "req-456")
        #expect(ctrlResp.response.response != nil)
    }

    @Test("Decode stream event message")
    func decodeStreamEvent() throws {
        let json = """
        {
            "type": "stream_event",
            "event": {"type": "content_block_delta", "delta": {"text": "hello"}}
        }
        """
        let data = json.data(using: .utf8)!
        let message = try JSONDecoder().decode(CLIMessage.self, from: data)

        guard case .streamEvent(let event) = message else {
            Issue.record("Expected .streamEvent, got \(message)")
            return
        }

        if case .object(let dict) = event.event {
            #expect(dict["type"] == .string("content_block_delta"))
        } else {
            Issue.record("Expected object event")
        }
    }
}
