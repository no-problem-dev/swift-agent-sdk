---
title: "Swift Agent SDK - メッセージフロー設計"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, message-flow]
references:
  - ./00_index.md
  - ./04_component_architecture.md
  - ../02_requirements/01_feature_overview.md
  - ../02_requirements/05_io_spec.md
---

# メッセージフロー設計

## Intent（意図）

本 SDK には画面遷移は存在しない（ライブラリ SDK のため）。
代わりに、各 Feature Flow（FF）のメッセージフローを設計する。
利用者と CLI の間を流れるメッセージの順序・種別・条件を明確にする。

---

## 1. メッセージフロー Overview

```mermaid
flowchart LR
    FF001["FF-001\nCLI プロセス管理"]
    FF002["FF-002\nJSONL トランスポート"]
    FF003["FF-003\n初期化ハンドシェイク"]
    FF004["FF-004\nワンショットクエリ"]
    FF005["FF-005\nセッション管理"]
    FF006["FF-006\n権限ハンドリング"]
    FF007["FF-007\nサブエージェント"]
    FF009["FF-009\nランタイム制御"]

    FF001 -->|"プロセス起動"| FF003
    FF003 -->|"初期化完了"| FF004
    FF003 -->|"初期化完了"| FF005
    FF004 -->|"クエリ中"| FF006
    FF005 -->|"セッション中"| FF006
    FF004 -->|"クエリ中"| FF007
    FF005 -->|"セッション中"| FF009
    FF002 -.->|"通信基盤"| FF003
    FF002 -.->|"通信基盤"| FF004
    FF002 -.->|"通信基盤"| FF005
```

---

## 2. FF-004: ワンショットクエリフロー

### 2.1 正常系: テキスト応答

```mermaid
sequenceDiagram
    participant App
    participant SDK as ClaudeCodeClient
    participant CLI as Claude Code CLI

    App->>SDK: query(prompt: "Hello", options)

    Note over SDK,CLI: connect() + handshake (FF-003)

    SDK->>CLI: UserMessage {"type":"user_message","content":"Hello"}

    CLI-->>SDK: PartialAssistantMessage (streaming text)
    SDK-->>App: yield .partial(...)

    CLI-->>SDK: AssistantMessage (complete)
    SDK-->>App: yield .assistant(...)

    CLI-->>SDK: ResultMessage {cost, duration, tokens}
    SDK-->>App: yield .result(...)
    Note over App: AsyncSequence completes
```

### 2.2 正常系: ツール使用を含む応答

```mermaid
sequenceDiagram
    participant App
    participant SDK as ClaudeCodeClient
    participant CLI as Claude Code CLI

    App->>SDK: query(prompt: "Read file.txt")
    SDK->>CLI: UserMessage

    CLI-->>SDK: AssistantMessage [toolUse: Read(file.txt)]
    SDK-->>App: yield .assistant(toolUse)

    Note over CLI: CLI がツール実行

    CLI-->>SDK: AssistantMessage [toolResult + text]
    SDK-->>App: yield .assistant(toolResult + text)

    CLI-->>SDK: ResultMessage
    SDK-->>App: yield .result(...)
```

---

## 3. FF-005: セッション管理フロー

### 3.1 セッションライフサイクル

```mermaid
stateDiagram-v2
    [*] --> Creating: createSession()
    Creating --> Active: handshake complete
    Creating --> Failed: error

    Active --> Sending: send(message)
    Sending --> Active: response complete
    Sending --> Interrupted: interrupt()
    Interrupted --> Active: ready for next message

    Active --> Resuming: close() then resumeSession()
    Resuming --> Active: handshake with --resume
    Resuming --> Expired: session expired

    Active --> Closed: close()
    Closed --> [*]
    Failed --> [*]
    Expired --> [*]
```

### 3.2 セッション内の複数メッセージ交換

```mermaid
sequenceDiagram
    participant App
    participant Session as ClaudeCodeSession
    participant CLI as Claude Code CLI

    App->>Session: send("最初の質問")
    Session->>CLI: UserMessage #1
    CLI-->>Session: AssistantMessage #1
    Session-->>App: yield messages
    CLI-->>Session: ResultMessage #1
    Session-->>App: yield result, iteration complete

    Note over Session,CLI: CLI プロセスは生存中

    App->>Session: send("それについて詳しく")
    Session->>CLI: UserMessage #2 (no cold start)
    CLI-->>Session: AssistantMessage #2 (context preserved)
    Session-->>App: yield messages
    CLI-->>Session: ResultMessage #2
    Session-->>App: yield result, iteration complete

    App->>Session: close()
    Session->>CLI: terminate process
```

