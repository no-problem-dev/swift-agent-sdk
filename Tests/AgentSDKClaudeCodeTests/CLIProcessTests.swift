import Testing
import Foundation
import AgentSDK
@testable import AgentSDKClaudeCode

@Suite("CLIProcess Tests", .serialized)
struct CLIProcessTests {

    @Test("Start and reach running state")
    func startReachesRunningState() async throws {
        let cliProcess = CLIProcess()
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/echo"),
            arguments: ["hello"]
        )
        let state = await cliProcess.state
        // echo exits immediately, so state could be .running or .terminated
        switch state {
        case .running, .terminated:
            // Both are acceptable for fast-exiting process
            break
        default:
            Issue.record("Expected .running or .terminated, got \(state)")
        }
    }

    @Test("Running to terminated state transition")
    func runningToTerminatedTransition() async throws {
        let cliProcess = CLIProcess()
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/echo"),
            arguments: ["test"]
        )

        let exitCode = await cliProcess.waitForExit()
        #expect(exitCode == 0)

        // Small delay to allow termination handler to complete
        try await Task.sleep(for: .milliseconds(100))

        let state = await cliProcess.state
        guard case .terminated(let code) = state else {
            Issue.record("Expected .terminated state, got \(state)")
            return
        }
        #expect(code == 0)
    }

    @Test("stdin write and stdout read with cat")
    func stdinWriteStdoutRead() async throws {
        let cliProcess = CLIProcess()
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/cat"),
            arguments: []
        )

        let testData = "hello from stdin\n".data(using: .utf8)!
        try await cliProcess.writeToStdin(testData)

        // Close stdin to signal EOF to cat
        try await cliProcess.closeStdin()

        // Read from stdout stream
        var receivedData = Data()
        let stream = await cliProcess.stdoutStream()

        do {
            for try await line in stream {
                receivedData.append(line)
                // Break after first line since we only sent one
                break
            }
        } catch {
            // Stream might throw on process termination - that's okay
        }

        let receivedString = String(data: receivedData, encoding: .utf8) ?? ""
        #expect(receivedString.contains("hello from stdin"))

        // Wait for process to complete
        _ = await cliProcess.waitForExit()
    }

    @Test("stderr accumulation")
    func stderrAccumulation() async throws {
        let cliProcess = CLIProcess()

        // Use sh to echo to stderr
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo 'error message' >&2"]
        )

        // Wait for process to complete
        let exitCode = await cliProcess.waitForExit()
        #expect(exitCode == 0)

        // Longer delay to allow stderr handler to process asynchronously
        try await Task.sleep(for: .milliseconds(500))

        let stderr = await cliProcess.stderrContent()
        #expect(stderr.contains("error message"))
    }

    @Test("terminate process", .timeLimit(.minutes(1)))
    func terminateProcess() async throws {
        let cliProcess = CLIProcess()

        // Start a long-running process (sleep for 60 seconds)
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["60"]
        )

        let stateAfterStart = await cliProcess.state
        guard case .running = stateAfterStart else {
            Issue.record("Expected .running state after start")
            return
        }

        // Terminate the process
        await cliProcess.terminate()

        // Wait a bit for termination to complete
        try await Task.sleep(for: .milliseconds(500))

        let stateAfterTerminate = await cliProcess.state
        switch stateAfterTerminate {
        case .terminating, .terminated:
            // Either is acceptable
            break
        default:
            Issue.record("Expected .terminating or .terminated, got \(stateAfterTerminate)")
        }
    }

    @Test("process already started error")
    func processAlreadyStartedError() async throws {
        let cliProcess = CLIProcess()

        // Start the process first time
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/echo"),
            arguments: ["first"]
        )

        // Try to start again - should throw
        do {
            try await cliProcess.start(
                executable: URL(fileURLWithPath: "/bin/echo"),
                arguments: ["second"]
            )
            Issue.record("Expected error when starting process twice")
        } catch {
            // Expected to throw
            #expect(error is AgentSDKError)
        }
    }

    @Test("write to not-running process error")
    func writeToNotRunningProcessError() async throws {
        let cliProcess = CLIProcess()

        // Try to write before starting - should throw
        let testData = "test".data(using: .utf8)!
        do {
            try await cliProcess.writeToStdin(testData)
            Issue.record("Expected error when writing to non-running process")
        } catch {
            // Expected to throw
            #expect(error is AgentSDKError)
        }
    }

    @Test("environment variables passed to process")
    func environmentVariablesPassed() async throws {
        let cliProcess = CLIProcess()

        // Use env to print an environment variable
        let testEnv = ["TEST_VAR": "test_value_123"]
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/usr/bin/env"),
            arguments: [],
            environment: testEnv
        )

        // Read stdout to verify env var
        var output = Data()
        let stream = await cliProcess.stdoutStream()

        do {
            for try await line in stream {
                output.append(line)
            }
        } catch {
            // Stream might throw on completion - that's okay
        }

        let outputString = String(data: output, encoding: .utf8) ?? ""
        #expect(outputString.contains("TEST_VAR=test_value_123"))

        _ = await cliProcess.waitForExit()
    }

    @Test("working directory passed to process")
    func workingDirectoryPassed() async throws {
        let cliProcess = CLIProcess()

        // Use pwd to print current working directory
        try await cliProcess.start(
            executable: URL(fileURLWithPath: "/bin/pwd"),
            arguments: [],
            cwd: "/tmp"
        )

        var output = Data()
        let stream = await cliProcess.stdoutStream()

        do {
            for try await line in stream {
                output.append(line)
            }
        } catch {
            // Stream might throw on completion
        }

        let outputString = String(data: output, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #expect(outputString == "/tmp" || outputString.hasSuffix("/tmp"))

        _ = await cliProcess.waitForExit()
    }
}
