# Swift Agent SDK

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI を Swift からプログラム的に操作するための SDK です。型安全な async/await API で、ワンショットクエリとマルチターンセッションの両方に対応しています。

## クイックスタート

```swift
import AgentSDKClaudeCode

for try await message in AgentSDK.query(prompt: "Hello, Claude!") {
    switch message {
    case .assistant(let info):
        for block in info.content {
            if case .text(let text) = block { print(text) }
        }
    case .result(let result): print("Cost: $\(result.costUsd)")
    default: break
    }
}
```

## 前提条件

- **macOS 15+** / Swift 6.0+
- **Node.js 18+**（`node` が PATH に存在すること）
- **Claude Code CLI**：`npm install -g @anthropic-ai/claude-agent-sdk`
- **サブスクリプション認証**：事前に `claude login` で認証を完了してください（API Key は使用しません）

## インストール

`Package.swift` に依存を追加します：

```swift
dependencies: [
    .package(url: "https://github.com/no-problem-dev/swift-agent-sdk.git", from: "0.1.0")
]
```

ターゲットに追加：

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "AgentSDKClaudeCode", package: "swift-agent-sdk"),
    ]
)
```

テスト用ユーティリティを使う場合は、テストターゲットにも追加します：

```swift
.testTarget(
    name: "YourAppTests",
    dependencies: [
        .product(name: "AgentSDKTesting", package: "swift-agent-sdk"),
    ]
)
```

## 使い方

### ワンショットクエリ

1 回きりの質問を投げて、ストリーミングで応答を受け取ります。

```swift
import AgentSDKClaudeCode

let options = QueryOptions(
    model: .sonnet,
    systemPrompt: "あなたは Swift のエキスパートです。",
    permissionMode: .bypassPermissions,
    maxTurns: 3
)

for try await message in AgentSDK.query(prompt: "async/await の仕組みを教えて", options: options) {
    switch message {
    case .system(let info):
        print("セッション: \(info.sessionId), モデル: \(info.model)")
    case .assistant(let info):
        for block in info.content {
            if case .text(let text) = block {
                print(text)
            }
        }
    case .result(let info):
        print("トークン: \(info.inputTokens) 入力 / \(info.outputTokens) 出力")
        print("コスト: $\(info.costUsd)")
    default:
        break
    }
}
```

### マルチターンセッション

セッションを作成して、会話のコンテキストを維持したまま複数回やり取りできます。

```swift
import AgentSDKClaudeCode

let session = try await AgentSDK.createSession(
    options: SessionOptions(permissionMode: .bypassPermissions)
)

// 1 ターン目
for try await msg in session.send("フランスの首都は？") {
    if case .assistant(let info) = msg {
        for block in info.content {
            if case .text(let text) = block { print(text) }
        }
    }
}

// 2 ターン目（コンテキストが引き継がれる）
for try await msg in session.send("ドイツは？") {
    if case .assistant(let info) = msg {
        for block in info.content {
            if case .text(let text) = block { print(text) }
        }
    }
}

try await session.close()
```

### セッション再開

セッション ID を保存しておけば、後から会話を再開できます。

```swift
// セッション ID を保存
let session = try await AgentSDK.createSession()
let sessionId = await session.id
try await session.close()

// 後から再開
let resumed = try await AgentSDK.resumeSession(id: sessionId)
for try await msg in resumed.send("さっきの続きから") {
    // ...
}
try await resumed.close()
```

### 権限ハンドリング

ツール実行時に許可・拒否を制御できます。

```swift
let options = QueryOptions(
    canUseTool: { toolName, input, metadata in
        if toolName == "Write" {
            return .deny(reason: "ファイル書き込みは許可されていません")
        }
        return .allow
    }
)

for try await msg in AgentSDK.query(prompt: "ファイルを作成して", options: options) {
    // Write ツールは拒否される
}
```

### ランタイム制御（セッション内）

セッション中にモデル変更やインタラプトなどの制御が可能です。

```swift
let session = try await AgentSDK.createSession()

// セッション中にモデルを変更
try await session.setModel(.opus)

// 権限モードを変更
try await session.setPermissionMode(.acceptEdits)

