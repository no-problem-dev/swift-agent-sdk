---
title: "ClaudeAgent - Phase 3: Infrastructure パッケージ実装タスク"
created: 2026-02-08
status: draft
tags: [tasks, phase3, infrastructure, claude-agent]
references:
  - ../04_implementation_plan/05_phase3_infrastructure.md
  - ../03_design_spec/03_layer_architecture.md#Infrastructure
  - ../03_design_spec/04_component_architecture.md#Infrastructure-コンポーネント詳細
  - ../03_design_spec/05_data_model.md#永続化仕様
---

# Phase 3: Infrastructure パッケージ実装 (T12-T16)

> Phase 4 と **並列実行可能**（Phase 2 完了後）

## Wave 3-1: AgentMessageMapper + AgentService 骨格

---

## T12: Implement AgentMessageMapper

- description:
  - SDK の AgentMessage を Domain の AgentEvent に変換する Mapper を実装する
  - ContentBlock → ContentItem のマッピング（text, toolUse, toolResult）を含む
  - ToolUse.input の `[String: AnyCodable]` → `[String: String]` 変換
  - 未知の ContentBlock は無視する（将来の SDK 拡張対策）
  - 完了時: 全マッピングケースが実装済み、テストパス

- spec_refs:
  - FF-003（ツール可視化）
  - specs/04_implementation_plan/05_phase3_infrastructure.md#Wave-3-1
  - specs/03_design_spec/04_component_architecture.md#AgentMessageMapper
  - specs/03_design_spec/03_layer_architecture.md#SDK-型マッピング

- agent:
  - general-purpose

- deps:
  - T11 (Domain 完了)

- package: Infrastructure

- files:
  - create: Packages/Infrastructure/Sources/Infrastructure/Mappers/AgentMessageMapper.swift
  - create: Packages/Infrastructure/Tests/InfrastructureTests/AgentMessageMapperTests.swift

- unit_test:
  - required: true
  - test_file: Packages/Infrastructure/Tests/InfrastructureTests/AgentMessageMapperTests.swift
  - coverage_goal: 90%
  - red_phase: 各 AgentMessage → AgentEvent の変換テスト（system→initialized, partial→partialText, assistant→assistantMessage, result→turnCompleted）を先に作成
  - green_phase: Mapper の全マッピングロジックを実装

- verification:
  - [ ] system → AgentEvent.initialized のテストパス
  - [ ] partial(.text) → AgentEvent.partialText のテストパス
  - [ ] assistant(content) → AgentEvent.assistantMessage のテストパス
  - [ ] result(cost, tokens) → AgentEvent.turnCompleted のテストパス
  - [ ] ContentBlock.toolUse → ContentItem.toolUse のテストパス
  - [ ] ContentBlock.toolResult → ContentItem.toolResult のテストパス
  - [ ] `swift test --package-path Packages/Infrastructure` テストパス

---

## T13: Implement AgentService 骨格

- description:
  - AgentServiceProtocol に準拠した AgentService struct の骨格を作成する
  - 全メソッドを `fatalError("Not implemented")` で仮実装する
  - 完了時: AgentService が AgentServiceProtocol に準拠しコンパイル成功

- spec_refs:
  - specs/04_implementation_plan/05_phase3_infrastructure.md#Wave-3-1
  - specs/03_design_spec/04_component_architecture.md#AgentService

- agent:
  - general-purpose

- deps:
  - T11 (Domain 完了)

- package: Infrastructure

- files:
  - create: Packages/Infrastructure/Sources/Infrastructure/Services/AgentService.swift

- unit_test:
  - required: false

- verification:
  - [ ] AgentService が AgentServiceProtocol に準拠
  - [ ] `swift build --package-path Packages/Infrastructure` 成功

---

## Wave 3-2: JSONSessionStore 実装

---

## T14: Implement JSONSessionStore

- description:
  - SessionStoreProtocol の JSON ファイル実装を行う
  - loadAll: ファイル未存在時は空配列、デコード失敗時は persistenceError
  - save: ディレクトリ未存在時は createDirectory、アトミック書き込み
  - delete: loadAll → 該当セッション除去 → save
  - ISO8601 日付エンコーディング、prettyPrinted 出力
  - 完了時: 全メソッド実装済み、一時ディレクトリでの Unit Test パス

- spec_refs:
  - FF-005（データ永続化）
  - specs/04_implementation_plan/05_phase3_infrastructure.md#Wave-3-2
  - specs/03_design_spec/04_component_architecture.md#JSONSessionStore
  - specs/03_design_spec/05_data_model.md#永続化仕様

- agent:
  - general-purpose

- deps:
  - T11 (Domain 完了)

- package: Infrastructure

