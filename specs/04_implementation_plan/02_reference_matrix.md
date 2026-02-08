---
title: "Swift Agent SDK - 参照マトリクス"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan, reference-matrix]
references:
  - ./00_index.md
  - ../02_requirements/01_feature_overview.md
  - ../03_design_spec/00_index.md
---

# 参照マトリクス（FF-ID 単位）

## Intent（意図）

各 Feature Flow（FF）の実装に必要な仕様参照先を一覧化する。
AI がタスク実行時に「何を参照して実装すべきか」を即座に特定できるようにする。

---

## 参照マトリクス

### FF-001: CLI プロセス管理

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-001〜FR-005 | 機能要件 |
| `03_design_spec/04_component_architecture.md` | #2.1 CLIProcess, #2.5 CLILocator, #2.6 CLIArgBuilder | コンポーネント設計 |
| `03_design_spec/06_auth_flow.md` | #3 CLI 探索フロー | 探索順序の詳細 |
| `03_design_spec/10_security.md` | #3.2 プロセス権限, #3.3 入力バリデーション | セキュリティ要件 |
| `03_design_spec/12_risks.md` | R-002, R-005 | Node.js依存、プロセスクラッシュ |

**実装 Wave:** Phase 2 Wave 2-1 [B][C], Wave 2-2

---

### FF-002: JSONL トランスポート

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-006〜FR-009 | 機能要件 |
| `02_requirements/05_io_spec.md` | 全体 | メッセージ仕様 |
| `03_design_spec/04_component_architecture.md` | #2.2 JSONLCodec | エンコード/デコード設計 |
| `03_design_spec/05_data_model.md` | #4 CLIMessage, SDKMessage | 内部メッセージ型 |

**実装 Wave:** Phase 2 Wave 2-1 [A], Wave 2-3

---

### FF-003: 初期化ハンドシェイク

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-010〜FR-012 | 機能要件 |
| `03_design_spec/06_auth_flow.md` | #1 ハンドシェイクフロー | シーケンス図 |
| `03_design_spec/06_auth_flow.md` | #4 InitializeRequest の構造 | リクエスト構造 |
| `03_design_spec/04_component_architecture.md` | #2.3 Handshake | コンポーネント設計 |
| `03_design_spec/12_risks.md` | R-001, R-004 | プロトコル変更、バージョン非互換 |

**実装 Wave:** Phase 2 Wave 2-3

---

### FF-004: ワンショットクエリ

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-013〜FR-017 | 機能要件 |
| `03_design_spec/01_architecture.md` | #2.1 ワンショットクエリのデータフロー | データフロー図 |
| `03_design_spec/08_api_spec.md` | #1.1 ワンショットクエリ, #2.2 ClaudeCodeClient | API 設計 |
| `03_design_spec/08_api_spec.md` | #4 QueryOptions 詳細 | オプション設計 |
| `03_design_spec/09_screen_flow.md` | #2 FF-004 フロー | メッセージフロー詳細 |

**実装 Wave:** Phase 3 Wave 3-2 [B], Wave 3-3

---

### FF-005: セッション管理

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-018〜FR-022 | 機能要件 |
| `03_design_spec/01_architecture.md` | #2.2 セッション維持のデータフロー | データフロー図 |
| `03_design_spec/06_auth_flow.md` | #2 セッション再開フロー | 再開フロー |
| `03_design_spec/08_api_spec.md` | #1.2, #1.3, #3.1 Session API | API 設計 |
| `03_design_spec/09_screen_flow.md` | #3 FF-005 フロー | ライフサイクル・メッセージフロー |
| `03_design_spec/12_risks.md` | R-003, R-006 | コールドスタート、セッション期限切れ |

**実装 Wave:** Phase 3 Wave 3-3

---

### FF-006: 権限ハンドリング

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-023〜FR-027 | 機能要件 |
| `03_design_spec/07_payment_flow.md` | #1 権限ハンドリングフロー | フロー図 |
| `03_design_spec/09_screen_flow.md` | #4 FF-006 フロー | カスタムハンドラ介入フロー |
| `03_design_spec/10_security.md` | #4 権限ハンドリングの安全設計 | デフォルト deny、ハンドラ安全性 |
| `03_design_spec/05_data_model.md` | #2.10 PermissionMode, PermissionDecision | 型定義 |

