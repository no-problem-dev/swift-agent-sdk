---
title: "Swift Agent SDK - Phase/Wave 構造"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan, phase-wave]
references:
  - ./00_index.md
  - ../03_design_spec/01_architecture.md
  - ../03_design_spec/04_component_architecture.md
---

# Phase/Wave 構造

## Intent（意図）

全実装を Phase/Wave 階層に分割し、各 Wave の成果物・依存関係・並列化可能性を明確にする。
実装者が「今何を作るか」「次に何を作るか」を一目で把握できる構造を提供する。

---

## Phase/Wave 全体図

```
Phase 1: 基盤構築
├── Wave 1-1: Package.swift + ディレクトリ構造
├── Wave 1-2: Protocol 層型定義（並列可能: 3 ファイルグループ）
│   ├── [A] Protocols: AgentTransport, AgentClient, AgentSession
│   ├── [B] Models: AgentMessage, ContentBlock, JSONValue, 補助型
│   └── [C] Errors: AgentSDKError
└── Wave 1-3: Protocol 層 Unit Tests + Convenience API スタブ
    ├── AgentMessage テスト
    ├── QueryOptions テスト
    ├── AgentSDKError テスト
    └── AgentSDK enum スタブ

Phase 2: CLI 具象 内部コンポーネント
├── Wave 2-1: 低レベル基盤（並列可能: 3 コンポーネント）
│   ├── [A] JSONLCodec（エンコード/デコード）
│   ├── [B] CLILocator（CLI 探索）
│   └── [C] CLIArgBuilder（引数構成）
├── Wave 2-2: CLIProcess Actor
│   └── プロセス管理 + stdin/stdout パイプ + 状態遷移
└── Wave 2-3: JSONL プロトコル型 + Handshake
    ├── CLIMessage / SDKMessage / ControlMessage 型定義
    └── Handshake struct

Phase 3: クライアント・セッション実装
├── Wave 3-1: MessageRouter Actor
│   └── メッセージ分類 + ストリーム配信 + 制御リクエスト管理
├── Wave 3-2: ClaudeCodeTransport + ClaudeCodeClient（並列可能: 2 コンポーネント）
│   ├── [A] ClaudeCodeTransport: AgentTransport 準拠
│   └── [B] ClaudeCodeClient<T>: AgentClient 準拠
└── Wave 3-3: ClaudeCodeSession + Convenience API 完成
    ├── ClaudeCodeSession: AgentSession 準拠
    └── AgentSDK.query() / createSession() / resumeSession() 実装

Phase 4: テスト・統合・ドキュメント
├── Wave 4-1: AgentSDKTesting モジュール（並列可能: 2 コンポーネント）
│   ├── [A] MockTransport
│   └── [B] MockFixtures
├── Wave 4-2: 統合テスト + 具象層ユニットテスト
│   ├── ClaudeCodeClientTests（MockTransport 使用）
│   ├── ClaudeCodeTransportTests
│   └── IntegrationTests（実 CLI、CI 用）
└── Wave 4-3: ドキュメント + リリース準備
    ├── README.md
    ├── DocC コメント整備
    └── CI 設定（GitHub Actions）
```

---

## Phase 1: 基盤構築

### Wave 1-1: Package.swift + ディレクトリ構造

| 項目 | 内容 |
|------|------|
| **目標** | SwiftPM パッケージとして `swift build` が成功する状態を作る |
| **成果物** | Package.swift, Sources/ ディレクトリ構造, 各モジュールの空ファイル |
| **依存** | なし（最初の Wave） |
| **並列化** | 不可（後続 Wave の基盤） |
| **検証** | `swift build` が成功する |

**具体的な作業:**
1. `Package.swift` を作成（`04_component_architecture.md#4` の定義に準拠）
2. `Sources/AgentSDK/`, `Sources/AgentSDKClaudeCode/`, `Sources/AgentSDKTesting/` ディレクトリを作成
3. `Tests/AgentSDKTests/`, `Tests/AgentSDKClaudeCodeTests/`, `Tests/IntegrationTests/` ディレクトリを作成
4. 各ターゲットにプレースホルダファイルを配置し、ビルド成功を確認

### Wave 1-2: Protocol 層型定義

