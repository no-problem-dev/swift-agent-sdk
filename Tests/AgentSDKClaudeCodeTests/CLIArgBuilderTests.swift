import Foundation
import Testing
@testable import AgentSDKClaudeCode
@testable import AgentSDK

@Suite("CLIArgBuilder Tests")
struct CLIArgBuilderTests {

    @Test("Default arguments are always included")
    func defaultArguments() {
        let options = QueryOptions()
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--output-format"))
        #expect(args.contains("stream-json"))
        #expect(args.contains("--input-format"))
        #expect(args.contains("--verbose"))
    }

    @Test("Empty options produces only default arguments")
    func emptyOptions() {
        let options = QueryOptions()
        let args = CLIArgBuilder.buildArguments(from: options)

        let expected = ["--output-format", "stream-json", "--input-format", "stream-json", "--verbose"]
        #expect(args == expected)
    }

    @Test("System prompt is added when set")
    func systemPrompt() {
        let options = QueryOptions(systemPrompt: "You are a helpful assistant")
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--system-prompt"))
        #expect(args.contains("You are a helpful assistant"))
    }

    @Test("Permission mode is added with correct rawValue")
    func permissionMode() {
        let options = QueryOptions(permissionMode: .acceptEdits)
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--permission-mode"))
        #expect(args.contains("acceptEdits"))
    }

    @Test("Max turns is added when set")
    func maxTurns() {
        let options = QueryOptions(maxTurns: 5)
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--max-turns"))
        #expect(args.contains("5"))
    }

    @Test("Resume session ID is added when provided")
    func resumeSessionId() {
        let options = QueryOptions()
        let args = CLIArgBuilder.buildArguments(from: options, resumeSessionId: "session-123")

        #expect(args.contains("--resume"))
        #expect(args.contains("session-123"))
    }

    @Test("Model is added with rawValue when set")
    func model() {
        let options = QueryOptions(model: .opus)
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--model"))
        #expect(args.contains("opus"))
    }

    @Test("Agents are serialized to JSON when set")
    func agents() {
        let agent = AgentDefinition(
            description: "Test agent",
            prompt: "Test agent prompt"
        )
        let options = QueryOptions(agents: ["test-agent": agent])
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--agents"))

        // Find the JSON argument and verify it can be parsed back
        if let agentsIndex = args.firstIndex(of: "--agents"),
           agentsIndex + 1 < args.count {
            let jsonString = args[agentsIndex + 1]
            #expect(jsonString.contains("test-agent"))
            #expect(jsonString.contains("Test agent prompt"))
        } else {
            Issue.record("--agents argument not found or missing value")
        }
    }

    @Test("MCP servers are serialized to JSON when set")
    func mcpServers() {
        let server = MCPServerConfig(
            command: "/usr/bin/test",
            args: ["--test"]
        )
        let options = QueryOptions(mcpServers: ["test-server": server])
        let args = CLIArgBuilder.buildArguments(from: options)

        #expect(args.contains("--mcp-servers"))

        // Find the JSON argument and verify it can be parsed back
        if let serversIndex = args.firstIndex(of: "--mcp-servers"),
           serversIndex + 1 < args.count {
            let jsonString = args[serversIndex + 1]
            #expect(jsonString.contains("test-server"))
            // JSON may escape slashes as "\/" so check for either format
            let hasCommand = jsonString.contains("\\/usr\\/bin\\/test") || jsonString.contains("/usr/bin/test")
            #expect(hasCommand)
        } else {
            Issue.record("--mcp-servers argument not found or missing value")
        }
    }

    @Test("All options combined produce correct arguments")
    func allOptionsCombined() {
        let agent = AgentDefinition(description: "Agent description", prompt: "Agent prompt")
        let server = MCPServerConfig(command: "/bin/server", args: [])

        let options = QueryOptions(
            model: .sonnet,
            systemPrompt: "System prompt",
            agents: ["agent1": agent],
            mcpServers: ["server1": server],
            permissionMode: .bypassPermissions,
            maxTurns: 10
        )

        let args = CLIArgBuilder.buildArguments(from: options, resumeSessionId: "resume-123")

        // Check all expected arguments are present
        #expect(args.contains("--output-format"))
        #expect(args.contains("stream-json"))
        #expect(args.contains("--input-format"))
        #expect(args.contains("--verbose"))
        #expect(args.contains("--system-prompt"))
        #expect(args.contains("System prompt"))
        #expect(args.contains("--permission-mode"))
        #expect(args.contains("bypassPermissions"))
        #expect(args.contains("--max-turns"))
        #expect(args.contains("10"))
        #expect(args.contains("--resume"))
        #expect(args.contains("resume-123"))
        #expect(args.contains("--model"))
        #expect(args.contains("sonnet"))
        #expect(args.contains("--agents"))
        #expect(args.contains("--mcp-servers"))
    }

    @Test("SessionOptions builds same args as equivalent QueryOptions")
    func sessionOptionsEquivalence() {
        let agent = AgentDefinition(description: "Agent description", prompt: "Agent prompt")
        let server = MCPServerConfig(command: "/bin/server", args: [])

        let sessionOptions = SessionOptions(
            model: .sonnet,
            systemPrompt: "System prompt",
            agents: ["agent1": agent],
            mcpServers: ["server1": server],
            permissionMode: .acceptEdits,
            maxTurns: 5
        )

        let queryOptions = QueryOptions(
            model: .sonnet,
            systemPrompt: "System prompt",
            agents: ["agent1": agent],
            mcpServers: ["server1": server],
            permissionMode: .acceptEdits,
            maxTurns: 5
        )

        let sessionArgs = CLIArgBuilder.buildArguments(from: sessionOptions, resumeSessionId: "test-123")
        let queryArgs = CLIArgBuilder.buildArguments(from: queryOptions, resumeSessionId: "test-123")

        // Compare the arrays. JSON ordering may differ but structure should be same
        #expect(sessionArgs.count == queryArgs.count)

        // Check that all key arguments match
        #expect(sessionArgs.contains("--system-prompt") == queryArgs.contains("--system-prompt"))
        #expect(sessionArgs.contains("System prompt") == queryArgs.contains("System prompt"))
        #expect(sessionArgs.contains("--model") == queryArgs.contains("--model"))
        #expect(sessionArgs.contains("sonnet") == queryArgs.contains("sonnet"))
        #expect(sessionArgs.contains("--permission-mode") == queryArgs.contains("--permission-mode"))
        #expect(sessionArgs.contains("acceptEdits") == queryArgs.contains("acceptEdits"))
        #expect(sessionArgs.contains("--max-turns") == queryArgs.contains("--max-turns"))
        #expect(sessionArgs.contains("5") == queryArgs.contains("5"))
        #expect(sessionArgs.contains("--resume") == queryArgs.contains("--resume"))
        #expect(sessionArgs.contains("test-123") == queryArgs.contains("test-123"))
        #expect(sessionArgs.contains("--agents") == queryArgs.contains("--agents"))
        #expect(sessionArgs.contains("--mcp-servers") == queryArgs.contains("--mcp-servers"))
    }
}
