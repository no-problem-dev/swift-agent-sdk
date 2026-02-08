---
title: "ClaudeAgent - Phase 2: Domain パッケージ実装"
created: 2026-02-08
status: draft
tags: [implementation-plan, phase2, domain, claude-agent]
references:
  - ./00_index.md
  - ./01_phase_overview.md
  - ../03_design_spec/03_layer_architecture.md#Domain
  - ../03_design_spec/04_component_architecture.md#Domain-コンポーネント詳細
  - ../03_design_spec/05_data_model.md
---

# Phase 2: Domain パッケージ実装

## 目的

アプリケーション全体の基盤となる Domain 層を実装する。
エンティティ、値オブジェクト、プロトコル、エラー型を定義し、
Infrastructure / Presentation が依存する契約を確定させる。

## 前提

- Phase 1 完了（Domain/Package.swift が存在し `swift build` 可能な状態）

---

## Wave 2-1: エンティティ + 値オブジェクト

### 実装内容（並列実行可能）

全型を `specs/03_design_spec/05_data_model.md` に準拠して実装する。

#### Entities/

| ファイル | 型 | 準拠プロトコル |
|---------|-----|--------------|
| `ChatMessage.swift` | `struct ChatMessage` | Identifiable, Codable, Sendable |
| `ContentItem.swift` | `enum ContentItem` | Codable, Sendable, Hashable |
| `ToolUseItem.swift` | `struct ToolUseItem` | Codable, Sendable, Hashable, Identifiable |
| `ToolResultItem.swift` | `struct ToolResultItem` | Codable, Sendable, Hashable |
| `SessionConfig.swift` | `struct SessionConfig` | Codable, Sendable |
| `SessionData.swift` | `struct SessionData` | Codable, Sendable, Identifiable |
| `TokenUsage.swift` | `struct TokenUsage` | Sendable |

**型定義の詳細:**
- `specs/03_design_spec/05_data_model.md#Domain-エンティティ` に完全準拠する
- `ChatMessage.textPreview` computed property を含める（先頭 30 文字）
- `ContentItem` は enum で `.text`, `.toolUse`, `.toolResult` の 3 ケース

#### ValueObjects/

| ファイル | 型 | 準拠プロトコル |
|---------|-----|--------------|
| `ModelSelection.swift` | `enum ModelSelection` | String, Codable, Sendable, CaseIterable |
| `SessionStatus.swift` | `enum SessionStatus` | String, Sendable |

**注意:**
- `SessionStatus` は Codable に準拠**しない**（復元時は常に `.disconnected`）
- `ModelSelection` の `displayName` computed property を含める

#### Events/

| ファイル | 型 | 準拠プロトコル |
|---------|-----|--------------|
| `AgentEvent.swift` | `enum AgentEvent` | Sendable |

**`AgentEvent` の定義:**
- `specs/03_design_spec/04_component_architecture.md#AgentEvent` に準拠
- `.initialized(sessionId:)`, `.partialText(_:)`, `.assistantMessage(content:)`, `.turnCompleted(costUsd:inputTokens:outputTokens:)` の 4 ケース

### Unit Test（TDD）

テストを先に書いてから型を実装する。

| テストファイル | テスト内容 |
|-------------|----------|
| `ChatMessageTests.swift` | 初期化、textPreview の動作（空コンテンツ・テキスト 30 文字超え） |
| `ContentItemTests.swift` | 各ケースの Codable エンコード/デコード |
| `SessionDataTests.swift` | 初期化、Codable ラウンドトリップ |
| `ModelSelectionTests.swift` | displayName、CaseIterable |

### 完了基準

- [ ] 全エンティティが `swift build --package-path Packages/Domain` でコンパイル成功
- [ ] 全型が Sendable（コンパイラ警告なし）
- [ ] Codable ラウンドトリップテストがパス
- [ ] `swift test --package-path Packages/Domain` 全テストパス

---

## Wave 2-2: プロトコル + エラー型

### 実装内容

#### Protocols/

| ファイル | 型 | 要件 |
|---------|-----|------|
| `AgentServiceProtocol.swift` | `protocol AgentServiceProtocol` | Sendable |
| `SessionStoreProtocol.swift` | `protocol SessionStoreProtocol` | Sendable |

**AgentServiceProtocol:**
- `specs/03_design_spec/04_component_architecture.md#AgentServiceProtocol` に完全準拠
- メソッドシグネチャ:
  - `createSession(config:) async throws -> (sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>)`
  - `resumeSession(id:config:) async throws -> AsyncThrowingStream<AgentEvent, Error>`
  - `send(sessionId:message:) async throws -> AsyncThrowingStream<AgentEvent, Error>`
  - `interrupt(sessionId:) async throws`
  - `close(sessionId:) async throws`
  - `setModel(sessionId:model:) async throws`

**SessionStoreProtocol:**
- `specs/03_design_spec/04_component_architecture.md#SessionStoreProtocol` に準拠
- メソッドシグネチャ:
  - `loadAll() throws -> [SessionData]`
  - `save(_ sessions: [SessionData]) throws`
  - `delete(sessionId: String) throws`

#### Errors/

| ファイル | 型 | 準拠プロトコル |
|---------|-----|--------------|
| `AppError.swift` | `enum AppError` | Error, Sendable, LocalizedError |

- `specs/03_design_spec/04_component_architecture.md#AppError` に準拠
- 全ケースに `errorDescription` を実装
- ケース: `cliNotFound`, `notConnected`, `sessionExpired`, `connectionTimeout`, `processExited(code:)`, `protocolError(_:)`, `persistenceError(_:)`

### 完了基準

- [ ] プロトコルのメソッドシグネチャが Design Spec と一致
- [ ] AppError の全ケースに errorDescription が定義済み
- [ ] コンパイル成功

---

## Wave 2-3: Domain 総合テスト

### 実装内容

Wave 2-1 のテストに加えて、以下のテストを追加する:

| テストファイル | テスト内容 |
|-------------|----------|
| `AgentEventTests.swift` | 各ケースの生成・パターンマッチ |
| `AppErrorTests.swift` | 全ケースの errorDescription が非空文字列 |

### 完了基準

- [ ] `swift test --package-path Packages/Domain` 全テストパス
- [ ] Domain パッケージに警告なし
- [ ] Placeholder.swift を削除済み

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
