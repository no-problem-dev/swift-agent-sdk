---
title: "Swift Agent SDK - 引き継ぎ時の注意点"
created: 2026-02-08
status: active
tags: [swift, agent-sdk, handoff, notes]
references:
  - ./01_status.md
  - ./05_next_actions.md
  - ./06_issues.md
---

# 引き継ぎ時の注意点

## 最重要: テストを全件実行する前に

`swift test` を一括実行するとハングする可能性がある。
必ず `05_next_actions.md` の「確認手順」に従い、フィルタで段階的に確認すること。

ハングした場合は `pkill -f "swift test"` で停止。

## コードベースの構造

```
Sources/
  AgentSDK/              ← 抽象層（Protocol + Model）。外部依存なし
  AgentSDKClaudeCode/    ← Claude Code CLI の具象実装
    Internal/            ← 内部コンポーネント（CLIProcess, MessageRouter 等）
      Protocol/          ← JSONL プロトコル型（CLIMessage, SDKMessage）
  AgentSDKTesting/       ← テストヘルパー（Phase 4 で実装予定）
```

## 設計上の重要判断

### 1. AgentSDK convenience API の配置
- `AgentSDK` モジュールは具象実装を知らない（循環依存回避）
- convenience API は `AgentSDKClaudeCode` モジュール内の `extension AgentSDK` として定義
- ユーザーは `import AgentSDKClaudeCode` で利用可能

### 2. Transport のインラインハンドシェイク
- `ClaudeCodeTransport` は `Handshake` struct を使わず、reader task 内でハンドシェイクを inline 実装
- 理由: 単一の stdout ストリームイテレータをハンドシェイク後のメッセージ転送と共有するため

### 3. CLIProcess の非同期パターン
- `stdoutStream()` は `nonisolated` で actor isolation から外している
- `waitForExit()` は continuation ベース（`terminationHandler` で resume）
- ブロッキング I/O は必ず `Task.detached` で actor 外のスレッドで実行すること

## ファイル参照ガイド

| 知りたいこと | 参照先 |
|-------------|--------|
| 全体アーキテクチャ | `specs/03_design_spec/01_architecture.md` |
| 公開 API 仕様 | `specs/03_design_spec/08_api_spec.md` |
| タスク定義 | `specs/05_tasks/01_phase1_foundation.md` 〜 `04_phase4_test_docs.md` |
| 完了タスク記録 | `specs/06_implementation_log/01_completed_tasks.md` |
| 技術的学び | `specs/06_implementation_log/02_learnings.md` |
| 進捗 | `specs/05_tasks/99_progress.md` |