| 項目 | 内容 |
|------|------|
| **目標** | AgentSDK モジュールの全 public 型を定義する |
| **成果物** | Protocols/, Models/, Errors/ 配下の全ファイル |
| **依存** | Wave 1-1 |
| **並列化** | [A][B][C] は並列実装可能 |
| **検証** | `swift build` 成功、全 public 型が import AgentSDK で利用可能 |

**[A] Protocols（3 ファイル）:**

| ファイル | Protocol | 主要メソッド | 参照 |
|---------|----------|------------|------|
| `AgentTransport.swift` | `AgentTransport` | `connect()`, `close()`, `write(_:)`, `messages()` | `03_layer_architecture.md#Protocol Layer` |
| `AgentClient.swift` | `AgentClient` | `query(prompt:options:)`, `createSession(options:)`, `resumeSession(id:options:)` | `08_api_spec.md#2.2` |
| `AgentSession.swift` | `AgentSession` | `send(_:)`, `interrupt()`, `close()` | `08_api_spec.md#3.1` |

**[B] Models（8 ファイル）:**

| ファイル | 型 | 参照 |
|---------|-----|------|
| `AgentMessage.swift` | `AgentMessage` enum + SystemInfo, AssistantInfo, PartialInfo, ResultInfo | `05_data_model.md#2.1-2.7` |
| `ContentBlock.swift` | `ContentBlock` enum + ToolUse, ToolResult | `05_data_model.md#2.4` |
| `JSONValue.swift` | `JSONValue` enum | `05_data_model.md#2.5` |
| `QueryOptions.swift` | `QueryOptions` struct | `05_data_model.md#2.8`, `08_api_spec.md#4` |
| `SessionOptions.swift` | `SessionOptions` struct | `05_data_model.md#2.9` |
| `AgentDefinition.swift` | `AgentDefinition` struct | `05_data_model.md#2.10` |
| `PermissionMode.swift` | `PermissionMode` enum, `PermissionDecision` enum | `05_data_model.md#2.10` |
| `MCPServerConfig.swift` | `MCPServerConfig` struct, `MCPServerInfo`, `ToolInfo`, `CommandInfo`, `ModelInfo` | `05_data_model.md#2.2`, `08_api_spec.md#3.2` |

**[C] Errors（1 ファイル）:**

| ファイル | 型 | 参照 |
|---------|-----|------|
| `AgentSDKError.swift` | `AgentSDKError` enum + LocalizedError 準拠 | `05_data_model.md#3` |

### Wave 1-3: Protocol 層 Unit Tests + Convenience API スタブ

| 項目 | 内容 |
|------|------|
| **目標** | Protocol 層の全型の初期化・Codable・Equatable をテスト、AgentSDK namespace を定義 |
| **成果物** | Tests/AgentSDKTests/ 配下のテストファイル、AgentSDK.swift |
| **依存** | Wave 1-2 |
| **並列化** | テストファイルは並列作成可能 |
| **検証** | `swift test --filter AgentSDKTests` 全パス |

**テスト対象:**

| テストファイル | テスト内容 |
|--------------|-----------|
| `AgentMessageTests.swift` | 各 case の初期化、Codable round-trip、パターンマッチング |
| `QueryOptionsTests.swift` | デフォルト値、全パラメータ指定 |
| `AgentSDKErrorTests.swift` | LocalizedError メッセージ品質、全 case 網羅 |

**AgentSDK.swift（スタブ）:**
- `public enum AgentSDK {}` を定義
- `query()` / `createSession()` / `resumeSession()` のシグネチャのみ（`fatalError("not implemented")` で仮実装）
- Phase 3 Wave 3-3 で本実装を差し込む

---

## Phase 2: CLI 具象 内部コンポーネント

### Wave 2-1: 低レベル基盤

| 項目 | 内容 |
|------|------|
| **目標** | CLI 操作の基盤コンポーネントを実装する |
| **成果物** | JSONLCodec, CLILocator, CLIArgBuilder + 各テスト |
| **依存** | Phase 1 完了 |
| **並列化** | [A][B][C] は並列実装可能 |
| **検証** | 各コンポーネントの Unit Test 全パス |

**[A] JSONLCodec:**

| メソッド | テスト観点 |
|---------|-----------|
| `encode<T: Encodable>(_ value: T) -> Data` | 正常エンコード、末尾 `\n` の存在、UTF-8 検証 |
| `decode<T: Decodable>(_ line: Data) -> T` | 正常デコード、不正 JSON 時のエラー |
| `decodeMessageType(_ line: Data) -> String` | `type` フィールドの先読み、`type` 未存在時のエラー |

