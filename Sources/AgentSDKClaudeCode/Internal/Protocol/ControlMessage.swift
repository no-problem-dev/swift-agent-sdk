import Foundation

/// Known control request subtypes.
internal enum ControlSubtype: String, Sendable, Codable {
    case initialize
    case interrupt
    case canUseTool = "can_use_tool"
    case setPermissionMode = "set_permission_mode"
    case setModel = "set_model"
    case rewindFiles = "rewind_files"
    case getAccountInfo = "get_account_info"
    case getModels = "get_models"
    case getCommands = "get_commands"
    case getMcpServerStatus = "get_mcp_server_status"
    case setMcpServers = "set_mcp_servers"
    case hookCallback = "hook_callback"
    case mcpMessage = "mcp_message"
}
