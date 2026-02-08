---
title: "ClaudeAgent - 制約・前提・外部依存"
created: 2026-02-08
status: draft
tags: [claude-agent, constraints]
references:
  - ./00_index.md
---

# 制約・前提・外部依存

## 1. ランタイム前提条件

| 前提 | 詳細 | 影響 |
|------|------|------|
| Node.js 18+ | Claude Code CLI の実行に必須 | Node.js 未インストール時はアプリ起動後にエラー |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` が事前に必要 | 未インストール時に `cliNotFound` エラー |
| `claude login` 完了 | サブスクリプション認証が必要 | 未認証時に CLI レベルでエラー |
| ネットワーク接続 | Claude API への HTTPS 通信が必要 | オフライン時はメッセージ送信不可 |

## 2. プラットフォーム制約

| 制約 | 詳細 | 理由 |
|------|------|------|
| macOS 15+ のみ | iOS / Linux / Windows は対象外 | SwiftUI + Observation framework が macOS 15 で安定 |
| App Sandbox 無効 | サブプロセス起動に必要 | Claude Code CLI をサブプロセスとして実行するため |
| App Store 非対応 | App Sandbox 無効のため | 直接配布のみ |

## 3. 技術的制約

| 制約 | 詳細 | 影響 |
|------|------|------|
| SDK コールドスタート ~12 秒 | 初回セッション接続に時間がかかる | ローディング UI が必須 |
| セッション有効期限 ~10 分 | 非活動 10 分でセッション失効 | 再接続機能が必要 |
| 権限モード固定 | `bypassPermissions` 固定（D-1） | canUseTool UI は不要 |
| swift-agent-sdk ローカル参照 | `../../` の相対パスで参照 | リポジトリ構成に依存 |

## 4. スコープ制約

| 除外項目 | 理由 |
|---------|------|
| ファイルエディタ統合 | サンプルアプリの範囲外 |
| MCP サーバー管理 UI | 複雑さが大きすぎる |
| サブエージェント定義 UI | 複雑さが大きすぎる |
| Hook 設定 UI | 複雑さが大きすぎる |
| 自動アップデート | サンプルアプリには不要 |
| ユーザー認証 UI | CLI の `claude login` に委ねる |
| 複数ウィンドウ対応 | 単一ウィンドウで十分 |

## 5. 外部依存（no-problem 製パッケージ）

no-problem 製 Swift パッケージは「外部サードパーティ」に含めず、積極的に活用する（D-6）。

| パッケージ | 用途 | GitHub |
|-----------|------|--------|
| **swift-agent-sdk** | Claude Code SDK（本体） | no-problem-dev/swift-agent-sdk |
| **swift-markdown-view** | Markdown レンダリング + シンタックスハイライト | no-problem-dev/swift-markdown-view |
| **swift-design-system** | UI コンポーネント + テーマシステム | no-problem-dev/swift-design-system |
| **swift-statable** | @Statable マクロによる非同期状態管理 | no-problem-dev/swift-statable |
| **swift-ui-routing** | NavigationSplitView + Sheet + Alert 管理 | no-problem-dev/swift-ui-routing |

> **注意**: 上記以外のサードパーティパッケージは使用しない。

## 6. 開発制約

| 制約 | 詳細 |
|------|------|
| 変更スコープ | `SampleApp/` ディレクトリ内のみ。SDK 本体の変更は不可 |
| プロジェクト管理 | XcodeGen（project.yml）で管理。.xcodeproj の直接編集禁止（D-7） |
| コード量 | サンプルアプリとして適切な規模に抑える（目安: 3,000 行以下） |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
| 2026-02-08 | no-problem 製パッケージ依存を追加、XcodeGen 制約を追加 |
