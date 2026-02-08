import Foundation
import AgentSDK

/// Raw JSONL message sent from SDK to CLI. Internal type.
internal enum SDKMessage: Sendable {
    case userMessage(content: String)
    case controlRequest(SDKControlRequest)
    case controlResponse(SDKControlResponse)
}

internal struct SDKControlRequest: Sendable, Codable {
    let requestId: String
    let request: RequestPayload

    struct RequestPayload: Sendable, Codable {
        let subtype: String
        // Additional fields vary by subtype
        let supportedCapabilities: [String]?
        let hooks: [JSONValue]?
        let permissionMode: String?
        let model: String?
        let userMessageUuid: String?
        let mcpServers: [String: JSONValue]?

        enum CodingKeys: String, CodingKey {
            case subtype
            case supportedCapabilities = "supported_capabilities"
            case hooks
            case permissionMode = "permission_mode"
            case model
            case userMessageUuid = "user_message_uuid"
            case mcpServers = "mcp_servers"
        }
    }

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case request
    }
}

internal struct SDKControlResponse: Sendable, Codable {
    let response: ResponsePayload

    struct ResponsePayload: Sendable, Codable {
        let subtype: String
        let requestId: String
        let response: JSONValue?

        enum CodingKeys: String, CodingKey {
            case subtype
            case requestId = "request_id"
            case response
        }
    }
}

// Encodable conformance for SDKMessage
extension SDKMessage: Encodable {
    func encode(to encoder: Encoder) throws {
        switch self {
        case .userMessage(let content):
            var container = encoder.container(keyedBy: UserMessageKeys.self)
            try container.encode("user_message", forKey: .type)
            try container.encode(content, forKey: .content)
        case .controlRequest(let req):
            var container = encoder.container(keyedBy: ControlKeys.self)
            try container.encode("control_request", forKey: .type)
            try container.encode(req.requestId, forKey: .requestId)
            try container.encode(req.request, forKey: .request)
        case .controlResponse(let resp):
            var container = encoder.container(keyedBy: ControlResponseKeys.self)
            try container.encode("control_response", forKey: .type)
            try container.encode(resp.response, forKey: .response)
        }
    }

    private enum UserMessageKeys: String, CodingKey { case type, content }
    private enum ControlKeys: String, CodingKey { case type, requestId = "request_id", request }
    private enum ControlResponseKeys: String, CodingKey { case type, response }
}
