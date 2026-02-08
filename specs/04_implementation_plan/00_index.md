---
title: "Swift Agent SDK - 実装計画 インデックス"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan]
references:
  - ../03_design_spec/00_index.md
  - ../02_requirements/00_index.md
---

# 実装計画: Swift Agent SDK

## Intent（意図）

Design Spec（03_design_spec）で設計した「どう実現するか」を、
Phase/Wave 構造の具体的な実装手順に落とし込む。
実装者（人間・AI）が迷わずコードを書き始められる状態を作る。

---

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_phase_wave_structure.md](./01_phase_wave_structure.md) | Phase/Wave 全体構造・依存関係 |
| [02_reference_matrix.md](./02_reference_matrix.md) | FF-ID 単位の参照マトリクス |
| [03_dev_rules.md](./03_dev_rules.md) | 開発ルール（ブランチ戦略・コーディング指針・コミット規約） |
| [04_test_strategy.md](./04_test_strategy.md) | テスト戦略（Unit/Integration/E2E） |
| [05_rollout.md](./05_rollout.md) | ロールアウト・ロールバック戦略 |
| [06_ai_instruction_template.md](./06_ai_instruction_template.md) | AI への指示構成テンプレート |

## Phase 概要

| Phase | 名称 | 概要 | Wave 数 |
|-------|------|------|---------|
| Phase 1 | 基盤構築 | Package.swift + Protocol Layer + 基盤データモデル | 3 |
| Phase 2 | CLI 具象実装 | CLIProcess〜Handshake の内部コンポーネント | 3 |
| Phase 3 | クライアント実装 | Client/Session/MessageRouter + 公開 API | 3 |
| Phase 4 | テスト・統合 | MockTransport + Integration Tests + ドキュメント | 3 |

## 依存関係概要

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase 4
(Protocol)   (CLI内部)   (Client)    (Test/Doc)
```

## コンパクション条件

各 Wave 完了後に `/compact` を実行し、以下の情報を保持する:
- 完了した Wave の成果物一覧
- 未解決の課題・検討事項
- 次の Wave の入力となるファイルパス

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
