---
title: "Swift Agent SDK - 非機能要件"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, nfr]
references:
  - ./01_feature_overview.md
---

# 非機能要件

## NFR-001: パフォーマンス

| 指標 | 目標値 | 備考 |
|------|--------|------|
| SDK オーバーヘッド（query 呼び出し → CLI spawn） | 100ms 以内 | CLI のコールドスタートは含まない |
| JSONL メッセージパース遅延 | 1ms 以内 / メッセージ | CLI → Swift 間の処理遅延 |
| メモリ使用量増分 | 10MB 以内 | SDK 自体のメモリフットプリント |
| セッション再利用時のオーバーヘッド | 50ms 以内 | stdin への書き込み完了まで |

## NFR-002: 信頼性

| 指標 | 目標値 | 備考 |
|------|--------|------|
| プロセスクラッシュ検知 | 100% | terminationHandler で保証 |
| リソースリーク（プロセス残留） | 0 件 | deinit/キャンセルで確実にクリーンアップ |
| プロトコルエラーからの復帰 | 不正メッセージをスキップし継続 | 未知のメッセージタイプは無視 |

## NFR-003: 互換性

| 指標 | 目標値 | 備考 |
|------|--------|------|
| Swift バージョン | 6.0+ | Swift Concurrency が安定したバージョン |
| macOS バージョン | 15.0+（Sequoia） | Foundation.Process の最新 API |
| Linux 対応 | 後回し（D-13） | 初期は macOS のみ、後日対応検討 |
| Node.js バージョン | 18+ | CLI の要件に準拠 |
| Agent SDK バージョン | 0.2.x（CLI 2.1.x） | バージョンロックで管理 |

## NFR-004: 保守性・追従性

| 指標 | 目標値 | 備考 |
|------|--------|------|
| **プロトコル層の安定性** | Claude Code CLI 更新時にプロトコル層の変更が 0 | 具象層のみ変更 |
| **具象層の変更局所性** | CLI プロトコル変更時の影響が ClaudeCode* 型内に収まる | protocol 準拠型の内部実装のみ |
| **protocol 定義の Claude Code 非依存性** | AgentTransport / AgentClient / AgentSession に CLI 固有概念が 0 | JSONL、cli.js 等への言及なし |
| テストカバレッジ | 80% 以上（プロトコル層 + 具象層） | MockTransport で単体テスト |
| 外部依存 | 0（Foundation のみ） | 依存更新コスト排除 |
| CLI バージョンアップ対応 | 具象層（ClaudeCode*）のみの変更で対応可能 | protocol 層に影響しない |

## NFR-005: セキュリティ

| 指標 | 目標値 | 備考 |
|------|--------|------|
| stdin/stdout 以外の通信経路 | 0 | ネットワーク通信は CLI に委ねる |
| CLI プロセスの権限 | 呼び出し元プロセスと同一 | 権限昇格しない |
| 環境変数の取り扱い | API キー等は CLI の環境変数経由 | SDK 内部に保持しない |

## NFR-006: ユーザビリティ（API 設計）

| 指標 | 目標値 | 備考 |
|------|--------|------|
| 最小コード行数（Hello World） | 10 行以内 | import からコンビニエンス API で結果表示まで |
| DI 不要の簡便利用 | コンビニエンス API で DI を意識せず利用可能 | `AgentSDK.query()` 等 |
| Swift Doc コメント | public API（protocol + 具象）100% | DocC 対応 |
| 型安全性 | メッセージタイプは Swift enum で表現 | 不正な状態を型で排除 |
| Sendable 準拠 | public protocol・型はすべて Sendable | Swift Concurrency 安全 |
| protocol 可読性 | 各 protocol のメソッド数が 5 以下 | 最小インターフェース原則 |

## NFR-007: テスタビリティ

| 指標 | 目標値 | 備考 |
|------|--------|------|
| モック作成容易性 | 各 protocol を 20 行以内でモック実装可能 | メソッド数が少ないため |
| CLI 不要テスト | MockTransport でプロトコル層の全機能をテスト可能 | Node.js / CLI 不要 |
| 送信メッセージ検証 | MockTransport が送信メッセージを記録 | テストでアサート可能 |
| 応答シナリオ注入 | MockTransport に事前定義メッセージ列を設定可能 | 各種シナリオをテスト |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
| 2026-02-08 | NFR-004 をプロトコル指向 + DI 観点で全面改訂、NFR-007（テスタビリティ）追加 |
