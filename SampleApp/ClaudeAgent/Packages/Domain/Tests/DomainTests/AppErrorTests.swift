import Foundation
import Testing
@testable import Domain

@Suite
struct AppErrorTests {
    @Test func allCasesHaveNonEmptyDescription() {
        let errors: [AppError] = [
            .cliNotFound,
            .notConnected,
            .sessionExpired,
            .connectionTimeout,
            .processExited(code: 1),
            .protocolError("test"),
            .persistenceError("test"),
        ]

        for error in errors {
            let description = error.errorDescription
            #expect(description != nil, "errorDescription should not be nil for \(error)")
            #expect(description?.isEmpty == false, "errorDescription should not be empty for \(error)")
        }
    }

    @Test func processExitedIncludesCode() {
        let error = AppError.processExited(code: 42)
        #expect(error.errorDescription?.contains("42") == true)
    }

    @Test func protocolErrorIncludesDetail() {
        let error = AppError.protocolError("invalid JSON")
        #expect(error.errorDescription?.contains("invalid JSON") == true)
    }

    @Test func persistenceErrorIncludesDetail() {
        let error = AppError.persistenceError("disk full")
        #expect(error.errorDescription?.contains("disk full") == true)
    }

    @Test func conformsToLocalizedError() {
        let error: any LocalizedError = AppError.cliNotFound
        #expect(error.errorDescription != nil)
    }
}
