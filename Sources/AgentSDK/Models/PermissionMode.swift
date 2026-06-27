import Foundation

/// Permission mode for controlling agent behavior.
///
/// - `default`: Standard permission checks
/// - `acceptEdits`: Automatically accept file edit operations
/// - `bypassPermissions`: Bypass all permission checks
/// - `plan`: Planning mode where the agent creates a plan without executing
public enum PermissionMode: String, Sendable, Codable {
    case `default` = "default"
    case acceptEdits = "acceptEdits"
    case bypassPermissions = "bypassPermissions"
    case plan = "plan"
}

/// Result of a permission check for tool execution.
public enum PermissionDecision: Sendable {
    /// Allow the tool to execute.
    case allow

    /// Deny the tool execution with a reason.
    case deny(reason: String)
}

/// Model selection for agent execution.
///
/// You can select from predefined models or specify a custom model string.
public enum ModelSelection: Sendable, Codable, Hashable {
    case opus
    case sonnet
    case haiku
    case custom(String)

    /// The raw string value to pass to the CLI.
    public var rawValue: String {
        switch self {
        case .opus: return "opus"
        case .sonnet: return "sonnet"
        case .haiku: return "haiku"
        case .custom(let value): return value
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "opus": self = .opus
        case "sonnet": self = .sonnet
        case "haiku": self = .haiku
        default: self = .custom(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

