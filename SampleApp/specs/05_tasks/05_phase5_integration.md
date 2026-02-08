---
title: "ClaudeAgent - Phase 5: 統合・テスト・仕上げタスク"
created: 2026-02-08
status: draft
tags: [tasks, phase5, integration, claude-agent]
references:
  - ../04_implementation_plan/07_phase5_integration.md
  - ../03_design_spec/01_architecture.md#DI-方針
  - ../03_design_spec/12_risks.md
  - ../02_requirements/04_non_functional_requirements.md
---

# Phase 5: 統合・テスト・仕上げ (T25-T27)

> Phase 3 + Phase 4 の **両方が完了後** に開始

## Wave 5-1: DI ワイヤリング + 統合ビルド

---

## T25: Implement DI ワイヤリング + 統合ビルド

- description:
  - ClaudeAgentApp.swift を更新し、Infrastructure の実装を Presentation の Store に注入する
  - AgentService + JSONSessionStore の生成と AppState への注入
  - アプリ終了時の全セッション保存 + close（ゾンビプロセス対策 R-5）
  - Cmd+N のキーボードショートカット設定
  - xcodegen generate + xcodebuild build で統合ビルド確認
  - 完了時: アプリ起動でサイドバー + チャットエリアが表示される

- spec_refs:
  - FF-001（セッション管理）
  - FF-005（データ永続化）
  - specs/04_implementation_plan/07_phase5_integration.md#Wave-5-1
  - specs/03_design_spec/01_architecture.md#DI-方針
  - specs/03_design_spec/12_risks.md#R-5

- agent:
  - general-purpose

- deps:
  - T16 (Infrastructure 完了)
  - T24 (Presentation 完了)

- files:
  - modify: SampleApp/ClaudeAgent/App/Sources/ClaudeAgentApp.swift
  - modify: SampleApp/ClaudeAgent/project.yml

- unit_test:
  - required: false

- verification:
  - [ ] `xcodegen generate` 成功
  - [ ] `xcodebuild build -project ClaudeAgent.xcodeproj -scheme ClaudeAgent -destination 'platform=macOS'` 成功
  - [ ] アプリ起動時にサイドバー + チャットエリアのレイアウトが表示される
  - [ ] アプリ終了時に全セッション close が呼ばれる

---

## Wave 5-2: Integration Test + E2E テスト

---

## T26: Verify Integration Test + E2E テスト

- description:
  - 実際の Claude Code CLI に接続してのインテグレーションテスト（IT-1〜IT-8）
  - UC ベースの E2E テスト（UC-1〜UC-4）
  - 発見されたバグの修正（該当パッケージ内で修正 + Unit Test 追加）
  - 前提: claude login 完了、Node.js 18+ インストール、Claude Code CLI インストール
  - 完了時: 全シナリオ合格、発見バグ修正済み

- spec_refs:
  - specs/04_implementation_plan/07_phase5_integration.md#Wave-5-2
  - specs/04_implementation_plan/07_phase5_integration.md#Wave-5-3
  - specs/01_request/spec_01_claude_agent_app.md#想定ユースケース

- agent:
  - general-purpose

- deps:
  - T25

- files:
  - modify: (バグ修正対象ファイルは実行時に特定)

- unit_test:
  - required: true
  - test_file: (バグ修正時に追加)
  - coverage_goal: 既存テストの維持
  - red_phase: バグ発見時に再現テストを先に作成
  - green_phase: バグ修正でテストパス

- verification:
  - [ ] IT-1: 新規セッション作成 → セッション一覧に追加、ステータス connected
  - [ ] IT-2: メッセージ送受信 → ストリーミング表示 → 応答完了
  - [ ] IT-3: ツール使用の可視化 → ToolUseCard + ToolResultCard 表示
  - [ ] IT-4: モデル切替 → ドロップダウン更新
  - [ ] IT-5: 処理中断 → ストリーミング停止、入力欄有効化
  - [ ] IT-6: セッション切替 → 別セッションのメッセージ表示
  - [ ] IT-7: セッション終了 + 再開 → disconnected → connected
  - [ ] IT-8: データ永続化 → アプリ再起動でセッション + メッセージ復元
  - [ ] UC-1〜UC-4: 全ユースケース動作確認済み
  - [ ] エラーでアプリがクラッシュしない

---

## Wave 5-3: Manual QA + 最終調整 + README

---

## T27: QA Manual QA + 最終調整 + README

- description:
  - NFR 検証: パフォーマンス（カクつき）、メモリ（100 メッセージで 200MB 以下）、CLI 未インストール時のエラー表示、ダークモード、キーボードショートカット、Swift 6 警告ゼロ、コード量 3,000 行以下
  - UI の細かなレイアウト調整
  - エラーメッセージの文言確認
  - README.md の作成（セットアップ手順、使い方、アーキテクチャ概要）
  - 完了時: 全 NFR 合格、README 作成済み、develop マージ可能

- spec_refs:
  - specs/04_implementation_plan/07_phase5_integration.md#Wave-5-4
  - specs/02_requirements/04_non_functional_requirements.md
  - specs/03_design_spec/12_risks.md
  - specs/04_implementation_plan/09_rollout.md

- agent:
  - general-purpose

- deps:
  - T26

- files:
  - create: SampleApp/ClaudeAgent/README.md
  - modify: (最終調整対象ファイルは実行時に特定)

- unit_test:
  - required: false

- verification:
  - [ ] NFR-001: ストリーミング中にカクつきなし
  - [ ] NFR-001: 100 メッセージで RSS 200MB 以下
  - [ ] NFR-002: CLI 未インストール時にクラッシュせずエラー表示
  - [ ] NFR-003: ダークモードで全画面の視認性確保
  - [ ] NFR-003: Cmd+N, Enter, Shift+Enter, Esc, Cmd+W が動作
  - [ ] NFR-004: strict concurrency 警告ゼロ
  - [ ] NFR-004: `cloc` でコード量 3,000 行以下
  - [ ] README.md が作成済み（セットアップ手順、使い方、アーキテクチャ）
  - [ ] develop ブランチにマージ可能な状態

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
