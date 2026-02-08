---
title: "Swift Agent SDK - Phase 2: CLI 具象 内部コンポーネント"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, phase-2]
references:
  - ./00_index.md
  - ../04_implementation_plan/01_phase_wave_structure.md
  - ../03_design_spec/04_component_architecture.md
  - ../03_design_spec/06_auth_flow.md
---

# Phase 2: CLI 具象 内部コンポーネント（T9〜T14）

## Wave 2-1: 低レベル基盤（並列可能: T9, T10, T11）

### T9: Implement JSONLCodec

- description:
  - JSONL 行のエンコード/デコードを行う struct を TDD で実装する
  - encode: Encodable → Data（末尾 `\n` 付き、UTF-8）
  - decode: Data → Decodable
  - decodeMessageType: `type` フィールドのみ先読み
  - 完了時: 全テストパス、`internal` 可視性で AgentSDKClaudeCode 内から利用可能

- spec_refs:
  - FF-002（JSONL トランスポート）
  - specs/03_design_spec/04_component_architecture.md#2.2 JSONLCodec
  - specs/02_requirements/05_io_spec.md
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 2-1 [A]

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/JSONLCodec.swift
  - create: Tests/AgentSDKClaudeCodeTests/JSONLCodecTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/JSONLCodecTests.swift
  - coverage_goal: 100%
  - red_phase: encode round-trip, 末尾 `\n` 検証, UTF-8 検証, 不正 JSON エラー, type 先読み成功/失敗
  - green_phase: 最小実装で全テスト通過

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/JSONLCodecTests` 全パス
  - [ ] encode で末尾 `\n` が付与されている
  - [ ] 不正 JSON で適切なエラーが throw される
  - [ ] decodeMessageType が `type` フィールドを返す
  - [ ] Sendable 準拠

---

### T10: Implement CLILocator

- description:
  - CLI バイナリの探索ロジックを TDD で実装する
  - 5 段階探索順序: ユーザー指定 → 環境変数 → ローカル npm → グローバル npm → system PATH
  - 全探索失敗時は `AgentSDKError.cliNotFound(searchedPaths:)` を throw
  - 完了時: 全テストパス

- spec_refs:
  - FF-001（CLI プロセス管理）
  - specs/03_design_spec/04_component_architecture.md#2.5 CLILocator
  - specs/03_design_spec/06_auth_flow.md#3 CLI 探索フロー
  - specs/02_requirements/03_functional_requirements.md#FR-001
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 2-1 [B]

- agent:
  - general-purpose

- deps:
  - T4 (AgentSDKError を使用)

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/CLILocator.swift
  - create: Tests/AgentSDKClaudeCodeTests/CLILocatorTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/CLILocatorTests.swift
  - coverage_goal: 90%
  - red_phase: ユーザー指定パス成功/失敗, 環境変数, ローカル npm, グローバル npm, which claude, 全探索失敗
  - green_phase: テンポラリディレクトリに CLI ファイルを配置してテスト

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/CLILocatorTests` 全パス
  - [ ] 5 段階の探索順序が正しい
  - [ ] 存在しないパス指定で適切なエラー
  - [ ] 全探索失敗で `cliNotFound` エラーに searchedPaths が含まれる
  - [ ] Sendable 準拠

---

### T11: Implement CLIArgBuilder

- description:
  - CLI 起動引数の構成ロジックを TDD で実装する
  - デフォルト引数: `--output-format stream-json --input-format stream-json --verbose`
  - オプション引数: systemPrompt, permissionMode, resume, maxTurns 等
  - agents/mcpServers: JSON シリアライズ引数
  - 完了時: 全テストパス

- spec_refs:
  - FF-001（CLI プロセス管理）
  - FF-007（サブエージェント定義 → agents 引数）
  - FF-008（MCP サーバー設定 → mcpServers 引数）
  - specs/03_design_spec/04_component_architecture.md#2.6 CLIArgBuilder
  - specs/02_requirements/05_io_spec.md（CLI 起動引数）
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 2-1 [C]

- agent:
  - general-purpose

- deps:
  - T3 (QueryOptions, SessionOptions, AgentDefinition, MCPServerConfig を使用)

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/CLIArgBuilder.swift
  - create: Tests/AgentSDKClaudeCodeTests/CLIArgBuilderTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/CLIArgBuilderTests.swift
  - coverage_goal: 100%
  - red_phase: デフォルト引数テスト, 各オプション引数テスト, agents JSON シリアライズ, mcpServers JSON シリアライズ
  - green_phase: 最小実装で全テスト通過

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/CLIArgBuilderTests` 全パス
  - [ ] デフォルト引数に `--output-format stream-json` が含まれる
  - [ ] systemPrompt 指定時に `--system-prompt` 引数が追加される
  - [ ] agents が JSON シリアライズされる
  - [ ] Sendable 準拠

---

## Wave 2-2: CLIProcess Actor

### T12: Implement CLIProcess

- description:
  - CLI サブプロセスのライフサイクル管理 Actor を TDD で実装する
  - 状態遷移: Idle → Starting → Running → Terminating → Terminated
  - stdin/stdout パイプによる通信
  - stderr 内容の蓄積
  - SIGTERM → SIGKILL エスカレーション
  - 完了時: 全テストパス（軽量子プロセス `echo`/`cat` 等で検証）

- spec_refs:
  - FF-001（CLI プロセス管理）
  - specs/03_design_spec/04_component_architecture.md#2.1 CLIProcess
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 2-2
  - specs/03_design_spec/10_security.md#3.2 プロセス権限

- agent:
  - general-purpose

- deps:
  - T10 (CLILocator を使用)
  - T11 (CLIArgBuilder を使用)

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/CLIProcess.swift
  - create: Tests/AgentSDKClaudeCodeTests/CLIProcessTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/CLIProcessTests.swift
  - coverage_goal: 80%
  - red_phase: 状態遷移（Idle→Running→Terminated）, stdin 書き込み, stdout 読み取り, stderr 蓄積, terminate() の動作
  - green_phase: Foundation.Process を使った最小実装

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/CLIProcessTests` 全パス
  - [ ] Idle → start() → Running の状態遷移テスト
  - [ ] Running → terminate() → Terminated の状態遷移テスト
  - [ ] stdin 書き込み → stdout 読み取りの通信テスト
  - [ ] プロセス異常終了の検知テスト
  - [ ] Swift 6 Actor isolation warning 0

