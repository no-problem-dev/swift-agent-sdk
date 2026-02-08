---
title: "ClaudeAgent - タスク依存関係"
created: 2026-02-08
status: draft
tags: [tasks, dependencies, claude-agent]
references:
  - ./00_index.md
---

# タスク依存関係

## Phase 1: プロジェクト基盤構築

| タスク | 依存先 | 備考 |
|--------|--------|------|
| T1 | none | 最初のタスク |
| T2 | T1 | Domain Package.swift |
| T3 | T1 | Infrastructure Package.swift |
| T4 | T1 | Presentation Package.swift |
| T5 | T2, T3, T4 | 統合ビルド（全パッケージ必要） |

## Phase 2: Domain パッケージ実装

| タスク | 依存先 | 備考 |
|--------|--------|------|
| T6 | T2 | Domain エンティティ |
| T7 | T2 | Domain 値オブジェクト + イベント |
| T8 | T2 | Domain テスト（T6/T7 と並列で TDD） |
| T9 | T6, T7 | プロトコル（エンティティに依存） |
| T10 | T6 | AppError |
| T11 | T9, T10 | Domain 総合テスト |

## Phase 3: Infrastructure パッケージ実装

| タスク | 依存先 | 備考 |
|--------|--------|------|
| T12 | T11 | AgentMessageMapper |
| T13 | T11 | AgentService 骨格 |
| T14 | T11 | JSONSessionStore |
| T15 | T12, T13 | AgentService 完全実装 |
| T16 | T15 | AgentService Integration Test |

## Phase 4: Presentation パッケージ実装

| タスク | 依存先 | 備考 |
|--------|--------|------|
| T17 | T11 | AppState + SessionState 骨格 |
| T18 | T17 | ContentView |
| T19 | T17 | SessionSidebar |
| T20 | T17 | InputArea |
| T21 | T18, T20 | ChatView（ContentView + InputArea 必要） |
| T22 | T17 | ToolUseCard + NewSessionSheet |
| T23 | T21, T22 | Store ロジック完全実装 |
| T24 | T23 | Presentation Unit Test |

## Phase 5: 統合・テスト・仕上げ

| タスク | 依存先 | 備考 |
|--------|--------|------|
| T25 | T16, T24 | DI ワイヤリング（Infrastructure + Presentation 完了） |
| T26 | T25 | Integration Test + E2E |
| T27 | T26 | Manual QA + README |

## 並列実行可能なタスクグループ

### Wave 内の並列タスク

| Wave | 並列タスク | ファイル競合チェック |
|------|----------|-----------------|
| P1-W2 | T2, T3, T4 | 競合なし（異なるパッケージの Package.swift） |
| P2-W1 | T6, T7, T8 | 競合なし（Entities/, ValueObjects/, Tests/ で分離） |
| P2-W2 | T9, T10 | 競合なし（Protocols/, Errors/ で分離） |
| P3-W1 | T12, T13 | 競合なし（Mappers/, Services/ で分離） |
| P4-W2 | T18, T19, T20 | 競合なし（Views/ContentView, Views/Sidebar/, Views/Input/ で分離） |

### Phase 間の並列実行

- Phase 3（T12-T16）と Phase 4（T17-T24）は Phase 2 完了後に **並列実行可能**
- 両パッケージは Domain にのみ依存し、互いに依存しない

## Wave 競合チェックテーブル

### P1-W2

| Task | files.create | files.modify | 競合 |
|------|-------------|--------------|------|
| T2 | Domain/Package.swift | - | - |
| T3 | Infrastructure/Package.swift | - | - |
| T4 | Presentation/Package.swift | - | - |

→ **競合なし**: 異なるパッケージの Package.swift

### P2-W1

| Task | files.create | files.modify | 競合 |
|------|-------------|--------------|------|
| T6 | Entities/*.swift | - | - |
| T7 | ValueObjects/*.swift, Events/*.swift | - | - |
| T8 | Tests/DomainTests/*.swift | - | - |

→ **競合なし**: 異なるディレクトリ

### P4-W2

| Task | files.create | files.modify | 競合 |
|------|-------------|--------------|------|
| T18 | Views/ContentView.swift, Common/EmptySessionView.swift | - | - |
| T19 | Sidebar/*.swift, Common/StatusBadge.swift | - | - |
| T20 | Input/InputArea.swift | - | - |

→ **競合なし**: 異なるディレクトリ

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
