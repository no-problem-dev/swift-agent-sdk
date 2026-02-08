---
title: "Swift Agent SDK - Phase 1: 基盤構築"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, phase-1]
references:
  - ./00_index.md
  - ../04_implementation_plan/01_phase_wave_structure.md
  - ../03_design_spec/04_component_architecture.md
  - ../03_design_spec/05_data_model.md
---

# Phase 1: 基盤構築（T1〜T8）

## Wave 1-1: Package.swift + ディレクトリ構造

### T1: Initialize パッケージ構造セットアップ

- description:
  - SwiftPM パッケージの Package.swift とディレクトリ構造を構築する
  - 完了時: 空のパッケージ構造で `swift build` が成功する状態

- spec_refs:
  - FF-011（プロトコル指向設計 + DI）
  - specs/03_design_spec/04_component_architecture.md#3 ディレクトリ構造
  - specs/03_design_spec/04_component_architecture.md#4 Package.swift 構成

- agent:
  - general-purpose

- deps:
  - none

- files:
  - create: Package.swift
  - create: Sources/AgentSDK/AgentSDK.swift (プレースホルダ)
  - create: Sources/AgentSDKClaudeCode/AgentSDKClaudeCode.swift (プレースホルダ)
  - create: Sources/AgentSDKTesting/AgentSDKTesting.swift (プレースホルダ)
  - create: Tests/AgentSDKTests/AgentSDKTests.swift (プレースホルダ)
  - create: Tests/AgentSDKClaudeCodeTests/AgentSDKClaudeCodeTests.swift (プレースホルダ)
  - create: Tests/IntegrationTests/IntegrationTests.swift (プレースホルダ)

- unit_test:
  - required: false

- verification:
  - [ ] `swift build` が成功する
  - [ ] 3 ライブラリターゲット（AgentSDK, AgentSDKClaudeCode, AgentSDKTesting）がビルドされる
  - [ ] 3 テストターゲット（AgentSDKTests, AgentSDKClaudeCodeTests, IntegrationTests）が認識される
  - [ ] `swift test` がエラーなく完了する

---

## Wave 1-2: Protocol 層型定義（並列可能: T2, T3, T4）

### T2: Implement Protocol 定義（AgentTransport / AgentClient / AgentSession）

- description:
  - Protocol Layer の 3 つの protocol を定義する
  - AgentTransport: 通信層の抽象（connect/close/write/messages）
  - AgentClient: 操作層の抽象（query/createSession/resumeSession）
  - AgentSession: セッション層の抽象（send/interrupt/close）
  - 完了時: `import AgentSDK` で 3 protocol にアクセス可能

- spec_refs:
  - FF-011（プロトコル指向設計 + DI）
  - specs/03_design_spec/03_layer_architecture.md#Protocol Layer
  - specs/03_design_spec/08_api_spec.md#2.1 ClaudeCodeTransport（Transport のメソッドシグネチャ）
  - specs/03_design_spec/08_api_spec.md#2.2 ClaudeCodeClient（Client のメソッドシグネチャ）
  - specs/03_design_spec/08_api_spec.md#3.1 ClaudeCodeSession（Session のメソッドシグネチャ）
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 1-2 [A] Protocols

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: Sources/AgentSDK/Protocols/AgentTransport.swift
  - create: Sources/AgentSDK/Protocols/AgentClient.swift
  - create: Sources/AgentSDK/Protocols/AgentSession.swift

- unit_test:
  - required: false
  - 理由: Protocol 定義自体はテスト不要。準拠型のテストは後続 Wave で実施。

- verification:
  - [ ] `swift build` が成功する
  - [ ] 全 protocol が `public` で定義されている
  - [ ] AgentTransport に connect/close/write/messages メソッドがある
  - [ ] AgentClient に associatedtype Session: AgentSession がある
  - [ ] AgentClient に query/createSession/resumeSession メソッドがある
  - [ ] AgentSession に send/interrupt/close メソッドがある
  - [ ] Swift 6 strict concurrency warning 0

---

### T3: Implement Model 型定義（AgentMessage / ContentBlock / JSONValue 等）

- description:
  - Protocol Layer の全 Model 型を定義する
  - AgentMessage enum, ContentBlock enum, JSONValue enum
  - SystemInfo, AssistantInfo, PartialInfo, ResultInfo struct
  - ToolUse, ToolResult struct
  - QueryOptions, SessionOptions struct
  - AgentDefinition, PermissionMode, PermissionDecision, MCPServerConfig
  - ModelSelection, CommandInfo, ModelInfo, ToolInfo, MCPServerInfo
  - 完了時: 全型が Sendable かつ適切な Codable/Hashable 準拠

