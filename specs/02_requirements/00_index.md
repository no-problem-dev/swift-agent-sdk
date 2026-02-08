---
title: "Swift Agent SDK - 要求仕様 インデックス"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, requirements]
references:
  - ../01_request/spec_01_swift_agent_sdk.md
---

# 要求仕様: Swift Agent SDK

## 概要

エージェント操作の抽象プロトコル群を Swift で定義し、
Claude Code CLI サブプロセスをその具象実装として DI する Swift パッケージ。
プロトコル指向設計により、具象バックエンドの差し替え・テスト・将来拡張を容易にする。

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
| プロトコル階層設計 | 各 protocol の責務・メソッド要件 | protocol 定義・associated type・ジェネリクス設計 |
| DI パターン | 注入ポイント・差し替え可能性の要件 | コンストラクタ注入・Factory 型の具体実装 |
| JSONL プロトコルの対応範囲 | メッセージタイプ一覧・振る舞い | Codable 型設計・パース実装 |
| CLI プロセス管理 | 起動・終了・エラー検知の要件 | Process/Subprocess API 選択・Actor 設計 |
| ストリーミング API | ユーザーが受け取るメッセージ種別・順序 | AsyncThrowingStream 実装詳細 |
| セッション管理 | 作成・再開・有効期限の要件 | メモリ管理・キャッシュ戦略 |
| 権限ハンドリング | 権限モード・カスタムハンドラの振る舞い | Actor ルーティング実装 |
| CLI 探索 | 探索順序・検出できない場合の振る舞い | FileManager/which 実装 |
| エラーハンドリング | エラー種別・リカバリ要件 | Error 型階層・retry 実装 |

## 決定事項

| ID | 決定内容 | 根拠 | 日付 |
|----|---------|------|------|
| D-1 | Approach B（CLI 直接制御）を採用 | Go SDK の先行事例あり、二重間接の排除 | 2026-02-08 |
| D-2 | ターゲットは macOS + Linux のみ | Node.js ランタイム依存により iOS 不可 | 2026-02-08 |
| D-3 | サードパーティ依存なし（Foundation のみ） | 依存最小化・Swift 標準ライブラリで十分 | 2026-02-08 |
| D-4 | CLI バイナリは同梱しない | ライセンス制約・ユーザーインストールに委ねる | 2026-02-08 |
| D-5 | 完全プロトコル指向設計を採用 | 公式 Python SDK の Transport ABC パターンを参考。具象バックエンドの差し替え・テスト容易性を最優先 | 2026-02-08 |
| D-6 | Claude Code CLI 実装は DI される具象の1つ | プロトコル層（What）と具象層（Claude Code固有）を完全分離し、CLI 更新時の変更を具象層に局所化 | 2026-02-08 |
| D-7 | Python SDK の Transport DI パターンに倣う | Go SDK の ISP 分解より、Python SDK のシンプルな Transport 注入の方が Swift に適合 | 2026-02-08 |
| D-8 | generics を採用（existential ではなく） | `some AgentClient` / `<T: AgentClient>` で型消去コストを回避、Swift らしい API | 2026-02-08 |
| D-9 | 各レイヤーは単一 protocol を基本、必要に応じて分割 | 実用主義。最初から ISP 分解せず、実際に必要になった時点で抽象化する | 2026-02-08 |
| D-10 | V2（セッション維持）を Primary API として実装 | プロセス再利用でコールドスタート回避。V1 query はセッション上のワンショットとして表現可能。SDK 側の V2 安定化に追随していく | 2026-02-08 |
| D-11 | hooks 機能は後回し | コア機能を先に安定させる。hooks は将来フェーズで対応 | 2026-02-08 |
| D-12 | JSON Schema は辞書型（`[String: Any]` 相当）で表現、外部ライブラリ不使用 | 外部依存ゼロの方針を堅持。swift-json-schema 等は入れない | 2026-02-08 |
| D-13 | Linux サポートは後回し、初期ターゲットは macOS のみ | まず macOS で安定させてから Linux 対応を検討 | 2026-02-08 |
| D-14 | 3モジュール分割: `AgentSDK` + `AgentSDKClaudeCode` + `AgentSDKTesting` | protocol 層・具象層・テスト支援を明確に分離 | 2026-02-08 |
| D-15 | プロセスプール/プリウォーミングはスコープ外 | コア機能に集中。必要になった時点で別パッケージとして検討 | 2026-02-08 |
| D-16 | JSONL プロトコル仕様はテスト駆動で検証する | 仕様書ベースではなく、実 CLI との統合テストで不整合を検出・修正していく方針 | 2026-02-08 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
| 2026-02-08 | プロトコル指向設計 + DI 要件追加（D-5〜D-7）、責務分離表にプロトコル・DI 項目追加 |
| 2026-02-08 | D-8（generics 採用）・D-9（単一 protocol 基本）追加、OQ-008・OQ-009 を解決済みに |
| 2026-02-08 | D-10（V2 セッション維持を Primary API）追加、OQ-003 を解決済みに |
| 2026-02-08 | D-11〜D-14 追加、OQ-002・004・006・007 を解決済みに |
| 2026-02-08 | D-15〜D-16 追加、OQ-001・005 を解決済みに。全オープンクエスチョン解決 |
