---
title: "ClaudeAgent - Phase 2: Domain パッケージ実装タスク"
created: 2026-02-08
status: draft
tags: [tasks, phase2, domain, claude-agent]
references:
  - ../04_implementation_plan/04_phase2_domain.md
  - ../03_design_spec/03_layer_architecture.md#Domain
  - ../03_design_spec/04_component_architecture.md#Domain-コンポーネント詳細
  - ../03_design_spec/05_data_model.md
---

# Phase 2: Domain パッケージ実装 (T6-T11)

## Wave 2-1: エンティティ + 値オブジェクト

---

## T6: Implement Domain エンティティ

- description:
  - ChatMessage, ContentItem, ToolUseItem, ToolResultItem, SessionConfig, SessionData, TokenUsage を実装する
  - 全型を `specs/03_design_spec/05_data_model.md` に準拠して定義する
  - ChatMessage.textPreview（先頭 30 文字）、ContentItem の 3 ケース enum を含む
  - 完了時: 全エンティティが Sendable + Codable でコンパイル成功

- spec_refs:
  - FF-001（セッション管理）
  - FF-002（チャットメッセージング）
  - FF-003（ツール可視化）
  - specs/04_implementation_plan/04_phase2_domain.md#Wave-2-1
  - specs/03_design_spec/05_data_model.md#Domain-エンティティ
  - specs/03_design_spec/04_component_architecture.md#Domain-コンポーネント詳細

- agent:
  - general-purpose

- deps:
  - T2

- package: Domain

- files:
  - create: Packages/Domain/Sources/Domain/Entities/ChatMessage.swift
  - create: Packages/Domain/Sources/Domain/Entities/ContentItem.swift
  - create: Packages/Domain/Sources/Domain/Entities/ToolUseItem.swift
  - create: Packages/Domain/Sources/Domain/Entities/ToolResultItem.swift
  - create: Packages/Domain/Sources/Domain/Entities/SessionConfig.swift
  - create: Packages/Domain/Sources/Domain/Entities/SessionData.swift
  - create: Packages/Domain/Sources/Domain/Entities/TokenUsage.swift

- unit_test:
  - required: true
  - test_file: Packages/Domain/Tests/DomainTests/ (T8 で作成)
  - coverage_goal: 80%
  - red_phase: T8 で先にテストを作成
  - green_phase: テストが通る最小実装

- verification:
  - [ ] 全エンティティが `swift build --package-path Packages/Domain` でコンパイル成功
  - [ ] 全型が Sendable（コンパイラ警告なし）
  - [ ] ChatMessage に textPreview computed property がある
  - [ ] ContentItem が .text, .toolUse, .toolResult の 3 ケース enum

---

## T7: Implement Domain 値オブジェクト + イベント型

- description:
  - ModelSelection, SessionStatus, AgentEvent を実装する
  - ModelSelection: String enum + CaseIterable + displayName
  - SessionStatus: String enum（Codable に準拠しない）
  - AgentEvent: .initialized, .partialText, .assistantMessage, .turnCompleted の 4 ケース
  - 完了時: 全型がコンパイル成功

- spec_refs:
  - FF-004（モデル・設定制御）
  - specs/04_implementation_plan/04_phase2_domain.md#Wave-2-1
  - specs/03_design_spec/05_data_model.md
  - specs/03_design_spec/04_component_architecture.md#AgentEvent

- agent:
  - general-purpose

- deps:
  - T2

- package: Domain

- files:
  - create: Packages/Domain/Sources/Domain/ValueObjects/ModelSelection.swift
  - create: Packages/Domain/Sources/Domain/ValueObjects/SessionStatus.swift
  - create: Packages/Domain/Sources/Domain/Events/AgentEvent.swift

- unit_test:
  - required: true
  - test_file: Packages/Domain/Tests/DomainTests/ (T8 で作成)
  - coverage_goal: 80%
  - red_phase: T8 で先にテストを作成
  - green_phase: テストが通る最小実装

- verification:
  - [ ] ModelSelection が CaseIterable + displayName computed property を持つ
  - [ ] SessionStatus が Codable に準拠していない
  - [ ] AgentEvent が 4 ケースを持つ
  - [ ] `swift build --package-path Packages/Domain` 成功

---

## T8: Test Domain エンティティ Unit Test

- description:
  - Domain の全エンティティ・値オブジェクトの Unit Test を作成する
  - TDD: テストファーストで作成し、T6/T7 と同時進行で実装する
  - テスト対象: ChatMessage (textPreview), ContentItem (Codable), SessionData (Codable), ModelSelection (displayName, CaseIterable)
  - 完了時: 全テストがパスする状態

- spec_refs:
  - specs/04_implementation_plan/04_phase2_domain.md#Wave-2-1
  - specs/04_implementation_plan/08_test_strategy.md#Unit-Test

- agent:
  - general-purpose

- deps:
  - T2

- package: Domain

- files:
  - create: Packages/Domain/Tests/DomainTests/ChatMessageTests.swift
  - create: Packages/Domain/Tests/DomainTests/ContentItemTests.swift
  - create: Packages/Domain/Tests/DomainTests/SessionDataTests.swift
  - create: Packages/Domain/Tests/DomainTests/ModelSelectionTests.swift

