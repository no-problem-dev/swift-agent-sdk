import Foundation

/// Configuration for an MCP (Model Context Protocol) server.
///
/// MCP servers provide additional tools and context to the agent through a standardized protocol.
public struct MCPServerConfig: Sendable, Codable {
    /// Command to execute to start the server.
    public let command: String

    /// Command-line arguments for the server.
    public let args: [String]?

    /// Environment variables for the server process.
    public let env: [String: String]?

    public init(
        command: String,
        args: [String]? = nil,
        env: [String: String]? = nil
    ) {
        self.command = command
        self.args = args
        self.env = env
    }
}
