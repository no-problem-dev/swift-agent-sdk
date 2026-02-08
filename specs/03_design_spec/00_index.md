---
title: "Swift Agent SDK - 設計仕様 インデックス"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, design-spec]
references:
  - ../01_request/spec_01_swift_agent_sdk.md
  - ../02_requirements/00_index.md
---

# 設計仕様: Swift Agent SDK

## Intent（意図）

Requirements（02_requirements）で定義された「何を満たすべきか（What）」を、
技術的に「どう実現するか（How）」として設計に落とし込む。
実装者が迷わずに開発を進められるよう、アーキテクチャ・型定義・フロー・テスト戦略を明確にする。

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_architecture.md](./01_architecture.md) | アーキテクチャ概要・システム構成図 |
| [02_tech_stack.md](./02_tech_stack.md) | 技術スタック・選定理由 |
| [03_layer_architecture.md](./03_layer_architecture.md) | レイヤーアーキテクチャ・依存関係 |
| [04_component_architecture.md](./04_component_architecture.md) | コンポーネント設計・ディレクトリ構造 |
| [05_data_model.md](./05_data_model.md) | データモデル（スキーマ・型定義） |
| [06_auth_flow.md](./06_auth_flow.md) | 認証フロー設計（該当なし→代替: 初期化・ハンドシェイクフロー） |
| [07_payment_flow.md](./07_payment_flow.md) | 決済フロー設計（該当なし→代替: 制御プロトコルフロー） |
| [08_api_spec.md](./08_api_spec.md) | 公開 API 設計 |
| [09_screen_flow.md](./09_screen_flow.md) | 画面遷移（該当なし→代替: メッセージフロー設計） |
| [10_security.md](./10_security.md) | セキュリティ設計 |
| [11_nfr_realization.md](./11_nfr_realization.md) | NFR 実現方式 |
| [12_risks.md](./12_risks.md) | 技術リスク・対策 |

## Requirements 対応表

| 要件 ID | 要件名 | 設計ファイル | セクション |
|---------|--------|------------|-----------|
| FR-001〜005 | CLI プロセス管理 | 04_component_architecture.md | CLIProcess |
| FR-006〜009 | JSONL トランスポート | 04_component_architecture.md | JSONLCodec |
| FR-010〜012 | 初期化ハンドシェイク | 06_auth_flow.md | ハンドシェイクフロー |
| FR-013〜017 | ワンショットクエリ | 08_api_spec.md | query API |
| FR-018〜022 | セッション管理 | 08_api_spec.md | Session API |
| FR-023〜027 | 権限ハンドリング | 07_payment_flow.md | 権限制御フロー |
| FR-028〜030 | サブエージェント定義 | 08_api_spec.md | Agent Definition |
| FR-031〜033 | MCP サーバー設定 | 08_api_spec.md | MCP Configuration |
| FR-034〜038 | ランタイム制御 | 08_api_spec.md | Runtime Control |
| FR-039〜043 | エラーハンドリング | 05_data_model.md | Error Types |
| FR-044〜046 | Protocol 定義 | 03_layer_architecture.md | Protocol Layer |
| FR-047 | AgentMessage 値型 | 05_data_model.md | Message Types |
| FR-048〜049 | Transport DI | 03_layer_architecture.md | DI Design |
| FR-050 | モジュール分離 | 01_architecture.md | Module Structure |
| FR-051〜052 | Claude Code 具象 | 04_component_architecture.md | Concrete Layer |
| FR-053 | MockTransport | 04_component_architecture.md | Testing Module |
| NFR-001 | パフォーマンス | 11_nfr_realization.md | Performance |
| NFR-002 | 信頼性 | 11_nfr_realization.md | Reliability |
| NFR-003 | 互換性 | 02_tech_stack.md | Compatibility |
| NFR-004 | 保守性・追従性 | 03_layer_architecture.md | Maintainability |
| NFR-005 | セキュリティ | 10_security.md | Security |
| NFR-006 | ユーザビリティ | 08_api_spec.md | Convenience API |
| NFR-007 | テスタビリティ | 11_nfr_realization.md | Testability |

## 用語定義（Glossary）

| 用語 | 定義 | 備考 |
|------|------|------|
| Transport | 通信層の抽象。バックエンドとの接続・メッセージ送受信を担う | Python SDK の Transport ABC に相当 |
| Client | 操作層の抽象。クエリ・セッション管理を担う | Transport を DI で受け取る |
| Session | セッション層の抽象。セッション内の対話を担う | CLI プロセスのライフサイクルに対応 |
| JSONL | 行区切り JSON。CLI との通信プロトコル | 各行が独立した JSON オブジェクト |
| CLI | Claude Code CLI（cli.js） | Node.js で実行される Agent SDK バイナリ |
| Handshake | CLI 起動後の初期化プロトコル | `initialize_ready` → `InitializeRequest` → `SystemMessage` |
| Control Message | SDK ↔ CLI 間の制御メッセージ | `control_request` / `control_response` |

## References（参照）

- [01_request/spec_01_swift_agent_sdk.md](../01_request/spec_01_swift_agent_sdk.md) - Request 仕様
- [02_requirements/00_index.md](../02_requirements/00_index.md) - Requirements インデックス

## Referenced By（被参照）

*（04_implementation_plan, 05_tasks から参照される予定）*

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
