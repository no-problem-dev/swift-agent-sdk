---
title: "Swift Agent SDK - 依存関係 Mermaid 図"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tasks, dependency-graph]
references:
  - ./00_index.md
  - ./99_dependencies.md
---

# 依存関係 Mermaid 図

## 1. Phase 間依存関係図

```mermaid
flowchart LR
    subgraph Phase1["Phase 1: 基盤構築"]
        P1["Protocol Layer\n型定義 + テスト"]
    end
    subgraph Phase2["Phase 2: CLI 具象 内部"]
        P2["CLI コンポーネント\nJSONL + Process + Handshake"]
    end
    subgraph Phase3["Phase 3: クライアント"]
        P3["Client + Session\n+ Convenience API"]
    end
    subgraph Phase4["Phase 4: テスト・統合"]
        P4["MockTransport\n統合テスト + ドキュメント"]
    end

    Phase1 --> Phase2
    Phase2 --> Phase3
    Phase3 --> Phase4
    Phase1 -.->|"T20/T21 は Phase 1 後に着手可"| Phase4
```

---

## 2. Wave 間依存関係図

### Phase 1

```mermaid
flowchart TD
    subgraph Phase1["Phase 1: 基盤構築"]
        W11["Wave 1-1\nPackage.swift"]
        W12["Wave 1-2\nProtocol 型定義"]
        W13["Wave 1-3\nUnit Tests + スタブ"]

        W11 --> W12
        W12 --> W13
    end
```

### Phase 2

```mermaid
flowchart TD
    subgraph Phase2["Phase 2: CLI 具象"]
        W21["Wave 2-1\nJSONLCodec / CLILocator / CLIArgBuilder"]
        W22["Wave 2-2\nCLIProcess Actor"]
        W23["Wave 2-3\nプロトコル型 + Handshake"]

        W21 --> W22
        W21 --> W23
        W22 --> W23
    end
```

### Phase 3

```mermaid
flowchart TD
    subgraph Phase3["Phase 3: クライアント"]
        W31["Wave 3-1\nMessageRouter"]
        W32["Wave 3-2\nTransport + Client"]
        W33["Wave 3-3\nSession + Convenience API"]

        W31 --> W32
        W32 --> W33
    end
```

### Phase 4

```mermaid
flowchart TD
    subgraph Phase4["Phase 4: テスト・統合"]
        W41["Wave 4-1\nMockTransport + Fixtures"]
        W42["Wave 4-2\nMock テスト + 統合テスト"]
        W43["Wave 4-3\nREADME + CI"]

        W41 --> W42
        W42 --> W43
    end
```

---

## 3. Task 間依存関係図（全体）

```mermaid
flowchart TD
    %% Phase 1: Wave 1-1
    subgraph W11["Wave 1-1"]
        T1["T1: Initialize\nパッケージ構造"]
    end

    %% Phase 1: Wave 1-2
    subgraph W12["Wave 1-2 (並列)"]
        T2["T2: Implement\nProtocol 定義"]
        T3["T3: Implement\nModel 型定義"]
        T4["T4: Implement\nエラー型"]
    end

    %% Phase 1: Wave 1-3
    subgraph W13["Wave 1-3 (並列)"]
        T5["T5: Test\nAgentMessage 等"]
        T6["T6: Test\nQueryOptions 等"]
        T7["T7: Test\nAgentSDKError"]
        T8["T8: Implement\nAgentSDK スタブ"]
    end

    %% Phase 2: Wave 2-1
    subgraph W21["Wave 2-1 (並列)"]
        T9["T9: Implement\nJSONLCodec"]
        T10["T10: Implement\nCLILocator"]
        T11["T11: Implement\nCLIArgBuilder"]
    end

    %% Phase 2: Wave 2-2
    subgraph W22["Wave 2-2"]
        T12["T12: Implement\nCLIProcess"]
    end

    %% Phase 2: Wave 2-3
    subgraph W23["Wave 2-3"]
        T13["T13: Implement\nJSONL プロトコル型"]
        T14["T14: Implement\nHandshake"]
    end

    %% Phase 3: Wave 3-1
    subgraph W31["Wave 3-1"]
        T15["T15: Implement\nMessageRouter"]
    end

    %% Phase 3: Wave 3-2
    subgraph W32["Wave 3-2 (並列)"]
        T16["T16: Implement\nClaudeCodeTransport"]
        T17["T17: Implement\nClaudeCodeClient"]
    end

    %% Phase 3: Wave 3-3
    subgraph W33["Wave 3-3"]
        T18["T18: Implement\nClaudeCodeSession"]
        T19["T19: Implement\nConvenience API"]
    end

    %% Phase 4: Wave 4-1
    subgraph W41["Wave 4-1 (並列)"]
        T20["T20: Implement\nMockTransport"]
        T21["T21: Implement\nMockFixtures"]
    end

    %% Phase 4: Wave 4-2
    subgraph W42["Wave 4-2 (並列)"]
        T22["T22: Test\nClient (Mock)"]
        T23["T23: Test\nEndToEnd"]
    end

    %% Phase 4: Wave 4-3
    subgraph W43["Wave 4-3 (並列)"]
        T24["T24: Create\nREADME + DocC"]
        T25["T25: Configure\nCI"]
    end

    %% Dependencies
    T1 --> T2
    T1 --> T3
    T1 --> T4
    T1 --> T9

    T3 --> T5
    T3 --> T6
    T3 --> T8
    T3 --> T11
    T3 --> T21

    T4 --> T7
    T4 --> T10

    T2 --> T8
    T2 --> T20

    T10 --> T12
    T11 --> T12

    T9 --> T13

    T12 --> T14
    T13 --> T14

    T13 --> T15
    T14 --> T15

    T12 --> T16
    T14 --> T16
    T15 --> T16

    T15 --> T17
    T16 --> T17

    T15 --> T18
    T17 --> T18

    T16 --> T19
    T17 --> T19
    T18 --> T19

    T20 --> T21

    T17 --> T22
    T18 --> T22
    T20 --> T22
    T21 --> T22

    T19 --> T23

    T19 --> T24
    T22 --> T24

    T22 --> T25
```

---

## 4. クリティカルパス（ハイライト）

```mermaid
flowchart TD
    T1["T1 (1h)"]:::critical --> T3["T3 (3h)"]:::critical
    T3 --> T11["T11 (2h)"]:::critical
    T11 --> T12["T12 (4h)"]:::critical
    T12 --> T14["T14 (3h)"]:::critical
    T14 --> T15["T15 (4h)"]:::critical
    T15 --> T16["T16 (3h)"]:::critical
    T16 --> T17["T17 (3h)"]:::critical
    T17 --> T18["T18 (3h)"]:::critical
    T18 --> T19["T19 (2h)"]:::critical
    T19 --> T22["T22 (3h)"]:::critical
    T22 --> T24["T24 (3h)"]:::critical

    classDef critical fill:#ff6b6b,stroke:#333,color:#fff
```

**クリティカルパス合計: 34h**

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