参照: `04_component_architecture.md#2.2`

**[B] CLILocator:**

| テスト観点 | 内容 |
|-----------|------|
| ユーザー指定パス | 存在するパス → 成功、存在しないパス → エラー |
| 環境変数 | `CLAUDE_CODE_CLI_PATH` 設定時の動作 |
| ローカル npm | `./node_modules/` パスの探索 |
| グローバル npm | `npm root -g` の出力パース |
| which claude | PATH 上の `claude` コマンド検出 |
| 全探索失敗 | `AgentSDKError.cliNotFound` の検証（searchedPaths 含む） |

参照: `04_component_architecture.md#2.5`, `06_auth_flow.md#3`

**[C] CLIArgBuilder:**

| テスト観点 | 内容 |
|-----------|------|
| デフォルト引数 | `--output-format stream-json --input-format stream-json --verbose` |
| オプション引数 | `--system-prompt`, `--permission-mode`, `--resume`, `--max-turns` |
| agents/mcpServers | JSON シリアライズした引数 |

参照: `04_component_architecture.md#2.6`

### Wave 2-2: CLIProcess Actor

| 項目 | 内容 |
|------|------|
| **目標** | CLI サブプロセスの起動・通信・終了を管理する Actor を実装 |
| **成果物** | CLIProcess.swift + CLIProcessTests.swift |
| **依存** | Wave 2-1（CLILocator、CLIArgBuilder を使用） |
| **並列化** | 不可（単一コンポーネント） |
| **検証** | 状態遷移テスト、stdin/stdout 通信テスト、プロセス終了検知テスト |

**状態遷移テスト:**

| テストケース | 期待動作 |
|------------|---------|
| Idle → start() → Running | プロセス起動成功 |
| Running → terminate() → Terminated | SIGTERM で終了 |
| Running → (process exits) → Terminated | プロセス自然終了を検知 |
| Idle → terminate() | 無視（エラーにならない） |

**通信テスト:**
- `writeToStdin` で書き込んだデータが子プロセスの stdin に届く
- 子プロセスの stdout 出力が `stdoutStream()` で受信できる
- stderr 内容が `stderrContent()` で取得できる

参照: `04_component_architecture.md#2.1`

### Wave 2-3: JSONL プロトコル型 + Handshake

| 項目 | 内容 |
|------|------|
| **目標** | CLI↔SDK 間の内部メッセージ型と初期化ハンドシェイクを実装 |
| **成果物** | CLIMessage.swift, SDKMessage.swift, ControlMessage.swift, Handshake.swift + テスト |
| **依存** | Wave 2-1（JSONLCodec を使用）、Wave 2-2（CLIProcess を使用） |
| **並列化** | プロトコル型定義とHandshakeは順次（Handshakeがプロトコル型に依存） |
| **検証** | JSONL メッセージの round-trip テスト、Handshake フローのモックテスト |

**CLIMessage デコードテスト:**

| JSONL 入力 | 期待される CLIMessage case |
|-----------|--------------------------|
| `{"type":"initialize_ready"}` | `.initializeReady` |
| `{"type":"system","session_id":"abc",...}` | `.system(CLISystemMessage)` |
| `{"type":"assistant","content":[...]}` | `.assistant(CLIAssistantMessage)` |
| `{"type":"result","result":"...","cost_usd":0.01,...}` | `.result(CLIResultMessage)` |
| `{"type":"control_request","request":{...}}` | `.controlRequest(CLIControlRequest)` |
| `{"type":"unknown_future_type"}` | `.unknown(type: "unknown_future_type")` |

**Handshake テスト:**

| テストケース | 期待動作 |
|------------|---------|
| 正常系 | initialize_ready → InitializeRequest 送信 → SystemMessage 受信 |
| タイムアウト | 60 秒以内に initialize_ready が来ない → `initializationTimeout` |
| 不正応答 | SystemMessage 以外が来た → `protocolError` |

参照: `05_data_model.md#4`, `06_auth_flow.md#1`

---

## Phase 3: クライアント・セッション実装

### Wave 3-1: MessageRouter Actor

| 項目 | 内容 |
|------|------|
| **目標** | 双方向メッセージルーティングを実装する |
| **成果物** | MessageRouter.swift + MessageRouterTests.swift |
| **依存** | Phase 2 完了（プロトコル型 + JSONLCodec） |
| **並列化** | 不可（単一コンポーネント） |
| **検証** | メッセージ分類テスト、制御リクエスト管理テスト、タイムアウトテスト |

