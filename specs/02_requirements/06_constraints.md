---
title: "Swift Agent SDK - 制約・前提・外部依存"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, constraints]
references:
  - ./00_index.md
  - ../01_request/spec_01_swift_agent_sdk.md
---

# 制約・前提・外部依存

## 1. プラットフォーム制約

| 制約 | 理由 |
|------|------|
| macOS 15+ / Linux のみ | Node.js ランタイムが必要、iOS/watchOS/tvOS は不可 |
| サブプロセス起動が可能な環境のみ | Foundation.Process（POSIX fork/exec）に依存 |
| サンドボックス環境では動作しない | App Sandbox はサブプロセス起動を制限する |

## 2. ランタイム依存

| 依存 | バージョン | 必須/任意 | 備考 |
|------|-----------|----------|------|
| Node.js | 18+ | 必須（いずれか1つ） | CLI 実行用 |
| Bun | - | 任意（Node.js 代替） | CLI 実行用 |
| Deno | - | 任意（Node.js 代替） | CLI 実行用 |
| `@anthropic-ai/claude-agent-sdk` | 0.2.x | 必須 | CLI バイナリ（cli.js）を含む npm パッケージ |

## 3. 認証

| 制約 | 説明 |
|------|------|
| サブスクリプション認証（Claude Pro/Max/Team）が必要 | 利用者が事前に `claude login` で OAuth 認証を完了しておく |
| SDK は認証情報を直接扱わない | CLI プロセスが OAuth トークンキャッシュから読み取る |
| SDK は認証情報を保持・記録しない | セキュリティ要件 |
| API Key 認証は想定しない | サブスクリプションモデルを前提とする |

## 4. プロトコル制約

| 制約 | 影響 | 緩和策 |
|------|------|--------|
| JSONL プロトコルは非公開内部仕様 | バージョンアップで破壊的変更の可能性 | CLI バージョンにロック |
| プロトコルのドキュメントが存在しない | 実装は CLI ソースコード / Go SDK からの逆算 | 包括的なプロトコルテスト |
| CLI と SDK のバージョンペア管理が必要 | SDK 0.2.x ↔ CLI 2.1.x | Package.swift でバージョンマッピングを管理 |

## 5. パフォーマンス制約

| 制約 | 値 | 備考 |
|------|-----|------|
| コールドスタート | ~12 秒 | CLI プロセス起動コスト、SDK 側では解決不可 |
| セッション有効期限 | 10 分（非活動時） | CLI 側の制限 |
| プロセスメモリ | Node.js プロセス分（100-300MB 程度） | Swift プロセスとは別 |

## 6. ライセンス制約

| 制約 | 説明 |
|------|------|
| Claude Agent SDK は Anthropic 商用利用規約 | CLI バイナリの再配布に制約がある可能性 |
| SDK パッケージに CLI を同梱しない | ユーザーが別途インストールする（D-4） |
| Swift SDK 自体のライセンスは独立 | MIT 等のオープンソースライセンスを想定 |

## 7. 前提条件

| 前提 | 説明 |
|------|------|
| ユーザーが Node.js をインストール済み | SDK のセットアップドキュメントで明記 |
| ユーザーが npm パッケージをインストール済み | `npm install @anthropic-ai/claude-agent-sdk` |
| ユーザーが認証済み | `claude login` でサブスクリプション認証を完了 |
| ネットワーク接続がある | CLI が Claude API にアクセスするため |

## 8. 技術的制約

| 制約 | 説明 |
|------|------|
| Swift 6.0+ が必要 | Swift Concurrency の安定版 |
| Foundation フレームワークが必要 | Process, Pipe, FileHandle, JSONEncoder/Decoder |
| Concurrency ランタイムが必要 | async/await, Actor, AsyncSequence |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
