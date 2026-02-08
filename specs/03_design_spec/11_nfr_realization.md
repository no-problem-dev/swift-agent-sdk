---
title: "Swift Agent SDK - NFR 実現方式"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, nfr]
references:
  - ./00_index.md
  - ../02_requirements/04_non_functional_requirements.md
---

# NFR 実現方式

## Intent（意図）

Requirements の非機能要件（NFR-001〜NFR-007）を具体的にどう実現するかを設計する。
各 NFR に対して、実装方針と検証方法を示す。

---

## 1. NFR-001: パフォーマンス

### 1.1 SDK オーバーヘッド: 100ms 以内

**実現方式:**
- `Process.launch()` は同期的に fork/exec を実行（OS レベルの高速操作）
- JSONL エンコード/デコードは `JSONEncoder`/`JSONDecoder` の標準実装で 1ms 以内
- `AsyncThrowingStream` の yield はメモリコピーなし（値型の move semantics）

**検証方法:**
```swift
func testSDKOverhead() async throws {
    let start = ContinuousClock.now
    let transport = ClaudeCodeTransport()
    try await transport.connect()
    let elapsed = ContinuousClock.now - start
    // CLI のコールドスタートを除いた SDK 純粋なオーバーヘッドを計測
    // connect() 内のハンドシェイク待機時間は除外
}
```

### 1.2 JSONL パース遅延: 1ms 以内

**実現方式:**
```swift
// JSONLCodec は状態を持たない struct
// 各行を独立してデコードするため、バッファリングなし
struct JSONLCodec {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func decode<T: Decodable>(_ line: Data) throws -> T {
        try decoder.decode(T.self, from: line)
    }
}
```

**検証方法:**
```swift
func testJSONLParsePerformance() {
    let codec = JSONLCodec()
    let testData = #"{"type":"assistant","message":{"content":[{"type":"text","text":"Hello"}]}}"#.data(using: .utf8)!

    measure {
        for _ in 0..<1000 {
            _ = try! codec.decode(CLIMessage.self, from: testData)
        }
    }
    // 1000 回デコードが 1 秒以内 = 1 回あたり 1ms 以内
}
```

### 1.3 メモリ使用量: 10MB 以内

**実現方式:**
- SDK はメッセージをバッファリングしない（ストリーミング配信）
- `AsyncThrowingStream` は backpressure を自然に処理
- 大きなメッセージも参照カウントで管理（COW）

### 1.4 セッション再利用オーバーヘッド: 50ms 以内

**実現方式:**
- 既存セッションでの `send()` は stdin への書き込みのみ
- プロセス再起動なし、ハンドシェイクなし

---

## 2. NFR-002: 信頼性

### 2.1 プロセスクラッシュ検知: 100%

**実現方式:**
```swift
// CLIProcess Actor 内部
actor CLIProcess {
    private var process: Process?
    private var terminationContinuation: CheckedContinuation<Int32, Never>?

    func start(...) async throws {
        let proc = Process()
        // ...
        proc.terminationHandler = { [weak self] process in
            Task { [weak self] in
                await self?.handleTermination(exitCode: process.terminationStatus)
            }
        }
        try proc.run()
        self.process = proc
    }

    private func handleTermination(exitCode: Int32) {
        terminationContinuation?.resume(returning: exitCode)
        terminationContinuation = nil
    }
}
```

### 2.2 リソースリーク: 0 件

**実現方式:**
```swift
// ClaudeCodeSession の deinit でクリーンアップ
final class ClaudeCodeSession: AgentSession {
    private let transport: any AgentTransport
    private var cleanupTask: Task<Void, Never>?

    deinit {
        // deinit から async を直接呼べないため、
        // detached Task でクリーンアップ
        let transport = self.transport
        Task.detached {
            try? await transport.close()
        }
    }

    func close() async throws {
        try await transport.close()
    }
}
```

**追加の安全策:**
- `Task.cancel()` 時に `withTaskCancellationHandler` でプロセスを終了
- `Process.terminationHandler` は必ず呼ばれる（OS 保証）

### 2.3 プロトコルエラーからの復帰

**実現方式:**
```swift
// MessageRouter 内部
func routeMessage(_ data: Data) {
    do {
        let message = try codec.decode(CLIMessage.self, from: data)
        switch message {
        case .unknown(let type):
            // 未知のメッセージタイプは無視（前方互換性）
            logger?.debug("Unknown message type: \(type)")
        default:
            // 既知のメッセージをルーティング
            try await dispatch(message)
        }
    } catch {
        // デコードエラーは警告ログのみ、ストリームは継続
        logger?.warning("Failed to decode JSONL line: \(error)")
    }
}
```

---

## 3. NFR-003: 互換性

**実現方式:**
- `Package.swift` で `platforms: [.macOS(.v15)]` を指定
- Swift 6.0 の strict concurrency を有効化
- Node.js バージョンチェックは行わない（CLI 側の責務）

---

## 4. NFR-004: 保守性・追従性

