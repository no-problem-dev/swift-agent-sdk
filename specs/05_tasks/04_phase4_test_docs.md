---
title: "Swift Agent SDK - Phase 4: テスト・統合・ドキュメント"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, phase-4]
references:
  - ./00_index.md
  - ../04_implementation_plan/01_phase_wave_structure.md
  - ../04_implementation_plan/04_test_strategy.md
  - ../03_design_spec/08_api_spec.md
---

# Phase 4: テスト・統合・ドキュメント（T20〜T25）

## Wave 4-1: AgentSDKTesting モジュール（並列可能: T20, T21）

### T20: Implement MockTransport

- description:
  - テスト用の AgentTransport 準拠 Actor を実装する
  - 事前定義応答: init(responses:) で応答メッセージシーケンスを設定
  - メッセージ記録: write() 呼び出しを sentMessages に蓄積
  - 接続状態: simulatedIsReady で制御
  - 完了時: MockTransport を使った基本テストがパス

- spec_refs:
  - FF-011（テスタビリティ → MockTransport）
  - specs/03_design_spec/04_component_architecture.md#2.7 MockTransport
  - specs/03_design_spec/08_api_spec.md#7.1 MockTransport
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 4-1 [A]

- agent:
  - general-purpose

- deps:
  - T2 (AgentTransport protocol)

- files:
  - modify: Sources/AgentSDKTesting/MockTransport.swift (プレースホルダから実装に置換)
  - create: Tests/AgentSDKTests/MockTransportTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/MockTransportTests.swift
  - coverage_goal: 90%
  - red_phase: responses 返却テスト, sentMessages 蓄積テスト, simulatedIsReady = false 時の notConnected テスト
  - green_phase: Actor + AsyncThrowingStream で最小実装

- verification:
  - [ ] `swift test --filter AgentSDKTests/MockTransportTests` 全パス
  - [ ] AgentTransport protocol に準拠
  - [ ] 事前定義応答が messages() ストリームで返る
  - [ ] write() 呼び出しが sentMessages に記録される
  - [ ] simulatedIsReady = false で notConnected エラー
  - [ ] `public` 可視性（AgentSDKTesting モジュール）
  - [ ] 12 行以内で MockTransport を生成可能（NFR-007）

---

### T21: Implement MockFixtures

- description:
  - テスト用の事前定義メッセージシーケンス ファクトリを実装する
  - simpleSuccess(text:): system → assistant → result
  - withToolUse(toolName:result:): system → assistant(toolUse) → assistant(toolResult) → result
  - protocolError(): エラーを含むシーケンス
  - 完了時: 各ファクトリが正しいシーケンスを返す

- spec_refs:
  - FF-011（テスタビリティ）
  - specs/03_design_spec/08_api_spec.md#7.2 MockFixtures
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 4-1 [B]

- agent:
  - general-purpose

- deps:
  - T3 (AgentMessage, SystemInfo, AssistantInfo, ResultInfo 等)
  - T20 (MockTransport と組み合わせて使用)

- files:
  - modify: Sources/AgentSDKTesting/MockFixtures.swift (プレースホルダから実装に置換、なければ作成)
  - create: Tests/AgentSDKTests/MockFixturesTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKTests/MockFixturesTests.swift
  - coverage_goal: 100%
  - red_phase: simpleSuccess のシーケンス検証, withToolUse のシーケンス検証, protocolError のシーケンス検証
  - green_phase: static factory メソッドの実装

- verification:
  - [ ] `swift test --filter AgentSDKTests/MockFixturesTests` 全パス
  - [ ] simpleSuccess が system → assistant → result を返す
  - [ ] withToolUse が system → assistant(toolUse) → assistant(toolResult) → result を返す
  - [ ] `public` 可視性

---

## Wave 4-2: 統合テスト + 具象層テスト（並列可能: T22, T23）

### T22: Test ClaudeCodeClient（MockTransport 使用）

- description:
  - MockTransport を使って ClaudeCodeClient と ClaudeCodeSession の振る舞いを検証する
  - CLI 不要で Client/Session の全 API パスをテスト
  - ワンショットクエリ成功、セッション作成・送信、セッション再開、権限ハンドラ、エラー伝播
  - 完了時: 全テストパス

- spec_refs:
  - FF-004（ワンショットクエリ）
  - FF-005（セッション管理）
  - FF-006（権限ハンドリング）
  - specs/04_implementation_plan/04_test_strategy.md#1.3 Mock-based Client Tests
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 4-2

- agent:
  - general-purpose

- deps:
  - T17 (ClaudeCodeClient)
  - T18 (ClaudeCodeSession)
  - T20 (MockTransport)
  - T21 (MockFixtures)