- unit_test:
  - required: true
  - test_file: 上記 4 ファイル
  - coverage_goal: 80%
  - red_phase: テストケースを先に作成（ChatMessage textPreview 空・30文字超え、ContentItem Codable エンコード/デコード、SessionData ラウンドトリップ、ModelSelection displayName・CaseIterable）
  - green_phase: T6/T7 の実装でテストが通る

- verification:
  - [ ] ChatMessageTests: textPreview の空コンテンツ・30 文字超えテスト
  - [ ] ContentItemTests: 各ケースの Codable エンコード/デコードテスト
  - [ ] SessionDataTests: Codable ラウンドトリップテスト
  - [ ] ModelSelectionTests: displayName、CaseIterable テスト
  - [ ] `swift test --package-path Packages/Domain` 全テストパス

---

## Wave 2-2: プロトコル + エラー型

---

## T9: Implement Domain プロトコル

- description:
  - AgentServiceProtocol, SessionStoreProtocol を定義する
  - Design Spec のメソッドシグネチャに完全準拠する
  - 完了時: プロトコル定義がコンパイル成功

- spec_refs:
  - FF-001（セッション管理）
  - FF-002（チャットメッセージング）
  - FF-005（データ永続化）
  - specs/04_implementation_plan/04_phase2_domain.md#Wave-2-2
  - specs/03_design_spec/04_component_architecture.md#AgentServiceProtocol
  - specs/03_design_spec/04_component_architecture.md#SessionStoreProtocol

- agent:
  - general-purpose

- deps:
  - T6
  - T7

- package: Domain

- files:
  - create: Packages/Domain/Sources/Domain/Protocols/AgentServiceProtocol.swift
  - create: Packages/Domain/Sources/Domain/Protocols/SessionStoreProtocol.swift

- unit_test:
  - required: false

- verification:
  - [ ] AgentServiceProtocol のメソッドシグネチャが Design Spec と一致
  - [ ] SessionStoreProtocol のメソッドシグネチャが Design Spec と一致
  - [ ] 両プロトコルが Sendable に準拠
  - [ ] `swift build --package-path Packages/Domain` 成功

---

## T10: Implement Domain AppError

- description:
  - AppError enum を定義する
  - 全ケースに errorDescription を実装する
  - ケース: cliNotFound, notConnected, sessionExpired, connectionTimeout, processExited(code:), protocolError(_:), persistenceError(_:)
  - 完了時: AppError が LocalizedError に準拠しコンパイル成功

- spec_refs:
  - specs/04_implementation_plan/04_phase2_domain.md#Wave-2-2
  - specs/03_design_spec/04_component_architecture.md#AppError

- agent:
  - general-purpose

- deps:
  - T6

- package: Domain

- files:
  - create: Packages/Domain/Sources/Domain/Errors/AppError.swift

- unit_test:
  - required: true
  - test_file: Packages/Domain/Tests/DomainTests/AppErrorTests.swift (T11 で作成)
  - coverage_goal: 100%
  - red_phase: T11 で全ケースの errorDescription 非空テストを作成
  - green_phase: 全ケースの errorDescription 実装

- verification:
  - [ ] AppError が Error, Sendable, LocalizedError に準拠
  - [ ] 全 7 ケースが定義されている
  - [ ] 全ケースの errorDescription が非空文字列
  - [ ] `swift build --package-path Packages/Domain` 成功

---

## Wave 2-3: Domain 総合テスト

---

## T11: Test Domain 総合テスト + クリーンアップ

- description:
  - AgentEvent, AppError のテストを追加する
  - Placeholder.swift を削除する
  - 全 Domain テストが通ることを最終確認する
  - 完了時: Domain パッケージに警告なし、全テストパス

- spec_refs:
  - specs/04_implementation_plan/04_phase2_domain.md#Wave-2-3
  - specs/04_implementation_plan/08_test_strategy.md

- agent:
  - general-purpose

- deps:
  - T9
  - T10

- package: Domain

- files:
  - create: Packages/Domain/Tests/DomainTests/AgentEventTests.swift
  - create: Packages/Domain/Tests/DomainTests/AppErrorTests.swift
  - delete: Packages/Domain/Sources/Domain/Placeholder.swift
  - delete: Packages/Domain/Tests/DomainTests/PlaceholderTests.swift

- unit_test:
  - required: true
  - test_file: 上記 2 ファイル
  - coverage_goal: 80%
  - red_phase: AgentEvent 各ケースの生成・パターンマッチテスト、AppError 全ケースの errorDescription 非空テスト
  - green_phase: テストがパスすることを確認（実装は T7/T10 で完了済み）

- verification:
  - [ ] AgentEventTests: 各ケースの生成・パターンマッチ
  - [ ] AppErrorTests: 全ケースの errorDescription が非空文字列
  - [ ] `swift test --package-path Packages/Domain` 全テストパス
  - [ ] Domain パッケージに警告なし
  - [ ] Placeholder.swift が削除済み

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
