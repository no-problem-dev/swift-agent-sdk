---
title: "Swift Agent SDK - テスト戦略"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan, test-strategy]
references:
  - ./00_index.md
  - ../03_design_spec/11_nfr_realization.md
  - ../03_design_spec/08_api_spec.md
---

# テスト戦略

## Intent（意図）

SDK の品質保証戦略を定義する。
テスト種別ごとの目的・実行条件・配置を明確にし、
各 Phase/Wave でのテスト実施タイミングを示す。

---

## 1. テスト種別

### 1.1 Unit Tests（TDD: 各 Wave に同梱）

| 項目 | 内容 |
|------|------|
| **目的** | 各コンポーネントの単体動作を検証 |
| **実行条件** | `swift test`（CLI 不要、Node.js 不要） |
| **配置** | `Tests/AgentSDKTests/`, `Tests/AgentSDKClaudeCodeTests/` |
| **実施タイミング** | 各 Wave で実装と同時（TDD） |

**テスト対象と配置:**

| テストターゲット | テスト対象 | 依存 |
|----------------|-----------|------|
| `AgentSDKTests` | AgentMessage, ContentBlock, JSONValue, QueryOptions, SessionOptions, AgentSDKError | `AgentSDK`, `AgentSDKTesting` |
| `AgentSDKClaudeCodeTests` | JSONLCodec, CLILocator, CLIArgBuilder, CLIProcess, Handshake, MessageRouter, ClaudeCodeClient, ClaudeCodeTransport | `AgentSDKClaudeCode`, `AgentSDKTesting` |

### 1.2 Integration Tests（関連機能完了後）

| 項目 | 内容 |
|------|------|
| **目的** | 実際の CLI とのエンドツーエンド通信を検証 |
| **実行条件** | Node.js 18+ + Claude Code CLI インストール済 + サブスクリプション認証済（`claude login` 完了）+ `AGENT_SDK_INTEGRATION_TEST=1` |
| **配置** | `Tests/IntegrationTests/` |
| **実施タイミング** | Phase 4 Wave 4-2 |

**統合テストケース:**

| テストケース | 検証内容 | 前提条件 |
|------------|---------|---------|
| Hello World | `AgentSDK.query(prompt: "Say hello")` → 応答受信 | CLI + 認証済セッション |
| Session Lifecycle | createSession → send → send → close | CLI + 認証済セッション |
| Session Resume | createSession → close → resumeSession → send | CLI + 認証済セッション |
| Permission Handler | canUseTool ハンドラが呼ばれる | CLI + 認証済セッション |
| Error: CLI Not Found | CLI パスが不正 → `cliNotFound` | CLI 不要 |
| Error: Runtime Not Found | runtime が不正 → `runtimeNotFound` | CLI 不要 |

### 1.3 Mock-based Client Tests（MockTransport 使用）

| 項目 | 内容 |
|------|------|
| **目的** | CLI なしで Client/Session の振る舞いを検証 |
| **実行条件** | `swift test`（CLI 不要） |
| **配置** | `Tests/AgentSDKClaudeCodeTests/` |
| **実施タイミング** | Phase 4 Wave 4-2（MockTransport 完成後） |

**MockTransport テストケース:**

| テストケース | MockTransport 設定 | 検証内容 |
|------------|-------------------|---------|
| query 成功 | `simpleSuccess(text:)` | stream → system → assistant → result |
| query with tool use | `withToolUse(toolName:result:)` | stream に toolUse, toolResult 含む |
| session send | 複数 response batch | send() 後に messages を受信 |
| canUseTool allow | control_request を含む | ハンドラが呼ばれ、allow が返る |
| canUseTool deny | control_request を含む | ハンドラが呼ばれ、deny が返る |
| notConnected error | `simulatedIsReady = false` | write() で notConnected throw |

---

## 2. テストの Phase/Wave 配置

