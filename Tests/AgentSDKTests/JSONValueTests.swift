import Testing
import Foundation
@testable import AgentSDK

@Suite("JSONValue Tests")
struct JSONValueTests {

    // MARK: - String Tests

    @Test("String case Codable round-trip")
    func stringRoundTrip() throws {
        let original = JSONValue.string("Hello, world!")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .string(let value) = decoded else {
            Issue.record("Expected string case")
            return
        }
        #expect(value == "Hello, world!")
    }

    @Test("String with special characters")
    func stringSpecialCharacters() throws {
        let original = JSONValue.string("Line1\nLine2\t\"Quoted\"\r\n🎉")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("Empty string")
    func emptyString() throws {
        let original = JSONValue.string("")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Number Tests

    @Test("Number case Codable round-trip")
    func numberRoundTrip() throws {
        let original = JSONValue.number(3.14159)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .number(let value) = decoded else {
            Issue.record("Expected number case")
            return
        }
        #expect(value == 3.14159)
    }

    @Test("Number with negative value")
    func negativeNumber() throws {
        let original = JSONValue.number(-42.5)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("Number with zero")
    func zeroNumber() throws {
        let original = JSONValue.number(0.0)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        // Note: 0.0 gets decoded as integer(0) because JSON doesn't distinguish
        // between 0 and 0.0 in the wire format
        #expect(decoded == .integer(0))
    }

    // MARK: - Integer Tests

    @Test("Integer case Codable round-trip")
    func integerRoundTrip() throws {
        let original = JSONValue.integer(42)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .integer(let value) = decoded else {
            Issue.record("Expected integer case")
            return
        }
        #expect(value == 42)
    }

    @Test("Integer with negative value")
    func negativeInteger() throws {
        let original = JSONValue.integer(-100)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("Integer with zero")
    func zeroInteger() throws {
        let original = JSONValue.integer(0)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("Large integer values")
    func largeInteger() throws {
        let original = JSONValue.integer(Int.max)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - Bool Tests

    @Test("Bool true case Codable round-trip")
    func boolTrueRoundTrip() throws {
        let original = JSONValue.bool(true)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .bool(let value) = decoded else {
            Issue.record("Expected bool case")
            return
        }
        #expect(value == true)
    }

    @Test("Bool false case Codable round-trip")
    func boolFalseRoundTrip() throws {
        let original = JSONValue.bool(false)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .bool(let value) = decoded else {
            Issue.record("Expected bool case")
            return
        }
        #expect(value == false)
    }

    // MARK: - Null Tests

    @Test("Null case Codable round-trip")
    func nullRoundTrip() throws {
        let original = JSONValue.null

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .null = decoded else {
            Issue.record("Expected null case")
            return
        }
    }

    // MARK: - Array Tests

    @Test("Array case Codable round-trip")
    func arrayRoundTrip() throws {
        let original = JSONValue.array([
            .string("item1"),
            .integer(42),
            .bool(true),
            .null
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .array(let values) = decoded else {
            Issue.record("Expected array case")
            return
        }
        #expect(values.count == 4)
        #expect(values[0] == .string("item1"))
        #expect(values[1] == .integer(42))
        #expect(values[2] == .bool(true))
        #expect(values[3] == .null)
    }

    @Test("Empty array")
    func emptyArray() throws {
        let original = JSONValue.array([])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("Nested arrays")
    func nestedArrays() throws {
        let original = JSONValue.array([
            .array([.integer(1), .integer(2)]),
            .array([.string("a"), .string("b")]),
            .array([])
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .array(let outer) = decoded else {
            Issue.record("Expected array case")
            return
        }
        #expect(outer.count == 3)

        guard case .array(let first) = outer[0] else {
            Issue.record("Expected nested array at index 0")
            return
        }
        #expect(first == [.integer(1), .integer(2)])
    }

    // MARK: - Object Tests

    @Test("Object case Codable round-trip")
    func objectRoundTrip() throws {
        let original = JSONValue.object([
            "name": .string("Alice"),
            "age": .integer(30),
            "active": .bool(true),
            "score": .number(95.5),
            "notes": .null
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .object(let dict) = decoded else {
            Issue.record("Expected object case")
            return
        }
        #expect(dict.count == 5)
        #expect(dict["name"] == .string("Alice"))
        #expect(dict["age"] == .integer(30))
        #expect(dict["active"] == .bool(true))
        #expect(dict["score"] == .number(95.5))
        #expect(dict["notes"] == .null)
    }

    @Test("Empty object")
    func emptyObject() throws {
        let original = JSONValue.object([:])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("Nested objects")
    func nestedObjects() throws {
        let original = JSONValue.object([
            "user": .object([
                "name": .string("Bob"),
                "settings": .object([
                    "theme": .string("dark"),
                    "notifications": .bool(true)
                ])
            ]),
            "metadata": .object([:])
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .object(let root) = decoded else {
            Issue.record("Expected object case")
            return
        }

        guard case .object(let user) = root["user"] else {
            Issue.record("Expected user to be object")
            return
        }
        #expect(user["name"] == .string("Bob"))

        guard case .object(let settings) = user["settings"] else {
            Issue.record("Expected settings to be object")
            return
        }
        #expect(settings["theme"] == .string("dark"))
        #expect(settings["notifications"] == .bool(true))
    }

    // MARK: - Complex Nested Structures

    @Test("Array of objects")
    func arrayOfObjects() throws {
        let original = JSONValue.array([
            .object(["id": .integer(1), "name": .string("First")]),
            .object(["id": .integer(2), "name": .string("Second")]),
            .object(["id": .integer(3), "name": .string("Third")])
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .array(let items) = decoded else {
            Issue.record("Expected array case")
            return
        }
        #expect(items.count == 3)

        for (index, item) in items.enumerated() {
            guard case .object(let obj) = item else {
                Issue.record("Expected object at index \(index)")
                return
            }
            #expect(obj["id"] == .integer(index + 1))
        }
    }

    @Test("Object with arrays")
    func objectWithArrays() throws {
        let original = JSONValue.object([
            "numbers": .array([.integer(1), .integer(2), .integer(3)]),
            "strings": .array([.string("a"), .string("b")]),
            "mixed": .array([.string("text"), .integer(42), .bool(true), .null])
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .object(let root) = decoded else {
            Issue.record("Expected object case")
            return
        }

        guard case .array(let numbers) = root["numbers"] else {
            Issue.record("Expected numbers to be array")
            return
        }
        #expect(numbers.count == 3)

        guard case .array(let mixed) = root["mixed"] else {
            Issue.record("Expected mixed to be array")
            return
        }
        #expect(mixed.count == 4)
        #expect(mixed[3] == .null)
    }

    @Test("Deeply nested structure")
    func deeplyNestedStructure() throws {
        let original = JSONValue.object([
            "level1": .object([
                "level2": .object([
                    "level3": .array([
                        .object([
                            "level4": .string("deep value")
                        ])
                    ])
                ])
            ])
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - ExpressibleByLiteral Tests

    @Test("ExpressibleByStringLiteral")
    func stringLiteral() {
        let value: JSONValue = "test string"

        guard case .string(let str) = value else {
            Issue.record("Expected string case")
            return
        }
        #expect(str == "test string")
    }

    @Test("ExpressibleByIntegerLiteral")
    func integerLiteral() {
        let value: JSONValue = 42

        guard case .integer(let num) = value else {
            Issue.record("Expected integer case")
            return
        }
        #expect(num == 42)
    }

    @Test("ExpressibleByFloatLiteral")
    func floatLiteral() {
        let value: JSONValue = 3.14

        guard case .number(let num) = value else {
            Issue.record("Expected number case")
            return
        }
        #expect(num == 3.14)
    }

    @Test("ExpressibleByBooleanLiteral true")
    func booleanLiteralTrue() {
        let value: JSONValue = true

        guard case .bool(let b) = value else {
            Issue.record("Expected bool case")
            return
        }
        #expect(b == true)
    }

    @Test("ExpressibleByBooleanLiteral false")
    func booleanLiteralFalse() {
        let value: JSONValue = false

        guard case .bool(let b) = value else {
            Issue.record("Expected bool case")
            return
        }
        #expect(b == false)
    }

    @Test("ExpressibleByArrayLiteral")
    func arrayLiteral() {
        let value: JSONValue = ["a", 1, true]

        guard case .array(let arr) = value else {
            Issue.record("Expected array case")
            return
        }
        #expect(arr.count == 3)
        #expect(arr[0] == "a")
        #expect(arr[1] == 1)
        #expect(arr[2] == true)
    }

    @Test("ExpressibleByDictionaryLiteral")
    func dictionaryLiteral() {
        let value: JSONValue = [
            "name": "Alice",
            "age": 30,
            "active": true
        ]

        guard case .object(let obj) = value else {
            Issue.record("Expected object case")
            return
        }
        #expect(obj.count == 3)
        #expect(obj["name"] == "Alice")
        #expect(obj["age"] == 30)
        #expect(obj["active"] == true)
    }

    @Test("ExpressibleByNilLiteral")
    func nilLiteral() {
        let value: JSONValue = nil

        guard case .null = value else {
            Issue.record("Expected null case")
            return
        }
    }

    @Test("Complex literal construction")
    func complexLiteralConstruction() {
        let value: JSONValue = [
            "user": [
                "name": "Bob",
                "age": 25,
                "active": true
            ],
            "tags": ["swift", "testing", "json"],
            "score": 95.5,
            "metadata": nil
        ]

        guard case .object(let root) = value else {
            Issue.record("Expected object case")
            return
        }

        guard case .object(let user) = root["user"] else {
            Issue.record("Expected user to be object")
            return
        }
        #expect(user["name"] == "Bob")
        #expect(user["age"] == 25)
        #expect(user["active"] == true)

        guard case .array(let tags) = root["tags"] else {
            Issue.record("Expected tags to be array")
            return
        }
        #expect(tags.count == 3)

        #expect(root["score"] == 95.5)
        #expect(root["metadata"] == .null)
    }

    // MARK: - Hashable Tests

    @Test("Hashable conformance - equal values hash equal")
    func hashableEqualValuesHashEqual() {
        let value1 = JSONValue.string("test")
        let value2 = JSONValue.string("test")

        #expect(value1 == value2)
        #expect(value1.hashValue == value2.hashValue)
    }

    @Test("Hashable conformance - different values hash different")
    func hashableDifferentValues() {
        let value1 = JSONValue.string("test1")
        let value2 = JSONValue.string("test2")

        #expect(value1 != value2)
        // Note: Different values MIGHT hash to the same value (hash collisions are allowed),
        // but we expect them to be different in practice for simple cases
    }

    @Test("Hashable conformance - complex structures")
    func hashableComplexStructures() {
        let value1: JSONValue = [
            "name": "Alice",
            "age": 30,
            "tags": ["a", "b"]
        ]

        let value2: JSONValue = [
            "name": "Alice",
            "age": 30,
            "tags": ["a", "b"]
        ]

        #expect(value1 == value2)
        #expect(value1.hashValue == value2.hashValue)
    }

    @Test("Hashable conformance - use in Set")
    func hashableInSet() {
        let set: Set<JSONValue> = [
            .string("a"),
            .integer(1),
            .bool(true),
            .string("a") // duplicate
        ]

        #expect(set.count == 3) // duplicate should be removed
        #expect(set.contains(.string("a")))
        #expect(set.contains(.integer(1)))
        #expect(set.contains(.bool(true)))
    }

    @Test("Hashable conformance - use in Dictionary")
    func hashableInDictionary() {
        let dict: [JSONValue: String] = [
            .string("key1"): "value1",
            .integer(42): "value2",
            .bool(true): "value3"
        ]

        #expect(dict.count == 3)
        #expect(dict[.string("key1")] == "value1")
        #expect(dict[.integer(42)] == "value2")
        #expect(dict[.bool(true)] == "value3")
    }

    // MARK: - Pattern Matching

    @Test("Pattern matching all cases")
    func patternMatchingAllCases() {
        let values: [JSONValue] = [
            .string("str"),
            .number(1.5),
            .integer(10),
            .bool(true),
            .null,
            .array([]),
            .object([:])
        ]

        for value in values {
            let matched: Bool
            switch value {
            case .string: matched = true
            case .number: matched = true
            case .integer: matched = true
            case .bool: matched = true
            case .null: matched = true
            case .array: matched = true
            case .object: matched = true
            }
            #expect(matched)
        }
    }

    // MARK: - Edge Cases

    @Test("Very large array")
    func veryLargeArray() throws {
        let largeArray = JSONValue.array(Array(repeating: .integer(1), count: 1000))

        let data = try JSONEncoder().encode(largeArray)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == largeArray)
    }

    @Test("Unicode strings")
    func unicodeStrings() throws {
        let original = JSONValue.object([
            "emoji": .string("😀🎉🚀"),
            "japanese": .string("こんにちは"),
            "chinese": .string("你好"),
            "arabic": .string("مرحبا"),
            "special": .string("™®©")
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
    }

    @Test("All value types in single object")
    func allTypesInObject() throws {
        let original = JSONValue.object([
            "string": .string("text"),
            "number": .number(3.14),
            "integer": .integer(42),
            "bool": .bool(true),
            "null": .null,
            "array": .array([.integer(1), .integer(2)]),
            "object": .object(["nested": .string("value")])
        ])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == original)
        guard case .object(let dict) = decoded else {
            Issue.record("Expected object case")
            return
        }
        #expect(dict.count == 7)
    }
}
