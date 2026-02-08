import Testing
import Foundation
import AgentSDK
@testable import AgentSDKClaudeCode

/// Whether integration tests should run (requires AGENT_SDK_INTEGRATION_TEST=1).
private let isIntegrationEnabled =
    ProcessInfo.processInfo.environment["AGENT_SDK_INTEGRATION_TEST"] == "1"

/// Whether the real Claude Code CLI is available on this system.
private let isCLIAvailable: Bool = {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = ["claude"]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}()

// MARK: - Error Path Tests (no CLI auth required, only need env var gate)

@Suite("Integration: Error Paths",
       .serialized,
       .enabled(if: isIntegrationEnabled))
struct ErrorPathTests {

    @Test("CLI not found with invalid explicit path",
          .timeLimit(.minutes(1)))
    func cliNotFoundWithInvalidPath() async throws {
        let transport = ClaudeCodeTransport(
            cliPath: "/nonexistent/path/to/claude-cli"
        )
        await #expect(throws: AgentSDKError.self) {
            try await transport.connect()
        }
    }

    @Test("cliNotFound error contains searched path",
          .timeLimit(.minutes(1)))
    func cliNotFoundContainsSearchedPath() async throws {
        let transport = ClaudeCodeTransport(
            cliPath: "/nonexistent/path/to/claude-cli"
        )
        do {
            try await transport.connect()
            Issue.record("Expected cliNotFound error")
        } catch let error as AgentSDKError {
            guard case .cliNotFound(let paths) = error else {
                Issue.record("Expected cliNotFound but got \(error)")
                return
            }
            #expect(paths.contains("/nonexistent/path/to/claude-cli"))
        }
    }

    @Test("Transport write before connect throws notConnected",
          .timeLimit(.minutes(1)))
    func writeBeforeConnectThrows() async throws {
        let transport = ClaudeCodeTransport(
            cliPath: "/nonexistent/cli"
        )
        // Do not connect - messages() returns a stream that immediately throws notConnected
        var threwError = false
        do {
            for try await _ in transport.messages() {
                Issue.record("Should not yield messages")
            }
        } catch {
            threwError = true
        }
        #expect(threwError)
    }
}

// MARK: - Live CLI Tests (require real CLI + authentication)

@Suite("Integration: Live CLI",
       .serialized,
       .enabled(if: isIntegrationEnabled && isCLIAvailable))
struct LiveCLITests {

    @Test("Hello World query receives response",
          .timeLimit(.minutes(2)))
    func helloWorldQuery() async throws {
        var receivedSystem = false
        var receivedResult = false
        var sessionId: String?

        let options = QueryOptions(
            permissionMode: .bypassPermissions,
            maxTurns: 1
        )
        for try await message in AgentSDK.query(
            prompt: "Respond with exactly: Hello from Swift Agent SDK",
            options: options
        ) {
            switch message {
            case .system(let info):
                receivedSystem = true
                sessionId = info.sessionId
                #expect(!info.sessionId.isEmpty)
                #expect(!info.model.isEmpty)
            case .result(let info):
                receivedResult = true
                #expect(!info.result.isEmpty)
                #expect(info.costUsd >= 0)
                #expect(info.inputTokens > 0)
                #expect(info.outputTokens > 0)
                #expect(!info.sessionId.isEmpty)
            default:
                break
            }
        }

        #expect(receivedSystem, "Should receive system message")
        #expect(receivedResult, "Should receive result message")
        #expect(sessionId != nil, "Should have a session ID")
    }

    @Test("Session create and send",
          .timeLimit(.minutes(2)))
    func sessionCreateAndSend() async throws {
        let options = SessionOptions(
            permissionMode: .bypassPermissions,
            maxTurns: 1
        )
        let session = try await AgentSDK.createSession(options: options)

        var receivedAssistant = false
        var receivedResult = false

        for try await message in session.send("What is 2 + 2? Reply with just the number.") {
            switch message {
            case .assistant:
                receivedAssistant = true
            case .result(let info):
                receivedResult = true
                #expect(!info.result.isEmpty)
            default:
                break
            }
        }

        #expect(receivedAssistant || receivedResult,
                "Should receive at least assistant or result")

        try await session.close()
    }
}
