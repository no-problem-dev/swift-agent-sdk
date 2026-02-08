---
title: "Swift Agent SDK - 技術的実現可能性調査 & Request仕様"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, claude-code, feasibility]
---

# spec_01: Swift Agent SDK

## 1. 発端・背景

Claude Code Agent SDK（TypeScript）は、Claude Code CLI をプログラマティックに操作する SDK として提供されている。
これを Swift ネイティブのパッケージとしてラップし、Swift エコシステムから同等の機能にアクセスできるようにしたい。

**想定ユースケース:**
- Swift CLI ツールに Claude Agent 機能を組み込む
- macOS アプリに AI エージェントを統合する
- Server-side Swift アプリケーションで AI 自動化を行う
- CI/CD パイプラインを Swift で記述し AI 支援を活用する

## 2. 既存 Agent SDK のアーキテクチャ分析

### 2.1 TypeScript SDK の本質

TypeScript Agent SDK は **Claude Code CLI のサブプロセスラッパー** である。直接 Claude API を呼んでいるわけではない。

```
┌──────────────────┐    stdin/stdout     ┌───────────────────┐
│  TS Agent SDK    │ ◄──── JSONL ────► │  Claude Code CLI   │
│  (Node.js)       │                     │  (cli.js / Node)   │
└──────────────────┘                     └───────┬───────────┘
                                                 │ HTTPS
                                         ┌───────▼───────────┐
                                         │  Claude API        │
                                         └───────────────────┘
```

**核心的発見:** SDK は API クライアントではなく、**サブプロセス制御 + JSONL プロトコル実装** がその実体。

### 2.2 JSONL 制御プロトコル

全通信は stdin/stdout 経由の行区切り JSON（JSONL）で行われる。

**初期化ハンドシェイク:**
```
1. SDK が CLI プロセスを spawn
2. CLI → SDK: {"type": "initialize_ready"}
3. SDK → CLI: InitializeRequest（hook 登録等）
4. CLI → SDK: サポートコマンド情報
5. SDK → CLI: ユーザーメッセージ
6. CLI → SDK: ストリーミングレスポンス
```

**制御メッセージサブタイプ（全量）:**

| サブタイプ | 方向 | 用途 |
|-----------|------|------|
| `initialize` | SDK→CLI | ハンドシェイク・hook 登録 |
| `interrupt` | SDK→CLI | 処理中断 |
| `can_use_tool` | CLI→SDK | ツール使用許可確認 |
| `set_permission_mode` | SDK→CLI | 権限モード変更 |
| `set_model` | SDK→CLI | ランタイムモデル変更 |
| `hook_callback` | CLI→SDK | 登録済み hook 呼び出し |
| `mcp_message` | 双方向 | MCP JSONRPC メッセージ中継 |
| `rewind_files` | SDK→CLI | チェックポイント復元 |
| `get_account_info` | SDK→CLI | アカウント情報取得 |
| `get_models` | SDK→CLI | 利用可能モデル一覧 |
| `get_commands` | SDK→CLI | スラッシュコマンド一覧 |
| `get_mcp_server_status` | SDK→CLI | MCP サーバー状態 |
| `set_mcp_servers` | SDK→CLI | MCP サーバー設定 |

**メッセージタイプ（CLI→SDK ストリーム）:**

| タイプ | 説明 |
|--------|------|
| `SDKAssistantMessage` | Claude の応答 |
| `SDKUserMessage` | ユーザー入力のエコー |
| `SDKResultMessage` | 最終結果（コスト・使用量・所要時間） |
| `SDKSystemMessage` | 初期化メッセージ（session_id、ツール一覧等） |
| `SDKPartialAssistantMessage` | ストリーミング途中コンテンツ |
| `SDKCompactBoundaryMessage` | コンテキスト圧縮境界 |

### 2.3 TypeScript SDK の主要 API

```typescript
// ワンショットクエリ
function query({
  prompt: string | AsyncIterable<SDKUserMessage>,
  options?: Options
}): Query  // extends AsyncGenerator<SDKMessage, void>

// セッションベース（V2 プレビュー）
const session = unstable_v2_createSession({ model: 'claude-opus-4-6' });
await session.send('Hello!');
for await (const msg of session.stream()) { ... }
```

