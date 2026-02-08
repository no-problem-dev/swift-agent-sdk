import Foundation

/// セッション作成時の設定
public struct SessionConfig: Codable, Sendable {
    public var model: ModelSelection
    public var workingDirectory: String
    public var systemPrompt: String?
    public var name: String?

    public init(
        model: ModelSelection = .sonnet,
        workingDirectory: String,
        systemPrompt: String? = nil,
        name: String? = nil
    ) {
        self.model = model
        self.workingDirectory = workingDirectory
        self.systemPrompt = systemPrompt
        self.name = name
    }
}
