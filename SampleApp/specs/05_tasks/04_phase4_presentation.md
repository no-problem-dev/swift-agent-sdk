---
title: "ClaudeAgent - Phase 4: Presentation パッケージ実装タスク"
created: 2026-02-08
status: draft
tags: [tasks, phase4, presentation, claude-agent]
references:
  - ../04_implementation_plan/06_phase4_presentation.md
  - ../03_design_spec/03_layer_architecture.md#Presentation
  - ../03_design_spec/04_component_architecture.md#Presentation-コンポーネント詳細
  - ../03_design_spec/09_screen_flow.md
---

# Phase 4: Presentation パッケージ実装 (T17-T24)

> Phase 3 と **並列実行可能**（Phase 2 完了後）

## Wave 4-1: AppState + SessionState 骨格

---

## T17: Implement AppState + SessionState 骨格

- description:
  - AppState と SessionState の Store クラスを @Observable + @MainActor で骨格作成する
  - プロパティ定義、computed property、メソッドシグネチャのみ
  - メソッドの実装ロジックは Wave 4-5（T23）で行う
  - Domain プロトコルへの依存のみ（Infrastructure を import しない）
  - 完了時: コンパイル成功、`swift build --package-path Packages/Presentation` 成功

- spec_refs:
  - FF-001（セッション管理）
  - FF-002（チャットメッセージング）
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-1
  - specs/03_design_spec/04_component_architecture.md#AppState
  - specs/03_design_spec/04_component_architecture.md#SessionState

- agent:
  - general-purpose

- deps:
  - T11 (Domain 完了)

- package: Presentation

- files:
  - create: Packages/Presentation/Sources/Presentation/Stores/AppState.swift
  - create: Packages/Presentation/Sources/Presentation/Stores/SessionState.swift

- unit_test:
  - required: false

- verification:
  - [ ] AppState が @Observable @MainActor で定義されている
  - [ ] SessionState が @Observable @MainActor + Identifiable で定義されている
  - [ ] Domain プロトコル（AgentServiceProtocol, SessionStoreProtocol）のみに依存
  - [ ] Infrastructure を import していない
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-2: 基本 View

---

## T18: Create ContentView + EmptySessionView

- description:
  - ContentView: NavigationSplitView でサイドバー + ディテールのルートビュー
  - EmptySessionView: セッション未選択時のプレースホルダー
  - ThemeProvider（swift-design-system）でアプリ全体をラップ
  - ツールバーの骨格（モデル選択・コスト表示）を配置
  - 完了時: コンパイル成功、Xcode Preview で表示される

- spec_refs:
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-2
  - specs/03_design_spec/09_screen_flow.md#画面構成

- agent:
  - general-purpose

- deps:
  - T17

- package: Presentation

- files:
  - create: Packages/Presentation/Sources/Presentation/Views/ContentView.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Common/EmptySessionView.swift

- unit_test:
  - required: false

- verification:
  - [ ] ContentView がコンパイル成功
  - [ ] NavigationSplitView でサイドバー + ディテール構成
  - [ ] EmptySessionView が「Cmd+N で新規セッションを作成」のガイドを表示
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## T19: Create SessionSidebar + SessionRow + StatusBadge

- description:
  - SessionSidebar: セッション一覧を List + ForEach で表示、+ ボタン、コンテキストメニュー
  - SessionRow: セッション名、ステータスバッジ、モデル名、最終アクティブ日時を表示
  - StatusBadge: SessionStatus に対応した色付きバッジ（connected→緑、connecting→黄、disconnected→グレー、error→赤）
  - 完了時: コンパイル成功

- spec_refs:
  - FF-001（セッション管理）
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-2
  - specs/03_design_spec/09_screen_flow.md

- agent:
  - general-purpose

- deps:
  - T17

- package: Presentation

- files:
  - create: Packages/Presentation/Sources/Presentation/Views/Sidebar/SessionSidebar.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Sidebar/SessionRow.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Common/StatusBadge.swift

- unit_test:
  - required: false

