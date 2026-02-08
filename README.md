# Swift Agent SDK

A Swift SDK for programmatic interaction with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI. Provides type-safe, async/await APIs for one-shot queries and multi-turn sessions.

## Quick Start

```swift
import AgentSDKClaudeCode

for try await message in AgentSDK.query(prompt: "Hello, Claude!") {
    switch message {
    case .assistant(let info): print(info.content)
    case .result(let result): print("Cost: $\(result.costUsd)")
    default: break
    }
}
```

## Prerequisites

- **macOS 15+** / Swift 6.0+
- **Node.js 18+** (`node` must be in PATH)
- **Claude Code CLI**: `npm install -g @anthropic-ai/claude-code`
- **Subscription authentication**: Run `claude login` to authenticate (API keys are not used)

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anthropics/swift-agent-sdk.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "AgentSDKClaudeCode", package: "swift-agent-sdk"),
    ]
)
```

For testing utilities, also add:

```swift
.testTarget(
    name: "YourAppTests",
    dependencies: [
        .product(name: "AgentSDKTesting", package: "swift-agent-sdk"),
    ]
)
```

## Usage

### One-Shot Query

```swift
import AgentSDKClaudeCode

let options = QueryOptions(
    model: .sonnet,
    systemPrompt: "You are a helpful coding assistant.",
    permissionMode: .bypassPermissions,
    maxTurns: 3
)

for try await message in AgentSDK.query(prompt: "Explain async/await in Swift", options: options) {
    switch message {
    case .system(let info):
        print("Session: \(info.sessionId), Model: \(info.model)")
    case .assistant(let info):
        for block in info.content {
            if case .text(let text) = block {
                print(text)
            }
        }
    case .result(let info):
        print("Tokens: \(info.inputTokens) in / \(info.outputTokens) out")
        print("Cost: $\(info.costUsd)")
    default:
        break
    }
}
```

### Multi-Turn Session

```swift
import AgentSDKClaudeCode

let session = try await AgentSDK.createSession(
    options: SessionOptions(permissionMode: .bypassPermissions)
)

// First turn
for try await msg in session.send("What is the capital of France?") {
    if case .assistant(let info) = msg {
        print(info.content)
    }
}

// Follow-up (maintains context)
for try await msg in session.send("What about Germany?") {
    if case .assistant(let info) = msg {
        print(info.content)
    }
}

try await session.close()
```

### Session Resume

```swift
// Save the session ID
let session = try await AgentSDK.createSession()
let sessionId = await session.id
try await session.close()

// Later, resume the session
let resumed = try await AgentSDK.resumeSession(id: sessionId)
for try await msg in resumed.send("Continue from where we left off") {
    // ...
}
try await resumed.close()
```

### Permission Handling

```swift
let options = QueryOptions(
    canUseTool: { toolName, input, metadata in
        if toolName == "Write" {
            return .deny(reason: "File writes are not allowed")
        }
        return .allow
    }
)

for try await msg in AgentSDK.query(prompt: "Create a file", options: options) {
    // The agent will be denied from writing files
}
```

### Runtime Control (Session)

```swift
let session = try await AgentSDK.createSession()

// Change model mid-session
try await session.setModel(.opus)

// Change permission mode
try await session.setPermissionMode(.acceptEdits)

// Interrupt current processing
try await session.interrupt()

// Query available models and commands
let models = try await session.supportedModels()
let commands = try await session.supportedCommands()

try await session.close()
```

## Customization (Dependency Injection)

The SDK uses a protocol-based architecture that supports DI:

```swift
import AgentSDK
import AgentSDKClaudeCode

// Use a custom transport
let transport = ClaudeCodeTransport(
    cliPath: "/custom/path/to/claude",
    runtime: .bun,
    additionalEnvironment: ["ANTHROPIC_MODEL": "claude-sonnet-4-5-20250929"]
)
let client = ClaudeCodeClient(transport: transport)

for try await msg in client.query(prompt: "Hello") {
    // ...
}
```

### Testing with MockTransport

```swift
import AgentSDKTesting

let mock = MockTransport(responses: MockFixtures.simpleSuccess(text: "Hello!"))
let client = ClaudeCodeClient(transport: mock)

for try await msg in client.query(prompt: "test") {
    switch msg {
    case .assistant(let info):
        // Verify the mocked response
        break
    case .result(let info):
        assert(info.costUsd == 0.001)
    default:
        break
    }
}

// Verify what was sent
assert(!mock.sentMessages.isEmpty)
```

## Architecture

```
AgentSDK              Protocol layer (AgentTransport, AgentClient, AgentSession)
AgentSDKClaudeCode    Claude Code CLI implementation
AgentSDKTesting       MockTransport & fixtures for testing
```

| Protocol | Implementation | Description |
|----------|---------------|-------------|
| `AgentTransport` | `ClaudeCodeTransport` | CLI subprocess management |
| `AgentClient` | `ClaudeCodeClient<T>` | Query and session orchestration |
| `AgentSession` | `ClaudeCodeSession` | Multi-turn conversation state |

## API Reference

### AgentSDK (Convenience)

| Method | Description |
|--------|-------------|
| `AgentSDK.query(prompt:options:)` | One-shot query returning `AsyncThrowingStream<AgentMessage, Error>` |
| `AgentSDK.createSession(options:)` | Create a new multi-turn session |
| `AgentSDK.resumeSession(id:options:)` | Resume an existing session |

### AgentMessage

| Case | Info Type | Description |
|------|-----------|-------------|
| `.system` | `SystemInfo` | Session ID, tools, model info |
| `.assistant` | `AssistantInfo` | Content blocks (text, tool use, tool result) |
| `.partial` | `PartialInfo` | Streaming partial content |
| `.result` | `ResultInfo` | Final result with cost, tokens, duration |

### QueryOptions / SessionOptions

| Property | Type | Description |
|----------|------|-------------|
| `model` | `ModelSelection?` | `.opus`, `.sonnet`, `.haiku`, `.custom(String)` |
| `systemPrompt` | `String?` | System prompt |
| `permissionMode` | `PermissionMode?` | `.default`, `.acceptEdits`, `.bypassPermissions`, `.plan` |
| `canUseTool` | Closure? | Permission handler for tool execution |
| `maxTurns` | `Int?` | Maximum conversation turns |
| `maxBudgetUsd` | `Double?` | Budget limit |
| `allowedTools` | `[String]?` | Whitelist of allowed tools |
| `disallowedTools` | `[String]?` | Blacklist of tools |

## Version Compatibility

| Swift Agent SDK | Claude Code CLI | Swift | macOS | Node.js |
|----------------|----------------|-------|-------|---------|
| 0.1.x | Latest | 6.0+ | 15+ | 18+ |

## License

See [LICENSE](LICENSE) for details.