- spec_refs:
  - FF-011（プロトコル指向設計 + DI）
  - specs/03_design_spec/05_data_model.md#2 Protocol Layer 型定義
  - specs/03_design_spec/08_api_spec.md#4 QueryOptions 詳細
  - specs/03_design_spec/08_api_spec.md#3.2 CommandInfo, ModelInfo
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 1-2 [B] Models

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: Sources/AgentSDK/Models/AgentMessage.swift
  - create: Sources/AgentSDK/Models/ContentBlock.swift
  - create: Sources/AgentSDK/Models/JSONValue.swift
  - create: Sources/AgentSDK/Models/QueryOptions.swift
  - create: Sources/AgentSDK/Models/SessionOptions.swift
  - create: Sources/AgentSDK/Models/AgentDefinition.swift
  - create: Sources/AgentSDK/Models/PermissionMode.swift
  - create: Sources/AgentSDK/Models/MCPServerConfig.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/ (T5, T6 で実装)
  - coverage_goal: 90%
  - red_phase: T5, T6 で Codable round-trip, デフォルト値, パターンマッチングテストを作成
  - green_phase: 本タスクで型定義を先行実装（テストは後続 Wave）

- verification:
  - [ ] `swift build` が成功する
  - [ ] 全 public 型が Sendable 準拠
  - [ ] AgentMessage, ContentBlock, JSONValue が Codable 準拠
  - [ ] QueryOptions, SessionOptions のデフォルト init が存在する
  - [ ] 全 public API に DocC コメントがある
  - [ ] Swift 6 strict concurrency warning 0

---

### T4: Implement エラー型（AgentSDKError）

- description:
  - SDK の公開エラー型 AgentSDKError を定義する
  - 全 case に LocalizedError 準拠のメッセージを実装
  - エラーメッセージにアクション（解決方法）を含める（FR-040）
  - 完了時: 全 11 case が定義され、localizedDescription が非空

- spec_refs:
  - FF-010（エラーハンドリング）
  - specs/03_design_spec/05_data_model.md#3 エラー型
  - specs/02_requirements/03_functional_requirements.md#FR-039〜FR-043
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 1-2 [C] Errors

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: Sources/AgentSDK/Errors/AgentSDKError.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/AgentSDKErrorTests.swift (T7 で実装)
  - coverage_goal: 100%
  - red_phase: T7 で全 case の localizedDescription 非空テストを作成
  - green_phase: 本タスクでエラー型を先行実装

- verification:
  - [ ] `swift build` が成功する
  - [ ] AgentSDKError が Sendable 準拠
  - [ ] 全 11 case が定義されている
  - [ ] LocalizedError 準拠で全 case が errorDescription を返す
  - [ ] エラーメッセージにアクション（解決方法）が含まれる
  - [ ] Swift 6 strict concurrency warning 0

---

## Wave 1-3: Protocol 層 Unit Tests + AgentSDK スタブ（T5〜T8 並列可能）

### T5: Test AgentMessage / ContentBlock / JSONValue テスト

- description:
  - AgentMessage, ContentBlock, JSONValue の Unit Test を作成する
  - Codable round-trip テスト: encode → decode → 元の値と一致
  - パターンマッチング: AgentMessage の全 case を switch で網羅
  - JSONValue の全ケース（string/number/integer/bool/null/array/object）テスト
  - 完了時: 全テストパス

- spec_refs:
  - FF-011（テスタビリティ）
  - specs/03_design_spec/05_data_model.md#2.1-2.6
  - specs/04_implementation_plan/04_test_strategy.md#3.1 Protocol 層のテスト方針

- agent:
  - general-purpose

- deps:
  - T3

- files:
  - create: Tests/AgentSDKTests/AgentMessageTests.swift
  - create: Tests/AgentSDKTests/ContentBlockTests.swift
  - create: Tests/AgentSDKTests/JSONValueTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/AgentMessageTests.swift, Tests/AgentSDKTests/ContentBlockTests.swift, Tests/AgentSDKTests/JSONValueTests.swift
  - coverage_goal: 90%
  - red_phase: テストケースを先に定義（Codable round-trip, パターンマッチング, エッジケース）
  - green_phase: T3 で型は実装済み。テスト失敗時は T3 の型定義を修正

