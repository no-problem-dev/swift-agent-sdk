import Testing
import Foundation
@testable import AgentSDK

@Suite("AgentSDKError Tests")
struct AgentSDKErrorTests {

    // MARK: - cliNotFound

    @Test("cliNotFound has non-empty description with install instructions")
    func cliNotFoundDescription() {
        let error = AgentSDKError.cliNotFound(searchedPaths: ["/usr/local/bin/claude", "/opt/homebrew/bin/claude"])
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("npm install"))
        #expect(description.contains("/usr/local/bin/claude"))
        #expect(description.contains("/opt/homebrew/bin/claude"))
    }

    // MARK: - runtimeNotFound

    @Test("runtimeNotFound has non-empty description with Node.js guidance")
    func runtimeNotFoundDescription() {
        let error = AgentSDKError.runtimeNotFound(runtime: "node")
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("Node.js"))
        #expect(description.contains("node"))
    }

    // MARK: - processLaunchFailed

    @Test("processLaunchFailed includes underlying error info")
    func processLaunchFailedDescription() {
        struct MockError: Error, LocalizedError {
            var errorDescription: String? { "Permission denied" }
        }

        let error = AgentSDKError.processLaunchFailed(underlying: MockError())
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("Permission denied"))
        #expect(description.contains("Failed to launch"))
    }

    // MARK: - processExited

    @Test("processExited includes exit code and stderr")
    func processExitedWithStderr() {
        let error = AgentSDKError.processExited(exitCode: 1, stderr: "Authentication failed")
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("1"))
        #expect(description.contains("Authentication failed"))
    }

    @Test("processExited handles empty stderr")
    func processExitedEmptyStderr() {
        let error = AgentSDKError.processExited(exitCode: 127, stderr: "")
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("127"))
        #expect(description.contains("(empty)"))
    }

    // MARK: - protocolError

    @Test("protocolError includes the message")
    func protocolErrorDescription() {
        let error = AgentSDKError.protocolError(message: "Invalid JSON structure", rawData: nil)
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("Invalid JSON structure"))
        #expect(description.contains("protocol error"))
    }

    @Test("protocolError with rawData")
    func protocolErrorWithRawData() {
        let data = Data("{broken".utf8)
        let error = AgentSDKError.protocolError(message: "Malformed JSON", rawData: data)
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("Malformed JSON"))
    }

    // MARK: - initializationTimeout

    @Test("initializationTimeout includes seconds")
    func initializationTimeoutDescription() {
        let error = AgentSDKError.initializationTimeout(seconds: 30)
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("30"))
        #expect(description.contains("seconds"))
        #expect(description.contains("timed out"))
    }

    // MARK: - controlRequestTimeout

    @Test("controlRequestTimeout includes subtype and seconds")
    func controlRequestTimeoutDescription() {
        let error = AgentSDKError.controlRequestTimeout(subtype: "createSession", seconds: 60)
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("createSession"))
        #expect(description.contains("60"))
        #expect(description.contains("seconds"))
        #expect(description.contains("timed out"))
    }

    // MARK: - sessionExpired

    @Test("sessionExpired includes sessionId")
    func sessionExpiredDescription() {
        let error = AgentSDKError.sessionExpired(sessionId: "session_abc123")
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("session_abc123"))
        #expect(description.contains("expired"))
        #expect(description.contains("10 minutes"))
    }

    // MARK: - sessionClosed

    @Test("sessionClosed includes sessionId")
    func sessionClosedDescription() {
        let error = AgentSDKError.sessionClosed(sessionId: "session_xyz789")
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("session_xyz789"))
        #expect(description.contains("closed"))
        #expect(description.contains("Create a new session"))
    }

    // MARK: - notConnected

    @Test("notConnected has actionable message with connect()")
    func notConnectedDescription() {
        let error = AgentSDKError.notConnected
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("connect()"))
        #expect(description.contains("not connected"))
    }

    // MARK: - cancelled

    @Test("cancelled has appropriate message")
    func cancelledDescription() {
        let error = AgentSDKError.cancelled
        let description = error.errorDescription ?? ""
        #expect(!description.isEmpty)
        #expect(description.contains("cancelled"))
        #expect(description.contains("Task.cancel()") || description.contains("interrupt()"))
    }

    // MARK: - Comprehensive Coverage

    @Test("All error cases have non-empty errorDescription")
    func allCasesHaveDescription() {
        let errors: [AgentSDKError] = [
            .cliNotFound(searchedPaths: ["/path/to/cli"]),
            .runtimeNotFound(runtime: "node"),
            .processLaunchFailed(underlying: NSError(domain: "test", code: 0)),
            .processExited(exitCode: 1, stderr: "error"),
            .protocolError(message: "test", rawData: nil),
            .initializationTimeout(seconds: 30),
            .controlRequestTimeout(subtype: "test", seconds: 60),
            .sessionExpired(sessionId: "session_1"),
            .sessionClosed(sessionId: "session_2"),
            .notConnected,
            .cancelled
        ]

        for error in errors {
            let description = error.errorDescription ?? ""
            #expect(!description.isEmpty, "Error \(error) should have non-empty description")
        }
    }
}
