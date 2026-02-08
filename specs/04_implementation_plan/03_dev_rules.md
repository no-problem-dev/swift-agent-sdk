---
title: "Swift Agent SDK - 開発ルール"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan, dev-rules]
references:
  - ./00_index.md
  - ../03_design_spec/01_architecture.md
  - ../03_design_spec/02_tech_stack.md
---

# 開発ルール

## Intent（意図）

プロジェクト全体を通じた開発規約を定義し、実装の一貫性を保つ。
複数の実装者（人間・AI）が同じ品質基準で開発できるようにする。

---

## 1. ブランチ戦略

### 1.1 ブランチ命名規則

| プレフィックス | 用途 | 例 |
|-------------|------|-----|
| `feat/` | 新機能の実装 | `feat/wave-1-1-package-setup` |
| `fix/` | バグ修正 | `fix/jsonl-decode-error` |
| `test/` | テスト追加 | `test/wave-4-2-integration` |
| `docs/` | ドキュメント | `docs/readme` |
| `refactor/` | リファクタリング | `refactor/message-router` |

### 1.2 ブランチフロー

```
main
  └── feat/wave-1-1-package-setup
  └── feat/wave-1-2-protocol-types
  └── feat/wave-2-1-cli-foundation
  ...
```

- 各 Wave を 1 ブランチとする（Wave が大きい場合は分割可）
- `main` への直接コミットは禁止
- PR レビュー後にマージ（スカッシュマージ推奨）

---

## 2. コーディング指針

### 2.1 Swift スタイル

| 規約 | 内容 |
|------|------|
| Swift バージョン | 6.0+ |
| 命名規則 | Swift API Design Guidelines に準拠 |
| アクセス制御 | デフォルト `internal`、意図的に `public` / `private` を指定 |
| ドキュメンテーション | public API には必ず `///` DocC コメント |
| 行長制限 | 120 文字（目安、強制しない） |

### 2.2 型設計規約

| 規約 | 理由 |
|------|------|
| public 型はすべて `Sendable` 準拠 | Swift 6 strict concurrency 対応（R-007） |
| メッセージ・オプション・エラーは値型（struct / enum） | Value Semantics（設計方針 3.1） |
| 可変状態を持つコンポーネントは Actor | データ競合の防止 |
| Generics over Existential | 型消去コスト回避（D-8） |
| 外部依存禁止 | Foundation のみ（設計方針） |

### 2.3 エラーハンドリング規約

| 規約 | 内容 |
|------|------|
| public エラーは `AgentSDKError` に集約 | 利用者が switch で網羅可能 |
| internal エラーは各コンポーネント内で `AgentSDKError` に変換 | エラーの抽象レベルを統一 |
| `LocalizedError` 準拠 | ユーザーフレンドリーなメッセージ |
| エラーメッセージにアクション（解決方法）を含める | FR-040 準拠 |

### 2.4 並行性規約

| 規約 | 内容 |
|------|------|
| `async/await` を使用 | completion handler パターン不使用 |
| `AsyncThrowingStream` でストリーミング | Combine 不使用 |
| `Task.sleep(for:)` でタイマー | Timer / DispatchQueue 不使用 |
| `withCheckedThrowingContinuation` でブリッジ | コールバック→async の変換時 |
| `withThrowingTaskGroup` でタイムアウト | 制御リクエストのタイムアウト |

---

## 3. コミット規約

### 3.1 コミットメッセージ形式

```
種別(スコープ): 内容

本文（任意）
```

### 3.2 種別一覧

| 種別 | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `test` | テスト追加・修正 |
| `docs` | ドキュメント |
| `refactor` | リファクタリング |
| `chore` | ビルド・CI 等の雑務 |

### 3.3 スコープ一覧

| スコープ | 対象モジュール |
|---------|--------------|
| `sdk` | AgentSDK（Protocol Layer） |
| `claude` | AgentSDKClaudeCode（Concrete Layer） |
| `testing` | AgentSDKTesting |
| `ci` | CI/CD 設定 |

### 3.4 例

```
feat(sdk): add AgentTransport protocol definition
feat(claude): implement JSONLCodec encode/decode
test(claude): add CLILocator unit tests
docs: add README with usage examples
chore(ci): add GitHub Actions test workflow
```

---

## 4. テスト規約

### 4.1 テストファイル配置

| テスト種別 | ディレクトリ | テストターゲット |
|-----------|------------|----------------|
| Protocol 層 Unit | `Tests/AgentSDKTests/` | `AgentSDKTests` |
| 具象層 Unit | `Tests/AgentSDKClaudeCodeTests/` | `AgentSDKClaudeCodeTests` |
| 統合テスト | `Tests/IntegrationTests/` | `IntegrationTests` |

### 4.2 テスト命名規約

```swift
func test_メソッド名_条件_期待結果() {
    // Arrange
    // Act
    // Assert
}
```

例:
```swift
func test_encode_validStruct_returnsJsonlLine() { ... }
func test_locate_noCliFound_throwsCliNotFound() { ... }
func test_handshake_timeout_throwsInitializationTimeout() { ... }
```

### 4.3 カバレッジ目標

| モジュール | 目標 |
|-----------|------|
| AgentSDK | 90%+ |
| AgentSDKClaudeCode | 80%+ |
| AgentSDKTesting | 不要（テスト支援コード自体） |

---

## 5. PR ルール

### 5.1 PR テンプレート

```markdown
## Summary
- 実装した Wave: Wave X-Y
- 対応 FF: FF-XXX

## Changes
- [変更内容の箇条書き]

## Test Plan
- [ ] Unit Tests pass
- [ ] swift build success
- [ ] [追加テスト観点]

## References
- specs/03_design_spec/XX_xxx.md#セクション
```

### 5.2 マージ条件

| 条件 | 必須 |
|------|------|
| `swift build` 成功 | 必須 |
| `swift test` 全パス | 必須 |
| Swift 6 strict concurrency warning 0 | 必須 |
| DocC コメント（public API） | 必須 |
| カバレッジ目標到達 | 推奨 |

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
