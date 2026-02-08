---
title: "ClaudeAgent - Phase 4: Presentation パッケージ実装"
created: 2026-02-08
status: draft
tags: [implementation-plan, phase4, presentation, claude-agent]
references:
  - ./00_index.md
  - ./01_phase_overview.md
  - ../03_design_spec/03_layer_architecture.md#Presentation
  - ../03_design_spec/04_component_architecture.md#Presentation-コンポーネント詳細
  - ../03_design_spec/09_screen_flow.md
---

# Phase 4: Presentation パッケージ実装

## 目的

SwiftUI View と Store（ViewModel）を実装する。
Domain プロトコルへの依存のみで、no-problem UI パッケージを活用した画面を構築する。

## 前提

- Phase 2 完了（Domain の型・プロトコルが確定済み）
- Phase 3 と**並列実行可能**（Infrastructure を import しないため）

---

## Wave 4-1: AppState + SessionState 骨格

### 実装内容

#### Stores/AppState.swift

`specs/03_design_spec/04_component_architecture.md#AppState` に準拠する。

```swift
@MainActor @Observable
final class AppState {
    private(set) var sessions: [SessionState] = []
    var activeSessionId: String?

    var activeSession: SessionState? { ... }
    var sortedSessions: [SessionState] { ... }

    private let agentService: any AgentServiceProtocol
    private let sessionStore: any SessionStoreProtocol

    init(agentService: any AgentServiceProtocol, sessionStore: any SessionStoreProtocol) { ... }

    // Actions（骨格のみ、ロジックは Wave 4-5 で実装）
    func createSession(config: SessionConfig) async throws { ... }
    func deleteSession(id: String) { ... }
    func loadSavedSessions() { ... }
    func saveAllSessions() { ... }
}
```

#### Stores/SessionState.swift

`specs/03_design_spec/04_component_architecture.md#SessionState` に準拠する。

```swift
@MainActor @Observable
final class SessionState: Identifiable {
    let id: String
    let config: SessionConfig
    let createdAt: Date

    private(set) var messages: [ChatMessage] = []
    private(set) var status: SessionStatus = .disconnected
    private(set) var streamingText: String = ""
    private(set) var isProcessing: Bool = false
    private(set) var totalCostUsd: Double = 0
    private(set) var lastTokenUsage: TokenUsage?
    var lastActiveAt: Date

    var displayName: String { ... }

    private let agentService: any AgentServiceProtocol
    private var streamTask: Task<Void, Never>?

    // Actions（骨格のみ）
    func send(_ message: String) async { ... }
    func interrupt() async { ... }
    func reconnect() async throws { ... }
    func disconnect() async { ... }
    func setModel(_ model: ModelSelection) async throws { ... }
}
```

### 完了基準

