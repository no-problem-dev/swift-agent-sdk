---
title: "ClaudeAgent - Phase 3: Infrastructure パッケージ実装"
created: 2026-02-08
status: draft
tags: [implementation-plan, phase3, infrastructure, claude-agent]
references:
  - ./00_index.md
  - ./01_phase_overview.md
  - ../03_design_spec/03_layer_architecture.md#Infrastructure
  - ../03_design_spec/04_component_architecture.md#Infrastructure-コンポーネント詳細
  - ../03_design_spec/05_data_model.md#永続化仕様
---

# Phase 3: Infrastructure パッケージ実装

## 目的

Domain プロトコルの具体実装を提供する。
swift-agent-sdk との連携層（AgentService）と JSON 永続化層（JSONSessionStore）を実装する。

## 前提

- Phase 2 完了（Domain のプロトコル・エンティティが確定済み）
- Phase 4 と**並列実行可能**

---

## Wave 3-1: AgentMessageMapper + AgentService 骨格

### 実装内容

#### Mappers/AgentMessageMapper.swift

SDK の `AgentMessage` を Domain の `AgentEvent` に変換する Mapper を実装する。

```
SDK 型                           →  Domain 型
AgentMessage.system              →  AgentEvent.initialized(sessionId:)
AgentMessage.partial(.text)      →  AgentEvent.partialText(_:)
AgentMessage.assistant(content)  →  AgentEvent.assistantMessage(content:)
AgentMessage.result(cost,tokens) →  AgentEvent.turnCompleted(cost:input:output:)
```

**ContentBlock → ContentItem のマッピング:**

| SDK ContentBlock | Domain ContentItem |
|-----------------|-------------------|
| `.text(String)` | `.text(String)` |
| `.toolUse(ToolUse)` | `.toolUse(ToolUseItem(id:name:input:))` |
| `.toolResult(ToolResult)` | `.toolResult(ToolResultItem(toolUseId:content:isError:))` |

**注意点:**
- `ToolUse.input` は `[String: AnyCodable]` 型。表示用に `[String: String]` に変換する（`String(describing:)` で文字列化）
- マッピングで未知の ContentBlock が来た場合は無視する（将来の SDK 拡張対策）

#### Services/AgentService.swift（骨格のみ）

`AgentServiceProtocol` に準拠した struct を作成する。
この Wave ではメソッドの骨格（`fatalError("Not implemented")` で一旦配置）のみ。

### Unit Test（TDD）

| テストファイル | テスト内容 |
|-------------|----------|
| `AgentMessageMapperTests.swift` | 各 AgentMessage → AgentEvent の変換テスト |

### 完了基準

- [ ] AgentMessageMapper が全マッピングケースを網羅
- [ ] AgentService が AgentServiceProtocol に準拠（コンパイル成功）
- [ ] Mapper テストパス

---

## Wave 3-2: JSONSessionStore 実装

### 実装内容

`specs/03_design_spec/04_component_architecture.md#JSONSessionStore` に準拠して実装する。

#### Persistence/JSONSessionStore.swift

```swift
struct JSONSessionStore: SessionStoreProtocol {
    private let baseURL: URL

    init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("ClaudeAgent")
    }
}
```

**実装ポイント:**
- `loadAll()`: ファイル未存在時は空配列を返す。デコード失敗時は `persistenceError` を throw
- `save()`: ディレクトリ未存在時は `createDirectory` で作成。`Data.write(to:options:.atomic)` でアトミック書き込み
- `delete()`: `loadAll()` → 該当セッション除去 → `save()`
- `JSONEncoder.dateEncodingStrategy = .iso8601`
- `JSONEncoder.outputFormatting = .prettyPrinted`

### Unit Test（TDD）

| テストファイル | テスト内容 |
|-------------|----------|
| `JSONSessionStoreTests.swift` | save → loadAll ラウンドトリップ |
| | ファイル未存在時の loadAll → 空配列 |
| | delete → 対象セッションが除去される |
| | アトミック書き込みの確認（一時ディレクトリ使用） |

テストでは一時ディレクトリ（`FileManager.default.temporaryDirectory`）を使用し、
テスト後にクリーンアップする。

### 完了基準

- [ ] JSONSessionStore の全メソッドが実装済み
- [ ] 一時ディレクトリでの Unit Test パス
- [ ] `swift test --package-path Packages/Infrastructure` でテストパス

---

## Wave 3-3: AgentService 完全実装 + Integration Test

### 実装内容

AgentService の全メソッドを実装する。

#### createSession

```swift
func createSession(config: SessionConfig) async throws
    -> (sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>) {
    do {
        let options = SessionOptions(
            model: config.model.sdkValue,
            systemPrompt: config.systemPrompt,
            permissionMode: .bypassPermissions,
            cwd: config.workingDirectory
        )
        let session = try await AgentSDK.createSession(options: options)
        let mappedStream = mapStream(session.messages)
        // session を内部で保持（sessionId → session のマッピング）
        return (session.id, mappedStream)
    } catch {
        throw mapError(error)
    }
}
```

**ModelSelection → SDK モデル名マッピング:**

```swift
extension ModelSelection {
    var sdkValue: String {
        switch self {
        case .opus: "claude-opus-4-6"
        case .sonnet: "claude-sonnet-4-5-20250929"
        case .haiku: "claude-haiku-4-5-20251001"
        }
    }
}
```

> この extension は Infrastructure 内に配置する（Domain は SDK を知らないため）。

**セッション管理:**
- `sessions: [String: AgentSession]` の Dictionary で複数セッションを管理
- `Synchronization.Mutex` で保護する（Swift 6 concurrency 対応）
- `@unchecked Sendable` で `AgentService` を Sendable にする（Mutex 内部管理のため）

#### resumeSession, send, interrupt, close, setModel

各メソッドは sessions Dictionary から該当セッションを取得し、SDK API を呼び出す。
エラーは `mapError()` で `AppError` に変換する。

#### エラーマッピング

```swift
private func mapError(_ error: Error) -> AppError {
    guard let sdkError = error as? AgentSDKError else {
        return .protocolError(error.localizedDescription)
    }
    switch sdkError {
    case .cliNotFound: return .cliNotFound
    case .notConnected: return .notConnected
    case .sessionExpired: return .sessionExpired
    case .initializationTimeout: return .connectionTimeout
    case .processExited(let code, _): return .processExited(code: code)
    default: return .protocolError(sdkError.localizedDescription)
    }
}
```

### Integration Test（MockTransport）

| テストファイル | テスト内容 |
|-------------|----------|
| `AgentServiceTests.swift` | createSession: MockTransport でセッション作成 → ストリーム受信 |
| | send: メッセージ送信 → partial → assistant → result の順で受信 |
| | interrupt: 処理中断が呼ばれる |
| | close: セッション終了 → sessions から削除 |
| | setModel: モデル変更が反映される |
| | エラーケース: 各 AgentSDKError → AppError の変換 |

### 完了基準

- [ ] AgentService の全メソッドが実装済み
- [ ] エラーマッピングが全 AgentSDKError ケースをカバー
- [ ] MockTransport での Integration Test パス
- [ ] `swift test --package-path Packages/Infrastructure` 全テストパス
- [ ] Placeholder.swift を削除済み

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