---

## 4. FF-006: 権限ハンドリングフロー

### 4.1 カスタム権限ハンドラの介入

```mermaid
sequenceDiagram
    participant App
    participant SDK as ClaudeCodeClient
    participant Router as MessageRouter
    participant Handler as canUseTool
    participant CLI as Claude Code CLI

    App->>SDK: query(prompt: "Delete old files", options: .init(canUseTool: handler))
    SDK->>CLI: UserMessage

    CLI-->>Router: ControlRequest: can_use_tool(Bash, "rm -rf ...")
    Router->>Handler: canUseTool("Bash", input)
    Handler-->>Router: .deny(reason: "Destructive operations blocked")
    Router->>CLI: ControlResponse: deny

    CLI-->>Router: AssistantMessage (alternative approach)
    Router-->>App: yield .assistant(...)

    CLI-->>Router: ControlRequest: can_use_tool(Read, "ls ...")
    Router->>Handler: canUseTool("Read", input)
    Handler-->>Router: .allow
    Router->>CLI: ControlResponse: allow

    CLI-->>Router: AssistantMessage (Read result)
    Router-->>App: yield .assistant(...)

    CLI-->>Router: ResultMessage
    Router-->>App: yield .result(...)
```

---

## 5. FF-007: サブエージェントフロー

### 5.1 サブエージェントのメッセージフロー

```mermaid
sequenceDiagram
    participant App
    participant SDK as ClaudeCodeClient
    participant CLI as Claude Code CLI

    App->>SDK: query(prompt: "Review code", options: .init(agents: ["reviewer": ...]))
    SDK->>CLI: UserMessage + agents config

    CLI-->>SDK: AssistantMessage (main: "Delegating to reviewer...")
    SDK-->>App: yield .assistant(parentToolUseId: nil)

    Note over CLI: CLI internally spawns sub-agent

    CLI-->>SDK: AssistantMessage (sub-agent response, parentToolUseId: "tool_abc")
    SDK-->>App: yield .assistant(parentToolUseId: "tool_abc")

    CLI-->>SDK: AssistantMessage (main: "Based on the review...")
    SDK-->>App: yield .assistant(parentToolUseId: nil)

    CLI-->>SDK: ResultMessage
    SDK-->>App: yield .result(...)
```

---

## 6. FF-010: エラーハンドリングフロー

### 6.1 プロセス異常終了

```mermaid
sequenceDiagram
    participant App
    participant SDK as ClaudeCodeClient
    participant CLI as Claude Code CLI

    App->>SDK: query(prompt: "...")
    SDK->>CLI: UserMessage

    CLI-->>SDK: AssistantMessage (partial)
    SDK-->>App: yield .assistant(...)

    Note over CLI: CLI crashes unexpectedly

    CLI-->>SDK: process exit(1), stderr: "Error: ..."
    SDK-->>App: throw AgentSDKError.processExited(exitCode: 1, stderr: "...")

    Note over App: AsyncSequence terminates with error
```

### 6.2 キャンセレーション

```mermaid
sequenceDiagram
    participant App
    participant Task as Swift Task
    participant SDK as ClaudeCodeClient
    participant CLI as Claude Code CLI

    App->>Task: Task { for try await msg in query(...) }
    SDK->>CLI: UserMessage

    CLI-->>SDK: AssistantMessage (streaming)
    SDK-->>App: yield messages

    App->>Task: task.cancel()
    Task->>SDK: CancellationError propagated
    SDK->>CLI: terminate process
    SDK-->>App: throw CancellationError
```

---

## Rationale（根拠）

### メッセージフロー図を FF 単位で分割

**決定:** 各 FF につき独立したシーケンス図を作成

**採用理由:**
- 1 つの図にすべてのフローを含めるとノード数が 50 を超える
- FF 単位の分割により、各フローの詳細が読みやすい
- spec-writing ルールの FF 単位分割に準拠

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成（画面遷移図枠をメッセージフロー設計に読み替え） | Claude Code |
