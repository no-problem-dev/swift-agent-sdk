---
title: "ClaudeAgent - 要求仕様 インデックス"
created: 2026-02-08
status: draft
tags: [claude-agent, macos, requirements]
references:
  - ../01_request/spec_01_claude_agent_app.md
---

# 要求仕様: ClaudeAgent

## 概要

swift-agent-sdk を活用した macOS ネイティブ GUI アプリ。
Claude Code CLI と同等の AI エージェント操作を、マルチセッション対応の軽量な GUI で実現する。

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_feature_overview.md](./01_feature_overview.md) | 機能概要・FF一覧 |
| [02_user_stories.md](./02_user_stories.md) | ユーザーストーリー |
| [03_functional_requirements.md](./03_functional_requirements.md) | 機能要件 |
| [04_non_functional_requirements.md](./04_non_functional_requirements.md) | 非機能要件 |
| [05_io_spec.md](./05_io_spec.md) | I/O 仕様 |
| [06_constraints.md](./06_constraints.md) | 制約・前提・外部依存 |
| [07_open_questions.md](./07_open_questions.md) | オープンクエスチョン |

## 責務分離表

| 項目 | 本仕様（What） | Design Spec（How） |
|------|----------------|-------------------|
| セッション管理 | 作成・再開・終了・削除の振る舞い要件 | AppState / SessionState の設計、SDK API 呼び出し詳細 |
| メッセージ表示 | ユーザーが見るべき情報と表示タイミング | SwiftUI View 構成、Markdown レンダリング実装 |
| ストリーミング | リアルタイム更新の振る舞い要件 | AsyncThrowingStream 処理、MainActor 設計 |
| ツール可視化 | 表示すべき情報と折りたたみ動作 | ToolUseCard / ToolResultCard の View 実装 |
| モデル選択 | 選択可能なモデルと切替タイミング | session.setModel() 呼び出し、UI バインディング |
| データ永続化 | 保存対象・タイミング・復元の振る舞い | SessionStore 実装、JSON ファイル構造 |
| エラー表示 | エラー種別ごとのユーザー体験 | AgentSDKError ハンドリング実装 |

## 決定事項

| ID | 決定内容 | 根拠 | 日付 |
|----|---------|------|------|
| D-1 | 権限モードは `bypassPermissions` 固定 | サンプルアプリとしてシンプルさを優先。canUseTool UI は作らない | 2026-02-08 |
| D-2 | Xcode プロジェクト (.xcodeproj) で構築 | App Sandbox 無効化・Entitlements 制御が容易 | 2026-02-08 |
| D-3 | SDK 本体とは独立したプロジェクト | SDK の Package.swift を変更しない。ローカルパス参照で依存 | 2026-02-08 |
| D-4 | アプリ名は「ClaudeAgent」 | SDK 名と対応するシンプルな命名 | 2026-02-08 |
| D-5 | MVVM + @Observable で状態管理 | SwiftUI + Observation framework が macOS 15 で安定。テスタビリティ確保 | 2026-02-08 |
| D-6 | no-problem 製 Swift パッケージを積極活用 | 自社パッケージは「外部サードパーティ」に含めない。Markdown、DesignSystem、Statable、UIRouting 等を使用 | 2026-02-08 |
| D-7 | XcodeGen で .xcodeproj を生成 | .xcodeproj の直接編集を禁止。project.yml で管理し、.xcodeproj は .gitignore | 2026-02-08 |
| D-8 | 同時接続セッション数に上限なし | アーキテクチャに影響しない。問題発生時に後から追加可能 | 2026-02-08 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
| 2026-02-08 | D-6〜D-8 追加。no-problem パッケージ活用・XcodeGen・セッション上限の決定 |