- [ ] AppState, SessionState がコンパイル成功
- [ ] Domain プロトコルへの依存のみ（Infrastructure を import していない）
- [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-2: 基本 View（ContentView, SessionSidebar, InputArea）

### 実装内容（並列実行可能）

#### Views/ContentView.swift

`specs/03_design_spec/09_screen_flow.md#画面構成` に準拠したルートビュー。

- NavigationSplitView（swift-ui-routing の SplitViewPresenter を使用）
- サイドバー: SessionSidebar
- ディテール: ChatView or EmptySessionView
- ツールバー: モデル選択・コスト表示
- ThemeProvider（swift-design-system）でアプリ全体をラップ

```swift
struct ContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        NavigationSplitView {
            SessionSidebar(appState: appState)
        } detail: {
            if let session = appState.activeSession {
                ChatView(session: session)
            } else {
                EmptySessionView()
            }
        }
        .toolbar { ... }
    }
}
```

#### Views/Sidebar/SessionSidebar.swift

- セッション一覧を `List` + `ForEach` で表示
- `appState.sortedSessions` をデータソースとする
- 各行は `SessionRow` コンポーネント
- `+` ボタンで NewSessionSheet を表示
- コンテキストメニュー: 終了、削除、名前変更

#### Views/Sidebar/SessionRow.swift

- セッション名（displayName）
- ステータスバッジ（StatusBadge）
- モデル名
- 最終アクティブ日時

#### Views/Input/InputArea.swift

- TextEditor で複数行入力対応
- Enter で送信、Shift+Enter で改行
- ストリーミング中は停止ボタン表示（送信ボタンと切替）
- セッション未接続・処理中は入力無効化

```swift
struct InputArea: View {
    @Bindable var session: SessionState
    @State private var text: String = ""

    var body: some View {
        HStack {
            TextEditor(text: $text)
            if session.isProcessing {
                Button("停止") { Task { await session.interrupt() } }
            } else {
                Button("送信") { sendMessage() }
                    .disabled(text.isEmpty || session.status != .connected)
            }
        }
        .onSubmit { sendMessage() }
    }
}
```

#### Views/Common/EmptySessionView.swift

- セッション未選択時のプレースホルダー
- 「Cmd+N で新規セッションを作成」のガイド

#### Views/Common/StatusBadge.swift

- SessionStatus に対応した色付きバッジ
- `.connected` → 緑、`.connecting` → 黄、`.disconnected` → グレー、`.error` → 赤

### 完了基準

- [ ] 各 View がコンパイル成功
- [ ] Xcode Preview で ContentView が表示される（Mock データ使用）
- [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-3: ChatView + MessageBubble + StreamingTextView

### 実装内容

#### Views/Chat/ChatView.swift

- ScrollView + LazyVStack でメッセージ一覧を表示
- `session.messages` をデータソースとする
- 新しいメッセージ追加時に自動スクロール（ScrollViewReader + `.onChange`）
- ストリーミング中は StreamingTextView を最下部に表示
- 下部に InputArea を配置

```swift
struct ChatView: View {
    @Bindable var session: SessionState

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(session.messages) { message in
                            MessageBubble(message: message)
                        }
                        if !session.streamingText.isEmpty {
                            StreamingTextView(text: session.streamingText)
                        }
                    }
                }
                .onChange(of: session.messages.count) { ... }
                .onChange(of: session.streamingText) { ... }
            }
            InputArea(session: session)
        }
    }
}
```

#### Views/Chat/MessageBubble.swift

- `ChatMessage` の role に応じた表示分岐
  - `.user` → 右寄せバブル
  - `.assistant` → 左寄せバブル
- `content: [ContentItem]` を forEach で表示
  - `.text` → MarkdownView（swift-markdown-view）
  - `.toolUse` → ToolUseCard（Wave 4-4 で実装、この時点ではプレースホルダー）
  - `.toolResult` → ToolResultCard（Wave 4-4 で実装）
- DesignSystem のカラーパレットを使用

```swift
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading) {
            ForEach(Array(message.content.enumerated()), id: \.offset) { _, item in
                switch item {
                case .text(let text):
                    MarkdownView(source: text)
                case .toolUse(let toolUse):
                    ToolUseCard(toolUse: toolUse)
                case .toolResult(let toolResult):
                    ToolResultCard(toolResult: toolResult)
                }
            }
        }
    }
}
```

#### Views/Chat/StreamingTextView.swift

- ストリーミング中の部分テキストを表示
- テキスト末尾にカーソルアニメーション（点滅する `▌`）
- MarkdownView で表示（部分テキストでも Markdown レンダリング）

### 完了基準

- [ ] ChatView + MessageBubble がコンパイル成功
- [ ] Xcode Preview で Mock メッセージが表示される
- [ ] 自動スクロールのロジックが実装されている
- [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-4: ToolUseCard + ToolResultCard + NewSessionSheet

### 実装内容（並列実行可能）

#### Views/Chat/ToolUseCard.swift

- `specs/02_requirements/03_functional_requirements.md#FR-013` に準拠
- DesignSystem の Card コンポーネントを使用
- ヘッダー: ツール名（例: "Read", "Bash", "Write"）
- ボディ: パラメータをキー・値のリストで表示

```swift
struct ToolUseCard: View {
    let toolUse: ToolUseItem

    var body: some View {
        Card {
            VStack(alignment: .leading) {
                Label(toolUse.name, systemImage: "wrench")
                    .font(.headline)
                ForEach(toolUse.input.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key).foregroundStyle(.secondary)
                        Text(value).lineLimit(3)
                    }
                }
            }
        }
    }
}
```

#### Views/Chat/ToolResultCard.swift

- `specs/02_requirements/03_functional_requirements.md#FR-014` に準拠
- 折りたたみ/展開切替（DisclosureGroup）
- `isError == true` 時は赤系背景色

```swift
struct ToolResultCard: View {
    let toolResult: ToolResultItem
    @State private var isExpanded: Bool = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(toolResult.content)
                .font(.system(.body, design: .monospaced))
        } label: {
            Label(
                toolResult.isError ? "エラー" : "結果",
                systemImage: toolResult.isError ? "xmark.circle" : "checkmark.circle"
            )
        }
        .padding()
        .background(toolResult.isError ? Color.red.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}
```

#### Views/Sheets/NewSessionSheet.swift

- `specs/02_requirements/03_functional_requirements.md#FR-001` に準拠
- 作業ディレクトリ選択（NSOpenPanel）
- モデル選択（Picker）
- システムプロンプト入力（テキストエリア、任意）
- 「作成」「キャンセル」ボタン

```swift
struct NewSessionSheet: View {
    @Bindable var appState: AppState
    @State private var workingDirectory: String = ""
    @State private var model: ModelSelection = .sonnet
    @State private var systemPrompt: String = ""

    var body: some View {
        Form {
            // ディレクトリ選択
            // モデルピッカー
            // システムプロンプト
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { ... }
            ToolbarItem(placement: .confirmationAction) { ... }
        }
    }
}
```

### 完了基準

- [ ] ToolUseCard, ToolResultCard が Xcode Preview で正しく表示
- [ ] ToolResultCard の折りたたみ/展開が動作
- [ ] NewSessionSheet のフォームが表示される
- [ ] `swift build --package-path Packages/Presentation` 成功

---

## Wave 4-5: Store ロジック完全実装 + Presentation Unit Test

### 実装内容

#### AppState のアクション実装

**createSession:**
1. `agentService.createSession(config:)` を呼び出す
2. 返却された sessionId と stream から `SessionState` を生成
3. `sessions` 配列に追加
4. `activeSessionId` を設定
5. `sessionStore.save()` でローカル保存

**loadSavedSessions:**
1. `sessionStore.loadAll()` で `[SessionData]` を取得
2. 各 `SessionData` を `SessionState`（status: .disconnected）に変換
3. `sessions` に設定

**saveAllSessions:**
1. 全 `SessionState` を `SessionData` に変換
2. `sessionStore.save()` で保存

**deleteSession:**
1. 接続中の場合は `close()` を呼ぶ
2. `sessions` から除去
3. `sessionStore.delete()` で永続化データ削除
4. `activeSessionId` を更新（削除した場合は先頭セッションに）

#### SessionState のアクション実装

**send:**
```
1. isProcessing = true
2. messages.append(ユーザーメッセージ)
3. stream = try await agentService.send(sessionId:message:)
4. streamTask = Task {
     for try await event in stream {
       switch event {
       case .partialText(let text): streamingText = text
       case .assistantMessage(let content):
         messages.append(ChatMessage(role: .assistant, content: content))
         streamingText = ""
       case .turnCompleted(let cost, let input, let output):
         totalCostUsd += cost
         lastTokenUsage = TokenUsage(inputTokens: input, outputTokens: output)
         isProcessing = false
         lastActiveAt = Date()
       case .initialized: break
       }
     }
   }
5. catch: エラーハンドリング（status = .error）
```

**interrupt:**
- `streamTask?.cancel()`
- `try await agentService.interrupt(sessionId:)`
- `isProcessing = false`

**reconnect:**
- `status = .connecting`
- `stream = try await agentService.resumeSession(id:config:)`
- ストリーム監視を開始
- `status = .connected`

**disconnect:**
- `try await agentService.close(sessionId:)`
- `status = .disconnected`
- `streamTask?.cancel()`

**setModel:**
- `try await agentService.setModel(sessionId:model:)`
- config の model を更新（SessionConfig を var にするか、新しい config を保持）

### Unit Test

| テストファイル | テスト内容 |
|-------------|----------|
| `AppStateTests.swift` | Mock AgentService + Mock SessionStore で: |
| | - createSession: sessions に追加される |
| | - deleteSession: sessions から除去 + store.delete 呼ばれる |
| | - loadSavedSessions: store.loadAll の結果が sessions に反映 |
| `SessionStateTests.swift` | Mock AgentService で: |
| | - send: messages にユーザーメッセージ追加 → ストリーム処理 |
| | - interrupt: isProcessing = false に遷移 |
| | - reconnect: status が .connected に遷移 |

**Mock の作成:**
- テスト用に `MockAgentService: AgentServiceProtocol` を Presentation テスト内に作成
- テスト用に `MockSessionStore: SessionStoreProtocol` を Presentation テスト内に作成

### 完了基準

- [ ] AppState の全アクションが実装済み
- [ ] SessionState の全アクションが実装済み
- [ ] ストリーム処理フローが `specs/03_design_spec/04_component_architecture.md#メッセージストリーム処理フロー` と一致
- [ ] `swift test --package-path Packages/Presentation` 全テストパス
- [ ] Placeholder.swift を削除済み

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
