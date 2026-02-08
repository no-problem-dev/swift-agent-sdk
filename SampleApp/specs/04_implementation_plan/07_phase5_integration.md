---
title: "ClaudeAgent - Phase 5: 統合・テスト・仕上げ"
created: 2026-02-08
status: draft
tags: [implementation-plan, phase5, integration, claude-agent]
references:
  - ./00_index.md
  - ./01_phase_overview.md
  - ../03_design_spec/01_architecture.md#DI-方針
  - ../03_design_spec/12_risks.md
  - ../02_requirements/04_non_functional_requirements.md
---

# Phase 5: 統合・テスト・仕上げ

## 目的

3 パッケージを App ターゲットで統合し、DI ワイヤリングを行う。
実 SDK 接続でのテスト、全ユースケースの動作確認、NFR の検証を実施する。

## 前提

- Phase 3（Infrastructure）完了
- Phase 4（Presentation）完了

---

## Wave 5-1: App ターゲット DI ワイヤリング + 統合ビルド

### 実装内容

#### App/Sources/ClaudeAgentApp.swift

`specs/03_design_spec/01_architecture.md#DI-方針` に準拠して DI ワイヤリングを実装する。

```swift
import SwiftUI
import Domain
import Infrastructure
import Presentation

@main
struct ClaudeAgentApp: App {
    @State private var appState: AppState

    init() {
        let agentService = AgentService()
        let sessionStore = JSONSessionStore()

        _appState = State(initialValue: AppState(
            agentService: agentService,
            sessionStore: sessionStore
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear { appState.loadSavedSessions() }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新規セッション") { /* Sheet 表示 */ }
                    .keyboardShortcut("n")
            }
        }
    }
}
```

**追加実装:**
- アプリ終了時の全セッション保存: `NSApplication.willTerminateNotification` で `saveAllSessions()` + 全セッション `close()`
- `specs/03_design_spec/12_risks.md#R-5` のゾンビプロセス対策

### 完了基準

- [ ] `xcodegen generate` 成功
- [ ] `xcodebuild build -project ClaudeAgent.xcodeproj -scheme ClaudeAgent -destination 'platform=macOS'` 成功
- [ ] アプリ起動時にウィンドウが表示される
- [ ] サイドバー + チャットエリアのレイアウトが表示される

---

## Wave 5-2: Integration Test（実 SDK 接続）

### 実装内容

実際の Claude Code CLI に接続してのインテグレーションテスト。

**前提条件:**
- `claude login` 完了済み
- Node.js 18+ インストール済み
- Claude Code CLI インストール済み

#### テストシナリオ

| # | シナリオ | 手順 | 期待結果 |
|---|---------|------|---------|
| IT-1 | 新規セッション作成 | Cmd+N → ディレクトリ選択 → モデル選択 → 作成 | セッション一覧に追加、ステータス `connected` |
| IT-2 | メッセージ送受信 | 「Hello」と送信 | ストリーミング表示 → 応答完了 |
| IT-3 | ツール使用の可視化 | 「このディレクトリの構成を教えて」 | ToolUseCard + ToolResultCard 表示 |
| IT-4 | モデル切替 | ツールバーで Opus に変更 | ドロップダウンが更新、次の応答が Opus |
| IT-5 | 処理中断 | ストリーミング中に停止ボタン | ストリーミング停止、入力欄有効化 |
| IT-6 | セッション切替 | サイドバーでセッション B に切替 | セッション B のメッセージが表示 |
| IT-7 | セッション終了 + 再開 | Cmd+W → セッション再選択 | ステータス `disconnected` → 再接続 → `connected` |
| IT-8 | データ永続化 | アプリ終了 → 再起動 | セッション一覧 + メッセージ履歴が復元 |

### 完了基準

- [ ] IT-1 〜 IT-8 の全シナリオが手動テストで合格
- [ ] エラーでアプリがクラッシュしない
- [ ] コスト・トークン表示が更新される

---

## Wave 5-3: E2E テスト + バグ修正

### 実装内容

#### UC ベースの E2E テスト

`specs/01_request/spec_01_claude_agent_app.md#想定ユースケース` に基づく。

| UC | テスト内容 |
|----|----------|
| UC-1 | 新規セッション → ディレクトリ選択 → 質問 → ストリーミング応答 → ツール可視化 → 追加質問 |
| UC-2 | セッション A + B を並行作成 → 切替 → 各セッションのコンテキストが独立 |
| UC-3 | セッション使用中にアプリ終了 → 再起動 → セッション再開 → 会話継続 |
| UC-4 | Opus に切替 → 処理開始 → 中断 → 再度送信 |

#### バグ修正

E2E テストで発見されたバグを修正する。
修正は該当パッケージ内で行い、Unit Test を追加する。

### 完了基準

- [ ] UC-1 〜 UC-4 の全ユースケースが動作確認済み
- [ ] 発見されたバグが修正済み
- [ ] 修正ごとに Unit Test が追加されている

---

## Wave 5-4: Manual QA + 最終調整

### 実装内容

#### NFR 検証

| NFR | 検証方法 | 合格基準 |
|-----|---------|---------|
| NFR-001 パフォーマンス | ストリーミング中のカクつき確認 | 主観的にスムーズ |
| NFR-001 メモリ | Activity Monitor で RSS 確認 | 100 メッセージで 200MB 以下 |
| NFR-002 信頼性 | CLI 未インストール状態でアプリ起動 | クラッシュせずエラー表示 |
| NFR-003 ダークモード | システム設定でダークモード切替 | 全画面で視認性確保 |
| NFR-003 キーボード | Cmd+N, Enter, Shift+Enter, Esc, Cmd+W | 全ショートカット動作 |
| NFR-004 Swift 6 | `swift build` で警告確認 | strict concurrency 警告ゼロ |
| NFR-004 コード量 | `cloc` で計測 | 3,000 行以下 |

#### 最終調整

- UI の細かなレイアウト調整
- エラーメッセージの文言確認
- README.md の作成（SampleApp/ClaudeAgent/README.md）

#### README 内容

- セットアップ手順（前提条件、`xcodegen generate`、ビルド）
- 使い方
- アーキテクチャ概要（Pattern B の説明）
- スクリーンショット（任意）

### 完了基準

- [ ] 全 NFR が合格基準をクリア
- [ ] README.md が作成済み
- [ ] コード量が 3,000 行以下
- [ ] `develop` ブランチにマージ可能な状態

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
