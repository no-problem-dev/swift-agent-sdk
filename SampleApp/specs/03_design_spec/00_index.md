---
title: "ClaudeAgent - 設計仕様 インデックス"
created: 2026-02-08
status: draft
tags: [design, claude-agent]
references:
  - ../02_requirements/00_index.md
---

# 設計仕様: ClaudeAgent

## 概要

ClaudeAgent の技術設計を定義する。Pattern B（ローカル SPM パッケージ分割）を採用し、
4 パッケージ構成（Domain / Infrastructure / Presentation + App ターゲット）で
コンパイル時に依存方向を強制する。

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_architecture.md](./01_architecture.md) | 全体アーキテクチャ・パッケージ構成 |
| [02_tech_stack.md](./02_tech_stack.md) | 技術スタック・外部依存割り当て |
| [03_layer_architecture.md](./03_layer_architecture.md) | レイヤー別アーキテクチャ・Package.swift |
| [04_component_architecture.md](./04_component_architecture.md) | コンポーネント設計・パッケージ境界図 |
| [05_data_model.md](./05_data_model.md) | データモデル・ER 図 |
| [09_screen_flow.md](./09_screen_flow.md) | 画面フロー（FF 単位） |
| [11_nfr_realization.md](./11_nfr_realization.md) | 非機能要件の実現方式 |
| [12_risks.md](./12_risks.md) | 技術リスクと対策 |

> 06_auth_flow, 07_payment_flow, 08_api_spec, 10_deployment は本アプリでは該当なし。

## 要求仕様 → 設計仕様 マッピング

| 要求仕様 | 対応する設計仕様 |
|---------|----------------|
| FF-001 セッション管理 | 04_component (AppState/SessionState), 05_data_model (SessionData), 09_screen_flow |
| FF-002 チャットメッセージング | 04_component (ChatView/MessageBubble), 03_layer (Presentation) |
| FF-003 ツール可視化 | 04_component (ToolUseCard/ToolResultCard), 05_data_model (ContentItem) |
| FF-004 モデル・設定制御 | 04_component (Toolbar), 05_data_model (SessionConfig) |
| FF-005 データ永続化 | 03_layer (Infrastructure), 05_data_model (SessionData) |
| NFR-001〜005 | 11_nfr_realization |

## 設計決定事項

| ID | 決定内容 | 根拠 |
|----|---------|------|
| DD-1 | Pattern B（4 パッケージ分割） | SPM 境界でコンパイル時に依存方向を強制。サンプルアプリとして SDK 活用のベストプラクティスを示す |
| DD-2 | Domain は外部依存ゼロ | Foundation のみ。エンティティ・プロトコルの純粋性を保証 |
| DD-3 | SDK 依存は Infrastructure に閉じ込め | AgentServiceProtocol で抽象化し Presentation から SDK を直接参照しない |
| DD-4 | UI パッケージは Presentation に配置 | swift-markdown-view, swift-design-system, swift-ui-routing は Presentation の Package.swift で管理 |
| DD-5 | XcodeGen は localPackages を使用 | 外部依存は各 Package.swift で管理。project.yml の packages は不使用 |
| DD-6 | entitlements は project.yml で宣言的管理 | .entitlements ファイルの直接編集禁止 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