**実装 Wave:** Phase 3 Wave 3-1（MessageRouter で can_use_tool をルーティング）

---

### FF-007: サブエージェント定義

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-028〜FR-030 | 機能要件 |
| `03_design_spec/08_api_spec.md` | #5 サブエージェント定義 | API 設計・使用例 |
| `03_design_spec/09_screen_flow.md` | #5 FF-007 フロー | メッセージフロー |
| `03_design_spec/05_data_model.md` | #2.10 AgentDefinition | 型定義 |

**実装 Wave:** Phase 2 Wave 2-1 [C]（CLIArgBuilder で agents 引数構成）、Phase 3 Wave 3-2 [B]（Client で agents オプション処理）

---

### FF-008: MCP サーバー設定

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-031〜FR-033 | 機能要件 |
| `03_design_spec/08_api_spec.md` | #6 MCP サーバー設定 | API 設計・使用例 |
| `03_design_spec/05_data_model.md` | #2.10 MCPServerConfig | 型定義 |

**実装 Wave:** Phase 2 Wave 2-1 [C]（CLIArgBuilder で mcpServers 引数構成）、Phase 3 Wave 3-3（Session で runtime MCP 制御）

---

### FF-009: ランタイム制御

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-034〜FR-038 | 機能要件 |
| `03_design_spec/07_payment_flow.md` | #2 ランタイム制御フロー | フロー図 |
| `03_design_spec/07_payment_flow.md` | #4 制御サブタイプ一覧 | サブタイプと方向 |
| `03_design_spec/08_api_spec.md` | #3.2 セッション内ランタイム制御 | API 設計 |

**実装 Wave:** Phase 3 Wave 3-1（MessageRouter で制御リクエスト管理）、Wave 3-3（Session API）

---

### FF-010: エラーハンドリング

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-039〜FR-043 | 機能要件 |
| `03_design_spec/05_data_model.md` | #3 AgentSDKError | エラー型定義 |
| `03_design_spec/09_screen_flow.md` | #6 FF-010 フロー | エラーフロー |
| `03_design_spec/10_security.md` | #3.4 リソースクリーンアップ | クリーンアップ戦略 |

**実装 Wave:** Phase 1 Wave 1-2 [C]（エラー型）、Phase 2〜3（各コンポーネントでエラーを throw）

---

### FF-011: プロトコル指向設計 + DI

| 参照仕様 | セクション | 用途 |
|---------|-----------|------|
| `02_requirements/03_functional_requirements.md` | FR-044〜FR-053 | 機能要件 |
| `03_design_spec/01_architecture.md` | #3 設計方針 | 設計原則 |
| `03_design_spec/03_layer_architecture.md` | 全体 | レイヤー構造・DI 設計 |
| `03_design_spec/04_component_architecture.md` | #3 ディレクトリ構造, #4 Package.swift | モジュール構成 |
| `03_design_spec/08_api_spec.md` | #7 テスト API | MockTransport 設計 |

**実装 Wave:** Phase 1 Wave 1-1〜1-2（Protocol 定義）、Phase 4 Wave 4-1（MockTransport）

---

## クロスリファレンス: Wave → FF 対応

| Wave | 対応 FF |
|------|--------|
| 1-1 | FF-011（Package.swift、モジュール構成） |
| 1-2 | FF-010（AgentSDKError）、FF-011（Protocols、Models） |
| 1-3 | FF-011（テスト、AgentSDK namespace） |
| 2-1 | FF-001（CLILocator, CLIArgBuilder）、FF-002（JSONLCodec）、FF-007/008（引数構成） |
| 2-2 | FF-001（CLIProcess） |
| 2-3 | FF-002（プロトコル型）、FF-003（Handshake） |
| 3-1 | FF-006（権限ルーティング）、FF-009（制御リクエスト管理） |
| 3-2 | FF-004（query）、FF-011（Transport/Client DI） |
| 3-3 | FF-004/005（Session、Convenience API）、FF-008/009（ランタイム制御） |
| 4-1 | FF-011（MockTransport、テスタビリティ） |
| 4-2 | FF-004/005/006（統合テスト） |
| 4-3 | ドキュメント・CI |

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
