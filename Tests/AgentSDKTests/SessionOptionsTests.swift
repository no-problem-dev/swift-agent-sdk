import Testing
@testable import AgentSDK

@Suite("SessionOptions Tests")
struct SessionOptionsTests {

    @Test("Default init has all nil properties")
    func defaultInit() {
        let options = SessionOptions()

        #expect(options.model == nil)
        #expect(options.systemPrompt == nil)
        #expect(options.allowedTools == nil)
        #expect(options.disallowedTools == nil)
        #expect(options.agents == nil)
        #expect(options.mcpServers == nil)
        #expect(options.permissionMode == nil)
        #expect(options.canUseTool == nil)
        #expect(options.maxTurns == nil)
        #expect(options.maxBudgetUsd == nil)
        #expect(options.cwd == nil)
    }

    @Test("Full parameter init sets all properties correctly")
    func fullInit() {
        let testAgent = AgentDefinition(
            description: "Session agent description",
            prompt: "Session agent prompt",
            model: .haiku
        )
        let testMCPServer = MCPServerConfig(command: "session-command", args: ["arg1", "arg2"])
        let testCanUseTool: @Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision = { _, _, _ in
            .deny(reason: "Default deny")
        }

        let options = SessionOptions(
            model: .sonnet,
            systemPrompt: "Session system prompt",
            allowedTools: ["sessionTool1", "sessionTool2"],
            disallowedTools: ["blockedTool"],
            agents: ["sessionAgent": testAgent],
            mcpServers: ["sessionServer": testMCPServer],
            permissionMode: .acceptEdits,
            canUseTool: testCanUseTool,
            maxTurns: 20,
            maxBudgetUsd: 10.0,
            cwd: "/session/directory"
        )

        #expect(options.model == .sonnet)
        #expect(options.systemPrompt == "Session system prompt")
        #expect(options.allowedTools == ["sessionTool1", "sessionTool2"])
        #expect(options.disallowedTools == ["blockedTool"])
        #expect(options.agents?["sessionAgent"]?.description == "Session agent description")
        #expect(options.mcpServers?["sessionServer"]?.command == "session-command")
        #expect(options.permissionMode == .acceptEdits)
        #expect(options.canUseTool != nil)
        #expect(options.maxTurns == 20)
        #expect(options.maxBudgetUsd == 10.0)
        #expect(options.cwd == "/session/directory")
    }

    @Test("Partial parameter init")
    func partialInit() {
        let options = SessionOptions(
            model: .opus,
            maxTurns: 15,
            cwd: "/partial/path"
        )

        #expect(options.model == .opus)
        #expect(options.maxTurns == 15)
        #expect(options.cwd == "/partial/path")
        #expect(options.systemPrompt == nil)
        #expect(options.allowedTools == nil)
        #expect(options.disallowedTools == nil)
        #expect(options.agents == nil)
        #expect(options.mcpServers == nil)
        #expect(options.permissionMode == nil)
        #expect(options.canUseTool == nil)
        #expect(options.maxBudgetUsd == nil)
    }

    @Test("canUseTool closure is correctly stored and callable")
    func canUseToolClosure() async {
        let testClosure: @Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision = { toolName, _, _ in
            toolName == "allowed" ? .allow : .deny(reason: "Not allowed")
        }

        let options = SessionOptions(canUseTool: testClosure)

        #expect(options.canUseTool != nil)

        if let canUseTool = options.canUseTool {
            let allowDecision = await canUseTool("allowed", [:], nil)
            switch allowDecision {
            case .allow:
                break // Expected
            case .deny:
                Issue.record("Expected allow decision")
            }

            let denyDecision = await canUseTool("blocked", [:], nil)
            if case .deny(let reason) = denyDecision {
                #expect(reason == "Not allowed")
            } else {
                Issue.record("Expected deny decision")
            }
        }
    }

