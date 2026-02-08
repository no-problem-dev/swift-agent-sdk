---
title: "Swift Agent SDK - タスク依存関係"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, dependencies]
references:
  - ./00_index.md
---

# タスク依存関係

## 依存関係一覧

| Task ID | 名称 | 依存先 | 被依存先 |
|---------|------|--------|---------|
| T1 | Initialize パッケージ構造 | none | T2, T3, T4, T9 |
| T2 | Implement Protocol 定義 | T1 | T8, T20 |
| T3 | Implement Model 型定義 | T1 | T5, T6, T8, T11, T21 |
| T4 | Implement エラー型 | T1 | T7, T10 |
| T5 | Test AgentMessage/ContentBlock/JSONValue | T3 | (なし) |
| T6 | Test QueryOptions/SessionOptions | T3 | (なし) |
| T7 | Test AgentSDKError | T4 | (なし) |
| T8 | Implement AgentSDK namespace スタブ | T2, T3 | (T19 で上書き) |
| T9 | Implement JSONLCodec | T1 | T13 |
| T10 | Implement CLILocator | T4 | T12 |
| T11 | Implement CLIArgBuilder | T3 | T12 |
| T12 | Implement CLIProcess | T10, T11 | T14, T16 |
| T13 | Implement JSONL プロトコル型 | T9 | T14, T15 |
| T14 | Implement Handshake | T12, T13 | T15, T16 |
| T15 | Implement MessageRouter | T13, T14 | T16, T17, T18 |
| T16 | Implement ClaudeCodeTransport | T12, T14, T15 | T17, T19 |
| T17 | Implement ClaudeCodeClient | T15, T16 | T18, T19, T22 |
| T18 | Implement ClaudeCodeSession | T15, T17 | T19, T22 |
| T19 | Implement AgentSDK convenience API | T16, T17, T18 | T23, T24 |
| T20 | Implement MockTransport | T2 | T21, T22 |
| T21 | Implement MockFixtures | T3, T20 | T22 |
| T22 | Test ClaudeCodeClient（Mock） | T17, T18, T20, T21 | T24, T25 |
| T23 | Test EndToEnd（統合テスト） | T19 | (なし) |
| T24 | Create README + DocC | T19, T22 | (なし) |
| T25 | Configure GitHub Actions CI | T22 | (なし) |

---

## クリティカルパス

最長の依存チェーン（ボトルネック）:

```
T1 → T3 → T11 → T12 → T14 → T15 → T16 → T17 → T18 → T19 → T22 → T24
```

所要時間見積: 1+3+2+4+3+4+3+3+3+2+3+3 = **34h**

---

## 並列実行可能なタスクグループ

### Phase 1

| Wave | 並列タスク | 前提 |
|------|-----------|------|
| Wave 1-2 | T2, T3, T4 | T1 完了後 |
| Wave 1-3 | T5, T6, T7, T8 | T2/T3/T4 完了後（各依存に応じて） |

### Phase 2

| Wave | 並列タスク | 前提 |
|------|-----------|------|
| Wave 2-1 | T9, T10, T11 | Phase 1 完了後（各依存に応じて） |
| Wave 2-3 | T13 → T14 | Wave 2-1, 2-2 完了後（順次） |

### Phase 3

| Wave | 並列タスク | 前提 |
|------|-----------|------|
| Wave 3-2 | T16, T17 | Wave 3-1 完了後（T17 は T16 に軽度依存） |
| Wave 3-3 | T18 → T19 | Wave 3-2 完了後（順次） |

### Phase 4

| Wave | 並列タスク | 前提 |
|------|-----------|------|
| Wave 4-1 | T20, T21 | T2, T3 完了後（Phase 1 時点で着手可能） |
| Wave 4-2 | T22, T23 | Wave 4-1 + Phase 3 完了後 |
| Wave 4-3 | T24, T25 | Wave 4-2 完了後 |

**注意:** Wave 4-1（T20, T21）は Phase 1 完了時点で着手可能。Phase 2-3 と並列で進められる。

---

## 循環依存チェック

循環依存は存在しない。全タスクは DAG（有向非巡回グラフ）を構成する。

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
