---
title: "ClaudeAgent - 実装計画書 インデックス"
created: 2026-02-08
status: draft
tags: [implementation-plan, claude-agent]
references:
  - ../03_design_spec/00_index.md
  - ../02_requirements/00_index.md
---

# 実装計画書: ClaudeAgent

## 概要

Design Spec の設計を、Phase/Wave 構造の実装計画に落とし込む。
実装者（人間・AI）が迷わずコードを書き始められる具体的な手順を定義する。

## ドキュメント構成

| ファイル | 内容 |
|---------|------|
| [01_phase_overview.md](./01_phase_overview.md) | Phase/Wave 構造の全体図・依存関係 |
| [02_dev_rules.md](./02_dev_rules.md) | 開発ルール（ブランチ戦略・コーディング規約・コミット規約） |
| [03_phase1_foundation.md](./03_phase1_foundation.md) | Phase 1: プロジェクト基盤構築 |
| [04_phase2_domain.md](./04_phase2_domain.md) | Phase 2: Domain パッケージ実装 |
| [05_phase3_infrastructure.md](./05_phase3_infrastructure.md) | Phase 3: Infrastructure パッケージ実装 |
| [06_phase4_presentation.md](./06_phase4_presentation.md) | Phase 4: Presentation パッケージ実装 |
| [07_phase5_integration.md](./07_phase5_integration.md) | Phase 5: 統合・テスト・仕上げ |
| [08_test_strategy.md](./08_test_strategy.md) | テスト戦略（Unit / Integration / E2E / Manual QA） |
| [09_rollout.md](./09_rollout.md) | ロールアウト・ロールバック手順 |
| [99_references.md](./99_references.md) | FF 単位の参照マトリクス |

## Phase 一覧

| Phase | 名称 | Wave 数 | 前提 |
|-------|------|---------|------|
| Phase 1 | プロジェクト基盤構築 | 3 | なし |
| Phase 2 | Domain パッケージ実装 | 3 | Phase 1 完了 |
| Phase 3 | Infrastructure パッケージ実装 | 3 | Phase 2 完了 |
| Phase 4 | Presentation パッケージ実装 | 5 | Phase 2 完了（Phase 3 と並列可能） |
| Phase 5 | 統合・テスト・仕上げ | 4 | Phase 3 + Phase 4 完了 |

## 並列化可能領域

```
Phase 1 (基盤)
  ↓
Phase 2 (Domain)
  ↓
  ├── Phase 3 (Infrastructure) ──┐
  │                              │
  └── Phase 4 (Presentation) ───┤
                                 ↓
                          Phase 5 (統合)
```

> Phase 3 と Phase 4 は Phase 2（Domain）完了後に**並列実行可能**。
> 両パッケージは Domain にのみ依存し、互いに依存しないため。

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
