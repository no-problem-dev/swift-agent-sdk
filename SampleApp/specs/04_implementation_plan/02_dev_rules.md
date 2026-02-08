---
title: "ClaudeAgent - 開発ルール"
created: 2026-02-08
status: draft
tags: [implementation-plan, dev-rules, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/06_constraints.md
  - ../03_design_spec/01_architecture.md
---

# 開発ルール

## 1. ブランチ戦略

| ブランチ | 用途 | ベース |
|---------|------|--------|
| `develop` | デフォルト開発ブランチ | — |
| `feat/p{N}-w{M}-{概要}` | Phase N Wave M の実装 | `develop` |
| 例: `feat/p1-w1-project-setup` | Phase 1 Wave 1 | `develop` |
| 例: `feat/p2-w1-domain-entities` | Phase 2 Wave 1 | `develop` |

**ルール:**
- 1 Wave = 1 ブランチ = 1 PR を原則とする
- Wave が小さい場合は複数 Wave をまとめてもよい
- PR は `develop` にマージ
- マージ後にブランチを削除

## 2. コミット規約

```
種別: 内容

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### 種別

| 種別 | 用途 |
|------|------|
| `feat` | 新機能追加 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング（機能変更なし） |
| `test` | テスト追加・修正 |
| `chore` | ビルド設定・依存追加等 |
| `docs` | ドキュメント |

### 例

```
feat: Domain エンティティ（ChatMessage, ContentItem）を実装
chore: project.yml + Package.swift 初期構成
test: AgentService の MockTransport テストを追加
```

## 3. コーディング規約

### 3.1 Swift 6 strict concurrency

- 全ファイルで `Sendable` 準拠を意識する
- `@MainActor` は Store（AppState, SessionState）と View に限定
- Domain の型はすべて struct + let で自動 Sendable
- `nonisolated(unsafe)` や `@unchecked Sendable` は原則禁止（必要な場合はコメントで理由を記載）

### 3.2 パッケージ依存ルール

| パッケージ | 許可される import |
|-----------|-----------------|
| Domain | `Foundation` のみ |
| Infrastructure | `Foundation`, `Domain`, `AgentSDKClaudeCode`, `AgentSDK` |
| Presentation | `Foundation`, `SwiftUI`, `Domain`, `MarkdownView`, `DesignSystem`, `UIRouting` |
| App | 全パッケージ |

**禁止:**
- Presentation で `Infrastructure` を import
- Infrastructure で `Presentation` を import
- Domain で上記いずれも import

### 3.3 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| 型名 | PascalCase | `ChatMessage`, `SessionState` |
| プロパティ・メソッド | camelCase | `streamingText`, `sendMessage()` |
| プロトコル | 動詞 + able / Protocol suffix | `AgentServiceProtocol` |
| View | 機能を表す名詞 | `ChatView`, `MessageBubble` |
| Store | State suffix | `AppState`, `SessionState` |
| ファイル名 | 型名と一致 | `ChatMessage.swift` |

### 3.4 ファイル配置ルール

Design Spec `03_layer_architecture.md` のディレクトリ構成に準拠する。
新規ファイル追加時は以下を確認:

1. そのファイルが属するパッケージは正しいか
2. ディレクトリ（Entities/, Views/Chat/ 等）は正しいか
3. Package.swift の target に自動的に含まれるか（Sources/ 配下なら自動）

### 3.5 エラーハンドリング

- SDK エラーは Infrastructure 内で `AppError` に変換する
- `AppError` は Domain に定義し、`LocalizedError` に準拠する
- Presentation では `do-catch` で `AppError` をキャッチし UI に表示する
- 予期しないエラーは `assertionFailure` ではなく `AppError.protocolError` にラップする

### 3.6 テストルール

- TDD: テストを先に書いてから実装する（Domain / Infrastructure のロジック）
- 各パッケージの Tests/ ディレクトリに配置する
- テストファイル名: `{対象型名}Tests.swift`
- Infrastructure テストでは `AgentSDKTesting` の `MockTransport` を使用する
- カバレッジ目標: Domain 80%以上、Infrastructure 70%以上

## 4. PR ルール

### 4.1 PR テンプレート

```markdown
## Summary
- Wave X-Y の実装

## Changes
- [変更内容の箇条書き]

## Test plan
- [ ] `swift test --package-path Packages/{Package}` パス
- [ ] `swift build --package-path Packages/{Package}` 成功
- [ ] [追加の確認事項]
```

### 4.2 レビュー基準

- パッケージ依存方向の遵守（コンパイルエラーで検出されるが念のため確認）
- Swift 6 strict concurrency 警告なし
- テストが追加されている（ロジック変更の場合）
- Design Spec との整合性

## 5. AI への指示テンプレート

タスク実行時に AI に渡す参照仕様のテンプレート:

```
## タスク
{タスクの概要}

## 参照仕様
- 設計: `specs/03_design_spec/{該当ファイル}#{該当セクション}`
- 要件: `specs/02_requirements/03_functional_requirements.md#{該当FR}`
- 実装計画: `specs/04_implementation_plan/{該当Phase}#{該当Wave}`

## 制約
- 変更スコープ: `SampleApp/ClaudeAgent/Packages/{パッケージ名}/`
- 依存方向: {許可されるimport一覧}
- テスト: `swift test --package-path Packages/{パッケージ名}`

## 完了基準
- {具体的な基準}
```

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
