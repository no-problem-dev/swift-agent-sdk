import Foundation
import AgentSDK
import AgentSDKClaudeCode
import Domain

/// Infrastructure 実装のファクトリ
public enum ServiceFactory {

    /// AgentServiceProtocol の実装を生成する
    public static func makeAgentService() -> any AgentServiceProtocol {
        AgentService(cliPath: resolveCliPath())
    }

    /// SessionStoreProtocol の実装を生成する
    public static func makeSessionStore() -> any SessionStoreProtocol {
        JSONSessionStore()
    }

    /// ネイティブインストール含む CLI パスを解決する
    ///
    /// Xcode から起動すると `~/.local/bin` が PATH に含まれないため、
    /// ネイティブインストールの一般的なパスを明示的にチェックする。
    private static func resolveCliPath() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude",
            "/usr/local/bin/claude",
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        // nil → ClaudeCodeTransport の既定検索 (npm, which) にフォールバック
        return nil
    }
}