- verification:
  - [ ] SessionSidebar がコンパイル成功
  - [ ] SessionRow がセッション名 + ステータスバッジを表示
  - [ ] StatusBadge が 4 種類のステータスに色分け対応
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## T20: Create InputArea

- description:
  - TextEditor で複数行入力対応のメッセージ入力エリアを実装する
  - Enter で送信、Shift+Enter で改行
  - ストリーミング中は停止ボタン表示（送信ボタンと切替）
  - セッション未接続・処理中は入力無効化
  - 完了時: コンパイル成功

- spec_refs:
  - FF-002（チャットメッセージング）
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-2
  - specs/02_requirements/03_functional_requirements.md#FR-008
  - specs/02_requirements/03_functional_requirements.md#FR-011

- agent:
  - general-purpose

- deps:
  - T17

- package: Presentation

- files:
  - create: Packages/Presentation/Sources/Presentation/Views/Input/InputArea.swift

- unit_test:
  - required: false

- verification:
  - [ ] InputArea がコンパイル成功
  - [ ] 送信ボタンと停止ボタンの切替ロジックが実装されている
  - [ ] テキスト空欄または未接続時に送信ボタン無効化
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-3: ChatView + MessageBubble + StreamingTextView

---

## T21: Create ChatView + MessageBubble + StreamingTextView

- description:
  - ChatView: ScrollView + LazyVStack でメッセージ一覧表示、自動スクロール、下部に InputArea
  - MessageBubble: role に応じた左右寄せバブル、ContentItem の forEach 表示（.text→MarkdownView, .toolUse→ToolUseCard, .toolResult→ToolResultCard）
  - StreamingTextView: ストリーミング中の部分テキスト + カーソルアニメーション
  - 完了時: コンパイル成功、Xcode Preview で Mock メッセージが表示される

- spec_refs:
  - FF-002（チャットメッセージング）
  - FF-003（ツール可視化）
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-3
  - specs/03_design_spec/09_screen_flow.md
  - specs/02_requirements/03_functional_requirements.md#FR-009
  - specs/02_requirements/03_functional_requirements.md#FR-010

- agent:
  - general-purpose

- deps:
  - T18
  - T20

- package: Presentation

- files:
  - create: Packages/Presentation/Sources/Presentation/Views/Chat/ChatView.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Chat/MessageBubble.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Chat/StreamingTextView.swift

- unit_test:
  - required: false

- verification:
  - [ ] ChatView がコンパイル成功
  - [ ] MessageBubble が role に応じた左右寄せを行う
  - [ ] StreamingTextView がカーソルアニメーション付きで表示
  - [ ] 自動スクロール（ScrollViewReader + onChange）が実装されている
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-4: ToolUseCard + ToolResultCard + NewSessionSheet

---

## T22: Create ToolUseCard + ToolResultCard + NewSessionSheet

- description:
  - ToolUseCard: DesignSystem Card でツール名 + パラメータ表示
  - ToolResultCard: DisclosureGroup で折りたたみ/展開、isError 時は赤系背景
  - NewSessionSheet: 作業ディレクトリ選択（NSOpenPanel）、モデル選択 Picker、システムプロンプト入力、作成/キャンセルボタン
  - 完了時: コンパイル成功、Xcode Preview で正しく表示

- spec_refs:
  - FF-001（セッション管理）
  - FF-003（ツール可視化）
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-4
  - specs/02_requirements/03_functional_requirements.md#FR-001
  - specs/02_requirements/03_functional_requirements.md#FR-013
  - specs/02_requirements/03_functional_requirements.md#FR-014

- agent:
  - general-purpose

- deps:
  - T17

- package: Presentation

- files:
  - create: Packages/Presentation/Sources/Presentation/Views/Chat/ToolUseCard.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Chat/ToolResultCard.swift
  - create: Packages/Presentation/Sources/Presentation/Views/Sheets/NewSessionSheet.swift

- unit_test:
  - required: false

