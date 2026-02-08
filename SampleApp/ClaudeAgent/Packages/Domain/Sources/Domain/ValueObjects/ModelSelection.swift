import Foundation

/// 利用可能なモデル
public enum ModelSelection: String, Codable, Sendable, CaseIterable {
    case opus
    case sonnet
    case haiku

    /// 表示名
    public var displayName: String {
        switch self {
        case .opus: "Opus"
        case .sonnet: "Sonnet"
        case .haiku: "Haiku"
        }
    }
}
