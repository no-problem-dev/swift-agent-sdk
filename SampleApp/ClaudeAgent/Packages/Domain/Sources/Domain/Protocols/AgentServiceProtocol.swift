import Foundation

/// SDK セッション管理を抽象化するプロトコル
public protocol AgentServiceProtocol: Sendable {
    /// 新規セッションを作成し、メッセージストリームを返す
    func createSession(
        config: SessionConfig
    ) async throws -> (sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>)

    /// 既存セッションを再開し、メッセージストリームを返す
    func resumeSession(
        id: String,
        config: SessionConfig
    ) async throws -> AsyncThrowingStream<AgentEvent, Error>

    /// メッセージを送信し、応答ストリームを返す
    func send(
        sessionId: String,
        message: String
    ) async throws -> AsyncThrowingStream<AgentEvent, Error>

    /// ストリーミング処理を中断する
    func interrupt(sessionId: String) async throws

    /// セッションを閉じる
    func close(sessionId: String) async throws

    /// モデルを変更する
    func setModel(sessionId: String, model: ModelSelection) async throws
}
