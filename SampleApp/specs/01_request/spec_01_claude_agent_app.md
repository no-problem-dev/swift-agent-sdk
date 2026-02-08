---
title: "Claude Agent App - macOS サンプルアプリ Request仕様"
created: 2026-02-08
status: draft
tags: [macos, swiftui, sample-app, swift-agent-sdk, multi-session]
---

# spec_01: Claude Agent App

## 1. 発端・背景

swift-agent-sdk は Claude Code CLI を Swift からプログラム的に操作する SDK として完成した。
この SDK の実用性を示すリファレンス実装として、macOS ネイティブの GUI アプリケーションを構築したい。

### 1.1 課題意識

- **SDK のショーケースがない**: README のコードスニペットだけでは、実際にどう使うかが伝わりにくい
- **Claude Code CLI は TUI のみ**: GUI で操作したいユーザーにとって敷居が高い
- **マルチセッション管理が煩雑**: CLI では複数セッションの同時管理が難しい

### 1.2 ゴール

swift-agent-sdk を使った **軽量な macOS GUI アプリ** を作成し、以下を実現する：

1. **SDK のリファレンス実装** — AgentClient / AgentSession / AgentMessage の全機能を活用
2. **マルチセッション対応** — 複数の会話を並行管理できる
3. **ストリーミング表示** — リアルタイムでレスポンスを描画する
4. **ツール実行の可視化** — Claude がどのツールを使ったか視覚的にわかる

## 2. プロダクトビジョン

> **Claude Code の機能を、軽量な macOS ネイティブ GUI で操作できるデスクトップアプリ**

Claude Code CLI と同等の操作を、直感的な GUI で実現する。
ターミナル操作に不慣れなユーザーでも AI エージェントの力を活用できるようにする。

### 2.1 ポジショニング

```
                        機能の豊富さ
                            ↑
    Claude Code CLI ────────●─────── フル機能（TUI）
                            │
    Claude Agent App ───●───┤        GUI・マルチセッション
                        │   │
    SDK スニペット ──●──┤   │        コード例のみ
                     │  │   │
                     ↓  ↓   ↓
              サンプル  実用  プロダクション
                    ← 利用形態 →
```

**スコープ**: プロダクション品質ではなく「実用的なサンプルアプリ」。
SDK の使い方を示しつつ、日常的にも使えるレベルを目指す。

## 3. 想定ユースケース

### UC-1: 新規セッションでコード相談

1. アプリを起動
2. 「新規セッション」を作成
3. 作業ディレクトリを選択
4. 「このプロジェクトの構造を説明して」と入力
5. ストリーミングで応答が表示される
6. ツール使用（Glob, Read 等）の経過が可視化される
7. 追加の質問を投げる（コンテキスト維持）

### UC-2: 複数セッションの並行利用

1. セッション A: プロジェクト X のコードレビュー
2. セッション B: プロジェクト Y のバグ修正
3. サイドバーでセッションを切り替え
4. 各セッションは独立したコンテキストを保持

### UC-3: セッションの中断と再開

1. セッション A で作業中にアプリを閉じる
2. 後日アプリを起動
3. セッション A を再開（`resumeSession` 利用）
4. 前回の続きから会話を再開

### UC-4: モデル・権限の動的変更

1. セッション中に「Opus に切り替えて複雑な分析を依頼」
2. 権限モードを `acceptEdits` に変更してファイル編集を許可
3. 必要に応じて `interrupt()` で処理を中断

## 4. 機能要件（概要レベル）

### 4.1 セッション管理

| 機能 | SDK API | 優先度 |
|------|---------|--------|
| 新規セッション作成 | `createSession()` | Must |
| セッション再開 | `resumeSession(id:)` | Must |
| セッション一覧表示 | ローカル保存 | Must |
| セッション終了 | `session.close()` | Must |
| セッション削除 | ローカルデータ削除 | Should |

### 4.2 メッセージング

| 機能 | SDK API | 優先度 |
|------|---------|--------|
| メッセージ送信 | `session.send()` | Must |
| ストリーミング表示 | `.partial` メッセージ処理 | Must |
| テキスト応答表示 | `.assistant` → `.text` | Must |
| ツール使用表示 | `.assistant` → `.toolUse` / `.toolResult` | Must |
| 処理中断 | `session.interrupt()` | Should |
| ワンショットクエリ | `AgentSDK.query()` | Could |

### 4.3 設定・制御

| 機能 | SDK API | 優先度 |
|------|---------|--------|
| モデル選択 | `session.setModel()` | Must |
| 作業ディレクトリ指定 | `SessionOptions.cwd` | Must |
| システムプロンプト | `SessionOptions.systemPrompt` | Should |
| コスト表示 | `.result` → `costUsd` | Should |
| トークン使用量表示 | `.result` → `inputTokens/outputTokens` | Should |

> **決定事項**: 権限モードは `bypassPermissions` 固定。canUseTool UI は作らない。

### 4.4 UI 構成

| 領域 | 内容 |
|------|------|
| サイドバー | セッション一覧 + 新規作成ボタン |
| メインエリア | チャット形式のメッセージ表示 |
| 入力エリア | テキスト入力 + 送信ボタン |
| ツールバー | モデル選択・設定・中断ボタン |

## 5. 非機能要件

| 項目 | 要件 |
|------|------|
| プラットフォーム | macOS 15+ |
| UI フレームワーク | SwiftUI |
| 状態管理 | Observation framework (`@Observable`) |
| データ永続化 | セッション ID のローカル保存（UserDefaults or JSON ファイル） |
| パフォーマンス | ストリーミング表示で UI がブロックされないこと |
| コード品質 | Swift 6 strict concurrency 準拠 |

## 6. 技術的制約

| 制約 | 詳細 |
|------|------|
| Node.js 必須 | Claude Code CLI の実行に Node.js 18+ が必要 |
| CLI インストール | `npm install -g @anthropic-ai/claude-code` が事前に必要 |
| 認証 | `claude login` による事前認証が必要 |
| サンドボックス | App Sandbox を無効化（サブプロセス起動のため） |
| スコープ | SampleApp/ ディレクトリ内のみに変更を限定 |

## 7. スコープ外

以下は本サンプルアプリのスコープ外とする：

- ファイルエディタ統合（VSCode 等のエディタ機能）
- MCP サーバー管理 UI
- サブエージェント定義 UI
- Hook 設定 UI
- App Store 配布
- 自動アップデート機能
- ユーザー認証 UI（CLI の `claude login` に委ねる）

## 8. 成功指標

1. **SDK 全機能のデモ**: AgentClient / AgentSession / AgentMessage の主要パスを網羅
2. **実用性**: 日常的なコード相談に使えるレベルの UX
3. **コード品質**: SDK の使い方のベストプラクティスを示すリファレンス品質
4. **簡潔さ**: 最小限のコードで最大限の機能を実現（SDK の使いやすさの証明）

## 9. 次のステップ

1. **Requirements Spec (02)** — 詳細な機能要件・ユーザーストーリーの策定
2. **Design Spec (03)** — UI 設計・アーキテクチャ・データモデル
3. **Implementation Plan (04)** — フェーズ分割・タスク定義
