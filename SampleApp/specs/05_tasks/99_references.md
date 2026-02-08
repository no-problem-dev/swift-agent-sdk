---
title: "ClaudeAgent - 参照マトリクス"
created: 2026-02-08
status: draft
tags: [tasks, references, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/01_feature_overview.md
  - ../04_implementation_plan/99_references.md
---

# 参照マトリクス

## FF → タスクマッピング

| FF-ID | FF 名称 | 関連タスク |
|-------|---------|----------|
| FF-001 | セッション管理 | T6 (SessionData, SessionConfig), T9 (AgentServiceProtocol), T17 (AppState, SessionState), T19 (SessionSidebar), T22 (NewSessionSheet), T23 (Store ロジック), T25 (DI) |
| FF-002 | チャットメッセージング | T6 (ChatMessage, ContentItem), T20 (InputArea), T21 (ChatView, MessageBubble, StreamingTextView), T23 (send/interrupt ロジック) |
| FF-003 | ツール可視化 | T6 (ToolUseItem, ToolResultItem), T12 (AgentMessageMapper), T22 (ToolUseCard, ToolResultCard) |
| FF-004 | モデル・設定制御 | T7 (ModelSelection, TokenUsage), T15 (setModel), T18 (ContentView ツールバー), T23 (setModel ロジック) |
| FF-005 | データ永続化 | T9 (SessionStoreProtocol), T14 (JSONSessionStore), T23 (save/load ロジック), T25 (アプリ終了時保存) |

## 機能別参照仕様マトリクス

| 機能 | Requirements | Design Spec | Implementation Plan |
|------|-------------|-------------|-------------------|
| セッション管理 (FF-001) | `02_requirements/03_functional_requirements.md#FR-001`〜`#FR-007` | `03_design_spec/04_component_architecture.md#AppState`, `#SessionState`, `05_data_model.md#SessionData` | `04_implementation_plan/06_phase4_presentation.md#Wave-4-1`, `#Wave-4-5` |
| チャットメッセージング (FF-002) | `02_requirements/03_functional_requirements.md#FR-008`〜`#FR-012` | `03_design_spec/04_component_architecture.md#メッセージストリーム処理フロー`, `05_data_model.md#ChatMessage` | `04_implementation_plan/06_phase4_presentation.md#Wave-4-3` |
| ツール可視化 (FF-003) | `02_requirements/03_functional_requirements.md#FR-013`〜`#FR-015` | `03_design_spec/04_component_architecture.md#ToolUseCard`, `#ToolResultCard`, `05_data_model.md#ToolUseItem` | `04_implementation_plan/06_phase4_presentation.md#Wave-4-4` |
| モデル・設定制御 (FF-004) | `02_requirements/03_functional_requirements.md#FR-016`〜`#FR-020` | `03_design_spec/05_data_model.md#ModelSelection`, `#TokenUsage` | `04_implementation_plan/05_phase3_infrastructure.md#Wave-3-3` |
| データ永続化 (FF-005) | `02_requirements/03_functional_requirements.md#FR-021`〜`#FR-024` | `03_design_spec/04_component_architecture.md#JSONSessionStore`, `05_data_model.md#永続化仕様` | `04_implementation_plan/05_phase3_infrastructure.md#Wave-3-2` |

## タスク → 参照仕様マトリクス

| Task | FF-ID | Requirements | Design Spec | Implementation Plan |
|------|-------|-------------|-------------|-------------------|
| T1 | - | - | `01_architecture.md#プロジェクト構成`, `#project-yml`, `#Makefile` | `03_phase1_foundation.md#Wave-1-1` |
| T2 | - | - | `03_layer_architecture.md#Domain-Package-swift` | `03_phase1_foundation.md#Wave-1-2` |
| T3 | - | - | `03_layer_architecture.md#Infrastructure-Package-swift` | `03_phase1_foundation.md#Wave-1-2` |
| T4 | - | - | `03_layer_architecture.md#Presentation-Package-swift` | `03_phase1_foundation.md#Wave-1-2` |
| T5 | - | - | `03_layer_architecture.md#App-ターゲット` | `03_phase1_foundation.md#Wave-1-3` |
| T6 | FF-001,002,003 | FR-001〜FR-015 | `05_data_model.md#Domain-エンティティ` | `04_phase2_domain.md#Wave-2-1` |
| T7 | FF-004 | FR-016〜FR-020 | `05_data_model.md`, `04_component_architecture.md#AgentEvent` | `04_phase2_domain.md#Wave-2-1` |
| T8 | - | - | - | `04_phase2_domain.md#Wave-2-1`, `08_test_strategy.md` |
| T9 | FF-001,002,005 | FR-001〜FR-024 | `04_component_architecture.md#AgentServiceProtocol`, `#SessionStoreProtocol` | `04_phase2_domain.md#Wave-2-2` |
| T10 | - | - | `04_component_architecture.md#AppError` | `04_phase2_domain.md#Wave-2-2` |
| T11 | - | - | - | `04_phase2_domain.md#Wave-2-3`, `08_test_strategy.md` |
| T12 | FF-003 | FR-013〜FR-015 | `04_component_architecture.md#AgentMessageMapper`, `03_layer_architecture.md#SDK-型マッピング` | `05_phase3_infrastructure.md#Wave-3-1` |
| T13 | FF-001,002 | - | `04_component_architecture.md#AgentService` | `05_phase3_infrastructure.md#Wave-3-1` |
| T14 | FF-005 | FR-021〜FR-024 | `04_component_architecture.md#JSONSessionStore`, `05_data_model.md#永続化仕様` | `05_phase3_infrastructure.md#Wave-3-2` |
| T15 | FF-001,002,004 | - | `04_component_architecture.md#AgentService` | `05_phase3_infrastructure.md#Wave-3-3` |
| T16 | - | - | - | `05_phase3_infrastructure.md#Wave-3-3`, `08_test_strategy.md` |
| T17 | FF-001,002 | - | `04_component_architecture.md#AppState`, `#SessionState` | `06_phase4_presentation.md#Wave-4-1` |
| T18 | - | - | `09_screen_flow.md#画面構成` | `06_phase4_presentation.md#Wave-4-2` |
| T19 | FF-001 | FR-002, FR-003 | `09_screen_flow.md` | `06_phase4_presentation.md#Wave-4-2` |
| T20 | FF-002 | FR-008, FR-011 | - | `06_phase4_presentation.md#Wave-4-2` |
| T21 | FF-002,003 | FR-009, FR-010 | `09_screen_flow.md` | `06_phase4_presentation.md#Wave-4-3` |
| T22 | FF-001,003 | FR-001, FR-013, FR-014 | - | `06_phase4_presentation.md#Wave-4-4` |
| T23 | FF-001,002,004,005 | - | `04_component_architecture.md#メッセージストリーム処理フロー` | `06_phase4_presentation.md#Wave-4-5` |
| T24 | - | - | - | `06_phase4_presentation.md#Wave-4-5`, `08_test_strategy.md` |
| T25 | FF-001,005 | - | `01_architecture.md#DI-方針`, `12_risks.md#R-5` | `07_phase5_integration.md#Wave-5-1` |
| T26 | - | UC-1〜UC-4 | - | `07_phase5_integration.md#Wave-5-2`, `#Wave-5-3` |
| T27 | - | NFR-001〜NFR-004 | `12_risks.md` | `07_phase5_integration.md#Wave-5-4`, `09_rollout.md` |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
