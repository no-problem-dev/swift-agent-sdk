import Foundation
import Testing
@testable import Domain

@Suite
struct ModelSelectionTests {
    @Test func displayNames() {
        #expect(ModelSelection.opus.displayName == "Opus")
        #expect(ModelSelection.sonnet.displayName == "Sonnet")
        #expect(ModelSelection.haiku.displayName == "Haiku")
    }

    @Test func caseIterable() {
        let allCases = ModelSelection.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.opus))
        #expect(allCases.contains(.sonnet))
        #expect(allCases.contains(.haiku))
    }

    @Test func rawValues() {
        #expect(ModelSelection.opus.rawValue == "opus")
        #expect(ModelSelection.sonnet.rawValue == "sonnet")
        #expect(ModelSelection.haiku.rawValue == "haiku")
    }

    @Test func codableRoundTrip() throws {
        for model in ModelSelection.allCases {
            let data = try JSONEncoder().encode(model)
            let decoded = try JSONDecoder().decode(ModelSelection.self, from: data)
            #expect(decoded == model)
        }
    }
}