```
Phase 1: 基盤構築
├── Wave 1-2: [Unit] AgentMessage, ContentBlock, JSONValue の Codable テスト
└── Wave 1-3: [Unit] QueryOptions, AgentSDKError テスト

Phase 2: CLI 具象
├── Wave 2-1: [Unit] JSONLCodec, CLILocator, CLIArgBuilder テスト
├── Wave 2-2: [Unit] CLIProcess テスト（モックプロセス使用）
└── Wave 2-3: [Unit] CLIMessage/SDKMessage デコード、Handshake テスト

Phase 3: クライアント
├── Wave 3-1: [Unit] MessageRouter テスト
├── Wave 3-2: [Unit] ClaudeCodeTransport, ClaudeCodeClient テスト
└── Wave 3-3: [Unit] ClaudeCodeSession テスト

Phase 4: テスト・統合
├── Wave 4-1: MockTransport, MockFixtures 実装
├── Wave 4-2: [Mock] Client/Session テスト + [Integration] E2E テスト
└── Wave 4-3: ドキュメント・CI
```

---

## 3. テスト戦略の方針

### 3.1 Protocol 層のテスト方針

- **Codable round-trip:** 全 Codable 型で `encode → decode → 元の値と一致` を検証
- **パターンマッチング:** AgentMessage の全 case を switch で網羅するテスト
- **デフォルト値:** QueryOptions, SessionOptions のデフォルト初期化子で全プロパティが nil
- **エラーメッセージ品質:** AgentSDKError の全 case で `localizedDescription` が非空

### 3.2 具象層のテスト方針

- **JSONLCodec:** 実際の CLI メッセージ JSON を固定テストデータとして使用
- **CLILocator:** ファイルシステムのモック（テンポラリディレクトリに CLI ファイルを配置）
- **CLIProcess:** 軽量な子プロセス（`echo`, `cat` 等）でプロセス管理をテスト
- **Handshake:** JSONLCodec + モック stdout ストリームでフロー検証
- **MessageRouter:** 直接メッセージを注入して分類・ルーティングを検証

### 3.3 統合テスト方針（D-16: テスト駆動プロトコル検証）

- 実 CLI との通信で JSONL プロトコルの正確性を検証
- CI では Node.js + CLI をインストールして実行
- ローカルでは `AGENT_SDK_INTEGRATION_TEST=1` で手動実行
- 統合テストは `swift test --filter IntegrationTests` でのみ実行

### 3.4 テストデータ管理

| データ種別 | 管理方法 |
|-----------|---------|
| JSONL メッセージ固定値 | テストファイル内にリテラル文字列として定義 |
| MockTransport 応答 | MockFixtures ファクトリメソッドで生成 |
| CLI パス | テンポラリディレクトリ + `FileManager` |

---

## 4. NFR 検証

| NFR | 検証方法 | テスト種別 |
|-----|---------|-----------|
| NFR-001 パフォーマンス | SDK オーバーヘッド計測（query 前後の時間差） | Integration |
| NFR-002 信頼性 | プロセスクラッシュ検知、リソースリーク検出 | Unit + Integration |
| NFR-003 互換性 | macOS + Swift 6 での全テストパス | CI |
| NFR-004 保守性 | テストカバレッジ 80%+（Xcode coverage report） | CI |
| NFR-005 セキュリティ | SDK が認証情報を保持しないことの検証（ログ・エラーに含まれない） | Unit |
| NFR-006 ユーザビリティ | Hello World 7 行以内で動作 | Integration |
| NFR-007 テスタビリティ | MockTransport 12 行以内で作成 | Unit |

---

## 5. CI テスト構成

### 5.1 `test.yml`（全 PR で実行）

```yaml
# 概要
- swift build（全ターゲット）
- swift test --filter AgentSDKTests
- swift test --filter AgentSDKClaudeCodeTests
- coverage report
```

### 5.2 `integration.yml`（手動 / 週次）

```yaml
# 概要
- Node.js 18 セットアップ
- npm install -g @anthropic-ai/claude-agent-sdk
- claude login（サブスクリプション認証。CI ではトークンキャッシュを利用）
- AGENT_SDK_INTEGRATION_TEST=1 swift test --filter IntegrationTests
```

**認証方式:** サブスクリプション（Claude Pro/Max/Team）の OAuth 認証を前提とする。
API Key 認証は想定しない。CI 環境では事前に `claude login` 済みの認証トークンをシークレット経由でキャッシュに注入する。

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
