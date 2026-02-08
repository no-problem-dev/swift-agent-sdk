import Domain

extension Domain.ModelSelection {
    /// Domain の ModelSelection を SDK の ModelSelection に変換する
    var sdkValue: SDKModelSelection {
        switch self {
        case .opus: .opus
        case .sonnet: .sonnet
        case .haiku: .haiku
        }
    }
}