**MessageRouter の責務:**

| 機能 | 実装詳細 | 参照 |
|------|---------|------|
| メッセージ分類 | CLIMessage の type でルーティング | `04_component_architecture.md#2.4` |
| ストリーム配信 | assistant/result/system を AsyncThrowingStream に yield | `04_component_architecture.md#2.4` |
| 制御リクエスト (CLI→SDK) | `can_use_tool` をカスタムハンドラにルーティング | `07_payment_flow.md#1` |
| 制御リクエスト (SDK→CLI) | request_id + CheckedContinuation で応答待機 | `07_payment_flow.md#3` |
| タイムアウト | TaskGroup で 30 秒タイムアウト | `07_payment_flow.md#3.3` |

**テスト観点:**

| テストケース | 期待動作 |
|------------|---------|
| assistant メッセージ受信 | ストリームに `.assistant` が yield される |
| result メッセージ受信 | ストリームに `.result` が yield される |
| can_use_tool → allow | ハンドラ呼び出し → allow レスポンス送信 |
| can_use_tool → deny | ハンドラ呼び出し → deny レスポンス送信 |
| SDK→CLI 制御リクエスト | request_id 生成 → 送信 → レスポンス受信 → continuation resume |
| 制御レスポンスタイムアウト | 30 秒後に `controlRequestTimeout` |

### Wave 3-2: ClaudeCodeTransport + ClaudeCodeClient

| 項目 | 内容 |
|------|------|
| **目標** | AgentTransport と AgentClient の具象実装を完成させる |
| **成果物** | ClaudeCodeTransport.swift, ClaudeCodeClient.swift + テスト |
| **依存** | Wave 3-1（MessageRouter）、Phase 2（CLIProcess, Handshake 等） |
| **並列化** | [A][B] は並列実装可能（ただし B は A に軽度依存するため、A 優先） |
| **検証** | Transport の接続/切断テスト、Client の query/session API テスト |

**[A] ClaudeCodeTransport:**

| メソッド | 実装内容 |
|---------|---------|
| `connect()` | CLILocator → CLIProcess.start() → Handshake → isReady = true |
| `close()` | CLIProcess.terminate() → isReady = false |
| `write(_ data: Data)` | CLIProcess.writeToStdin(data) |
| `messages()` | CLIProcess.stdoutStream() を CLIMessage にデコードして返す |

参照: `08_api_spec.md#2.1`

**[B] ClaudeCodeClient\<T\>:**

| メソッド | 実装内容 |
|---------|---------|
| `query(prompt:options:)` | Transport 接続 → UserMessage 送信 → MessageRouter でストリーム → Transport 切断 |
| `createSession(options:)` | Transport 接続 → ClaudeCodeSession を生成して返す |
| `resumeSession(id:options:)` | Transport 接続（--resume 付き） → ClaudeCodeSession を生成して返す |

参照: `08_api_spec.md#2.2`

### Wave 3-3: ClaudeCodeSession + Convenience API

| 項目 | 内容 |
|------|------|
| **目標** | Session 実装と、AgentSDK convenience API を完成させる |
| **成果物** | ClaudeCodeSession.swift, AgentSDK.swift（本実装）+ テスト |
| **依存** | Wave 3-2（Transport, Client） |
| **並列化** | Session → Convenience API の順（直列） |
| **検証** | Session ライフサイクルテスト、Convenience API テスト |

**ClaudeCodeSession:**

| メソッド | 実装内容 | 参照 |
|---------|---------|------|
| `send(_:)` | UserMessage → Transport → ストリーム返却 | `08_api_spec.md#3.1` |
| `interrupt()` | interrupt 制御リクエスト送信 | `07_payment_flow.md#2.1` |
| `close()` | Transport.close() | `08_api_spec.md#3.1` |
| `setModel(_:)` | set_model 制御リクエスト | `08_api_spec.md#3.2` |
| `setPermissionMode(_:)` | set_permission_mode 制御リクエスト | `08_api_spec.md#3.2` |
| `rewindFiles(toMessageId:)` | rewind_files 制御リクエスト | `08_api_spec.md#3.2` |
| `supportedCommands()` | get_commands 制御リクエスト | `08_api_spec.md#3.2` |
| `supportedModels()` | get_models 制御リクエスト | `08_api_spec.md#3.2` |
| `mcpServerStatus()` | get_mcp_server_status 制御リクエスト | `08_api_spec.md#3.2` |
| `setMCPServers(_:)` | set_mcp_servers 制御リクエスト | `08_api_spec.md#3.2` |

