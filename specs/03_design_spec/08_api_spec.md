---
title: "Swift Agent SDK - 公開 API 設計"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, api-spec]
references:
  - ./00_index.md
  - ./03_layer_architecture.md
  - ./05_data_model.md
  - ../02_requirements/03_functional_requirements.md
---

# 公開 API 設計

## Intent（意図）

利用者が直接触れる公開 API の詳細設計を定義する。
Protocol 層のメソッドシグネチャ、コンビニエンス API、および具象層の設定 API を網羅する。
利用者が API ドキュメントとして参照できるレベルの詳細度を目指す。

---

## 1. コンビニエンス API（AgentSDK namespace）

### 1.1 ワンショットクエリ

```swift
/// DI 不要のワンショットクエリ。デフォルトの Claude Code 実装を使用。
///
/// - Parameters:
///   - prompt: 送信するプロンプト文字列
///   - options: クエリオプション（省略時はデフォルト値）
/// - Returns: AgentMessage のストリーム
///
/// ```swift
/// for try await message in AgentSDK.query(prompt: "Hello") {
///     switch message {
///     case .assistant(let info): print(info.content)
///     case .result(let result): print("Cost: $\(result.costUsd)")
///     default: break
///     }
/// }
/// ```
public enum AgentSDK {
    public static func query(
        prompt: String,
        options: QueryOptions = QueryOptions()
    ) -> AsyncThrowingStream<AgentMessage, Error>
}
```

### 1.2 セッション作成

```swift
extension AgentSDK {
    /// DI 不要のセッション作成。デフォルトの Claude Code 実装を使用。
    ///
    /// ```swift
    /// let session = try await AgentSDK.createSession()
    /// for try await msg in session.send("最初の質問") { ... }
    /// for try await msg in session.send("追加の質問") { ... }
    /// await session.close()
    /// ```
    public static func createSession(
        options: SessionOptions = SessionOptions()
    ) async throws -> some AgentSession
}
```

### 1.3 セッション再開

```swift
extension AgentSDK {
    /// DI 不要のセッション再開。
    public static func resumeSession(
        id: String,
        options: SessionOptions = SessionOptions()
    ) async throws -> some AgentSession
}
```

---

## 2. 明示的 DI API

### 2.1 ClaudeCodeTransport 初期化

```swift
/// Claude Code CLI サブプロセスを使った AgentTransport 実装。
///
/// ```swift
/// let transport = ClaudeCodeTransport(
///     cliPath: "/custom/path/to/cli.js",
///     runtime: .bun
/// )
/// ```
public struct ClaudeCodeTransport: AgentTransport {
    /// CLI バイナリのカスタムパス（nil = 自動探索）
    public var cliPath: String?

    /// JS ランタイム
    public var runtime: JSRuntime

    /// 環境変数の追加
    public var additionalEnvironment: [String: String]

    public init(
        cliPath: String? = nil,
        runtime: JSRuntime = .node,
        additionalEnvironment: [String: String] = [:]
    )
}

public enum JSRuntime: String, Sendable {
    case node = "node"
    case bun = "bun"
    case deno = "deno"
}
```

### 2.2 ClaudeCodeClient 初期化

```swift
/// AgentClient の Claude Code 実装。Transport を generics で DI。
///
/// ```swift
/// let transport = ClaudeCodeTransport()
/// let client = ClaudeCodeClient(transport: transport)
/// for try await msg in client.query(prompt: "Hello") { ... }
/// ```
public struct ClaudeCodeClient<T: AgentTransport>: AgentClient {
    public typealias SessionType = ClaudeCodeSession

    public init(transport: T)

    public func query(
        prompt: String,
        options: QueryOptions = QueryOptions()
    ) -> AsyncThrowingStream<AgentMessage, Error>

    public func createSession(
        options: SessionOptions = SessionOptions()
    ) async throws -> ClaudeCodeSession