**Query オブジェクトの操作メソッド:**
- `interrupt()` - 処理中断
- `rewindFiles(userMessageUuid)` - ファイル復元
- `setPermissionMode(mode)` - 権限モード変更
- `setModel(model)` - モデル変更
- `supportedCommands()` - コマンド一覧
- `supportedModels()` - モデル一覧
- `mcpServerStatus()` - MCP 状態

**Options の主要フィールド:**
- `model` - Claude モデル指定
- `systemPrompt` - システムプロンプト
- `allowedTools` / `disallowedTools` - ツールフィルタ
- `agents` - サブエージェント定義
- `mcpServers` - MCP サーバー設定
- `hooks` - ライフサイクルフック
- `permissionMode` - 権限モード
- `canUseTool` - カスタム権限ハンドラ
- `maxTurns` / `maxBudgetUsd` - 制限
- `resume` - セッション再開
- `cwd` - 作業ディレクトリ
- `outputFormat` - 構造化出力スキーマ

### 2.4 サブエージェントシステム

サブエージェントは `Task` ツール経由で起動される。CLI 内部で管理され、SDK 側から見ると追加の OS プロセスではない。

```typescript
agents: {
  'code-reviewer': {
    description: 'Expert code reviewer',
    prompt: 'You are a code review specialist...',
    tools: ['Read', 'Grep', 'Glob'],
    model: 'sonnet'
  }
}
```

制約: サブエージェントはさらにサブエージェントを起動できない（`Task` ツール不可）。

### 2.5 パフォーマンス特性

| 項目 | 値 |
|------|-----|
| コールドスタート | ~12 秒 |
| セッション再利用時 | ~2-3 秒（77%改善） |
| セッション有効期限 | 非活動 10 分 |
| 初期化タイムアウト | 60 秒 |
| Hook タイムアウト | 30 秒 |

## 3. 技術的実現可能性分析

### 3.1 アプローチ比較

| アプローチ | 概要 | 判定 |
|-----------|------|------|
| **A: TS SDK ラップ** | Swift→Node.js(TS SDK)→CLI | ❌ 二重間接・不要な複雑さ |
| **B: CLI 直接制御** | Swift→CLI（JSONL プロトコル実装） | ✅ **推奨** |
| **C: API 直接実装** | Claude API を直接呼び、ツール実行も自前実装 | ❌ 膨大な工数・目的外 |