**AgentSDK convenience API（本実装）:**
- `AgentSDK.query()` → 内部で `ClaudeCodeTransport` + `ClaudeCodeClient` を生成して実行
- `AgentSDK.createSession()` → 同上
- `AgentSDK.resumeSession()` → 同上

参照: `08_api_spec.md#1`

---

## Phase 4: テスト・統合・ドキュメント

### Wave 4-1: AgentSDKTesting モジュール

| 項目 | 内容 |
|------|------|
| **目標** | テスト支援モジュールを完成させる |
| **成果物** | MockTransport.swift, MockFixtures.swift |
| **依存** | Phase 1（Protocol 層） |
| **並列化** | [A][B] は並列実装可能 |
| **検証** | MockTransport を使ったテストが成功する |

**[A] MockTransport:**

| 機能 | 実装内容 | 参照 |
|------|---------|------|
| 事前定義応答 | `init(responses:)` で応答シーケンスを設定 | `08_api_spec.md#7.1` |
| メッセージ記録 | `write()` 呼び出しを `sentMessages` に蓄積 | `08_api_spec.md#7.1` |
| 接続状態 | `simulatedIsReady` で制御 | `08_api_spec.md#7.1` |

**[B] MockFixtures:**

| ファクトリ | 返す応答シーケンス | 参照 |
|-----------|------------------|------|
| `simpleSuccess(text:)` | system → assistant → result | `08_api_spec.md#7.2` |
| `withToolUse(toolName:result:)` | system → assistant(toolUse) → assistant(toolResult) → result | `08_api_spec.md#7.2` |
| `protocolError()` | エラーを含むシーケンス | `08_api_spec.md#7.2` |

### Wave 4-2: 統合テスト + 具象層ユニットテスト

| 項目 | 内容 |
|------|------|
| **目標** | MockTransport を使った Client テスト + 実 CLI との統合テスト |
| **成果物** | ClaudeCodeClientTests, ClaudeCodeTransportTests, EndToEndTests |
| **依存** | Wave 4-1（MockTransport）、Phase 3（Client/Session） |
| **並列化** | Mock テストと統合テストは並列実行可能 |
| **検証** | `swift test` 全パス（統合テストは CI 環境で実行） |

**MockTransport を使ったテスト:**

| テストケース | 検証内容 |
|------------|---------|
| ワンショットクエリ成功 | query() → stream → result |
| セッション作成・送信 | createSession() → send() → messages |
| セッション再開 | resumeSession() → send() → messages |
| 権限ハンドラ呼び出し | canUseTool が呼ばれ、allow/deny が伝播 |
| エラー伝播 | Transport エラーが stream に throw される |

**統合テスト（EndToEndTests）:**
- 環境変数 `AGENT_SDK_INTEGRATION_TEST=1` で有効化
- 実際の Claude Code CLI との通信テスト（サブスクリプション認証済が前提、API Key 不使用）
- Hello World クエリ成功、セッション作成・再開

### Wave 4-3: ドキュメント + リリース準備

| 項目 | 内容 |
|------|------|
| **目標** | 利用者向けドキュメントと CI を整備する |
| **成果物** | README.md, DocC コメント, .github/workflows/ |
| **依存** | Wave 4-2（全テスト完了後） |
| **並列化** | README と CI 設定は並列作成可能 |
| **検証** | README の使用例が動作する、CI が green |

**README 構成:**
1. 概要（7 行 Hello World）
2. インストール（SwiftPM dependency 追加）
3. 前提条件（Node.js 18+, Claude Code CLI, サブスクリプション認証済 `claude login`）
4. 使用例（query, session, sub-agents, permissions）
5. カスタマイズ（DI, MockTransport）
6. API リファレンス（DocC リンク）
7. バージョン互換表（SDK ↔ CLI バージョン）

**CI 構成:**

| ワークフロー | トリガー | 内容 |
|-------------|---------|------|
| `test.yml` | push / PR | `swift test`（Unit + AgentSDKClaudeCode） |
| `integration.yml` | 手動 / 定期 | 統合テスト（Node.js + CLI インストール） |

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