- files:
  - create: Packages/Infrastructure/Sources/Infrastructure/Persistence/JSONSessionStore.swift
  - create: Packages/Infrastructure/Tests/InfrastructureTests/JSONSessionStoreTests.swift

- unit_test:
  - required: true
  - test_file: Packages/Infrastructure/Tests/InfrastructureTests/JSONSessionStoreTests.swift
  - coverage_goal: 90%
  - red_phase: save → loadAll ラウンドトリップ、ファイル未存在時 loadAll → 空配列、delete → 対象セッション除去のテストを先に作成
  - green_phase: JSONSessionStore の全メソッドを実装

- verification:
  - [ ] save → loadAll ラウンドトリップテストパス
  - [ ] ファイル未存在時の loadAll → 空配列テストパス
  - [ ] delete → 対象セッションが除去されるテストパス
  - [ ] アトミック書き込み（.atomic オプション）が使用されている
  - [ ] テストで一時ディレクトリを使用している
  - [ ] `swift test --package-path Packages/Infrastructure` テストパス

---

## Wave 3-3: AgentService 完全実装 + Integration Test

---

## T15: Implement AgentService 完全実装

- description:
  - AgentService の全メソッドを完全実装する
  - createSession: SDK セッション作成 + ストリームマッピング
  - resumeSession, send, interrupt, close, setModel の各メソッド
  - ModelSelection → SDK モデル名マッピング extension を Infrastructure 内に配置
  - sessions Dictionary を Synchronization.Mutex で保護
  - エラーマッピング（AgentSDKError → AppError）
  - 完了時: 全メソッドが実装済みでコンパイル成功

- spec_refs:
  - FF-001（セッション管理）
  - FF-002（チャットメッセージング）
  - FF-004（モデル・設定制御）
  - specs/04_implementation_plan/05_phase3_infrastructure.md#Wave-3-3
  - specs/03_design_spec/04_component_architecture.md#AgentService

- agent:
  - general-purpose

- deps:
  - T12
  - T13

- package: Infrastructure

- files:
  - modify: Packages/Infrastructure/Sources/Infrastructure/Services/AgentService.swift
  - create: Packages/Infrastructure/Sources/Infrastructure/Extensions/ModelSelection+SDK.swift

- unit_test:
  - required: true
  - test_file: Packages/Infrastructure/Tests/InfrastructureTests/AgentServiceTests.swift (T16 で作成)
  - coverage_goal: 70%
  - red_phase: T16 で MockTransport テストを先に作成
  - green_phase: テストが通る実装

- verification:
  - [ ] createSession が SDK セッション作成 + ストリームマッピングを行う
  - [ ] sessions Dictionary を Mutex で保護している
  - [ ] エラーマッピングが全 AgentSDKError ケースをカバー
  - [ ] ModelSelection.sdkValue が正しいモデル名を返す
  - [ ] `swift build --package-path Packages/Infrastructure` 成功

---

## T16: Test AgentService Integration Test

- description:
  - AgentSDKTesting の MockTransport を使用した AgentService の Integration Test を作成する
  - createSession, send, interrupt, close, setModel の各シナリオ
  - エラーケース: 各 AgentSDKError → AppError の変換テスト
  - Placeholder ファイルを削除する
  - 完了時: 全 Integration Test パス、Placeholder 削除済み

- spec_refs:
  - specs/04_implementation_plan/05_phase3_infrastructure.md#Wave-3-3
  - specs/04_implementation_plan/08_test_strategy.md#Integration-Test

- agent:
  - general-purpose

- deps:
  - T15

- package: Infrastructure

- files:
  - create: Packages/Infrastructure/Tests/InfrastructureTests/AgentServiceTests.swift
  - delete: Packages/Infrastructure/Sources/Infrastructure/Placeholder.swift
  - delete: Packages/Infrastructure/Tests/InfrastructureTests/PlaceholderTests.swift

- unit_test:
  - required: true
  - test_file: Packages/Infrastructure/Tests/InfrastructureTests/AgentServiceTests.swift
  - coverage_goal: 70%
  - red_phase: MockTransport でのセッション作成→ストリーム受信、メッセージ送信→partial→assistant→result の順で受信、interrupt 中断、close セッション終了のテスト
  - green_phase: テストパスを確認

- verification:
  - [ ] createSession: MockTransport でセッション作成 → ストリーム受信テストパス
  - [ ] send: メッセージ送信 → partial → assistant → result の順で受信テストパス
  - [ ] interrupt: 処理中断テストパス
  - [ ] close: セッション終了 → sessions から削除テストパス
  - [ ] エラーケース: AgentSDKError → AppError 変換テストパス
  - [ ] `swift test --package-path Packages/Infrastructure` 全テストパス
  - [ ] Placeholder.swift が削除済み

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