- verification:
  - [ ] `swift test --filter AgentSDKTests` で該当テストが全パス
  - [ ] AgentMessage の全 case（system/assistant/partial/result）のテストがある
  - [ ] ContentBlock の全 case（text/toolUse/toolResult）のテストがある
  - [ ] JSONValue の全 case（7 種）のテストがある
  - [ ] Codable round-trip が全型で成功する

---

### T6: Test QueryOptions / SessionOptions テスト

- description:
  - QueryOptions, SessionOptions の Unit Test を作成する
  - デフォルト init で全プロパティが nil であることを検証
  - 全パラメータ指定の init テスト
  - 完了時: 全テストパス

- spec_refs:
  - specs/03_design_spec/05_data_model.md#2.8-2.9
  - specs/03_design_spec/08_api_spec.md#4 QueryOptions 詳細
  - specs/04_implementation_plan/04_test_strategy.md#3.1

- agent:
  - general-purpose

- deps:
  - T3

- files:
  - create: Tests/AgentSDKTests/QueryOptionsTests.swift
  - create: Tests/AgentSDKTests/SessionOptionsTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/QueryOptionsTests.swift, Tests/AgentSDKTests/SessionOptionsTests.swift
  - coverage_goal: 90%
  - red_phase: デフォルト init テスト、全パラメータ指定テスト
  - green_phase: T3 で型は実装済み

- verification:
  - [ ] `swift test --filter AgentSDKTests` で該当テストが全パス
  - [ ] QueryOptions デフォルト init で全 Optional が nil
  - [ ] SessionOptions デフォルト init で全 Optional が nil
  - [ ] 全パラメータ指定テストがある

---

### T7: Test AgentSDKError テスト

- description:
  - AgentSDKError の Unit Test を作成する
  - 全 case の LocalizedError メッセージ品質テスト
  - errorDescription が非空であること、アクション情報が含まれること
  - 完了時: 全テストパス

- spec_refs:
  - FF-010（エラーハンドリング）
  - specs/03_design_spec/05_data_model.md#3 エラー型
  - specs/04_implementation_plan/04_test_strategy.md#3.1

- agent:
  - general-purpose

- deps:
  - T4

- files:
  - create: Tests/AgentSDKTests/AgentSDKErrorTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/AgentSDKErrorTests.swift
  - coverage_goal: 100%
  - red_phase: 全 11 case の localizedDescription 非空テスト
  - green_phase: T4 で型は実装済み

- verification:
  - [ ] `swift test --filter AgentSDKTests` で AgentSDKErrorTests が全パス
  - [ ] 全 11 case の errorDescription が非空
  - [ ] cliNotFound と runtimeNotFound にインストール方法が含まれる

---

### T8: Implement AgentSDK namespace スタブ

- description:
  - `public enum AgentSDK {}` namespace を定義する
  - query() / createSession() / resumeSession() のシグネチャを定義
  - 本体は `fatalError("not implemented")` で仮実装
  - Phase 3 Wave 3-3（T19）で本実装を差し込む
  - 完了時: `AgentSDK.query`, `AgentSDK.createSession`, `AgentSDK.resumeSession` がコンパイル可能

- spec_refs:
  - specs/03_design_spec/08_api_spec.md#1 コンビニエンス API
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 1-3 AgentSDK.swift

- agent:
  - general-purpose

- deps:
  - T2
  - T3

- files:
  - modify: Sources/AgentSDK/AgentSDK.swift

- unit_test:
  - required: false
  - 理由: スタブのため。本実装テストは T19 + T22 で実施。

- verification:
  - [ ] `swift build` が成功する
  - [ ] `AgentSDK.query(prompt:options:)` のシグネチャが存在する
  - [ ] `AgentSDK.createSession(options:)` のシグネチャが存在する
  - [ ] `AgentSDK.resumeSession(id:options:)` のシグネチャが存在する
  - [ ] DocC コメントがある

---

## Wave 完了チェック

### Wave 1-1 完了後

- [ ] `swift build` 成功
- [ ] → `/compact` 実行

### Wave 1-2 完了後

- [ ] `swift build` 成功
- [ ] 全 public 型が Sendable 準拠
- [ ] Swift 6 strict concurrency warning 0
- [ ] → `/compact` 実行

### Wave 1-3 完了後

- [ ] `swift test --filter AgentSDKTests` 全パス
- [ ] AgentSDK namespace スタブがビルド成功
- [ ] → `/compact` 実行

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
