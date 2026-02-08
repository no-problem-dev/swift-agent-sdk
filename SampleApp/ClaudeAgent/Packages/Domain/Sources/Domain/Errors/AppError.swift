import Foundation

/// アプリケーションレベルのエラー
public enum AppError: Error, Sendable, LocalizedError {
    case cliNotFound
    case notConnected
    case sessionExpired
    case connectionTimeout
    case processExited(code: Int)
    case protocolError(String)
    case persistenceError(String)

    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            "Claude Code CLI が見つかりません。npm install -g @anthropic-ai/claude-code を実行してください"
        case .notConnected:
            "セッションが接続されていません"
        case .sessionExpired:
            "セッションの有効期限が切れました"
        case .connectionTimeout:
            "接続がタイムアウトしました"
        case .processExited(let code):
            "Claude Code が予期せず終了しました (code: \(code))"
        case .protocolError(let detail):
            "通信エラーが発生しました: \(detail)"
        case .persistenceError(let detail):
            "データ保存エラー: \(detail)"
        }
    }
}