**Approach B を推奨する根拠:**
- Go 言語で同アプローチの実装が既に存在（[dotcommander/agent-sdk-go](https://pkg.go.dev/github.com/dotcommander/agent-sdk-go/claude/subprocess)）
- Swift は Foundation.Process でサブプロセス制御に十分な機能を持つ
- JSONL プロトコルは Swift Codable で自然にモデリング可能
- AsyncThrowingStream がストリーミングメッセージに完全対応

### 3.2 Swift 技術要素の適合性評価

| 技術要素 | Swift での対応 | 実現性 |
|---------|---------------|--------|
| サブプロセス起動 | `Foundation.Process` / Swift 6 `Subprocess` | ✅ 問題なし |
| stdin/stdout パイプ | `Pipe` + `FileHandle` | ✅ 問題なし |
| JSONL エンコード/デコード | `JSONEncoder` / `JSONDecoder` + `Codable` | ✅ 問題なし |
| ストリーミングメッセージ | `AsyncThrowingStream<Message, Error>` | ✅ 完全対応 |
| 双方向制御（permission） | Swift Concurrency Task + Actor | ✅ 要注意設計 |
| エラーハンドリング | Swift Error protocol + typed throws | ✅ 問題なし |
| リソース管理 | `deinit` + Task cancellation | ✅ 問題なし |
| 並行セッション管理 | Actor + TaskGroup | ✅ 問題なし |

### 3.3 依存関係

**ランタイム依存:**
- Node.js 18+（または Bun/Deno）— CLI 実行に必須
- `@anthropic-ai/claude-agent-sdk` npm パッケージ（CLI バイナリ同梱）

**Swift パッケージ依存:**
- Foundation のみ（サードパーティ依存なし）

### 3.4 プラットフォーム制約

| プラットフォーム | 対応 | 理由 |
|----------------|------|------|
| macOS 15+ | ✅ | Node.js 利用可・Process API 利用可 |
| Linux | ✅ | Node.js 利用可・Process API 利用可 |
| iOS | ❌ | Node.js ランタイム不可 |
| watchOS / tvOS | ❌ | サブプロセス起動不可 |

→ **ターゲット: macOS + Linux（Server-side Swift）**

## 4. 想定 Swift API デザイン

### 4.1 Protocol 定義（利用者が依存する安定 API）

```swift
/// 通信層の抽象（Claude Code 固有の概念を含まない）
public protocol AgentTransport: Sendable {
    func connect() async throws
    func write(_ message: Data) async throws
    func messages() -> AsyncThrowingStream<Data, Error>
    func close() async throws
    var isReady: Bool { get }
}

/// 操作層の抽象
public protocol AgentClient: Sendable {
    associatedtype Session: AgentSession
    func query(prompt: String, options: QueryOptions) -> AsyncThrowingStream<AgentMessage, Error>
    func createSession(options: SessionOptions) async throws -> Session
    func resumeSession(id: String, options: SessionOptions) async throws -> Session
}

/// セッション層の抽象
public protocol AgentSession: Sendable {
    var id: String { get }
    func send(_ message: String) -> AsyncThrowingStream<AgentMessage, Error>
    func interrupt() async throws
    func close() async throws
}
```

### 4.2 コンビニエンス API（DI 不要、最速で使い始められる）

```swift
import AgentSDK

// デフォルトの Claude Code 実装をワンライナーで利用
for try await message in AgentSDK.query(
    prompt: "このコードを説明して",
    options: .init(
        model: .opus,
        systemPrompt: "あなたはコードレビューの専門家です",
        allowedTools: [.read, .grep, .glob],
        permissionMode: .bypassPermissions,
        cwd: "/path/to/project"
    )
) {
    switch message {
    case .assistant(let msg): print(msg.content)
    case .result(let result): print("コスト: $\(result.costUsd)")
    case .system(let sys):    print("セッション: \(sys.sessionId)")
    }
}
```

### 4.3 明示的 DI（テスト・カスタムバックエンド）

```swift
import AgentSDK
import AgentSDKClaudeCode  // 具象モジュール

// Transport を明示的に構成して Client に注入
let transport = ClaudeCodeTransport(
    cliPath: "/custom/path/to/cli.js",
    runtime: .bun
)
let client = ClaudeCodeClient(transport: transport)

let session = try await client.createSession(options: .init(model: .opus))
for try await message in session.send("こんにちは！") {
    // ストリーミングメッセージ処理
}
// セッション再利用（コールドスタートなし）
for try await message in session.send("前の内容を踏まえて...") {
    // ...
}
await session.close()
```

### 4.4 テスト用モック

```swift
import AgentSDK
import AgentSDKTesting  // テスト支援モジュール

// 事前定義した応答を返す MockTransport を注入
let mock = MockTransport(responses: [
    .system(sessionId: "test-session"),
    .assistant(content: "Hello!"),
    .result(costUsd: 0.01)
])
let client: any AgentClient = ClaudeCodeClient(transport: mock)

for try await msg in client.query(prompt: "Test") {
    // テストアサーション
}
// 送信されたメッセージを検証
XCTAssertEqual(mock.sentMessages.count, 1)
```

### 4.5 サブエージェント定義

```swift
for try await msg in AgentSDK.query(
    prompt: "このPRをレビューして",
    options: .init(
        agents: [
            "code-reviewer": AgentDefinition(
                description: "コードレビューの専門家",
                prompt: "あなたはコードレビューの専門家です...",
                tools: [.read, .grep, .glob],
                model: .sonnet
            )
        ]
    )
) { /* ... */ }
```

### 4.6 カスタム権限ハンドラ

```swift
for try await msg in AgentSDK.query(
    prompt: "テストを実行して",
    options: .init(
        permissionMode: .default,
        canUseTool: { toolName, input, serverInfo in
            switch toolName {
            case "Bash":  return .deny(reason: "Bash not allowed")
            default:      return .allow
            }
        }
    )
) { /* ... */ }
```

## 5. 内部アーキテクチャ（推奨）

### 設計方針: 完全プロトコル指向 + DI

公式 Python SDK の `Transport` ABC パターンを参考に、**完全プロトコル指向設計**を採用する。
Claude Code CLI 実装は DI される具象の1つに過ぎない。

```
┌───────────────────────────────────────────────────┐
│                Swift Application                   │
│   利用者は protocol に対してプログラミングする       │
└─────────────────────┬─────────────────────────────┘
                      │
┌─────────────────────▼─────────────────────────────┐
│         Protocol Layer（安定・変更なし）             │
│                                                     │
│   protocol AgentTransport  ← 通信の抽象             │
│     connect() / write() / messages() / close()      │
│                                                     │
│   protocol AgentClient     ← 操作の抽象             │
│     query() / createSession() / resumeSession()     │
│                                                     │
│   protocol AgentSession    ← セッションの抽象       │
│     send() / interrupt() / close()                  │
│                                                     │
│   AgentMessage (enum)      ← 共通メッセージ型       │
│   AgentOptions (struct)    ← 共通設定型             │
└─────────────────────┬─────────────────────────────┘
                      │ DI（コンストラクタ注入）
┌─────────────────────▼─────────────────────────────┐
│     Concrete: ClaudeCode（CLI 更新時ここだけ変更）   │
│                                                     │
│   ClaudeCodeTransport: AgentTransport               │
│     - CLIProcess (subprocess lifecycle)             │
│     - JSONLTransport (JSONL encode/decode)          │
│     - Handshake (initialization protocol)           │
│                                                     │
│   ClaudeCodeClient<T: AgentTransport>: AgentClient   │
│     init(transport: T)                    ← DI     │
│     - MessageRouter (bidirectional routing)         │
│     - ControlProtocol (request/response)            │
│                                                     │
│   ClaudeCodeSession: AgentSession                   │
└─────────────────────┬─────────────────────────────┘
                      │ stdin/stdout (JSONL)
┌─────────────────────▼─────────────────────────────┐
│   Claude Code CLI (cli.js) / Node.js                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│   MockTransport: AgentTransport  ← テスト用         │
│   (将来) DirectAPITransport: AgentTransport          │
└─────────────────────────────────────────────────────┘
```

### 5.1 先行事例との対応

| SDK | Transport 抽象 | Client 抽象 | DI 方式 |
|-----|---------------|------------|---------|
| Python（公式） | `Transport` ABC | `ClaudeSDKClient(transport:)` | コンストラクタ注入 |
| Go（community） | `Transport` interface | `Client` interface (5 sub-interface) | Factory + helper |
| **Swift（本 SDK）** | `AgentTransport` protocol | `AgentClient` protocol | コンストラクタ注入 |

Python SDK のシンプルなコンストラクタ注入パターンを採用。Go SDK の ISP 5分割は過剰と判断。

### 5.2 利用イメージ

```swift
// ① コンビニエンス API（DI 不要、デフォルト Claude Code 実装）
for try await msg in AgentSDK.query(prompt: "Hello", options: .init(model: .opus)) {
    // ...
}

// ② 明示的 DI（テスト・カスタムバックエンド）
let transport = ClaudeCodeTransport(cliPath: "/custom/path", runtime: .bun)
let client = ClaudeCodeClient(transport: transport)
for try await msg in client.query(prompt: "Hello") {
    // ...
}

// ③ テスト用モック
let mock = MockTransport(responses: [.assistant("Hello!"), .result(cost: 0.01)])
let client: any AgentClient = ClaudeCodeClient(transport: mock)
// テスト実行...
XCTAssertEqual(mock.sentMessages.count, 1)
```

### 5.3 CLI バイナリ探索（ClaudeCodeTransport 内部）

```swift
// ClaudeCodeTransport 固有のロジック（protocol 層には含まない）
struct CLILocator {
    static func locate() throws -> URL {
        // 1. 明示的パス指定（options.pathToClaudeCodeExecutable）
        // 2. 環境変数 CLAUDE_CODE_CLI_PATH
        // 3. ./node_modules/@anthropic-ai/claude-agent-sdk/cli.js
        // 4. グローバル npm パッケージ
        // 5. which claude（システム PATH）
        throw AgentSDKError.cliNotFound(searchedPaths: [...])
    }
}
```

## 6. リスク分析

### 6.1 クリティカルリスク

| リスク | 深刻度 | 発生確率 | 緩和策 |
|--------|--------|----------|--------|
| **プロトコル破壊的変更** | 高 | 中 | バージョンロック + 互換性テスト |
| **Node.js 依存** | 中 | 確定 | 明示的に制約として受容 |
| **ライセンス制約** | 中 | 低 | CLI を同梱せず、ユーザーインストールに委ねる |

### 6.2 運用リスク

| リスク | 深刻度 | 発生確率 | 緩和策 |
|--------|--------|----------|--------|
| **コールドスタート 12秒** | 中 | 確定 | セッション再利用・プリウォーム |
| **セッション期限切れ** | 低 | 中 | 自動再接続 + セッション ID 永続化 |
| **CLI プロセスクラッシュ** | 中 | 低 | terminationHandler + 自動リトライ |

### 6.3 Go SDK（先行事例）から学べること

[dotcommander/agent-sdk-go](https://pkg.go.dev/github.com/dotcommander/agent-sdk-go/claude/subprocess) が同じアプローチ（Approach B）で実装済み。
- プロトコルの逆算・実装が可能であることを実証
- バージョンピンニングで安定性を確保
- stdin/stdout JSONL プロトコルの全量が明らかになっている

## 7. 実装フェーズ（概算）

| Phase | 内容 | 依存 |
|-------|------|------|
| **Phase 0** | Protocol 定義（AgentTransport / AgentClient / AgentSession / AgentMessage） | なし |
| **Phase 1** | ClaudeCodeTransport（CLIProcess + JSONL + Handshake） | Phase 0 |
| **Phase 2** | ClaudeCodeClient + ワンショット query() | Phase 0, 1 |
| **Phase 3** | ClaudeCodeSession + resume | Phase 2 |
| **Phase 4** | サブエージェント定義 + MCP 設定 | Phase 2 |
| **Phase 5** | 双方向 Permission ハンドリング + Hooks | Phase 2 |
| **Phase 6** | MockTransport + テストユーティリティ | Phase 0 |

## 8. 結論

### 技術的実現可能性: **実現可能 ✅**

Swift Agent SDK は、Approach B（CLI 直接制御）+ 完全プロトコル指向設計により技術的に実現可能である。

**根拠:**
1. Go 言語での先行実装が実証済み
2. 公式 Python SDK が Transport ABC + コンストラクタ注入パターンを採用しており、Swift protocol で同パターンが自然に実装可能
3. Swift の Process API + Codable + AsyncSequence が JSONL プロトコルに完全対応
4. Swift Concurrency が双方向非同期通信に最適
5. サードパーティ依存なしで実装可能

**設計方針:**
1. **完全プロトコル指向:** 公開 API はすべて Swift protocol（AgentTransport / AgentClient / AgentSession）
2. **Claude Code は DI される具象:** ClaudeCode* 型は protocol 準拠の1実装
3. **最小追従コスト:** CLI 更新時の変更は ClaudeCode* 型内に局所化

**主要な制約:**
1. Node.js ランタイムが必須（ターゲットは macOS + Linux のみ）
2. JSONL プロトコルは非公開内部仕様であり、バージョン間での互換性保証はない
3. コールドスタート ~12 秒は SDK レイヤーでは解決不可（セッション再利用で緩和）

**推奨:** 次フェーズとして Design Spec（03）へ進み、protocol 定義・具象型設計・モジュール分割・テスト戦略を策定する。
