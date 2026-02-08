import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("SDKMessage Encoding Tests")
struct SDKMessageTests {

    @Test("Encode user message")
    func encodeUserMessage() throws {
        let message = SDKMessage.userMessage(content: "hello")
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["type"] as? String == "user_message")
        #expect(json?["content"] as? String == "hello")
    }

    @Test("Encode control request")
    func encodeControlRequest() throws {
        let request = SDKControlRequest(
            requestId: "req-789",
            request: SDKControlRequest.RequestPayload(
                subtype: "initialize",
                supportedCapabilities: ["tool_use"],
                hooks: nil,
                permissionMode: "auto",
                model: nil,
                userMessageUuid: nil,
                mcpServers: nil
            )
        )
        let message = SDKMessage.controlRequest(request)
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["type"] as? String == "control_request")
        #expect(json?["request_id"] as? String == "req-789")

        if let requestData = json?["request"] as? [String: Any] {
            #expect(requestData["subtype"] as? String == "initialize")
            #expect((requestData["supported_capabilities"] as? [String])?.contains("tool_use") == true)
            #expect(requestData["permission_mode"] as? String == "auto")
        } else {
            Issue.record("Expected request field in JSON")
        }
    }

    @Test("Encode control response")
    func encodeControlResponse() throws {
        let response = SDKControlResponse(
            response: SDKControlResponse.ResponsePayload(
                subtype: "can_use_tool",
                requestId: "req-999",
                response: .bool(true)
            )
        )
        let message = SDKMessage.controlResponse(response)
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["type"] as? String == "control_response")

        if let responseData = json?["response"] as? [String: Any] {
            #expect(responseData["subtype"] as? String == "can_use_tool")
            #expect(responseData["request_id"] as? String == "req-999")
            #expect(responseData["response"] as? Bool == true)
        } else {
            Issue.record("Expected response field in JSON")
        }
    }

    @Test("Encode control request with model")
    func encodeControlRequestWithModel() throws {
        let request = SDKControlRequest(
            requestId: "req-model-123",
            request: SDKControlRequest.RequestPayload(
                subtype: "set_model",
                supportedCapabilities: nil,
                hooks: nil,
                permissionMode: nil,
                model: "claude-opus-4-6",
                userMessageUuid: nil,
                mcpServers: nil
            )
        )
        let message = SDKMessage.controlRequest(request)
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["type"] as? String == "control_request")
        #expect(json?["request_id"] as? String == "req-model-123")

        if let requestData = json?["request"] as? [String: Any] {
            #expect(requestData["subtype"] as? String == "set_model")
            #expect(requestData["model"] as? String == "claude-opus-4-6")
        } else {
            Issue.record("Expected request field in JSON")
        }
    }

    @Test("Encode control response with null response")
    func encodeControlResponseWithNullResponse() throws {
        let response = SDKControlResponse(
            response: SDKControlResponse.ResponsePayload(
                subtype: "interrupt",
                requestId: "req-null-123",
                response: .null
            )
        )
        let message = SDKMessage.controlResponse(response)
        let data = try JSONEncoder().encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["type"] as? String == "control_response")

        if let responseData = json?["response"] as? [String: Any] {
            #expect(responseData["subtype"] as? String == "interrupt")
            #expect(responseData["request_id"] as? String == "req-null-123")
            // When JSONValue is .null, it should serialize as NSNull
            #expect(responseData["response"] is NSNull)
        } else {
            Issue.record("Expected response field in JSON")
        }
    }
}
