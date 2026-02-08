import Testing
@testable import AgentSDK

@Suite("QueryOptions Tests")
struct QueryOptionsTests {

    @Test("Default init has all nil properties")
    func defaultInit() {
        let options = QueryOptions()

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
        #expect(options.outputFormat == nil)
    }

    @Test("Full parameter init sets all properties correctly")
    func fullInit() {
        let testAgent = AgentDefinition(
            description: "Test agent description",
            prompt: "Test agent prompt",
            model: .sonnet
        )
        let testMCPServer = MCPServerConfig(command: "test-command", args: ["arg1"])
        let testCanUseTool: @Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision = { _, _, _ in
            .allow
        }

        let options = QueryOptions(
            model: .opus,
            systemPrompt: "Test system prompt",
            allowedTools: ["tool1", "tool2"],
            disallowedTools: ["tool3"],
            agents: ["test": testAgent],
            mcpServers: ["testServer": testMCPServer],
            permissionMode: .bypassPermissions,
            canUseTool: testCanUseTool,
            maxTurns: 10,
            maxBudgetUsd: 5.0,
            cwd: "/test/directory",
            outputFormat: .object(["type": .string("test")])
        )

        #expect(options.model == .opus)
        #expect(options.systemPrompt == "Test system prompt")
        #expect(options.allowedTools == ["tool1", "tool2"])
        #expect(options.disallowedTools == ["tool3"])
        #expect(options.agents?["test"]?.description == "Test agent description")
        #expect(options.mcpServers?["testServer"]?.command == "test-command")
        #expect(options.permissionMode == .bypassPermissions)
        #expect(options.canUseTool != nil)
        #expect(options.maxTurns == 10)
        #expect(options.maxBudgetUsd == 5.0)
        #expect(options.cwd == "/test/directory")
        #expect(options.outputFormat != nil)
    }

    @Test("Partial parameter init")
    func partialInit() {
        let options = QueryOptions(
            model: .sonnet,
            systemPrompt: "Partial test",
            maxTurns: 5
        )

        #expect(options.model == .sonnet)
        #expect(options.systemPrompt == "Partial test")
        #expect(options.maxTurns == 5)
        #expect(options.allowedTools == nil)
        #expect(options.disallowedTools == nil)
        #expect(options.agents == nil)
        #expect(options.mcpServers == nil)
        #expect(options.permissionMode == nil)
        #expect(options.canUseTool == nil)
        #expect(options.maxBudgetUsd == nil)
        #expect(options.cwd == nil)
        #expect(options.outputFormat == nil)
    }

    @Test("canUseTool closure is correctly stored and callable")
    func canUseToolClosure() async {
        let testClosure: @Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision = { _, _, _ in
            .allow
        }

        let options = QueryOptions(canUseTool: testClosure)

        #expect(options.canUseTool != nil)

        if let canUseTool = options.canUseTool {
            let decision = await canUseTool("testTool", [:], nil)
            // Check the result is .allow by pattern matching
            switch decision {
            case .allow:
                break // Expected
            case .deny:
                Issue.record("Expected allow decision")
            }
        }
    }

    @Test("canUseTool closure with deny decision")
    func canUseToolDeny() async {
        let testClosure: @Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision = { _, _, _ in
            .deny(reason: "Test denial")
        }

        let options = QueryOptions(canUseTool: testClosure)

        if let canUseTool = options.canUseTool {
            let decision = await canUseTool("blockedTool", [:], nil)
            if case .deny(let reason) = decision {
                #expect(reason == "Test denial")
            } else {
                Issue.record("Expected deny decision")
            }
        }
    }

    @Test("Model selection variations")
    func modelSelections() {
        let opusOptions = QueryOptions(model: .opus)
        #expect(opusOptions.model == .opus)

        let sonnetOptions = QueryOptions(model: .sonnet)
        #expect(sonnetOptions.model == .sonnet)

        let haikuOptions = QueryOptions(model: .haiku)
        #expect(haikuOptions.model == .haiku)
    }

    @Test("Permission mode variations")
    func permissionModes() {
        let defaultOptions = QueryOptions(permissionMode: .default)
        #expect(defaultOptions.permissionMode == .default)

        let acceptEditsOptions = QueryOptions(permissionMode: .acceptEdits)
        #expect(acceptEditsOptions.permissionMode == .acceptEdits)

        let bypassOptions = QueryOptions(permissionMode: .bypassPermissions)
        #expect(bypassOptions.permissionMode == .bypassPermissions)

        let planOptions = QueryOptions(permissionMode: .plan)
        #expect(planOptions.permissionMode == .plan)
    }

    @Test("Tool lists can be empty arrays")
    func emptyToolLists() {
        let options = QueryOptions(
            allowedTools: [],
            disallowedTools: []
        )

        #expect(options.allowedTools == [])
        #expect(options.disallowedTools == [])
    }

    @Test("Budget and turns can be zero")
    func zeroValues() {
        let options = QueryOptions(
            maxTurns: 0,
            maxBudgetUsd: 0.0
        )

        #expect(options.maxTurns == 0)
        #expect(options.maxBudgetUsd == 0.0)
    }

    @Test("Negative budget and turns")
    func negativeValues() {
        let options = QueryOptions(
            maxTurns: -1,
            maxBudgetUsd: -5.0
        )

        #expect(options.maxTurns == -1)
        #expect(options.maxBudgetUsd == -5.0)
    }
}
