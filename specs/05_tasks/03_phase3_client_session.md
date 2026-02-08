---
title: "Swift Agent SDK - Phase 3: クライアント・セッション実装"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, phase-3]
references:
  - ./00_index.md
  - ../04_implementation_plan/01_phase_wave_structure.md
  - ../03_design_spec/08_api_spec.md
  - ../03_design_spec/07_payment_flow.md
---

# Phase 3: クライアント・セッション実装（T15〜T19）

## Wave 3-1: MessageRouter Actor

### T15: Implement MessageRouter

- description:
  - 双方向メッセージルーティング Actor を TDD で実装する
  - メッセージ分類: CLIMessage の type で assistant/result/system/control_request/control_response にルーティング
  - ストリーム配信: assistant/result/system を AsyncThrowingStream に yield
  - 制御リクエスト（CLI→SDK）: can_use_tool をカスタムハンドラにルーティング
  - 制御リクエスト（SDK→CLI）: request_id + CheckedContinuation で応答待機（30 秒タイムアウト）
  - 完了時: 全テストパス

- spec_refs:
  - FF-006（権限ハンドリング → can_use_tool ルーティング）
  - FF-009（ランタイム制御 → 制御リクエスト管理）
  - specs/03_design_spec/04_component_architecture.md#2.4 MessageRouter
  - specs/03_design_spec/07_payment_flow.md#1 権限ハンドリングフロー
  - specs/03_design_spec/07_payment_flow.md#3 制御リクエスト/レスポンス
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 3-1

- agent:
  - general-purpose

- deps:
  - T13 (CLIMessage/SDKMessage を使用)
  - T14 (Handshake → プロトコル型の理解)

