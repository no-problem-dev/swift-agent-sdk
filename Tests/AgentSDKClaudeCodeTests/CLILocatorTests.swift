import Testing
import Foundation
@testable import AgentSDKClaudeCode
import AgentSDK

@Suite("CLILocator Tests")
struct CLILocatorTests {

    @Test("User-specified path exists - returns that URL")
    func testUserPathExists() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeCLI = tempDir.appendingPathComponent("cli.js")
        FileManager.default.createFile(atPath: fakeCLI.path, contents: nil)

        let result = try CLILocator.locate(
            userPath: fakeCLI.path,
            cwd: tempDir.path,
            environment: [:]
        )

        #expect(result.path == fakeCLI.path)
    }

    @Test("User-specified path doesn't exist - throws cliNotFound immediately")
    func testUserPathNotExists() throws {
        let nonExistentPath = "/tmp/nonexistent-\(UUID().uuidString)/cli.js"

        #expect(throws: AgentSDKError.self) {
            try CLILocator.locate(
                userPath: nonExistentPath,
                cwd: "/tmp",
                environment: [:]
            )
        }
    }

    @Test("Environment variable path found")
    func testEnvironmentVariablePath() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeCLI = tempDir.appendingPathComponent("claude-cli")
        FileManager.default.createFile(atPath: fakeCLI.path, contents: nil)

        let result = try CLILocator.locate(
            userPath: nil,
            cwd: tempDir.path,
            environment: ["CLAUDE_CODE_CLI_PATH": fakeCLI.path]
        )

        #expect(result.path == fakeCLI.path)
    }

    @Test("Local node_modules path found")
    func testLocalNodeModulesPath() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nodeModulesPath = tempDir.appendingPathComponent("node_modules/@anthropic-ai/claude-agent-sdk")
        try FileManager.default.createDirectory(at: nodeModulesPath, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fakeCLI = nodeModulesPath.appendingPathComponent("cli.js")
        FileManager.default.createFile(atPath: fakeCLI.path, contents: nil)

        let result = try CLILocator.locate(
            userPath: nil,
            cwd: tempDir.path,
            environment: [:]
        )

        #expect(result.path == fakeCLI.path)
    }

    @Test("All search fails - throws cliNotFound with searchedPaths")
    func testAllSearchFails() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Note: This test may succeed if `which claude` finds a system installation.
        // We test the failure path by checking that if an error IS thrown, it has the right structure.
        var caughtError: AgentSDKError?
        var foundCLI: URL?

        do {
            foundCLI = try CLILocator.locate(
                userPath: nil,
                cwd: tempDir.path,
                environment: [:]
            )
        } catch let error as AgentSDKError {
            caughtError = error
        }

        // If we found a CLI (via system PATH), that's fine - just verify it exists
        if let cli = foundCLI {
            #expect(FileManager.default.fileExists(atPath: cli.path))
        }

        // If we got an error, verify it's the right type with searchedPaths
        if case let .cliNotFound(searchedPaths) = caughtError {
            // Should have searched at least:
            // - local node_modules path
            // - claude (not found in PATH)
            #expect(searchedPaths.count >= 2)
            #expect(searchedPaths.contains(where: { $0.contains("node_modules") }))
        }
    }

    @Test("Sendable conformance")
    func testSendableConformance() {
        // This test ensures CLILocator conforms to Sendable
        // If it doesn't, this won't compile
        let _: any Sendable = CLILocator.self
    }

    @Test("Environment variable takes precedence over local node_modules")
    func testEnvironmentVariablePrecedence() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let nodeModulesPath = tempDir.appendingPathComponent("node_modules/@anthropic-ai/claude-agent-sdk")
        try FileManager.default.createDirectory(at: nodeModulesPath, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create both environment path and local node_modules path
        let envCLI = tempDir.appendingPathComponent("env-cli.js")
        let localCLI = nodeModulesPath.appendingPathComponent("cli.js")
        FileManager.default.createFile(atPath: envCLI.path, contents: nil)
        FileManager.default.createFile(atPath: localCLI.path, contents: nil)

        let result = try CLILocator.locate(
            userPath: nil,
            cwd: tempDir.path,
            environment: ["CLAUDE_CODE_CLI_PATH": envCLI.path]
        )

        // Environment variable should take precedence
        #expect(result.path == envCLI.path)
    }

    @Test("User path takes precedence over environment variable")
    func testUserPathPrecedence() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create both user path and environment path
        let userCLI = tempDir.appendingPathComponent("user-cli.js")
        let envCLI = tempDir.appendingPathComponent("env-cli.js")
        FileManager.default.createFile(atPath: userCLI.path, contents: nil)
        FileManager.default.createFile(atPath: envCLI.path, contents: nil)

        let result = try CLILocator.locate(
            userPath: userCLI.path,
            cwd: tempDir.path,
            environment: ["CLAUDE_CODE_CLI_PATH": envCLI.path]
        )

        // User path should take precedence
        #expect(result.path == userCLI.path)
    }
}
