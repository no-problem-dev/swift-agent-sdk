---
title: "Swift Agent SDK - AI 指示構成テンプレート"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan, ai-template]
references:
  - ./00_index.md
  - ./01_phase_wave_structure.md
  - ./02_reference_matrix.md
---

# AI への指示構成テンプレート

## Intent（意図）

AI エージェントにタスクを委譲する際の指示テンプレートを定義する。
各 Wave の実装を AI に依頼する際に、このテンプレートに沿って指示を構成することで、
必要な仕様参照先と検証基準を漏れなく伝達できる。

---

## 1. 基本テンプレート

```markdown
## タスク
[Wave ID]: [Wave 名称]

## 目標
[Wave の成果物の説明]

## 参照仕様
以下のファイルを読み込んで実装すること:
- [参照マトリクスから取得したファイル一覧（パス#セクション）]

## 実装対象ファイル
- Sources/[モジュール]/[ファイル名].swift

## 実装詳細
[01_phase_wave_structure.md の該当 Wave から具体的な作業を転記]

## コーディング規約
- Swift 6.0+, Sendable 準拠必須
- public API には DocC コメント必須
- 外部依存禁止（Foundation のみ）
- テスト命名: test_メソッド名_条件_期待結果

## テスト
- テストファイル: Tests/[ターゲット]/[テストファイル名].swift
- テスト観点: [テストケースの一覧]

## 検証基準
- [ ] `swift build` 成功
- [ ] `swift test --filter [テストターゲット]` 全パス
- [ ] Swift 6 strict concurrency warning 0
- [ ] [Wave 固有の検証基準]
```

---

## 2. Wave 別テンプレート例

### Wave 1-1: Package.swift + ディレクトリ構造

```markdown
## タスク
Wave 1-1: Package.swift + ディレクトリ構造

## 目標
SwiftPM パッケージとして `swift build` が成功する状態を作る。

## 参照仕様
- specs/03_design_spec/04_component_architecture.md#3 ディレクトリ構造
- specs/03_design_spec/04_component_architecture.md#4 Package.swift 構成

## 実装対象ファイル
- Package.swift
- Sources/AgentSDK/ (プレースホルダ)
- Sources/AgentSDKClaudeCode/ (プレースホルダ)
- Sources/AgentSDKTesting/ (プレースホルダ)
- Tests/AgentSDKTests/ (プレースホルダ)
- Tests/AgentSDKClaudeCodeTests/ (プレースホルダ)
- Tests/IntegrationTests/ (プレースホルダ)

## 実装詳細
1. Package.swift を specs の定義通りに作成
2. 各モジュールディレクトリを作成
3. 各ターゲットに空の .swift ファイルを配置（ビルド通過用）

## 検証基準
- [ ] `swift build` 成功
- [ ] 3 モジュール（AgentSDK, AgentSDKClaudeCode, AgentSDKTesting）がビルドされる
- [ ] 3 テストターゲットが認識される
```

### Wave 1-2: Protocol 層型定義

```markdown
## タスク
Wave 1-2: Protocol 層型定義

## 目標
AgentSDK モジュールの全 public 型を定義する。

## 参照仕様
- specs/03_design_spec/03_layer_architecture.md#Protocol Layer
- specs/03_design_spec/05_data_model.md#2 Protocol Layer 型定義
- specs/03_design_spec/05_data_model.md#3 エラー型
- specs/03_design_spec/08_api_spec.md#1-3 コンビニエンス API
- specs/03_design_spec/08_api_spec.md#3.2 セッション内ランタイム制御（CommandInfo, ModelInfo）

## 実装対象ファイル
- Sources/AgentSDK/Protocols/AgentTransport.swift
- Sources/AgentSDK/Protocols/AgentClient.swift
- Sources/AgentSDK/Protocols/AgentSession.swift
- Sources/AgentSDK/Models/AgentMessage.swift
- Sources/AgentSDK/Models/ContentBlock.swift
- Sources/AgentSDK/Models/JSONValue.swift
- Sources/AgentSDK/Models/QueryOptions.swift
- Sources/AgentSDK/Models/SessionOptions.swift
- Sources/AgentSDK/Models/AgentDefinition.swift
- Sources/AgentSDK/Models/PermissionMode.swift
- Sources/AgentSDK/Models/MCPServerConfig.swift
- Sources/AgentSDK/Errors/AgentSDKError.swift

## 実装詳細
- 全 public 型は Sendable 準拠
- AgentMessage, ContentBlock, JSONValue は Codable 準拠
- AgentSDKError は LocalizedError 準拠（全 case にメッセージ）
- Protocol は associatedtype を使用（Generics 方針）
- QueryOptions / SessionOptions にクロージャプロパティあり（Sendable 非対応→ @Sendable を指定）

## 検証基準
- [ ] `swift build` 成功
- [ ] `import AgentSDK` で全 public 型にアクセス可能
- [ ] Sendable 準拠で warning 0
```

### Wave 2-1: 低レベル基盤

```markdown
## タスク
Wave 2-1: 低レベル基盤（JSONLCodec, CLILocator, CLIArgBuilder）

## 目標
CLI 操作の基盤コンポーネント 3 つを TDD で実装する。

## 参照仕様
- specs/03_design_spec/04_component_architecture.md#2.2 JSONLCodec
- specs/03_design_spec/04_component_architecture.md#2.5 CLILocator
- specs/03_design_spec/04_component_architecture.md#2.6 CLIArgBuilder
- specs/03_design_spec/06_auth_flow.md#3 CLI 探索フロー
- specs/02_requirements/05_io_spec.md（CLI 起動引数）

## 実装対象ファイル
- Sources/AgentSDKClaudeCode/Internal/JSONLCodec.swift
- Sources/AgentSDKClaudeCode/Internal/CLILocator.swift
- Sources/AgentSDKClaudeCode/Internal/CLIArgBuilder.swift
- Tests/AgentSDKClaudeCodeTests/JSONLCodecTests.swift
- Tests/AgentSDKClaudeCodeTests/CLILocatorTests.swift
- Tests/AgentSDKClaudeCodeTests/CLIArgBuilderTests.swift

## TDD サイクル
各コンポーネントについて:
1. テストを先に書く（Red）
2. 最小限の実装で通す（Green）
3. リファクタリング（Refactor）

## 検証基準
- [ ] `swift test --filter AgentSDKClaudeCodeTests` 全パス
- [ ] JSONLCodec: encode/decode round-trip テスト
- [ ] CLILocator: 5段階探索の各パスのテスト
- [ ] CLIArgBuilder: デフォルト + オプション引数のテスト
```

---

## 3. コンパクション指示

各 Wave 完了後に `/compact` を実行する際は、以下の情報を保持するよう指示する:

```markdown
## コンパクション指示
Wave [X-Y] が完了しました。以下の情報を保持してコンテキストを圧縮してください:

### 完了成果物
- [作成/修正したファイル一覧]

### テスト結果
- [テスト結果サマリー]

### 未解決課題
- [あれば記載]

### 次の Wave
- Wave [X-Y+1]: [名称]
- 入力ファイル: [依存するファイルパス]
```

---

## 4. 並列実装指示

並列化可能な Wave 内のサブタスクを複数 AI に分担する場合:

```markdown
## 並列タスク指示

### タスク [A]: [名称]
[基本テンプレートを適用]

### タスク [B]: [名称]
[基本テンプレートを適用]

### 統合条件
- タスク [A] と [B] の完了後に統合
- 統合時の検証: `swift build` + `swift test`
- 名前空間の衝突がないことを確認
```

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
