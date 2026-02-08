---
title: "Swift Agent SDK - I/O 仕様"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, io]
references:
  - ./03_functional_requirements.md
  - ../01_request/spec_01_swift_agent_sdk.md
---

# I/O 仕様

## 1. SDK → CLI（stdin 送信）

### 1.1 ユーザーメッセージ

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `type` | string | Yes | `"user_message"` |
| `content` | string | Yes | プロンプト文字列 |

### 1.2 制御リクエスト

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `type` | string | Yes | `"control_request"` |
| `request_id` | string | Yes | `"req_{counter}_{hex}"` 形式 |
| `request` | object | Yes | サブタイプ固有のペイロード |
| `request.subtype` | string | Yes | 制御リクエスト種別 |

**サブタイプ別ペイロード:**

| サブタイプ | 追加フィールド |
|-----------|---------------|
| `initialize` | `hooks`, `supported_capabilities` |
| `interrupt` | なし |
| `set_permission_mode` | `permission_mode` |
| `set_model` | `model` |
| `rewind_files` | `user_message_uuid` |
| `get_account_info` | なし |
| `get_models` | なし |
| `get_commands` | なし |
| `get_mcp_server_status` | なし |
| `set_mcp_servers` | `mcp_servers` |

### 1.3 制御レスポンス（権限応答等）

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `type` | string | Yes | `"control_response"` |
| `response` | object | Yes | 応答ペイロード |
| `response.subtype` | string | Yes | `"success"` or `"error"` |
| `response.request_id` | string | Yes | 対応するリクエスト ID |
| `response.response` | object | Yes | サブタイプ固有の応答 |

---

## 2. CLI → SDK（stdout 受信）

### 2.1 initialize_ready

```json
{"type": "initialize_ready"}
```

### 2.2 SystemMessage

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `type` | string | `"system"` |
| `session_id` | string | セッション識別子 |
| `tools` | [object] | 利用可能ツール一覧 |
| `model` | string | 使用モデル ID |
| `mcp_servers` | [object] | MCP サーバー情報 |

### 2.3 AssistantMessage

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `type` | string | `"assistant"` |
| `message` | object | Claude API Message 形式 |
| `message.content` | [ContentBlock] | テキスト/ツール使用ブロック |
| `parent_tool_use_id` | string? | サブエージェント時のみ |

### 2.4 PartialAssistantMessage

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `type` | string | `"assistant"` |
| `subtype` | string | `"partial"` |
| `message` | object | 途中段階のメッセージ |

### 2.5 ResultMessage

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `type` | string | `"result"` |
| `result` | string | 最終テキスト結果 |
| `cost_usd` | number | 累計コスト（USD） |
| `duration_ms` | number | 処理時間（ミリ秒） |
| `input_tokens` | number | 入力トークン数 |
| `output_tokens` | number | 出力トークン数 |
| `session_id` | string | セッション ID |
| `num_turns` | number | ターン数 |

### 2.6 制御リクエスト（CLI → SDK）

主に権限確認で使用:

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `type` | string | `"control_request"` |
| `request_id` | string | リクエスト ID |
| `request.subtype` | string | `"can_use_tool"` |
| `request.tool_name` | string | ツール名 |
| `request.tool_input` | object | ツール入力パラメータ |

### 2.7 制御レスポンス（SDK リクエストへの応答）

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `type` | string | `"control_response"` |
| `response.subtype` | string | `"success"` or `"error"` |
| `response.request_id` | string | 対応するリクエスト ID |
| `response.response` | object | サブタイプ固有の応答データ |

---

## 3. SDK 公開メッセージ型（利用者が受け取る）

| メッセージ種別 | 含まれる情報 | 配信タイミング |
|--------------|-------------|---------------|
| system | session_id, tools, model | ストリーム先頭 |
| assistant | content blocks (text, tool_use, tool_result) | 応答中 |
| partial | 部分コンテンツ | ストリーミング中（逐次） |
| result | cost, duration, tokens, final text | ストリーム末尾 |

---

## 4. CLI 起動引数

| 引数 | 値 | 必須 |
|------|-----|------|
| `--output-format` | `stream-json` | Yes |
| `--input-format` | `stream-json` | Yes |
| `--verbose` | - | Yes |
| `--system-prompt` | プロンプト文字列 | No |
| `--permission-mode` | `default`/`acceptEdits`/`bypassPermissions`/`plan` | No |
| `--setting-sources` | JSON 文字列 | No |
| `--resume` | session_id | No（再開時） |
| `--max-turns` | 数値 | No |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
