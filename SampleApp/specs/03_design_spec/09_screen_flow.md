---
title: "ClaudeAgent - 画面フロー"
created: 2026-02-08
status: draft
tags: [design, screen-flow, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/01_feature_overview.md
  - ../02_requirements/03_functional_requirements.md
---

# 画面フロー

## 1. 画面構成（全体レイアウト）

```
┌─────────────────────────────────────────────────────────────┐
│  [+ 新規] [モデル: ▼ Sonnet] [/Users/dev/project]  [$0.04] │ ← ツールバー
├────────────────┬────────────────────────────────────────────┤
│                │                                            │
│  セッション    │  チャットエリア                              │
│  サイドバー    │                                            │
│                │  ┌── MessageBubble (user) ──────────┐     │
│  ● Session 1   │  │ メッセージテキスト                 │     │
│  ○ Session 2   │  └─────────────────────────────────┘     │
│  ○ Session 3   │                                            │
│                │  ┌── MessageBubble (assistant) ────┐     │
│                │  │ Markdown レンダリングテキスト      │     │
│                │  │ ┌── ToolUseCard ────────────┐   │     │
│                │  │ │ 🔧 Read { path: "..." }   │   │     │
│                │  │ └──────────────────────────┘   │     │
│                │  │ ┌── ToolResultCard ─────────┐   │     │
│                │  │ │ ▼ 結果テキスト（折りたたみ）│   │     │
│                │  │ └──────────────────────────┘   │     │
│                │  └─────────────────────────────────┘     │
│                │                                            │
│                │  ┌── StreamingText ────────────────┐     │
│                │  │ ストリーミング中テキスト...▌       │     │
│                │  └─────────────────────────────────┘     │
│                │                                            │
│                ├────────────────────────────────────────────┤
│                │  ┌── InputArea ────────────────────┐     │
│                │  │ メッセージを入力...     [■ 停止] │     │
│                │  └─────────────────────────────────┘     │
└────────────────┴────────────────────────────────────────────┘
```

## 2. FF-001: セッション管理フロー

```mermaid
stateDiagram-v2
    [*] --> アプリ起動
    アプリ起動 --> セッション一覧表示: sessions.json 読み込み

    state セッション一覧表示 {
        [*] --> 空状態: セッション 0 件
        [*] --> 一覧表示: セッション 1+ 件
        空状態 --> 新規作成ダイアログ: Cmd+N / +ボタン
        一覧表示 --> 新規作成ダイアログ: Cmd+N / +ボタン
        一覧表示 --> セッション選択: クリック
    }

    新規作成ダイアログ --> セッション接続中: 作成実行
    セッション接続中 --> チャット表示: 接続成功
    セッション接続中 --> エラー表示: 接続失敗

    セッション選択 --> チャット表示: connected の場合
    セッション選択 --> セッション再接続中: disconnected の場合
    セッション再接続中 --> チャット表示: 再接続成功
    セッション再接続中 --> エラー表示: 再接続失敗

    チャット表示 --> セッション一覧表示: Cmd+W（終了）
    チャット表示 --> セッション一覧表示: 削除（確認後）
    エラー表示 --> セッション再接続中: リトライ
    エラー表示 --> 新規作成ダイアログ: 新規作成
```

## 3. FF-002: チャットメッセージングフロー

```mermaid
stateDiagram-v2
    [*] --> 入力待機: セッション connected

    state 入力待機 {
        [*] --> テキスト入力中
        テキスト入力中 --> テキスト入力中: Shift+Enter（改行）
    }

    入力待機 --> メッセージ送信: Enter
    メッセージ送信 --> ストリーミング中: session.send()

    state ストリーミング中 {
        [*] --> partial受信
        partial受信 --> partial受信: streamingText 更新
        partial受信 --> assistant受信: .assistant メッセージ
        assistant受信 --> partial受信: 次の partial
        assistant受信 --> result受信: .result メッセージ
    }

    ストリーミング中 --> 入力待機: ターン完了
    ストリーミング中 --> 入力待機: 中断（Esc / 停止ボタン）
    ストリーミング中 --> エラー表示: エラー発生

    エラー表示 --> 入力待機: 再接続成功
```

## 4. FF-003: ツール可視化フロー

```mermaid
flowchart TD
    A[".assistant メッセージ受信"] --> B{ContentBlock の種別}
    B -->|".text"| C["MarkdownView で表示"]
    B -->|".toolUse"| D["ToolUseCard 表示<br/>ツール名 + パラメータ"]
    B -->|".toolResult"| E{"isError?"}

    E -->|false| F["ToolResultCard（通常）<br/>折りたたみ可能"]
    E -->|true| G["ToolResultCard（エラー）<br/>赤系背景"]

    D --> H{"結果待ち?"}
    H -->|はい| I["ローディングインジケータ"]
    H -->|いいえ| J["ToolUse + ToolResult ペア表示"]
    I --> J
```

## 5. FF-004: モデル・設定制御フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant TB as ツールバー
    participant SS as SessionState
    participant AS as AgentService

    User->>TB: モデルドロップダウン選択
    TB->>SS: setModel(.opus)
    SS->>AS: setModel(sessionId, .opus)
    AS-->>SS: 成功
    SS->>TB: config.model 更新

    Note over TB: ドロップダウンに反映

    alt 失敗時
        AS-->>SS: エラー
        SS->>TB: 選択を元に戻す
        SS->>TB: エラーメッセージ表示
    end
```

## 6. FF-005: データ永続化フロー

```mermaid
flowchart TD
    A["アプリ起動"] --> B["SessionStore.loadAll()"]
    B --> C{"sessions.json 存在?"}
    C -->|はい| D["セッション一覧復元<br/>全セッション disconnected"]
    C -->|いいえ| E["空のセッション一覧"]
    C -->|破損| F["ログ出力 → 空状態"]

    G["セッション作成"] --> H["SessionStore.save()"]
    I[".result 受信"] --> H
    J["セッション終了"] --> H
    K["セッション削除"] --> L["SessionStore.delete()"]
    M["アプリ終了"] --> H

    style H fill:#e3f2fd,stroke:#2196f3
    style L fill:#ffebee,stroke:#f44336
```

## 7. 画面遷移サマリー

| 起点 | アクション | 遷移先 | 対応 FR |
|------|----------|--------|---------|
| 空状態 | Cmd+N / +ボタン | NewSessionSheet | FR-001 |
| サイドバー | セッションクリック | ChatView (切替) | FR-003 |
| サイドバー | コンテキストメニュー → 終了 | ステータス変更 | FR-005 |
| サイドバー | コンテキストメニュー → 削除 | 確認ダイアログ → 削除 | FR-006 |
| サイドバー | ダブルクリック | 名前変更モード | FR-007 |
| ChatView | Enter | メッセージ送信 → ストリーミング | FR-008, FR-009 |
| ChatView | Esc / 停止ボタン | 処理中断 | FR-011 |
| ツールバー | モデルドロップダウン | モデル変更 | FR-016 |
| エラーバナー | 再接続ボタン | セッション再接続 | FR-004 |

## 8. キーボードショートカット一覧

| ショートカット | アクション | 対応画面 |
|---------------|----------|---------|
| Cmd+N | 新規セッション作成 | グローバル |
| Enter | メッセージ送信 | InputArea |
| Shift+Enter | 改行 | InputArea |
| Esc | 処理中断 | ChatView（ストリーミング中） |
| Cmd+W | セッション終了 | ChatView |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