- files:
  - create: Sources/AgentSDKClaudeCode/Internal/MessageRouter.swift
  - create: Tests/AgentSDKClaudeCodeTests/MessageRouterTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/MessageRouterTests.swift
  - coverage_goal: 90%
  - red_phase: assistant メッセージ → ストリーム yield, result メッセージ → ストリーム yield, can_use_tool → allow/deny, SDK→CLI 制御リクエスト → レスポンス受信, タイムアウト
  - green_phase: Actor + AsyncThrowingStream + CheckedContinuation で実装

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/MessageRouterTests` 全パス
  - [ ] assistant メッセージがストリームに yield される
  - [ ] result メッセージがストリームに yield される
  - [ ] can_use_tool → allow レスポンス送信
  - [ ] can_use_tool → deny レスポンス送信
  - [ ] SDK→CLI 制御レスポンスタイムアウト（30 秒）
  - [ ] Actor isolation warning 0

---

## Wave 3-2: ClaudeCodeTransport + ClaudeCodeClient（並列可能: T16, T17）

### T16: Implement ClaudeCodeTransport

- description:
  - AgentTransport 準拠の Claude Code 実装を作成する
  - connect(): CLILocator → CLIProcess.start() → Handshake → isReady
  - close(): CLIProcess.terminate()
  - write(_ data: Data): CLIProcess.writeToStdin()
  - messages(): CLIProcess.stdoutStream() を CLIMessage にデコード
  - JSRuntime enum 定義を含む
  - 完了時: 全テストパス

- spec_refs:
  - FF-001（CLI プロセス管理）
  - FF-002（JSONL トランスポート）
  - FF-003（初期化ハンドシェイク）
  - specs/03_design_spec/08_api_spec.md#2.1 ClaudeCodeTransport
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 3-2 [A]

- agent:
  - general-purpose

- deps:
  - T12 (CLIProcess)
  - T14 (Handshake)
  - T15 (MessageRouter)

- files:
  - create: Sources/AgentSDKClaudeCode/ClaudeCodeTransport.swift
  - create: Tests/AgentSDKClaudeCodeTests/ClaudeCodeTransportTests.swift

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/ClaudeCodeTransportTests.swift
  - coverage_goal: 80%
  - red_phase: connect() 成功/失敗, close() 後の状態, write() で notConnected エラー, messages() ストリーム
  - green_phase: 内部コンポーネントを組み合わせた実装

- verification:
  - [ ] `swift test --filter AgentSDKClaudeCodeTests/ClaudeCodeTransportTests` 全パス
  - [ ] AgentTransport protocol に準拠
  - [ ] connect() で CLI プロセスが起動しハンドシェイク完了
  - [ ] close() でプロセスが終了
  - [ ] 未接続時の write() で `notConnected` エラー
  - [ ] `public` 可視性
  - [ ] Swift 6 strict concurrency warning 0

---

### T17: Implement ClaudeCodeClient

- description:
  - AgentClient 準拠の Claude Code 実装を作成する
  - ClaudeCodeClient<T: AgentTransport> で Transport を generics で DI
  - query(): Transport 接続 → UserMessage 送信 → MessageRouter でストリーム → Transport 切断
  - createSession(): Transport 接続 → ClaudeCodeSession を返す
  - resumeSession(): Transport 接続（--resume 付き）→ ClaudeCodeSession を返す
  - 完了時: 全テストパス

- spec_refs:
  - FF-004（ワンショットクエリ）
  - FF-005（セッション管理）
  - FF-011（プロトコル指向設計 + DI → generics DI）
  - specs/03_design_spec/08_api_spec.md#2.2 ClaudeCodeClient
  - specs/03_design_spec/09_screen_flow.md#2 FF-004 フロー
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 3-2 [B]

- agent:
  - general-purpose

- deps:
  - T15 (MessageRouter)
  - T16 (ClaudeCodeTransport)

- files:
  - create: Sources/AgentSDKClaudeCode/ClaudeCodeClient.swift
  - create: Tests/AgentSDKClaudeCodeTests/ClaudeCodeClientTests.swift (スタブ、本テストは T22)

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/ClaudeCodeClientTests.swift
  - coverage_goal: 80%
  - red_phase: query() のストリーム返却, createSession() で Session 返却, resumeSession() で Session 返却
  - green_phase: Transport + MessageRouter を組み合わせた実装（本格テストは T22 で MockTransport 使用）

- verification:
  - [ ] `swift build` 成功
  - [ ] AgentClient protocol に準拠
  - [ ] associatedtype SessionType = ClaudeCodeSession
  - [ ] query() が AsyncThrowingStream を返す
  - [ ] createSession() が ClaudeCodeSession を返す
  - [ ] `public` 可視性
  - [ ] Swift 6 strict concurrency warning 0

---

## Wave 3-3: ClaudeCodeSession + Convenience API

### T18: Implement ClaudeCodeSession

- description:
  - AgentSession 準拠の Claude Code 実装を作成する
  - final class（参照同一性、deinit でクリーンアップ）
  - send(): UserMessage → Transport → ストリーム返却
  - interrupt(): interrupt 制御リクエスト送信
  - close(): Transport.close()
  - ランタイム制御: setModel, setPermissionMode, rewindFiles, supportedCommands, supportedModels, mcpServerStatus, setMCPServers
  - 完了時: 全テストパス

- spec_refs:
  - FF-005（セッション管理）
  - FF-008（MCP サーバー設定 → setMCPServers, mcpServerStatus）
  - FF-009（ランタイム制御 → setModel, interrupt 等）
  - specs/03_design_spec/08_api_spec.md#3.1 ClaudeCodeSession
  - specs/03_design_spec/08_api_spec.md#3.2 セッション内ランタイム制御
  - specs/03_design_spec/09_screen_flow.md#3 FF-005 フロー
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 3-3

- agent:
  - general-purpose

- deps:
  - T15 (MessageRouter)
  - T17 (ClaudeCodeClient が Session を生成)

- files:
  - create: Sources/AgentSDKClaudeCode/ClaudeCodeSession.swift
  - create: Tests/AgentSDKClaudeCodeTests/ClaudeCodeSessionTests.swift (スタブ、本テストは T22)

- unit_test:
  - required: true
  - test_file: Tests/AgentSDKClaudeCodeTests/ClaudeCodeSessionTests.swift
  - coverage_goal: 80%
  - red_phase: send() ストリーム返却, interrupt() 制御リクエスト送信, close() 後の状態, ランタイム制御メソッド
  - green_phase: MessageRouter 経由の制御リクエスト/レスポンスで実装（本格テストは T22）

- verification:
  - [ ] `swift build` 成功
  - [ ] AgentSession protocol に準拠
  - [ ] final class として定義
  - [ ] Sendable 準拠
  - [ ] send() が AsyncThrowingStream を返す
  - [ ] 全 7 ランタイム制御メソッドが存在する
  - [ ] `public` 可視性
  - [ ] DocC コメントがある

---

### T19: Implement AgentSDK convenience API（本実装）

- description:
  - T8 で作成した AgentSDK namespace スタブに本実装を差し込む
  - query(): 内部で ClaudeCodeTransport + ClaudeCodeClient を生成して実行
  - createSession(): 同上
  - resumeSession(): 同上
  - 完了時: AgentSDK.query/createSession/resumeSession が動作する

- spec_refs:
  - FF-004（ワンショットクエリ）
  - FF-005（セッション管理）
  - specs/03_design_spec/08_api_spec.md#1 コンビニエンス API
  - specs/04_implementation_plan/01_phase_wave_structure.md#Wave 3-3

- agent:
  - general-purpose

- deps:
  - T16 (ClaudeCodeTransport)
  - T17 (ClaudeCodeClient)
  - T18 (ClaudeCodeSession)

- files:
  - modify: Sources/AgentSDK/AgentSDK.swift

- unit_test:
  - required: true
  - test_file: T22 で MockTransport を使用してテスト
  - coverage_goal: 80%
  - red_phase: T22 で実施
  - green_phase: ClaudeCodeTransport + ClaudeCodeClient を内部生成して delegate

- verification:
  - [ ] `swift build` 成功
  - [ ] `AgentSDK.query(prompt:options:)` が AsyncThrowingStream を返す
  - [ ] `AgentSDK.createSession(options:)` が `some AgentSession` を返す
  - [ ] `AgentSDK.resumeSession(id:options:)` が `some AgentSession` を返す
  - [ ] fatalError が除去されている
  - [ ] DocC コメントに使用例が含まれる

---

## Wave 完了チェック

### Wave 3-1 完了後

- [ ] MessageRouter テスト全パス
- [ ] → `/compact` 実行

### Wave 3-2 完了後

- [ ] ClaudeCodeTransport + ClaudeCodeClient がビルド成功
- [ ] → `/compact` 実行

### Wave 3-3 完了後

- [ ] `swift build` 成功
- [ ] AgentSDK convenience API がコンパイル可能
- [ ] → `/compact` 実行

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
