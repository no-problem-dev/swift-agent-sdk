import Foundation
import Testing
@testable import AgentSDKClaudeCode

@Suite("JSONLCodec Tests")
struct JSONLCodecTests {

    // MARK: - Test Models

    struct TestMessage: Codable, Equatable {
        let type: String
        let content: String
        let count: Int
    }

    struct MessageWithType: Codable {
        let type: String
    }

    struct MessageWithoutType: Codable {
        let content: String
    }

    // MARK: - Tests

    @Test("encode-decode round-trip preserves original value")
    func encodeDecodeRoundTrip() throws {
        let codec = JSONLCodec()
        let original = TestMessage(type: "test", content: "hello", count: 42)

        let encoded = try codec.encode(original)
        let decoded: TestMessage = try codec.decode(encoded)

        #expect(decoded == original)
    }

    @Test("encode appends trailing newline")
    func encodeAppendsNewline() throws {
        let codec = JSONLCodec()
        let message = TestMessage(type: "test", content: "hello", count: 42)

        let encoded = try codec.encode(message)

        // Last byte should be 0x0A ('\n')
        #expect(encoded.last == 0x0A)
    }

    @Test("encode produces valid UTF-8")
    func encodeProducesValidUTF8() throws {
        let codec = JSONLCodec()
        let message = TestMessage(type: "test", content: "hello 世界", count: 42)

        let encoded = try codec.encode(message)
        let utf8String = String(data: encoded, encoding: .utf8)

        #expect(utf8String != nil)
        #expect(utf8String!.contains("hello 世界"))
    }

    @Test("decode handles input with trailing newline")
    func decodeWithTrailingNewline() throws {
        let codec = JSONLCodec()
        let jsonString = #"{"type":"test","content":"hello","count":42}"# + "\n"
        let data = jsonString.data(using: .utf8)!

        let decoded: TestMessage = try codec.decode(data)

        #expect(decoded.type == "test")
        #expect(decoded.content == "hello")
        #expect(decoded.count == 42)
    }

    @Test("decode handles input without trailing newline")
    func decodeWithoutTrailingNewline() throws {
        let codec = JSONLCodec()
        let jsonString = #"{"type":"test","content":"hello","count":42}"#
        let data = jsonString.data(using: .utf8)!

        let decoded: TestMessage = try codec.decode(data)

        #expect(decoded.type == "test")
        #expect(decoded.content == "hello")
        #expect(decoded.count == 42)
    }

    @Test("decode throws on invalid JSON")
    func decodeThrowsOnInvalidJSON() throws {
        let codec = JSONLCodec()
        let invalidJSON = "not valid json".data(using: .utf8)!

        #expect(throws: (any Error).self) {
            let _: TestMessage = try codec.decode(invalidJSON)
        }
    }

    @Test("decodeMessageType extracts type field")
    func decodeMessageTypeExtractsType() throws {
        let codec = JSONLCodec()
        let jsonString = #"{"type":"test_message","content":"hello","count":42}"# + "\n"
        let data = jsonString.data(using: .utf8)!

        let messageType = try codec.decodeMessageType(data)

        #expect(messageType == "test_message")
    }

    @Test("decodeMessageType handles input without trailing newline")
    func decodeMessageTypeWithoutNewline() throws {
        let codec = JSONLCodec()
        let jsonString = #"{"type":"another_type","content":"world"}"#
        let data = jsonString.data(using: .utf8)!

        let messageType = try codec.decodeMessageType(data)

        #expect(messageType == "another_type")
    }

    @Test("decodeMessageType throws on JSON without type field")
    func decodeMessageTypeThrowsWithoutTypeField() throws {
        let codec = JSONLCodec()
        let jsonString = #"{"content":"hello","count":42}"# + "\n"
        let data = jsonString.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            _ = try codec.decodeMessageType(data)
        }
    }

    @Test("JSONLCodec is Sendable")
    func codecIsSendable() {
        // This test verifies that JSONLCodec conforms to Sendable
        // If it doesn't, this won't compile
        let codec = JSONLCodec()

        Task {
            // Should be able to capture codec in concurrent context
            let _: JSONLCodec = codec
        }

        #expect(true) // Compilation is the real test
    }
}
