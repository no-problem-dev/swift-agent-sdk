---
title: "ClaudeAgent - 依存関係 Mermaid 図"
created: 2026-02-08
status: draft
tags: [tasks, dependencies, mermaid, claude-agent]
references:
  - ./00_index.md
  - ./99_dependencies.md
---

# 依存関係 Mermaid 図

## 1. Phase 間依存関係図

```mermaid
flowchart LR
    subgraph Phase1[Phase 1: 基盤構築]
        P1[T1-T5]
    end
    subgraph Phase2[Phase 2: Domain]
        P2[T6-T11]
    end
    subgraph Phase3[Phase 3: Infrastructure]
        P3[T12-T16]
    end
    subgraph Phase4[Phase 4: Presentation]
        P4[T17-T24]
    end
    subgraph Phase5[Phase 5: 統合]
        P5[T25-T27]
    end

    Phase1 --> Phase2
    Phase2 --> Phase3
    Phase2 --> Phase4
    Phase3 --> Phase5
    Phase4 --> Phase5
```

## 2. Wave 間依存関係図

### Phase 1

```mermaid
flowchart TD
    subgraph Phase1[Phase 1: 基盤構築]
        W1.1[Wave 1-1: ディレクトリ構造<br/>T1]
        W1.2[Wave 1-2: Package.swift<br/>T2, T3, T4]
        W1.3[Wave 1-3: App エントリポイント<br/>T5]

        W1.1 --> W1.2
        W1.2 --> W1.3
    end
```

### Phase 2

```mermaid
flowchart TD
    subgraph Phase2[Phase 2: Domain]
        W2.1[Wave 2-1: エンティティ + 値オブジェクト<br/>T6, T7, T8]
        W2.2[Wave 2-2: プロトコル + エラー型<br/>T9, T10]
        W2.3[Wave 2-3: 総合テスト<br/>T11]

        W2.1 --> W2.2
        W2.2 --> W2.3
    end
```

### Phase 3 + Phase 4（並列）

```mermaid
flowchart TD
    P2_done[Phase 2 完了]

    subgraph Phase3[Phase 3: Infrastructure]
        W3.1[Wave 3-1: Mapper + Service 骨格<br/>T12, T13]
        W3.2[Wave 3-2: JSONSessionStore<br/>T14]
        W3.3[Wave 3-3: Service 完全実装<br/>T15, T16]

        W3.1 --> W3.3
        W3.2
    end

    subgraph Phase4[Phase 4: Presentation]
        W4.1[Wave 4-1: Store 骨格<br/>T17]
        W4.2[Wave 4-2: 基本 View<br/>T18, T19, T20]
        W4.3[Wave 4-3: ChatView<br/>T21]
        W4.4[Wave 4-4: ToolCard + Sheet<br/>T22]
        W4.5[Wave 4-5: Store ロジック + Test<br/>T23, T24]

        W4.1 --> W4.2
        W4.1 --> W4.4
        W4.2 --> W4.3
        W4.3 --> W4.5
        W4.4 --> W4.5
    end

    P2_done --> W3.1
    P2_done --> W3.2
    P2_done --> W4.1
```

### Phase 5

```mermaid
flowchart TD
    P3_done[Phase 3 完了<br/>T16]
    P4_done[Phase 4 完了<br/>T24]

    subgraph Phase5[Phase 5: 統合]
        W5.1[Wave 5-1: DI ワイヤリング<br/>T25]
        W5.2[Wave 5-2: Integration + E2E<br/>T26]
        W5.3[Wave 5-3: Manual QA + README<br/>T27]

        W5.1 --> W5.2
        W5.2 --> W5.3
    end

    P3_done --> W5.1
    P4_done --> W5.1
```

## 3. Task 間依存関係図（全体）

```mermaid
flowchart TD
    %% Phase 1
    T1[T1: Initialize プロジェクト構造]
    T2[T2: Domain Package.swift]
    T3[T3: Infrastructure Package.swift]
    T4[T4: Presentation Package.swift]
    T5[T5: App エントリポイント]

    T1 --> T2
    T1 --> T3
    T1 --> T4
    T2 --> T5
    T3 --> T5
    T4 --> T5

    %% Phase 2
    T6[T6: Domain エンティティ]
    T7[T7: Domain 値オブジェクト]
    T8[T8: Domain Unit Test]
    T9[T9: Domain プロトコル]
    T10[T10: Domain AppError]
    T11[T11: Domain 総合テスト]

    T2 --> T6
    T2 --> T7
    T2 --> T8
    T6 --> T9
    T7 --> T9
    T6 --> T10
    T9 --> T11
    T10 --> T11

    %% Phase 3
    T12[T12: AgentMessageMapper]
    T13[T13: AgentService 骨格]
    T14[T14: JSONSessionStore]
    T15[T15: AgentService 完全実装]
    T16[T16: AgentService Integration Test]

    T11 --> T12
    T11 --> T13
    T11 --> T14
    T12 --> T15
    T13 --> T15
    T15 --> T16

    %% Phase 4
    T17[T17: AppState + SessionState 骨格]
    T18[T18: ContentView]
    T19[T19: SessionSidebar]
    T20[T20: InputArea]
    T21[T21: ChatView]
    T22[T22: ToolCard + Sheet]
    T23[T23: Store ロジック]
    T24[T24: Presentation Unit Test]

    T11 --> T17
    T17 --> T18
    T17 --> T19
    T17 --> T20
    T18 --> T21
    T20 --> T21
    T17 --> T22
    T21 --> T23
    T22 --> T23
    T23 --> T24

    %% Phase 5
    T25[T25: DI ワイヤリング]
    T26[T26: Integration + E2E]
    T27[T27: Manual QA + README]

    T16 --> T25
    T24 --> T25
    T25 --> T26
    T26 --> T27

    %% Styling
    style T1 fill:#fce4ec
    style T2 fill:#fce4ec
    style T3 fill:#fce4ec
    style T4 fill:#fce4ec
    style T5 fill:#fce4ec
    style T6 fill:#e8f5e9
    style T7 fill:#e8f5e9
    style T8 fill:#e8f5e9
    style T9 fill:#e8f5e9
    style T10 fill:#e8f5e9
    style T11 fill:#e8f5e9
    style T12 fill:#e3f2fd
    style T13 fill:#e3f2fd
    style T14 fill:#e3f2fd
    style T15 fill:#e3f2fd
    style T16 fill:#e3f2fd
    style T17 fill:#fff3e0
    style T18 fill:#fff3e0
    style T19 fill:#fff3e0
    style T20 fill:#fff3e0
    style T21 fill:#fff3e0
    style T22 fill:#fff3e0
    style T23 fill:#fff3e0
    style T24 fill:#fff3e0
    style T25 fill:#f3e5f5
    style T26 fill:#f3e5f5
    style T27 fill:#f3e5f5
```

### 凡例

| 色 | Phase |
|----|-------|
| 赤系 | Phase 1: 基盤構築 |
| 緑系 | Phase 2: Domain |
| 青系 | Phase 3: Infrastructure |
| 橙系 | Phase 4: Presentation |
| 紫系 | Phase 5: 統合 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
