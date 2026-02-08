---
title: "Swift Agent SDK - 参照マトリクス"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, references]
references:
  - ./00_index.md
  - ../04_implementation_plan/02_reference_matrix.md
---

# 参照マトリクス（タスク単位）

## FF-ID → タスク対応

| FF-ID | 名称 | 対応タスク |
|-------|------|-----------|
| FF-001 | CLI プロセス管理 | T10, T11, T12, T16 |
| FF-002 | JSONL トランスポート | T9, T13 |
| FF-003 | 初期化ハンドシェイク | T14 |
| FF-004 | ワンショットクエリ | T17, T19, T22 |
| FF-005 | セッション管理 | T18, T19, T22, T23 |
| FF-006 | 権限ハンドリング | T15, T22 |
| FF-007 | サブエージェント定義 | T11 |
| FF-008 | MCP サーバー設定 | T11, T18 |
| FF-009 | ランタイム制御 | T15, T18 |
| FF-010 | エラーハンドリング | T4, T7 |
| FF-011 | プロトコル指向設計 + DI | T1, T2, T3, T8, T17, T20 |

---

## タスク → 仕様書参照マトリクス

| Task ID | Requirements | Design Spec | Implementation Plan |
|---------|-------------|-------------|---------------------|
| T1 | - | 04_component_architecture.md#3,#4 | 01_phase_wave_structure.md#Wave 1-1 |
| T2 | - | 03_layer_architecture.md, 08_api_spec.md#2-3 | 01_phase_wave_structure.md#Wave 1-2 [A] |
| T3 | - | 05_data_model.md#2, 08_api_spec.md#4 | 01_phase_wave_structure.md#Wave 1-2 [B] |
| T4 | 03_functional_requirements.md#FR-039〜043 | 05_data_model.md#3 | 01_phase_wave_structure.md#Wave 1-2 [C] |
| T5 | - | 05_data_model.md#2.1-2.6 | 04_test_strategy.md#3.1 |
| T6 | - | 05_data_model.md#2.8-2.9 | 04_test_strategy.md#3.1 |
| T7 | - | 05_data_model.md#3 | 04_test_strategy.md#3.1 |
| T8 | - | 08_api_spec.md#1 | 01_phase_wave_structure.md#Wave 1-3 |
| T9 | 05_io_spec.md | 04_component_architecture.md#2.2 | 01_phase_wave_structure.md#Wave 2-1 [A] |
| T10 | 03_functional_requirements.md#FR-001 | 04_component_architecture.md#2.5, 06_auth_flow.md#3 | 01_phase_wave_structure.md#Wave 2-1 [B] |
| T11 | 05_io_spec.md | 04_component_architecture.md#2.6 | 01_phase_wave_structure.md#Wave 2-1 [C] |
| T12 | - | 04_component_architecture.md#2.1, 10_security.md#3.2 | 01_phase_wave_structure.md#Wave 2-2 |
| T13 | 05_io_spec.md | 05_data_model.md#4 | 01_phase_wave_structure.md#Wave 2-3 |
| T14 | 03_functional_requirements.md#FR-010〜012 | 06_auth_flow.md#1,#4, 04_component_architecture.md#2.3 | 01_phase_wave_structure.md#Wave 2-3 |
| T15 | 03_functional_requirements.md#FR-023〜027 | 04_component_architecture.md#2.4, 07_payment_flow.md#1,#3 | 01_phase_wave_structure.md#Wave 3-1 |
| T16 | - | 08_api_spec.md#2.1 | 01_phase_wave_structure.md#Wave 3-2 [A] |
| T17 | - | 08_api_spec.md#2.2, 09_screen_flow.md#2 | 01_phase_wave_structure.md#Wave 3-2 [B] |
| T18 | 03_functional_requirements.md#FR-018〜022 | 08_api_spec.md#3.1,#3.2, 09_screen_flow.md#3 | 01_phase_wave_structure.md#Wave 3-3 |
| T19 | - | 08_api_spec.md#1 | 01_phase_wave_structure.md#Wave 3-3 |
| T20 | - | 04_component_architecture.md#2.7, 08_api_spec.md#7.1 | 01_phase_wave_structure.md#Wave 4-1 [A] |
| T21 | - | 08_api_spec.md#7.2 | 01_phase_wave_structure.md#Wave 4-1 [B] |
| T22 | - | - | 04_test_strategy.md#1.3 |
| T23 | - | - | 04_test_strategy.md#1.2 |
| T24 | - | 08_api_spec.md（使用例） | 05_rollout.md#2 |
| T25 | - | - | 04_test_strategy.md#5 |

---

## Wave → 仕様書参照マトリクス

| Wave | Requirements | Design Spec | Implementation Plan |
|------|-------------|-------------|---------------------|
| 1-1 | - | 04_component_architecture.md | 01_phase_wave_structure.md |
| 1-2 | FR-039〜043 | 03_layer_architecture.md, 05_data_model.md, 08_api_spec.md | 01_phase_wave_structure.md |
| 1-3 | - | 05_data_model.md, 08_api_spec.md | 04_test_strategy.md |
| 2-1 | FR-001, 05_io_spec.md | 04_component_architecture.md, 06_auth_flow.md | 01_phase_wave_structure.md |
| 2-2 | - | 04_component_architecture.md, 10_security.md | 01_phase_wave_structure.md |
| 2-3 | FR-010〜012, 05_io_spec.md | 05_data_model.md, 06_auth_flow.md | 01_phase_wave_structure.md |
| 3-1 | FR-023〜027, FR-034〜038 | 04_component_architecture.md, 07_payment_flow.md | 01_phase_wave_structure.md |
| 3-2 | - | 08_api_spec.md, 09_screen_flow.md | 01_phase_wave_structure.md |
| 3-3 | FR-018〜022 | 08_api_spec.md, 09_screen_flow.md | 01_phase_wave_structure.md |
| 4-1 | - | 04_component_architecture.md, 08_api_spec.md | 01_phase_wave_structure.md |
| 4-2 | - | - | 04_test_strategy.md |
| 4-3 | - | 08_api_spec.md | 04_test_strategy.md, 05_rollout.md |

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
