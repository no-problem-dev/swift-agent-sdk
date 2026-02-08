import Foundation

/// セッションの接続状態
public enum SessionStatus: String, Sendable {
    case connecting
    case connected
    case disconnected
    case error
}
