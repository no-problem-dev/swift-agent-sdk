---
title: "ClaudeAgent - タスク仕様書 インデックス"
created: 2026-02-08
status: draft
tags: [tasks, claude-agent]
references:
  - ../04_implementation_plan/00_index.md
  - ../03_design_spec/00_index.md
  - ../02_requirements/00_index.md
---

# タスク仕様書: ClaudeAgent

## 概要

Implementation Plan の Phase/Wave 構造をタスク単位に分解した仕様書。
全 27 タスク、5 Phase、18 Wave で構成される。

## Phase/Wave 構造

```
Phase 1: プロジェクト基盤構築 (T1-T5)
  Wave 1-1: ディレクトリ構造 + project.yml + Makefile (T1)
  Wave 1-2: Package.swift 作成 + 依存解決 (T2, T3, T4)
  Wave 1-3: App ターゲット + エントリポイント (T5)

Phase 2: Domain パッケージ実装 (T6-T11)
  Wave 2-1: エンティティ + 値オブジェクト (T6, T7, T8)
  Wave 2-2: プロトコル + エラー型 (T9, T10)
  Wave 2-3: Domain 総合テスト (T11)

Phase 3: Infrastructure パッケージ実装 (T12-T16)
  Wave 3-1: AgentMessageMapper + AgentService 骨格 (T12, T13)
  Wave 3-2: JSONSessionStore 実装 (T14)
  Wave 3-3: AgentService 完全実装 + Integration Test (T15, T16)

Phase 4: Presentation パッケージ実装 (T17-T24)
  Wave 4-1: AppState + SessionState 骨格 (T17)
  Wave 4-2: 基本 View (T18, T19, T20)
  Wave 4-3: ChatView + MessageBubble + StreamingTextView (T21)
  Wave 4-4: ToolUseCard + ToolResultCard + NewSessionSheet (T22)
  Wave 4-5: Store ロジック + Presentation Unit Test (T23, T24)

Phase 5: 統合・テスト・仕上げ (T25-T27)
  Wave 5-1: DI ワイヤリング + 統合ビルド (T25)
  Wave 5-2: Integration Test + E2E テスト (T26)
  Wave 5-3: Manual QA + 最終調整 + README (T27)
```

## 並列化可能領域

```
Phase 1 (基盤)
  |
Phase 2 (Domain)
  |
  +-- Phase 3 (Infrastructure) --+
  |                               |
  +-- Phase 4 (Presentation) ----+
                                  |
                           Phase 5 (統合)
```

> Phase 3 と Phase 4 は Phase 2 完了後に **並列実行可能**。

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_phase1_foundation.md](./01_phase1_foundation.md) | Phase 1: プロジェクト基盤構築 (T1-T5) |
| [02_phase2_domain.md](./02_phase2_domain.md) | Phase 2: Domain パッケージ実装 (T6-T11) |
| [03_phase3_infrastructure.md](./03_phase3_infrastructure.md) | Phase 3: Infrastructure パッケージ実装 (T12-T16) |
| [04_phase4_presentation.md](./04_phase4_presentation.md) | Phase 4: Presentation パッケージ実装 (T17-T24) |
| [05_phase5_integration.md](./05_phase5_integration.md) | Phase 5: 統合・テスト・仕上げ (T25-T27) |
| [99_dependencies.md](./99_dependencies.md) | タスク依存関係（テキスト形式） |
| [99_dependency_graph.md](./99_dependency_graph.md) | 依存関係の Mermaid 図 |
| [99_progress.md](./99_progress.md) | 進捗管理・検討事項 |
| [99_references.md](./99_references.md) | 参照マトリクス |

## タスクサマリー

| ID | タスク | Phase/Wave | パッケージ |
|----|--------|-----------|-----------|
| T1 | Initialize プロジェクト構造セットアップ | P1-W1 | App/全体 |
| T2 | Configure Domain Package.swift | P1-W2 | Domain |
| T3 | Configure Infrastructure Package.swift | P1-W2 | Infrastructure |
| T4 | Configure Presentation Package.swift | P1-W2 | Presentation |
| T5 | Implement App エントリポイント + 統合ビルド | P1-W3 | App |
| T6 | Implement Domain エンティティ | P2-W1 | Domain |
| T7 | Implement Domain 値オブジェクト + イベント型 | P2-W1 | Domain |
| T8 | Test Domain エンティティ Unit Test | P2-W1 | Domain |
| T9 | Implement Domain プロトコル | P2-W2 | Domain |
| T10 | Implement Domain AppError | P2-W2 | Domain |
| T11 | Test Domain 総合テスト + クリーンアップ | P2-W3 | Domain |
| T12 | Implement AgentMessageMapper | P3-W1 | Infrastructure |
| T13 | Implement AgentService 骨格 | P3-W1 | Infrastructure |
| T14 | Implement JSONSessionStore | P3-W2 | Infrastructure |
| T15 | Implement AgentService 完全実装 | P3-W3 | Infrastructure |
| T16 | Test AgentService Integration Test | P3-W3 | Infrastructure |
| T17 | Implement AppState + SessionState 骨格 | P4-W1 | Presentation |
| T18 | Create ContentView + EmptySessionView | P4-W2 | Presentation |
| T19 | Create SessionSidebar + SessionRow + StatusBadge | P4-W2 | Presentation |
| T20 | Create InputArea | P4-W2 | Presentation |
| T21 | Create ChatView + MessageBubble + StreamingTextView | P4-W3 | Presentation |
| T22 | Create ToolUseCard + ToolResultCard + NewSessionSheet | P4-W4 | Presentation |
| T23 | Implement Store ロジック完全実装 | P4-W5 | Presentation |
| T24 | Test Presentation Unit Test | P4-W5 | Presentation |
| T25 | Implement DI ワイヤリング + 統合ビルド | P5-W1 | App |
| T26 | Verify Integration Test + E2E テスト | P5-W2 | 全体 |
| T27 | QA Manual QA + 最終調整 + README | P5-W3 | 全体 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