// 処理を中断
try await session.interrupt()

// 利用可能なモデルとコマンドを取得
let models = try await session.supportedModels()
let commands = try await session.supportedCommands()

try await session.close()
```

## カスタマイズ（依存性注入）

SDK はプロトコルベースのアーキテクチャを採用しており、Transport を差し替えることで柔軟にカスタマイズできます。

```swift
import AgentSDK
import AgentSDKClaudeCode

// カスタム設定の Transport を使う
let transport = ClaudeCodeTransport(
    cliPath: "/custom/path/to/claude",
    runtime: .bun,
    additionalEnvironment: ["ANTHROPIC_MODEL": "claude-sonnet-4-5-20250929"]
)
let client = ClaudeCodeClient(transport: transport)

for try await msg in client.query(prompt: "こんにちは") {
    // ...
}
```

### MockTransport を使ったテスト

CLI を起動せずに Client/Session の振る舞いをテストできます。

```swift
import AgentSDKTesting

// モックレスポンスを設定
let mock = MockTransport(responses: MockFixtures.simpleSuccess(text: "テスト応答"))
let client = ClaudeCodeClient(transport: mock)

for try await msg in client.query(prompt: "テスト") {
    switch msg {
    case .assistant(let info):
        // モックされた応答を検証
        break
    case .result(let info):
        assert(info.costUsd == 0.01)
    default:
        break
    }
}

// 送信されたメッセージを検証
assert(!mock.sentMessages.isEmpty)
```

## アーキテクチャ

SDK は 3 つのモジュールで構成されています：

```
AgentSDK              プロトコル層（AgentTransport, AgentClient, AgentSession）
AgentSDKClaudeCode    Claude Code CLI の具象実装
AgentSDKTesting       テスト用 MockTransport & フィクスチャ
```

| プロトコル | 具象実装 | 役割 |
|-----------|---------|------|
| `AgentTransport` | `ClaudeCodeTransport` | CLI サブプロセスの管理 |
| `AgentClient` | `ClaudeCodeClient<T>` | クエリ・セッションのオーケストレーション |
| `AgentSession` | `ClaudeCodeSession` | マルチターン会話の状態管理 |

## API リファレンス

### AgentSDK（コンビニエンス API）

| メソッド | 説明 |
|---------|------|
| `AgentSDK.query(prompt:options:)` | ワンショットクエリ。`AsyncThrowingStream<AgentMessage, Error>` を返す |
| `AgentSDK.createSession(options:)` | 新規マルチターンセッションを作成 |
| `AgentSDK.resumeSession(id:options:)` | 既存セッションを再開 |

### AgentMessage

| ケース | 型 | 説明 |
|-------|------|------|
| `.system` | `SystemInfo` | セッション ID、利用可能ツール、モデル情報 |
| `.assistant` | `AssistantInfo` | コンテンツブロック（テキスト、ツール使用、ツール結果） |
| `.partial` | `PartialInfo` | ストリーミング中の部分応答 |
| `.result` | `ResultInfo` | 最終結果（コスト、トークン数、所要時間） |

### QueryOptions / SessionOptions

| プロパティ | 型 | 説明 |
|-----------|------|------|
| `model` | `ModelSelection?` | `.opus`, `.sonnet`, `.haiku`, `.custom(String)` |
| `systemPrompt` | `String?` | システムプロンプト |
| `permissionMode` | `PermissionMode?` | `.default`, `.acceptEdits`, `.bypassPermissions`, `.plan` |
| `canUseTool` | クロージャ? | ツール実行の許可・拒否ハンドラ |
| `maxTurns` | `Int?` | 最大会話ターン数 |
| `maxBudgetUsd` | `Double?` | 予算上限（USD） |
| `allowedTools` | `[String]?` | 許可するツールのリスト |
| `disallowedTools` | `[String]?` | 禁止するツールのリスト |

## バージョン互換性

| Swift Agent SDK | Claude Code CLI | Swift | macOS | Node.js |
|----------------|----------------|-------|-------|---------|
| 0.1.x | 最新版 | 6.0+ | 15+ | 18+ |

## ライセンス

詳細は [LICENSE](LICENSE) を参照してください。