    @Test("canUseTool closure with metadata")
    func canUseToolWithMetadata() async {
        // Use an actor to safely capture metadata
        actor MetadataCapture {
            var metadata: JSONValue?
            func set(_ value: JSONValue?) {
                metadata = value
            }
        }

        let capture = MetadataCapture()
        let testClosure: @Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision = { _, _, metadata in
            await capture.set(metadata)
            return .allow
        }

        let options = SessionOptions(canUseTool: testClosure)

        if let canUseTool = options.canUseTool {
            let testMetadata = JSONValue.object(["key": .string("value")])
            _ = await canUseTool("testTool", [:], testMetadata)
            let received = await capture.metadata
            #expect(received != nil)
        }
    }

    @Test("Model selection variations")
    func modelSelections() {
        let opusOptions = SessionOptions(model: .opus)
        #expect(opusOptions.model == .opus)

        let sonnetOptions = SessionOptions(model: .sonnet)
        #expect(sonnetOptions.model == .sonnet)

        let haikuOptions = SessionOptions(model: .haiku)
        #expect(haikuOptions.model == .haiku)
    }

    @Test("Permission mode variations")
    func permissionModes() {
        let defaultOptions = SessionOptions(permissionMode: .default)
        #expect(defaultOptions.permissionMode == .default)

        let acceptEditsOptions = SessionOptions(permissionMode: .acceptEdits)
        #expect(acceptEditsOptions.permissionMode == .acceptEdits)

        let bypassOptions = SessionOptions(permissionMode: .bypassPermissions)
        #expect(bypassOptions.permissionMode == .bypassPermissions)

        let planOptions = SessionOptions(permissionMode: .plan)
        #expect(planOptions.permissionMode == .plan)
    }

    @Test("Multiple agents configuration")
    func multipleAgents() {
        let agent1 = AgentDefinition(description: "Agent1 description", prompt: "Do task 1", model: .sonnet)
        let agent2 = AgentDefinition(description: "Agent2 description", prompt: "Do task 2", model: .haiku)

        let options = SessionOptions(
            agents: [
                "agent1": agent1,
                "agent2": agent2
            ]
        )

        #expect(options.agents?.count == 2)
        #expect(options.agents?["agent1"]?.description == "Agent1 description")
        #expect(options.agents?["agent2"]?.description == "Agent2 description")
    }

    @Test("Multiple MCP servers configuration")
    func multipleMCPServers() {
        let server1 = MCPServerConfig(command: "server1", args: [])
        let server2 = MCPServerConfig(command: "server2", args: ["--verbose"])

        let options = SessionOptions(
            mcpServers: [
                "server1": server1,
                "server2": server2
            ]
        )

        #expect(options.mcpServers?.count == 2)
        #expect(options.mcpServers?["server1"]?.command == "server1")
        #expect(options.mcpServers?["server2"]?.command == "server2")
    }

    @Test("Tool lists can be empty arrays")
    func emptyToolLists() {
        let options = SessionOptions(
            allowedTools: [],
            disallowedTools: []
        )

        #expect(options.allowedTools == [])
        #expect(options.disallowedTools == [])
    }

    @Test("Budget and turns can be zero")
    func zeroValues() {
        let options = SessionOptions(
            maxTurns: 0,
            maxBudgetUsd: 0.0
        )

        #expect(options.maxTurns == 0)
        #expect(options.maxBudgetUsd == 0.0)
    }

    @Test("Large budget and turns values")
    func largeValues() {
        let options = SessionOptions(
            maxTurns: 1000,
            maxBudgetUsd: 999.99
        )

        #expect(options.maxTurns == 1000)
        #expect(options.maxBudgetUsd == 999.99)
    }

    @Test("Working directory paths")
    func workingDirectoryPaths() {
        let absolutePath = SessionOptions(cwd: "/absolute/path/to/dir")
        #expect(absolutePath.cwd == "/absolute/path/to/dir")

        let relativePath = SessionOptions(cwd: "./relative/path")
        #expect(relativePath.cwd == "./relative/path")

        let emptyPath = SessionOptions(cwd: "")
        #expect(emptyPath.cwd == "")
    }
}