### 4.1 Protocol 層の安定性

**実現方式:**
- AgentTransport / AgentClient / AgentSession に CLI 固有の概念を含めない
- メッセージ型変換は具象層（ClaudeCodeClient 内の `MessageConverter`）で行う

```swift
// 具象層の内部変換
internal struct MessageConverter {
    /// CLI raw メッセージを共通 AgentMessage に変換
    func convert(_ cliMessage: CLIMessage) -> AgentMessage? {
        switch cliMessage {
        case .system(let sys):
            return .system(SystemInfo(
                sessionId: sys.session_id,
                tools: sys.tools.map { ToolInfo(name: $0.name, description: $0.description) },
                model: sys.model,
                mcpServers: sys.mcp_servers?.map { MCPServerInfo(name: $0.name, status: $0.status) } ?? []
            ))
        case .assistant(let ast):
            return .assistant(AssistantInfo(
                content: ast.message.content.map(convertContentBlock),
                parentToolUseId: ast.parent_tool_use_id
            ))
        // ...
        }
    }
}
```

### 4.2 テストカバレッジ: 80% 以上

**実現方式:**
- Protocol 層: `AgentMessage` の Codable テスト、`AgentSDKError` のメッセージテスト
- 具象層: MockTransport を使った ClaudeCodeClient の全メソッドテスト
- JSONLCodec: 全メッセージタイプのエンコード/デコードテスト
- Handshake: タイムアウト、異常系のテスト
- MessageRouter: 権限ハンドリング、制御メッセージルーティングのテスト

---

## 5. NFR-005: セキュリティ

**実現方式:** [10_security.md](./10_security.md) を参照。

---

## 6. NFR-006: ユーザビリティ（API 設計）

### 6.1 最小コード行数: 10 行以内

```swift
// 7 行で Hello World
import AgentSDK
import AgentSDKClaudeCode

for try await message in AgentSDK.query(prompt: "Hello!") {
    if case .assistant(let info) = message {
        for block in info.content {
            if case .text(let text) = block { print(text) }
        }
    }
}
```

### 6.2 DI 不要の簡便利用

**実現方式:**
- `AgentSDK.query()` / `AgentSDK.createSession()` でデフォルト具象を自動使用
- `QueryOptions` の全パラメータにデフォルト値を設定

### 6.3 型安全性

**実現方式:**
- `AgentMessage` は enum → パターンマッチで網羅性チェック
- `PermissionMode` / `ModelSelection` は enum → 不正な値を型で排除
- `ContentBlock` は enum → テキスト/ツール使用/ツール結果を型で区別

### 6.4 Sendable 準拠

**実現方式:**
- Swift 6 の strict concurrency checking を有効化
- 全 public 型に `Sendable` 準拠を要求
- `@Sendable` クロージャで canUseTool ハンドラの安全性を保証

---

## 7. NFR-007: テスタビリティ

### 7.1 モック作成容易性: 20 行以内

```swift
// 利用者が自前でモックを作る場合（MockTransport 不使用）
struct MyMockTransport: AgentTransport {
    var isReady: Bool { true }
    func connect() async throws { }
    func write(_ data: Data) async throws { }
    func messages() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            // テスト用の応答を yield
            continuation.finish()
        }
    }
    func close() async throws { }
}
// → 12 行
```

### 7.2 CLI 不要テスト

**実現方式:**
```swift
// Node.js / CLI なしでユニットテスト
func testQueryReturnsAssistantMessage() async throws {
    let mock = MockTransport(responses: [
        .system(SystemInfo(sessionId: "s1", tools: [], model: "opus", mcpServers: [])),
        .assistant(AssistantInfo(content: [.text("Hi!")], parentToolUseId: nil)),
        .result(ResultInfo(result: "Hi!", costUsd: 0.01, durationMs: 100, inputTokens: 5, outputTokens: 2, sessionId: "s1", numTurns: 1))
    ])
    let client = ClaudeCodeClient(transport: mock)

    var messages: [AgentMessage] = []
    for try await msg in client.query(prompt: "Test") {
        messages.append(msg)
    }

    XCTAssertEqual(messages.count, 3)
    if case .assistant(let info) = messages[1] {
        XCTAssertEqual(info.content.first, .text("Hi!"))
    }
}
```

---

## Rationale（根拠）

### ストリーミング配信（バッファリングなし）

**決定:** メッセージをバッファに溜めず、受信次第 yield する

**採用理由:**
- メモリ使用量を最小化（10MB 以内の要件）
- リアルタイム性（partial メッセージの即時配信）
- backpressure は `AsyncThrowingStream` が自然に処理

### deinit + Task.detached によるクリーンアップ

**決定:** Session の `deinit` で detached Task を使ってプロセスを終了

**採用理由:**
- `deinit` は同期メソッドのため `async` を直接呼べない
- `Task.detached` でクリーンアップを非同期実行
- `close()` の明示的呼び出しが推奨だが、忘れた場合のセーフティネット

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
