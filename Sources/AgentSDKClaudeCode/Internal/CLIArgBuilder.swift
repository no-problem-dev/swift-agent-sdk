import Foundation
import AgentSDK

/// Builds CLI launch arguments from SDK options.
internal struct CLIArgBuilder: Sendable {

    /// Build CLI arguments from QueryOptions.
    ///
    /// Default arguments always included:
    /// - `--output-format stream-json`
    /// - `--input-format stream-json`
    /// - `--verbose`
    ///
    /// Optional arguments based on options:
    /// - `--system-prompt <prompt>` if systemPrompt is set
    /// - `--permission-mode <mode>` if permissionMode is set
    /// - `--max-turns <n>` if maxTurns is set
    /// - `--resume <id>` if resumeSessionId is provided
    /// - `--agents <json>` if agents is set (JSON serialized)
    /// - `--mcp-servers <json>` if mcpServers is set (JSON serialized)
    static func buildArguments(
        from options: QueryOptions,
        resumeSessionId: String? = nil
    ) -> [String] {
        var args: [String] = []

        // Default arguments
        args.append(contentsOf: ["--output-format", "stream-json"])
        args.append(contentsOf: ["--input-format", "stream-json"])
        args.append("--verbose")

        // System prompt
        if let systemPrompt = options.systemPrompt {
            args.append(contentsOf: ["--system-prompt", systemPrompt])
        }

        // Permission mode
        if let mode = options.permissionMode {
            args.append(contentsOf: ["--permission-mode", mode.rawValue])
        }

        // Max turns
        if let maxTurns = options.maxTurns {
            args.append(contentsOf: ["--max-turns", String(maxTurns)])
        }

        // Resume session
        if let sessionId = resumeSessionId {
            args.append(contentsOf: ["--resume", sessionId])
        }

        // Model
        if let model = options.model {
            args.append(contentsOf: ["--model", model.rawValue])
        }

        // Agents (JSON serialized)
        if let agents = options.agents, !agents.isEmpty {
            if let jsonData = try? JSONEncoder().encode(agents),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                args.append(contentsOf: ["--agents", jsonString])
            }
        }

        // MCP Servers (JSON serialized)
        if let mcpServers = options.mcpServers, !mcpServers.isEmpty {
            if let jsonData = try? JSONEncoder().encode(mcpServers),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                args.append(contentsOf: ["--mcp-servers", jsonString])
            }
        }

        return args
    }

    /// Build CLI arguments from SessionOptions.
    static func buildArguments(
        from options: SessionOptions,
        resumeSessionId: String? = nil
    ) -> [String] {
        // Convert SessionOptions to the same argument structure
        let queryOptions = QueryOptions(
            model: options.model,
            systemPrompt: options.systemPrompt,
            allowedTools: options.allowedTools,
            disallowedTools: options.disallowedTools,
            agents: options.agents,
            mcpServers: options.mcpServers,
            permissionMode: options.permissionMode,
            maxTurns: options.maxTurns,
            cwd: options.cwd
        )
        return buildArguments(from: queryOptions, resumeSessionId: resumeSessionId)
    }
}