---

## Wave 2-3: JSONL プロトコル型 + Handshake

### T13: Implement CLIMessage / SDKMessage / ControlMessage 型定義

- description:
  - CLI↔SDK 間の内部 JSONL メッセージ型を定義する
  - CLIMessage: CLI → SDK（initializeReady/system/assistant/partial/result/controlRequest/controlResponse/unknown）
  - SDKMessage: SDK → CLI（userMessage/controlRequest/controlResponse）
  - ControlMessage 関連型: subtype 定義
  - 完了時: 全型が Codable round-trip テストをパス

- spec_refs:
  - FF-002（JSONL トランスポート）
  - FF-003（初期化ハンドシェイク → initializeReady）
  - FF-009（ランタイム制御 → control subtypes）
  - specs/03_design_spec/05_data_model.md#4 Concrete Layer 内部型
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 2-3

- agent:
  - general-purpose

- deps:
  - T9 (JSONLCodec でエンコード/デコード)

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/Protocol/CLIMessage.swift
  - create: Sources/AgentSDKClaudeCode/Internal/Protocol/SDKMessage.swift
  - create: Sources/AgentSDKClaudeCode/Internal/Protocol/ControlMessage.swift
  - create: Tests/AgentSDKClaudeCodeTests/CLIMessageTests.swift
  - create: Tests/AgentSDKClaudeCodeTests/SDKMessageTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/CLIMessageTests.swift, Tests/AgentSDKClaudeCodeTests/SDKMessageTests.swift
  - coverage_goal: 90%
  - red_phase: CLIMessage 全 case のデコードテスト（固定 JSONL 文字列から）、SDKMessage のエンコードテスト、unknown type のフォールバック
  - green_phase: カスタム Codable 実装

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests` で CLIMessage/SDKMessage テスト全パス
  - [ ] CLIMessage の全 7 case がデコードできる
  - [ ] `{"type":"initialize_ready"}` → `.initializeReady` のデコード成功
  - [ ] 未知の type → `.unknown(type:)` にフォールバック
  - [ ] SDKMessage のエンコードが正しい JSON を生成
  - [ ] Sendable 準拠

---

### T14: Implement Handshake

- description:
  - CLI との初期化プロトコル（ハンドシェイク）を実装する
  - フロー: initialize_ready 待機 → InitializeRequest 送信 → SystemMessage 受信
  - タイムアウト: 60 秒
  - 完了時: 正常系・タイムアウト・不正応答のテストがパス

- spec_refs:
  - FF-003（初期化ハンドシェイク）
  - specs/03_design_spec/04_component_architecture.md#2.3 Handshake
  - specs/03_design_spec/06_auth_flow.md#1 ハンドシェイクフロー
  - specs/03_design_spec/06_auth_flow.md#4 InitializeRequest の構造
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 2-3 Handshake

- agent:
  - general-purpose

- deps:
  - T12 (CLIProcess を使用)
  - T13 (CLIMessage/SDKMessage を使用)

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/Handshake.swift
  - create: Tests/AgentSDKClaudeCodeTests/HandshakeTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/HandshakeTests.swift
  - coverage_goal: 90%
  - red_phase: 正常系フロー、タイムアウト（60s 以内に initialize_ready が来ない）、不正応答（SystemMessage 以外）
  - green_phase: JSONLCodec + モック stdout ストリームでフロー検証

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/HandshakeTests` 全パス
  - [ ] 正常系: initialize_ready → InitializeRequest → SystemMessage
  - [ ] タイムアウト: `initializationTimeout` エラー
  - [ ] 不正応答: `protocolError` エラー
  - [ ] Sendable 準拠

---

## Wave 完了チェック

### Wave 2-1 完了後

- [ ] JSONLCodec, CLILocator, CLIArgBuilder の全テストパス
- [ ] `swift build` 成功
- [ ] → `/compact` 実行

### Wave 2-2 完了後

- [ ] CLIProcess のテスト全パス
- [ ] Actor isolation warning 0
- [ ] → `/compact` 実行

### Wave 2-3 完了後

- [ ] JSONL プロトコル型テスト全パス
- [ ] Handshake テスト全パス
- [ ] → `/compact` 実行

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