- verification:
  - [ ] ToolUseCard がツール名 + パラメータをカード表示
  - [ ] ToolResultCard の折りたたみ/展開が動作
  - [ ] ToolResultCard が isError 時に赤系背景
  - [ ] NewSessionSheet のフォームが表示される
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-5: Store ロジック完全実装 + Presentation Unit Test

---

## T23: Implement Store ロジック完全実装

- description:
  - AppState: createSession, deleteSession, loadSavedSessions, saveAllSessions の全アクションを実装
  - SessionState: send, interrupt, reconnect, disconnect, setModel の全アクションを実装
  - ストリーム処理フローを Design Spec に準拠して実装
  - DateFormatting ユーティリティを追加
  - 完了時: 全アクションが実装済み、コンパイル成功

- spec_refs:
  - FF-001（セッション管理）
  - FF-002（チャットメッセージング）
  - FF-004（モデル・設定制御）
  - FF-005（データ永続化）
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-5
  - specs/03_design_spec/04_component_architecture.md#メッセージストリーム処理フロー

- agent:
  - general-purpose

- deps:
  - T21
  - T22

- package: Presentation

- files:
  - modify: Packages/Presentation/Sources/Presentation/Stores/AppState.swift
  - modify: Packages/Presentation/Sources/Presentation/Stores/SessionState.swift
  - create: Packages/Presentation/Sources/Presentation/Utilities/DateFormatting.swift

- unit_test:
  - required: true
  - test_file: Packages/Presentation/Tests/PresentationTests/ (T24 で作成)
  - coverage_goal: 60%
  - red_phase: T24 で Mock を使った Store テストを先に作成
  - green_phase: テストが通る実装

- verification:
  - [ ] AppState.createSession: sessions に追加 + activeSessionId 設定
  - [ ] AppState.deleteSession: sessions から除去 + store.delete 呼び出し
  - [ ] AppState.loadSavedSessions: store.loadAll の結果が反映
  - [ ] SessionState.send: messages にユーザーメッセージ追加 → ストリーム処理
  - [ ] SessionState.interrupt: isProcessing = false に遷移
  - [ ] `swift build --package-path Packages/Presentation` 成功

---

## T24: Test Presentation Unit Test

- description:
  - MockAgentService, MockSessionStore を Presentation テスト内に作成する
  - AppState テスト: createSession → sessions 追加、deleteSession → 除去、loadSavedSessions
  - SessionState テスト: send → messages 追加 + ストリーム処理、interrupt → isProcessing = false、reconnect → status = .connected
  - Placeholder ファイルを削除する
  - 完了時: 全テストパス、Placeholder 削除済み

- spec_refs:
  - specs/04_implementation_plan/06_phase4_presentation.md#Wave-4-5
  - specs/04_implementation_plan/08_test_strategy.md#Presentation-テスト用

- agent:
  - general-purpose

- deps:
  - T23

- package: Presentation

- files:
  - create: Packages/Presentation/Tests/PresentationTests/Mocks/MockAgentService.swift
  - create: Packages/Presentation/Tests/PresentationTests/Mocks/MockSessionStore.swift
  - create: Packages/Presentation/Tests/PresentationTests/AppStateTests.swift
  - create: Packages/Presentation/Tests/PresentationTests/SessionStateTests.swift
  - delete: Packages/Presentation/Sources/Presentation/Placeholder.swift
  - delete: Packages/Presentation/Tests/PresentationTests/PlaceholderTests.swift

- unit_test:
  - required: true
  - test_file: 上記 4 ファイル（Mocks 含む）
  - coverage_goal: 60%
  - red_phase: Mock を作成し、AppState/SessionState の主要アクションのテストを先に作成
  - green_phase: テストパスを確認

- verification:
  - [ ] MockAgentService が AgentServiceProtocol に準拠
  - [ ] MockSessionStore が SessionStoreProtocol に準拠
  - [ ] AppStateTests: createSession/deleteSession/loadSavedSessions テストパス
  - [ ] SessionStateTests: send/interrupt/reconnect テストパス
  - [ ] `swift test --package-path Packages/Presentation` 全テストパス
  - [ ] Placeholder.swift が削除済み

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
