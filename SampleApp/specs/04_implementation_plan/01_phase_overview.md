---
title: "ClaudeAgent - Phase/Wave 全体図"
created: 2026-02-08
status: draft
tags: [implementation-plan, phases, claude-agent]
references:
  - ./00_index.md
  - ../03_design_spec/01_architecture.md
  - ../03_design_spec/03_layer_architecture.md
---

# Phase/Wave 全体図

## Phase 1: プロジェクト基盤構築

| Wave | 内容 | 並列化 | 完了基準 |
|------|------|--------|---------|
| 1-1 | ディレクトリ構造作成 + project.yml + Makefile | 順次 | `xcodegen generate` 成功 |
| 1-2 | 3 パッケージの Package.swift 作成 + 依存解決 | 並列（各パッケージ独立） | 各 `swift build --package-path` 成功 |
| 1-3 | App ターゲット + エントリポイント + ビルド確認 | 順次 | `xcodebuild build` 成功 + アプリ起動 |

## Phase 2: Domain パッケージ実装

| Wave | 内容 | 並列化 | 完了基準 |
|------|------|--------|---------|
| 2-1 | エンティティ + 値オブジェクト（全型定義） | 並列（型間に依存なし） | コンパイル成功 + Unit Test パス |
| 2-2 | プロトコル + エラー型 | 順次（エンティティに依存） | コンパイル成功 + Unit Test パス |
| 2-3 | Domain Unit Test | 順次 | `swift test --package-path Packages/Domain` パス |

## Phase 3: Infrastructure パッケージ実装

| Wave | 内容 | 並列化 | 完了基準 |
|------|------|--------|---------|
| 3-1 | AgentMessageMapper + AgentService 骨格 | 順次 | コンパイル成功 |
| 3-2 | JSONSessionStore 実装 | 並列（AgentService と独立） | Unit Test パス |
| 3-3 | AgentService 完全実装 + Integration Test | 順次 | MockTransport でのテストパス |

## Phase 4: Presentation パッケージ実装

| Wave | 内容 | 並列化 | 完了基準 |
|------|------|--------|---------|
| 4-1 | AppState + SessionState 骨格 | 順次 | コンパイル成功 |
| 4-2 | 基本 View（ContentView, SessionSidebar, InputArea） | 並列（View 間は疎結合） | コンパイル成功 + プレビュー動作 |
| 4-3 | ChatView + MessageBubble + Streaming | 並列（4-2 と部分並列可） | コンパイル成功 + プレビュー動作 |
| 4-4 | ToolUseCard + ToolResultCard + NewSessionSheet | 並列 | コンパイル成功 + プレビュー動作 |
| 4-5 | Store ロジック完全実装 + Presentation Unit Test | 順次 | `swift test --package-path Packages/Presentation` パス |

## Phase 5: 統合・テスト・仕上げ

| Wave | 内容 | 並列化 | 完了基準 |
|------|------|--------|---------|
| 5-1 | App ターゲット DI ワイヤリング + 統合ビルド | 順次 | `xcodebuild build` 成功 |
| 5-2 | Integration Test（実 SDK 接続） | 順次 | 新規セッション作成 → メッセージ送受信 → 終了の一連フロー |
| 5-3 | E2E テスト + バグ修正 | 順次 | 全ユースケース（UC-1〜UC-4）の動作確認 |
| 5-4 | Manual QA + 最終調整 | 順次 | 全 NFR の確認 + README 作成 |

## クリティカルパス

```
P1-W1 → P1-W2 → P1-W3 → P2-W1 → P2-W2 → P2-W3
  → P3-W1 → P3-W2 → P3-W3
  → P4-W1 → P4-W2 → P4-W5
→ P5-W1 → P5-W2 → P5-W3 → P5-W4
```

最長パスは **Phase 1 → Phase 2 → Phase 4 → Phase 5**（Phase 4 の方が Phase 3 より Wave 数が多い）。

## コンパクション条件

各 Phase 完了時に `/compact` を実行し、コンテキストを圧縮する。

| タイミング | 圧縮対象 | 保持する情報 |
|-----------|---------|-------------|
| Phase 1 完了後 | ディレクトリ構成・ビルド設定の詳細 | project.yml パス、Package.swift の存在確認 |
| Phase 2 完了後 | Domain 型定義の実装詳細 | プロトコル定義のシグネチャ、型名一覧 |
| Phase 3 完了後 | Infrastructure 実装詳細 | AgentService / SessionStore の公開 API |
| Phase 4 完了後 | Presentation 実装詳細 | View 名一覧、Store の公開メソッド |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
