import Foundation

/// JSONL line encoder/decoder. Stateless and Sendable.
internal struct JSONLCodec: Sendable {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    /// Encode a value to a JSONL line (JSON + trailing newline, UTF-8)
    func encode<T: Encodable>(_ value: T) throws -> Data {
        var data = try encoder.encode(value)
        data.append(contentsOf: [0x0A]) // '\n'
        return data
    }

    /// Decode a JSONL line to a value
    func decode<T: Decodable>(_ line: Data) throws -> T {
        // Strip trailing newline if present
        let trimmed = line.last == 0x0A ? line.dropLast() : line[...]
        return try decoder.decode(T.self, from: Data(trimmed))
    }

    /// Peek at the "type" field without fully decoding the message
    func decodeMessageType(_ line: Data) throws -> String {
        let trimmed = line.last == 0x0A ? line.dropLast() : line[...]
        let wrapper = try decoder.decode(TypeWrapper.self, from: Data(trimmed))
        return wrapper.type
    }

    private struct TypeWrapper: Decodable {
        let type: String
    }
}