    public func resumeSession(
        id: String,
        options: SessionOptions = SessionOptions()
    ) async throws -> ClaudeCodeSession
}
```

---

## 3. Session API

### 3.1 ClaudeCodeSession

```swift
/// AgentSession の Claude Code 実装。
/// CLI プロセスとの接続を維持し、複数回のメッセージ交換を可能にする。
public final class ClaudeCodeSession: AgentSession, Sendable {
    /// セッション識別子
    public var id: String { get async }

    /// メッセージ送信
    ///
    /// ```swift
    /// for try await msg in session.send("質問") {
    ///     switch msg {
    ///     case .assistant(let info): print(info.content)
    ///     case .result(let result): print("Done")
    ///     default: break
    ///     }
    /// }
    /// ```
    public func send(_ message: String) -> AsyncThrowingStream<AgentMessage, Error>

    /// 処理中断
    public func interrupt() async throws

    /// セッション終了
    public func close() async throws
}
```

### 3.2 セッション内ランタイム制御

```swift
extension ClaudeCodeSession {
    /// ランタイムモデル変更
    public func setModel(_ model: ModelSelection) async throws

    /// 権限モード変更
    public func setPermissionMode(_ mode: PermissionMode) async throws

    /// ファイル巻き戻し
    public func rewindFiles(toMessageId messageId: String) async throws

    /// サポートコマンド一覧
    public func supportedCommands() async throws -> [CommandInfo]

    /// サポートモデル一覧
    public func supportedModels() async throws -> [ModelInfo]

    /// MCP サーバー状態
    public func mcpServerStatus() async throws -> [MCPServerInfo]

    /// MCP サーバー設定変更
    public func setMCPServers(_ servers: [String: MCPServerConfig]) async throws
}

public struct CommandInfo: Sendable, Codable {
    public let name: String
    public let description: String
}

public struct ModelInfo: Sendable, Codable {
    public let id: String
    public let name: String?
}
```

---

## 4. QueryOptions 詳細

```swift
public struct QueryOptions: Sendable {
    // --- モデル ---
    public var model: ModelSelection?

    // --- プロンプト ---
    public var systemPrompt: String?

    // --- ツールフィルタ ---
    public var allowedTools: [String]?
    public var disallowedTools: [String]?

    // --- エージェント ---
    public var agents: [String: AgentDefinition]?

    // --- MCP ---
    public var mcpServers: [String: MCPServerConfig]?

    // --- 権限 ---
    public var permissionMode: PermissionMode?
    public var canUseTool: (@Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision)?

    // --- 制限 ---
    public var maxTurns: Int?
    public var maxBudgetUsd: Double?

    // --- 環境 ---
    public var cwd: String?

    // --- 構造化出力 ---
    public var outputFormat: JSONValue?

