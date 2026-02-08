import Foundation

/// Convenience namespace for Swift Agent SDK.
///
/// Provides DI-free entry points using the default Claude Code implementation.
/// Import `AgentSDKClaudeCode` to enable the convenience methods.
///
/// ```swift
/// import AgentSDKClaudeCode
///
/// for try await message in AgentSDK.query(prompt: "Hello") {
///     switch message {
///     case .assistant(let info): print(info.content)
///     case .result(let result): print("Cost: $\(result.costUsd)")
///     default: break
///     }
/// }
/// ```
public enum AgentSDK {}
