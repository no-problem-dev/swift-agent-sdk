import Foundation
import AgentSDK  // for AgentSDKError

/// CLI binary locator. Searches for Claude Code CLI in multiple locations.
internal struct CLILocator: Sendable {

    /// Locate the CLI binary using 5-step search order.
    ///
    /// Search order:
    /// 1. User-specified path (if provided)
    /// 2. Environment variable CLAUDE_CODE_CLI_PATH
    /// 3. Local node_modules: ./node_modules/@anthropic-ai/claude-agent-sdk/cli.js
    /// 4. Global npm package: `npm root -g`/@anthropic-ai/claude-agent-sdk/cli.js
    /// 5. System PATH: `which claude`
    ///
    /// - Parameters:
    ///   - userPath: Explicit CLI path provided by the user (optional)
    ///   - cwd: Working directory for local node_modules search
    ///   - environment: Environment variables to check (defaults to ProcessInfo)
    /// - Returns: URL to the CLI binary
    /// - Throws: AgentSDKError.cliNotFound if all searches fail
    static func locate(
        userPath: String? = nil,
        cwd: String? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> URL {
        var searchedPaths: [String] = []

        // 1. User-specified path
        if let userPath {
            let url = URL(fileURLWithPath: userPath)
            searchedPaths.append(userPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            // If user explicitly specified a path and it doesn't exist, fail immediately
            throw AgentSDKError.cliNotFound(searchedPaths: searchedPaths)
        }

        // 2. Environment variable
        if let envPath = environment["CLAUDE_CODE_CLI_PATH"] {
            searchedPaths.append(envPath)
            let url = URL(fileURLWithPath: envPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // 3. Local node_modules
        let workDir = cwd ?? FileManager.default.currentDirectoryPath
        let localPath = (workDir as NSString).appendingPathComponent(
            "node_modules/@anthropic-ai/claude-agent-sdk/cli.js"
        )
        searchedPaths.append(localPath)
        if FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath)
        }

        // 4. Global npm package
        if let globalRoot = Self.npmGlobalRoot() {
            let globalPath = (globalRoot as NSString).appendingPathComponent(
                "@anthropic-ai/claude-agent-sdk/cli.js"
            )
            searchedPaths.append(globalPath)
            if FileManager.default.fileExists(atPath: globalPath) {
                return URL(fileURLWithPath: globalPath)
            }
        }

        // 4.5. Native install paths
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let nativePaths = [
            (home as NSString).appendingPathComponent(".local/bin/claude"),
            (home as NSString).appendingPathComponent(".claude/local/claude"),
            "/usr/local/bin/claude",
        ]
        for nativePath in nativePaths {
            searchedPaths.append(nativePath)
            if FileManager.default.fileExists(atPath: nativePath) {
                return URL(fileURLWithPath: nativePath)
            }
        }

        // 5. System PATH (which claude)
        if let whichPath = Self.whichClaude() {
            searchedPaths.append(whichPath)
            return URL(fileURLWithPath: whichPath)
        }
        searchedPaths.append("claude (not found in PATH)")

        throw AgentSDKError.cliNotFound(searchedPaths: searchedPaths)
    }

    /// Run `npm root -g` to find global npm packages directory
    private static func npmGlobalRoot() -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["npm", "root", "-g"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    /// Run `which claude` to find claude in PATH
    private static func whichClaude() -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == true ? nil : path
        } catch {
            return nil
        }
    }
}
