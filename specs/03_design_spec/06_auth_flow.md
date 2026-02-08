---
title: "Swift Agent SDK - 初期化・ハンドシェイクフロー"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, handshake, initialization]
references:
  - ./00_index.md
  - ./04_component_architecture.md
  - ../02_requirements/05_io_spec.md
  - ../02_requirements/03_functional_requirements.md
---

# 初期化・ハンドシェイクフロー

## Intent（意図）

本 SDK には認証フロー（ログイン等）は存在しない（認証は CLI が環境変数で行う）。
代わりに、CLI プロセスとの初期化ハンドシェイクフローを設計する。
このフローは SDK の最も重要なシーケンスであり、正確な実装が全機能の基盤となる。

---

## 1. ハンドシェイクフロー（FF-003）

### 1.1 正常系: 初回接続

```mermaid
sequenceDiagram
    participant App as Swift App
    participant Transport as ClaudeCodeTransport
    participant Process as CLIProcess
    participant CLI as Claude Code CLI

    App->>Transport: connect()
    Transport->>Transport: CLILocator.locate()
    Transport->>Process: start(node, cli.js, args)
    Process->>CLI: fork/exec

    Note over Transport,CLI: Phase 1: initialize_ready 待機（60秒タイムアウト）

    CLI-->>Process: stdout: {"type":"initialize_ready"}
    Process-->>Transport: Data line

    Note over Transport,CLI: Phase 2: InitializeRequest 送信

    Transport->>Process: stdin: {"type":"control_request","request":{"subtype":"initialize",...}}
    Process->>CLI: JSONL line

    Note over Transport,CLI: Phase 3: SystemMessage 受信

    CLI-->>Process: stdout: {"type":"system","session_id":"...","tools":[...]}
    Process-->>Transport: Data line
    Transport-->>App: connect() returns (ready)
```

### 1.2 異常系: タイムアウト

```mermaid
sequenceDiagram
    participant App as Swift App
    participant Transport as ClaudeCodeTransport
    participant Process as CLIProcess
    participant CLI as Claude Code CLI

    App->>Transport: connect()
    Transport->>Process: start(node, cli.js, args)
    Process->>CLI: fork/exec

    Note over Transport,CLI: 60秒経過...

    Transport->>Transport: タイムアウト検知
    Transport->>Process: terminate()
    Process->>CLI: SIGTERM
    Transport-->>App: throw AgentSDKError.initializationTimeout(seconds: 60)
```

### 1.3 異常系: プロセス起動失敗

```mermaid
sequenceDiagram
    participant App as Swift App
    participant Transport as ClaudeCodeTransport
    participant Locator as CLILocator

    App->>Transport: connect()
    Transport->>Locator: locate()
    Locator-->>Transport: throw AgentSDKError.cliNotFound(searchedPaths: [...])
    Transport-->>App: throw AgentSDKError.cliNotFound(...)
```

---

## 2. セッション再開フロー（FF-005: FR-020）

### 2.1 正常系: セッション再開

```mermaid
sequenceDiagram
    participant App as Swift App
    participant Client as ClaudeCodeClient
    participant Transport as ClaudeCodeTransport
    participant CLI as Claude Code CLI

    App->>Client: resumeSession(id: "prev-session-id", options)
    Client->>Transport: connect() with --resume flag
    Transport->>CLI: start with ["--resume", "prev-session-id"]

    CLI-->>Transport: {"type":"initialize_ready"}
    Transport->>CLI: InitializeRequest
    CLI-->>Transport: SystemMessage (session_id: "prev-session-id")
    Transport-->>Client: connected
    Client-->>App: ClaudeCodeSession (resumed)

    App->>App: session.send("続きの質問")
```

### 2.2 異常系: セッション期限切れ

```mermaid
sequenceDiagram
    participant App as Swift App
    participant Client as ClaudeCodeClient
    participant Transport as ClaudeCodeTransport
    participant CLI as Claude Code CLI

    App->>Client: resumeSession(id: "expired-id", options)
    Client->>Transport: connect() with --resume flag
    Transport->>CLI: start with ["--resume", "expired-id"]

    CLI-->>Transport: エラーメッセージ（session not found）
    CLI-->>Transport: process exit (non-zero)
    Transport-->>Client: throw AgentSDKError.sessionExpired
    Client-->>App: throw AgentSDKError.sessionExpired(sessionId: "expired-id")
```

---

## 3. CLI 探索フロー（FF-001: FR-001）

### 3.1 探索順序の詳細

```mermaid
flowchart TD
    Start["CLILocator.locate()"] --> Check1{"1. ユーザー指定パス?"}
    Check1 -->|"あり"| Verify1["パス存在・実行権限チェック"]
    Check1 -->|"なし"| Check2

    Verify1 -->|"OK"| Found["return URL"]
    Verify1 -->|"NG"| Error1["throw cliNotFound"]

    Check2{"2. ENV: CLAUDE_CODE_CLI_PATH?"} -->|"あり"| Verify2["パス存在チェック"]
    Check2 -->|"なし"| Check3

    Verify2 -->|"OK"| Found
    Verify2 -->|"NG"| Check3

    Check3{"3. ./node_modules/.../ cli.js?"} -->|"あり"| Verify3["ファイル存在チェック"]
    Check3 -->|"なし"| Check4

    Verify3 -->|"OK"| Found
    Verify3 -->|"NG"| Check4

    Check4{"4. グローバル npm パッケージ?"} -->|"あり"| Verify4["npm root -g + パスチェック"]
    Check4 -->|"なし"| Check5

    Verify4 -->|"OK"| Found
    Verify4 -->|"NG"| Check5

    Check5{"5. which claude?"} -->|"あり"| Found
    Check5 -->|"なし"| NotFound["throw AgentSDKError.cliNotFound\n(searchedPaths: [...])"]
```

---

## 4. InitializeRequest の構造

```swift
// SDK → CLI: 初期化リクエスト
{
    "type": "control_request",
    "request_id": "req_1_abc123",
    "request": {
        "subtype": "initialize",
        "supported_capabilities": ["mcp"],
        "hooks": []  // D-11: hooks は後回し
    }
}
```

---

## Rationale（根拠）

### ハンドシェイクを Transport 内部に隠蔽

**決定:** `connect()` メソッド内でハンドシェイク全体を実行し、完了後に返る

**採用理由:**
- 利用者がハンドシェイクの詳細を知る必要がない
- Protocol 層（AgentTransport）は「接続」という抽象のみを公開
- テスト時は MockTransport が即座に connected 状態を返す

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成（認証フロー枠を初期化・ハンドシェイクフローに読み替え） | Claude Code |