    /// デフォルト初期化子
    public init(
        model: ModelSelection? = nil,
        systemPrompt: String? = nil,
        allowedTools: [String]? = nil,
        disallowedTools: [String]? = nil,
        agents: [String: AgentDefinition]? = nil,
        mcpServers: [String: MCPServerConfig]? = nil,
        permissionMode: PermissionMode? = nil,
        canUseTool: (@Sendable (String, [String: JSONValue], JSONValue?) async -> PermissionDecision)? = nil,
        maxTurns: Int? = nil,
        maxBudgetUsd: Double? = nil,
        cwd: String? = nil,
        outputFormat: JSONValue? = nil
    )
}
```

---

## 5. サブエージェント定義（FF-007）

```swift
/// サブエージェント定義の使用例
///
/// ```swift
/// for try await msg in AgentSDK.query(
///     prompt: "このPRをレビューして",
///     options: .init(
///         agents: [
///             "code-reviewer": AgentDefinition(
///                 description: "コードレビューの専門家",
///                 prompt: "コード品質を評価して...",
///                 tools: ["Read", "Grep", "Glob"],
///                 model: .sonnet
///             ),
///             "security-reviewer": AgentDefinition(
///                 description: "セキュリティレビューの専門家",
///                 prompt: "セキュリティ脆弱性を検出して...",
///                 tools: ["Read", "Grep"],
///                 model: .sonnet
///             )
///         ]
///     )
/// ) {
///     switch msg {
///     case .assistant(let info):
///         if let parentId = info.parentToolUseId {
///             print("[SubAgent] \(info.content)")
///         } else {
///             print("[Main] \(info.content)")
///         }
///     default: break
///     }
/// }
/// ```
```

---

## 6. MCP サーバー設定（FF-008）

```swift
/// MCP サーバー設定の使用例
///
/// ```swift
/// let session = try await AgentSDK.createSession(options: .init(
///     mcpServers: [
///         "my-tools": MCPServerConfig(
///             command: "npx",
///             args: ["-y", "@my-org/mcp-tools"],
///             env: ["TOOL_API_KEY": "..."]
///         )
///     ]
/// ))
///
/// // ランタイムで MCP サーバーを追加
/// try await session.setMCPServers([
///     "my-tools": MCPServerConfig(command: "npx", args: ["-y", "@my-org/mcp-tools"]),
///     "another-tool": MCPServerConfig(command: "another-mcp-server")
/// ])
///
/// // MCP サーバー状態の確認
/// let status = try await session.mcpServerStatus()
/// ```
```

---

## 7. テスト API（AgentSDKTesting）

### 7.1 MockTransport

```swift
/// テスト用 Transport。事前定義した応答を返し、送信メッセージを記録する。
///
/// ```swift
/// let mock = MockTransport(responses: [
///     .system(SystemInfo(sessionId: "test", tools: [], model: "opus", mcpServers: [])),
///     .assistant(AssistantInfo(content: [.text("Hello!")], parentToolUseId: nil)),
///     .result(ResultInfo(result: "Hello!", costUsd: 0.01, durationMs: 100, inputTokens: 10, outputTokens: 5, sessionId: "test", numTurns: 1))
/// ])
/// let client = ClaudeCodeClient(transport: mock)
///
/// for try await msg in client.query(prompt: "Test") {
///     // assertions
/// }
///
/// XCTAssertEqual(mock.sentMessages.count, 1)
/// ```
public actor MockTransport: AgentTransport {
    /// 返す応答メッセージ列
    public init(responses: [AgentMessage])

    /// 送信されたメッセージの記録
    public var sentMessages: [Data] { get }

    /// 接続状態の制御
    public var simulatedIsReady: Bool
}
```

### 7.2 MockFixtures

```swift
/// テスト用の事前定義メッセージシーケンス
public enum MockFixtures {
    /// 最小限の成功レスポンス
    public static func simpleSuccess(text: String = "Hello!") -> [AgentMessage]

    /// ツール使用を含むレスポンス
    public static func withToolUse(toolName: String, result: String) -> [AgentMessage]

    /// エラーレスポンス
    public static func protocolError() -> [AgentMessage]
}
```

---

## Rationale（根拠）

### query() が AsyncThrowingStream を直接返す設計

**決定:** `query()` は `async throws` ではなく、同期的に `AsyncThrowingStream` を返す

**採用理由:**
- `for try await msg in client.query(prompt:)` のように直感的に書ける
- ストリーム内部で非同期にプロセス起動・ハンドシェイクを実行
- エラーはストリームの最初のイテレーションで throw される

**検討した代替案:**

| 代替案 | 不採用理由 |
|--------|-----------|
| `async throws -> AsyncThrowingStream` | `try await` が 2 回必要になり API が冗長 |
| `AsyncSequence` プロトコル準拠型を返す | 型が複雑になり利用者に不親切 |

### ClaudeCodeSession を class で実装

**決定:** AgentSession 準拠型を `final class` で実装（struct ではなく）

**採用理由:**
- セッションは参照同一性が重要（同じ CLI プロセスへの参照を共有）
- 内部に Actor（MessageRouter）を保持し、ライフサイクルを管理
- `deinit` でクリーンアップ（プロセス終了）が可能

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
