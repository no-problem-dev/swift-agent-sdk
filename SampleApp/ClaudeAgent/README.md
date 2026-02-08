# ClaudeAgent

macOS native desktop client for Claude Code, built with swift-agent-sdk.

## Prerequisites

- macOS 15.0+
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and `claude login` completed
- Node.js 18+

## Setup

```bash
# Generate Xcode project
cd SampleApp/ClaudeAgent
xcodegen generate

# Build
xcodebuild build -project ClaudeAgent.xcodeproj -scheme ClaudeAgent -destination 'platform=macOS'

# Or open in Xcode
open ClaudeAgent.xcodeproj
```

## Usage

1. Launch the app
2. Press **Cmd+N** to create a new session
3. Select a working directory and model
4. Start chatting with Claude

### Features

- Multi-session management with sidebar navigation
- Streaming message display with cursor animation
- Tool use visualization (ToolUseCard / ToolResultCard)
- Model switching (Sonnet / Opus / Haiku)
- Session persistence across app restarts
- Keyboard shortcuts: Cmd+N (new session), Enter (send), Shift+Enter (newline)

## Architecture

Pattern B: XcodeGen + local SPM packages.

```
ClaudeAgent/
  App/Sources/          App target (DI wiring)
  Packages/
    Domain/             Entities, protocols, value objects
    Infrastructure/     SDK integration, persistence
    Presentation/       SwiftUI views, stores (@Observable)
  project.yml           XcodeGen configuration
```

### Dependency Flow

```
App -> Presentation -> Domain
App -> Infrastructure -> Domain
                      -> swift-agent-sdk (AgentSDK + AgentSDKClaudeCode)
```

- **Domain**: Pure Swift types. No framework dependencies. Defines `AgentServiceProtocol` and `SessionStoreProtocol`.
- **Infrastructure**: Implements protocols using swift-agent-sdk (`AgentService<ClaudeCodeTransport>`) and JSON file persistence (`JSONSessionStore`). Provides `ServiceFactory` for DI.
- **Presentation**: SwiftUI views and `@Observable @MainActor` stores (`AppState`, `SessionState`). Depends only on Domain protocols.
- **App**: Wires Infrastructure implementations into Presentation stores via `ServiceFactory`.

## Running Tests

```bash
# Domain tests
swift test --package-path Packages/Domain

# Infrastructure tests
swift test --package-path Packages/Infrastructure

# Presentation tests
swift test --package-path Packages/Presentation
```

## License

This sample app is part of [swift-agent-sdk](https://github.com/no-problem-dev/swift-agent-sdk).
