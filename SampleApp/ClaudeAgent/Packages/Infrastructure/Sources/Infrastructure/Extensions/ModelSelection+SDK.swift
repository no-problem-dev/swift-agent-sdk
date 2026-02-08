import AgentSDK

/// AgentSDK モジュールの ModelSelection を Infrastructure 内で参照するための typealias
/// AgentSDK モジュール内に同名の namespace enum があるため、モジュール修飾が使えない
typealias SDKModelSelection = ModelSelection
