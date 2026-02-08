import Foundation
import AgentSDK
import AgentSDKClaudeCode
import Domain

/// Infrastructure 実装のファクトリ
public enum ServiceFactory {

    /// AgentServiceProtocol の実装を生成する
    public static func makeAgentService() -> any AgentServiceProtocol {
        let transport = ClaudeCodeTransport()
        let client = ClaudeCodeClient(transport: transport)
        return AgentService(client: client)
    }

    /// SessionStoreProtocol の実装を生成する
    public static func makeSessionStore() -> any SessionStoreProtocol {
        JSONSessionStore()
    }
}
