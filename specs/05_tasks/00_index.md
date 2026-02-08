---
title: "Swift Agent SDK - タスク仕様書 インデックス"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks]
references:
  - ../04_implementation_plan/00_index.md
  - ../04_implementation_plan/01_phase_wave_structure.md
  - ../02_requirements/01_feature_overview.md
---

# タスク仕様書: Swift Agent SDK

## Intent（意図）

Implementation Plan の Phase/Wave 構造を実装可能な粒度のタスクに分解する。
各タスクは 1〜4 時間で完了し、verification で完了判断が可能。

---

## Phase/Wave 構造 概要

```
Phase 1: 基盤構築（T1〜T8）
├── Wave 1-1: Package.swift + ディレクトリ構造
│   └── T1: Initialize パッケージ構造
├── Wave 1-2: Protocol 層型定義（並列可能: 3 グループ）
│   ├── T2: Implement Protocol 定義（AgentTransport/Client/Session）
│   ├── T3: Implement Model 型定義（AgentMessage/ContentBlock/JSONValue 等）
│   └── T4: Implement エラー型（AgentSDKError）
└── Wave 1-3: Protocol 層 Unit Tests + AgentSDK スタブ
    ├── T5: Test AgentMessage / ContentBlock / JSONValue テスト
    ├── T6: Test QueryOptions / SessionOptions テスト
    ├── T7: Test AgentSDKError テスト
    └── T8: Implement AgentSDK namespace スタブ

Phase 2: CLI 具象 内部コンポーネント（T9〜T16）
├── Wave 2-1: 低レベル基盤（並列可能: 3 コンポーネント）
│   ├── T9: Implement JSONLCodec
│   ├── T10: Implement CLILocator
│   └── T11: Implement CLIArgBuilder
├── Wave 2-2: CLIProcess Actor
│   └── T12: Implement CLIProcess
└── Wave 2-3: JSONL プロトコル型 + Handshake
    ├── T13: Implement CLIMessage / SDKMessage / ControlMessage 型定義
    └── T14: Implement Handshake

Phase 3: クライアント・セッション実装（T15〜T20）
├── Wave 3-1: MessageRouter Actor
│   └── T15: Implement MessageRouter
├── Wave 3-2: ClaudeCodeTransport + ClaudeCodeClient（並列可能: 2 コンポーネント）
│   ├── T16: Implement ClaudeCodeTransport
│   └── T17: Implement ClaudeCodeClient
└── Wave 3-3: ClaudeCodeSession + Convenience API
    ├── T18: Implement ClaudeCodeSession
    └── T19: Implement AgentSDK convenience API（本実装）

Phase 4: テスト・統合・ドキュメント（T20〜T25）
├── Wave 4-1: AgentSDKTesting モジュール（並列可能）
│   ├── T20: Implement MockTransport
│   └── T21: Implement MockFixtures
├── Wave 4-2: 統合テスト + 具象層テスト
│   ├── T22: Test ClaudeCodeClient（MockTransport 使用）
│   └── T23: Test EndToEnd（統合テスト）
└── Wave 4-3: ドキュメント + リリース準備（並列可能）
    ├── T24: Create README + DocC コメント整備
    └── T25: Configure GitHub Actions CI
```

## タスクサマリー

| Task ID | 名称 | Phase/Wave | 依存 | 見積 |
|---------|------|-----------|------|------|
| T1 | Initialize パッケージ構造 | 1/1-1 | none | 1h |
| T2 | Implement Protocol 定義 | 1/1-2 | T1 | 2h |
| T3 | Implement Model 型定義 | 1/1-2 | T1 | 3h |
| T4 | Implement エラー型 | 1/1-2 | T1 | 1h |
| T5 | Test AgentMessage/ContentBlock/JSONValue | 1/1-3 | T3 | 2h |
| T6 | Test QueryOptions/SessionOptions | 1/1-3 | T3 | 1h |
| T7 | Test AgentSDKError | 1/1-3 | T4 | 1h |
| T8 | Implement AgentSDK namespace スタブ | 1/1-3 | T2, T3 | 1h |
| T9 | Implement JSONLCodec | 2/2-1 | T1 | 2h |
| T10 | Implement CLILocator | 2/2-1 | T4 | 3h |
| T11 | Implement CLIArgBuilder | 2/2-1 | T3 | 2h |
| T12 | Implement CLIProcess | 2/2-2 | T10, T11 | 4h |
| T13 | Implement JSONL プロトコル型 | 2/2-3 | T9 | 2h |
| T14 | Implement Handshake | 2/2-3 | T12, T13 | 3h |
| T15 | Implement MessageRouter | 3/3-1 | T13, T14 | 4h |
| T16 | Implement ClaudeCodeTransport | 3/3-2 | T12, T14, T15 | 3h |
| T17 | Implement ClaudeCodeClient | 3/3-2 | T15, T16 | 3h |
| T18 | Implement ClaudeCodeSession | 3/3-3 | T15, T17 | 3h |
| T19 | Implement AgentSDK convenience API | 3/3-3 | T16, T17, T18 | 2h |
| T20 | Implement MockTransport | 4/4-1 | T2 | 2h |
| T21 | Implement MockFixtures | 4/4-1 | T3, T20 | 1h |
| T22 | Test ClaudeCodeClient（Mock） | 4/4-2 | T17, T18, T20, T21 | 3h |
| T23 | Test EndToEnd（統合テスト） | 4/4-2 | T19 | 3h |
| T24 | Create README + DocC | 4/4-3 | T19, T22 | 3h |
| T25 | Configure GitHub Actions CI | 4/4-3 | T22 | 2h |

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_phase1_foundation.md](./01_phase1_foundation.md) | Phase 1: 基盤構築（T1〜T8） |
| [02_phase2_cli_internals.md](./02_phase2_cli_internals.md) | Phase 2: CLI 具象 内部コンポーネント（T9〜T14） |
| [03_phase3_client_session.md](./03_phase3_client_session.md) | Phase 3: クライアント・セッション（T15〜T19） |
| [04_phase4_test_docs.md](./04_phase4_test_docs.md) | Phase 4: テスト・統合・ドキュメント（T20〜T25） |
| [99_dependencies.md](./99_dependencies.md) | タスク依存関係（テキスト形式） |
| [99_dependency_graph.md](./99_dependency_graph.md) | 依存関係の Mermaid 図 |
| [99_progress.md](./99_progress.md) | 進捗管理・検討事項 |
| [99_references.md](./99_references.md) | 参照マトリクス |

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
