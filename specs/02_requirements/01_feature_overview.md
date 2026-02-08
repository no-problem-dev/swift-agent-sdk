---
title: "Swift Agent SDK - 機能概要"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, features]
references:
  - ../01_request/spec_01_swift_agent_sdk.md
  - ./00_index.md
---

# 機能概要

## Why

TypeScript/Python でしか利用できない Claude Code Agent SDK の機能を、
Swift 開発者が Swift ネイティブな API で利用できるようにする。

## What

エージェント操作の抽象（Swift protocol 群）と、Claude Code CLI サブプロセスによる具象実装を提供する Swift パッケージ。
利用者はプロトコルに対してプログラミングし、具象バックエンドは DI で注入する。

## Intent

- **完全プロトコル指向設計:** 公開 API はすべて Swift protocol として定義。具象型は DI で注入
- **Claude Code は具象の1つ:** Claude Code CLI 固有のコードは差し替え可能な1実装に局所化
- **最小追従コスト:** Claude Code SDK の更新時、変更は具象層のみ。プロトコル層は安定
- Swift Concurrency（async/await, AsyncSequence）を活用した自然な API
- サードパーティ依存なし（Foundation のみ）で軽量に保つ

---

## FF 一覧表

| FF-ID | 名称 | 概要 | 関連要件 |
|-------|------|------|----------|
| FF-001 | CLI プロセス管理 | CLI の探索・起動・終了・エラー検知 | FR-001〜FR-005 |
| FF-002 | JSONL トランスポート | stdin/stdout 経由の JSONL メッセージ送受信 | FR-006〜FR-009 |
| FF-003 | 初期化ハンドシェイク | CLI との初期化プロトコル実行 | FR-010〜FR-012 |
| FF-004 | ワンショットクエリ | 単発のプロンプト送信とストリーミング応答受信 | FR-013〜FR-017 |
| FF-005 | セッション管理 | セッション作成・メッセージ送信・再開 | FR-018〜FR-022 |
| FF-006 | 権限ハンドリング | 権限モード設定・カスタム権限ハンドラ | FR-023〜FR-027 |
| FF-007 | サブエージェント定義 | エージェント定義の構成と CLI への受け渡し | FR-028〜FR-030 |
| FF-008 | MCP サーバー設定 | MCP サーバーの構成・状態取得 | FR-031〜FR-033 |
| FF-009 | ランタイム制御 | モデル変更・中断・ファイル巻き戻し | FR-034〜FR-038 |
| FF-010 | エラーハンドリング | エラー種別の分類・伝播・リカバリ | FR-039〜FR-043 |
| **FF-011** | **プロトコル指向設計 + DI** | **抽象 protocol 定義・具象注入・テスタビリティ** | **FR-044〜FR-053** |

---

## 機能概要図

```
                    Swift Application
                          │
                          │ プロトコルに対してプログラミング
                          │
   ┌──────────────────────▼──────────────────────┐
   │          Protocol Layer (FF-011)              │
   │   ┌───────────────────────────────────────┐  │
   │   │  AgentTransport protocol              │  │
   │   │  AgentClient protocol                 │  │
   │   │  AgentSession protocol                │  │
   │   │  AgentMessage / AgentOptions (値型)   │  │
   │   └───────────────────────────────────────┘  │
   └──────────────────────┬──────────────────────┘
                          │ DI（コンストラクタ注入）
   ┌──────────────────────▼──────────────────────┐
   │    Concrete: ClaudeCode (差し替え可能)        │
   │                                               │
   │   FF-001: CLIProcess (プロセス管理)           │
   │   FF-002: JSONLTransport (JSONL 通信)         │
   │   FF-003: Handshake (初期化)                  │
   │   FF-004〜009: ClaudeCodeClient 実装          │
   │   FF-010: エラー変換                          │
   │                                               │
   └──────────────────────┬──────────────────────┘
                          │ stdin/stdout
   ┌──────────────────────▼──────────────────────┐
   │   Claude Code CLI (cli.js)                    │
   └───────────────────────────────────────────────┘

   ┌───────────────────────────────────────────────┐
   │    Alternative: MockTransport (テスト用)       │
   │    Future: DirectAPITransport (将来拡張)       │
   └───────────────────────────────────────────────┘
```

### プロトコル階層（参考: Python SDK Transport ABC パターン）

```
AgentTransport (通信層)
  ├─ connect() / close() / write() / messages()
  └─ 具象: ClaudeCodeTransport, MockTransport

AgentClient (操作層, associatedtype Session: AgentSession)
  ├─ query() / createSession() / resumeSession()
  └─ 具象: ClaudeCodeClient<T: AgentTransport>  ← Transport を generics で DI

AgentSession (セッション層)
  ├─ send() / interrupt() / close()
  └─ 具象: ClaudeCodeSession
```

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
| 2026-02-08 | FF-011（プロトコル指向設計 + DI）追加、アーキテクチャ図をプロトコル階層に全面改訂 |
