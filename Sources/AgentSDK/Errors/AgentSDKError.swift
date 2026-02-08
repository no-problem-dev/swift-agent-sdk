import Foundation

/// SDK の公開エラー型。全ケースに解決方法を含むメッセージを提供。
///
/// このエラー型は、Swift Agent SDK で発生する可能性のあるすべてのエラー状態を表現します。
/// 各エラーケースには、問題の診断と解決に役立つ詳細な情報が含まれています。
public enum AgentSDKError: Error, Sendable {
    /// CLI バイナリが見つからない
    ///
    /// - Parameter searchedPaths: 検索された全パス
    ///
    /// Claude Code CLI がシステム上で見つかりませんでした。
    /// `npm install -g @anthropic-ai/claude-agent-sdk` でインストールしてください。
    case cliNotFound(searchedPaths: [String])

    /// JS ランタイム（Node.js / Bun / Deno）が見つからない
    ///
    /// - Parameter runtime: 検索対象のランタイム名
    ///
    /// 指定された JavaScript ランタイムが PATH 上で見つかりませんでした。
    /// Node.js 18 以上のインストールが推奨されます。
    case runtimeNotFound(runtime: String)

    /// CLI プロセスの起動に失敗
    ///
    /// - Parameter underlying: 起動失敗の原因となったエラー
    ///
    /// CLI プロセスの `Process.run()` が失敗しました。
    /// パーミッション、パス、ランタイムの設定を確認してください。
    case processLaunchFailed(underlying: any Error)

    /// CLI プロセスが異常終了
    ///
    /// - Parameters:
    ///   - exitCode: プロセスの終了コード
    ///   - stderr: 標準エラー出力の内容
    ///
    /// CLI プロセスが非ゼロの終了コードで終了しました。
    /// 認証エラーやバージョン不一致の可能性があります。
    case processExited(exitCode: Int32, stderr: String)

    /// JSONL プロトコルエラー（不正 JSON、予期しないメッセージ）
    ///
    /// - Parameters:
    ///   - message: エラーの詳細メッセージ
    ///   - rawData: パースに失敗した生データ（存在する場合）
    ///
    /// CLI からの JSONL メッセージのパースまたは検証に失敗しました。
    /// SDK と CLI のバージョンが一致していることを確認してください。
    case protocolError(message: String, rawData: Data?)

    /// 初期化タイムアウト
    ///
    /// - Parameter seconds: タイムアウトまでの秒数
    ///
    /// CLI プロセスが指定時間内に初期化メッセージを返しませんでした。
    /// ネットワーク接続や CLI の応答性を確認してください。
    case initializationTimeout(seconds: Int)

    /// 制御リクエストタイムアウト
    ///
    /// - Parameters:
    ///   - subtype: タイムアウトしたリクエストの種類
    ///   - seconds: タイムアウトまでの秒数
    ///
    /// 制御リクエスト（createSession, closeSession など）が指定時間内に完了しませんでした。
    /// CLI の負荷状態やネットワーク環境を確認してください。
    case controlRequestTimeout(subtype: String, seconds: Int)

    /// セッションが期限切れ
    ///
    /// - Parameter sessionId: 期限切れとなったセッション ID
    ///
    /// セッションが非アクティブ期間（デフォルト: 10 分）を超えて期限切れになりました。
    /// 新しいセッションを作成するか、`resumeSession()` を使用してください。
    case sessionExpired(sessionId: String)

    /// セッションが既に閉じている
    ///
    /// - Parameter sessionId: 閉じられたセッション ID
    ///
    /// 既にクローズされたセッションに対して操作が試みられました。
    /// 新しいセッションを作成してください。
    case sessionClosed(sessionId: String)

    /// Transport が未接続
    ///
    /// Transport が接続されていない状態でメッセージ送信が試みられました。
    /// `connect()` を先に呼び出してください。
    case notConnected

    /// キャンセルされた
    ///
    /// タスクまたは操作がユーザーによってキャンセルされました。
    /// これは `Task.cancel()` や `interrupt()` 呼び出し時の正常な動作です。
    case cancelled
}

extension AgentSDKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cliNotFound(let paths):
            return """
            Claude Code CLI not found. \
            Searched paths: \(paths.joined(separator: ", ")). \
            Install with: npm install -g @anthropic-ai/claude-agent-sdk
            """
        case .runtimeNotFound(let runtime):
            return """
            JavaScript runtime '\(runtime)' not found. \
            Install Node.js 18+ from https://nodejs.org or specify an alternative runtime.
            """
        case .processLaunchFailed(let underlying):
            return """
            Failed to launch CLI process: \(underlying.localizedDescription). \
            Verify the CLI is installed and the path is correct.
            """
        case .processExited(let exitCode, let stderr):
            return """
            CLI process exited with code \(exitCode). \
            stderr: \(stderr.isEmpty ? "(empty)" : stderr). \
            Check the Claude Code CLI installation and authentication.
            """
        case .protocolError(let message, _):
            return """
            JSONL protocol error: \(message). \
            This may indicate a version mismatch between the SDK and CLI.
            """
        case .initializationTimeout(let seconds):
            return """
            CLI initialization timed out after \(seconds) seconds. \
            Ensure the CLI is responsive and the network is available.
            """
        case .controlRequestTimeout(let subtype, let seconds):
            return """
            Control request '\(subtype)' timed out after \(seconds) seconds. \
            The CLI may be unresponsive or overloaded.
            """
        case .sessionExpired(let sessionId):
            return """
            Session '\(sessionId)' has expired. \
            Sessions expire after 10 minutes of inactivity. Create a new session or use resumeSession().
            """
        case .sessionClosed(let sessionId):
            return """
            Session '\(sessionId)' is already closed. \
            Create a new session to continue.
            """
        case .notConnected:
            return """
            Transport is not connected. \
            Call connect() before sending messages.
            """
        case .cancelled:
            return """
            Operation was cancelled. \
            This is expected when using Task.cancel() or interrupt().
            """
        }
    }
}
