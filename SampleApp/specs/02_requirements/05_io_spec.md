---
title: "ClaudeAgent - I/O 仕様"
created: 2026-02-08
status: draft
tags: [claude-agent, io-spec]
references:
  - ./00_index.md
  - ./03_functional_requirements.md
---

# I/O 仕様

## 1. ユーザー入力

### 1.1 テキストメッセージ入力

| 項目 | 仕様 |
|------|------|
| 入力ソース | テキストエディタ（複数行対応） |
| 送信トリガー | Enter キー |
| 改行トリガー | Shift+Enter |
| バリデーション | 空文字列を送信不可 |
| 文字制限 | なし（SDK に委ねる） |

### 1.2 セッション作成入力

| フィールド | 型 | 必須 | デフォルト | バリデーション |
|-----------|-----|------|-----------|--------------|
| 作業ディレクトリ | ディレクトリパス | Yes | なし | 存在するディレクトリであること |
| モデル | enum (opus/sonnet/haiku) | Yes | sonnet | 選択式 |
| システムプロンプト | テキスト | No | 空（SDK デフォルト） | なし |
| セッション名 | テキスト | No | 最初のメッセージから自動生成 | なし |

### 1.3 キーボードショートカット

| ショートカット | アクション |
|---------------|-----------|
| Cmd+N | 新規セッション作成 |
| Enter | メッセージ送信 |
| Shift+Enter | 改行 |
| Esc | 処理中断（ストリーミング中） |
| Cmd+W | セッション終了 |

---

## 2. システム出力

### 2.1 SDK メッセージ → UI マッピング

| SDK メッセージ | UI 表示 | 更新頻度 |
|---------------|---------|---------|
| `.system(SystemInfo)` | 内部処理のみ（セッション初期化） | セッション開始時 1 回 |
| `.partial(PartialInfo)` | ストリーミングテキスト（逐次更新） | 高頻度（数十〜数百ms ごと） |
| `.assistant(AssistantInfo)` | メッセージバブル（確定表示） | ターン中 1〜複数回 |
| `.result(ResultInfo)` | コスト/トークン情報の更新 | ターン終了時 1 回 |

### 2.2 ContentBlock → UI マッピング

| ContentBlock | UI コンポーネント |
|-------------|-----------------|
| `.text(String)` | Markdown レンダリングされたテキスト |
| `.toolUse(ToolUse)` | ツール使用カード（ツール名 + パラメータ） |
| `.toolResult(ToolResult)` | ツール結果カード（折りたたみ可能） |

### 2.3 エラー出力

| AgentSDKError | ユーザー向けメッセージ | UI 表示方法 |
|---------------|---------------------|------------|
| `cliNotFound` | "Claude Code CLI が見つかりません。npm install -g @anthropic-ai/claude-code を実行してください" | アラートダイアログ |
| `processExited` | "Claude Code が予期せず終了しました" | チャット内エラーバナー + 再接続ボタン |
| `sessionExpired` | "セッションの有効期限が切れました" | チャット内通知 + 新規作成ボタン |
| `notConnected` | "セッションが接続されていません" | チャット内エラーバナー + 再接続ボタン |
| `initializationTimeout` | "接続がタイムアウトしました" | チャット内エラーバナー + リトライボタン |
| `protocolError` | "通信エラーが発生しました" | チャット内エラーバナー |

---

## 3. データ永続化 I/O

### 3.1 保存先

```
~/Library/Application Support/ClaudeAgent/
└── sessions.json     ← 全セッションデータ
```

### 3.2 sessions.json 構造（概念レベル）

```
[
  {
    "id": "セッション ID（SDK 発行）",
    "config": { "model": "sonnet", "workingDirectory": "/path", "systemPrompt": null, "name": "..." },
    "createdAt": "ISO8601 日時",
    "lastActiveAt": "ISO8601 日時",
    "totalCostUsd": 0.0123,
    "messages": [
      { "id": "UUID", "role": "user", "timestamp": "...", "content": [...] },
      { "id": "UUID", "role": "assistant", "timestamp": "...", "content": [...] }
    ]
  }
]
```

### 3.3 保存タイミング

| トリガー | 保存内容 |
|---------|---------|
| セッション作成 | セッション情報（メッセージなし） |
| `.result` メッセージ受信 | メッセージ履歴 + コスト |
| セッション終了 | ステータス更新 |
| セッション削除 | 該当セッション除去 |
| アプリ終了時 | 全セッション状態 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