- files:
  - modify: Tests/AgentSDKClaudeCodeTests/ClaudeCodeClientTests.swift (スタブから本テストに置換)
  - modify: Tests/AgentSDKClaudeCodeTests/ClaudeCodeSessionTests.swift (スタブから本テストに置換)

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/ClaudeCodeClientTests.swift, Tests/AgentSDKClaudeCodeTests/ClaudeCodeSessionTests.swift
  - coverage_goal: 80%
  - red_phase: query 成功, query with tool use, session send, canUseTool allow/deny, notConnected error, session resume
  - green_phase: MockTransport + MockFixtures で全パス（既存実装の振る舞い検証）

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests` 全パス
  - [ ] ワンショットクエリ: query() → stream → result
  - [ ] セッション: createSession() → send() → messages
  - [ ] セッション再開: resumeSession() → send() → messages
  - [ ] 権限: canUseTool ハンドラが呼ばれ allow/deny が伝播
  - [ ] エラー: Transport エラーが stream に throw

---

### T23: Test EndToEnd（統合テスト）

- description:
  - 実際の Claude Code CLI との通信テストを作成する
  - 環境変数 `AGENT_SDK_INTEGRATION_TEST=1` で有効化
  - サブスクリプション認証済が前提（API Key 不使用）
  - 完了時: ローカルで統合テストがパス

- spec_refs:
  - specs/04_implementation_plan/04_test_strategy.md#1.2 Integration Tests
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 4-2

- agent:
  - general-purpose

- deps:
  - T19 (AgentSDK convenience API)

- files:
  - modify: Tests/IntegrationTests/IntegrationTests.swift (プレースホルダから本テストに置換)
  - create: Tests/IntegrationTests/EndToEndTests.swift

- unit_test:
  - required: false
  - 理由: 統合テストのため unit_test ではなく integration test

- verification:
  - [ ] `AGENT_SDK_INTEGRATION_TEST=1 swift test --filter IntegrationTests` 全パス（ローカル環境）
  - [ ] Hello World クエリが応答を受信
  - [ ] セッション作成・送信が成功
  - [ ] セッション再開が成功
  - [ ] CLI 不正パスで cliNotFound エラー

---

## Wave 4-3: ドキュメント + リリース準備（並列可能: T24, T25）

### T24: Create README + DocC コメント整備

- description:
  - 利用者向け README.md を作成する
  - 構成: 概要（7行 Hello World）、インストール、前提条件、使用例、カスタマイズ（DI, MockTransport）、API リファレンス、バージョン互換表
  - 全 public API の DocC コメントを最終整備する
  - 完了時: README が使用例付きで完成、DocC ビルド成功

- spec_refs:
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 4-3
  - specs/04_implementation_plan/05_rollout.md#2 リリース手順
  - specs/03_design_spec/08_api_spec.md（API 使用例）

- agent:
  - general-purpose

- deps:
  - T19 (AgentSDK convenience API 完成)
  - T22 (テスト完成で API の正確性が保証)

- files:
  - create: README.md
  - modify: Sources/AgentSDK/**/*.swift (DocC コメント追加)
  - modify: Sources/AgentSDKClaudeCode/ClaudeCodeTransport.swift (DocC)
  - modify: Sources/AgentSDKClaudeCode/ClaudeCodeClient.swift (DocC)
  - modify: Sources/AgentSDKClaudeCode/ClaudeCodeSession.swift (DocC)

- unit_test:
  - required: false

- verification:
  - [ ] README.md が存在する
  - [ ] 7 行以内の Hello World 使用例がある（NFR-006）
  - [ ] インストール手順（SwiftPM dependency 追加）がある
  - [ ] 前提条件（Node.js 18+, Claude Code CLI, サブスクリプション認証）が記載
  - [ ] query, session, sub-agents, permissions の使用例がある
  - [ ] バージョン互換表がある
  - [ ] `swift package generate-documentation` 成功（DocC）

---

### T25: Configure GitHub Actions CI

- description:
  - GitHub Actions ワークフローを作成する
  - test.yml: push / PR で swift build + swift test（Unit + AgentSDKClaudeCode）
  - integration.yml: 手動 / 定期で統合テスト（Node.js + CLI）
  - 完了時: CI 設定ファイルが存在し、ローカルで構文検証済み

- spec_refs:
  - specs/04_implementation_plan/04_test_strategy.md#5 CI テスト構成
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 4-3

- agent:
  - general-purpose

- deps:
  - T22 (テストが完成している)

- files:
  - create: .github/workflows/test.yml
  - create: .github/workflows/integration.yml

- unit_test:
  - required: false

- verification:
  - [ ] `.github/workflows/test.yml` が存在する
  - [ ] test.yml に `swift build` + `swift test` ステップがある
  - [ ] test.yml が push / PR でトリガーされる
  - [ ] `.github/workflows/integration.yml` が存在する
  - [ ] integration.yml に Node.js セットアップ + 統合テストステップがある
  - [ ] integration.yml が手動トリガー対応（workflow_dispatch）
  - [ ] YAML 構文が正しい

---

## Wave 完了チェック

### Wave 4-1 完了後

- [ ] MockTransport + MockFixtures のテスト全パス
- [ ] → `/compact` 実行

### Wave 4-2 完了後

- [ ] `swift test` 全パス（Unit + Mock テスト）
- [ ] 統合テスト全パス（ローカル環境）
- [ ] → `/compact` 実行

### Wave 4-3 完了後

- [ ] README.md 完成
- [ ] DocC ビルド成功
- [ ] CI 設定ファイル作成済み
- [ ] → Phase 4 完了

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
