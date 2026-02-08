---
title: "ClaudeAgent - FF 単位参照マトリクス"
created: 2026-02-08
status: draft
tags: [implementation-plan, references, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/01_feature_overview.md
  - ../02_requirements/03_functional_requirements.md
  - ../03_design_spec/00_index.md
---

# FF 単位参照マトリクス

## 参照マトリクス

| FF-ID | FF 名称 | 参照仕様 |
|-------|---------|---------|
| FF-001 | セッション管理 | `02_requirements/03_functional_requirements.md#FR-001`〜`#FR-007`, `03_design_spec/04_component_architecture.md#AppState`, `03_design_spec/04_component_architecture.md#SessionState`, `03_design_spec/05_data_model.md#SessionData`, `03_design_spec/05_data_model.md#SessionConfig`, `03_design_spec/09_screen_flow.md#FF-001` |
| FF-002 | チャットメッセージング | `02_requirements/03_functional_requirements.md#FR-008`〜`#FR-012`, `03_design_spec/04_component_architecture.md#メッセージストリーム処理フロー`, `03_design_spec/04_component_architecture.md#SessionState`, `03_design_spec/05_data_model.md#ChatMessage`, `03_design_spec/09_screen_flow.md#FF-002` |
| FF-003 | ツール可視化 | `02_requirements/03_functional_requirements.md#FR-013`〜`#FR-015`, `03_design_spec/04_component_architecture.md#ToolUseCard`, `03_design_spec/04_component_architecture.md#ToolResultCard`, `03_design_spec/05_data_model.md#ToolUseItem`, `03_design_spec/05_data_model.md#ToolResultItem`, `03_design_spec/09_screen_flow.md#FF-003` |
| FF-004 | モデル・設定制御 | `02_requirements/03_functional_requirements.md#FR-016`〜`#FR-020`, `03_design_spec/05_data_model.md#ModelSelection`, `03_design_spec/05_data_model.md#TokenUsage`, `03_design_spec/09_screen_flow.md#FF-004` |
| FF-005 | データ永続化 | `02_requirements/03_functional_requirements.md#FR-021`〜`#FR-024`, `02_requirements/05_io_spec.md#データ永続化-IO`, `03_design_spec/04_component_architecture.md#JSONSessionStore`, `03_design_spec/05_data_model.md#永続化仕様`, `03_design_spec/09_screen_flow.md#FF-005` |

## FF → Phase/Wave マッピング

| FF-ID | 関連 Phase/Wave | 説明 |
|-------|---------------|------|
| FF-001 | P2-W1 (SessionData, SessionConfig), P4-W1 (AppState), P4-W2 (SessionSidebar), P4-W4 (NewSessionSheet), P4-W5 (Store ロジック) | セッション管理は複数 Wave にまたがる |
| FF-002 | P2-W1 (ChatMessage, ContentItem), P4-W3 (ChatView, MessageBubble, StreamingTextView), P4-W2 (InputArea), P4-W5 (send/interrupt ロジック) | メッセージングの UI + ロジック |
| FF-003 | P2-W1 (ToolUseItem, ToolResultItem), P3-W1 (AgentMessageMapper), P4-W4 (ToolUseCard, ToolResultCard) | ツール可視化はマッピング + View |
| FF-004 | P2-W1 (ModelSelection, TokenUsage), P3-W3 (setModel), P4-W2 (ContentView ツールバー), P4-W5 (setModel ロジック) | 設定制御は薄い |
| FF-005 | P2-W2 (SessionStoreProtocol), P3-W2 (JSONSessionStore), P4-W5 (save/load ロジック), P5-W1 (アプリ終了時保存) | 永続化は Infrastructure + Store |

## FR → 実装ファイルマッピング

| FR | 実装ファイル（パッケージ/パス） |
|----|----------------------------|
| FR-001 | `Presentation/Stores/AppState.swift#createSession`, `Presentation/Views/Sheets/NewSessionSheet.swift` |
| FR-002 | `Presentation/Stores/AppState.swift#sortedSessions`, `Presentation/Views/Sidebar/SessionSidebar.swift` |
| FR-003 | `Presentation/Stores/AppState.swift#activeSessionId`, `Presentation/Views/Sidebar/SessionRow.swift` |
| FR-004 | `Presentation/Stores/SessionState.swift#reconnect`, `Infrastructure/Services/AgentService.swift#resumeSession` |
| FR-005 | `Presentation/Stores/SessionState.swift#disconnect`, `Infrastructure/Services/AgentService.swift#close` |
| FR-006 | `Presentation/Stores/AppState.swift#deleteSession`, `Infrastructure/Persistence/JSONSessionStore.swift#delete` |
| FR-007 | `Presentation/Views/Sidebar/SessionRow.swift` (名前変更 UI) |
| FR-008 | `Presentation/Stores/SessionState.swift#send`, `Presentation/Views/Input/InputArea.swift` |
| FR-009 | `Presentation/Stores/SessionState.swift#streamingText`, `Presentation/Views/Chat/StreamingTextView.swift` |
| FR-010 | `Presentation/Views/Chat/MessageBubble.swift`, `Presentation/Views/Chat/ChatView.swift` |
| FR-011 | `Presentation/Stores/SessionState.swift#interrupt`, `Presentation/Views/Input/InputArea.swift` |
| FR-012 | `Presentation/Stores/SessionState.swift#send` (turnCompleted ハンドリング) |
| FR-013 | `Presentation/Views/Chat/ToolUseCard.swift` |
| FR-014 | `Presentation/Views/Chat/ToolResultCard.swift` |
| FR-015 | `Presentation/Views/Chat/MessageBubble.swift` (ToolUse + ToolResult ペアリング) |
| FR-016 | `Presentation/Stores/SessionState.swift#setModel`, ContentView ツールバー |
| FR-017 | ContentView ツールバー（config.workingDirectory 表示） |
| FR-018 | `Presentation/Views/Sheets/NewSessionSheet.swift` |
| FR-019 | ContentView ツールバー（totalCostUsd 表示） |
| FR-020 | ContentView ツールバー（lastTokenUsage 表示） |
| FR-021 | `Infrastructure/Persistence/JSONSessionStore.swift#save`, `Presentation/Stores/AppState.swift#createSession` |
| FR-022 | `Presentation/Stores/SessionState.swift#send` (turnCompleted → saveAllSessions) |
| FR-023 | `Presentation/Stores/AppState.swift#loadSavedSessions`, `Infrastructure/Persistence/JSONSessionStore.swift#loadAll` |
| FR-024 | `Presentation/Stores/AppState.swift#deleteSession`, `Infrastructure/Persistence/JSONSessionStore.swift#delete` |

## AI への指示構成テンプレート

タスク実行時に以下の形式で参照仕様を指定する:

```
## タスク: {タスク概要}

## FF コンテキスト
FF-ID: {FF-001 等}
参照仕様:
- {99_references.md の該当行をコピー}

## 実装対象
パッケージ: {Domain / Infrastructure / Presentation}
ファイル: {対象ファイルパス}

## 設計仕様
- {03_design_spec の該当セクションへのリンク}

## 完了基準
- {具体的な基準}
```

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
