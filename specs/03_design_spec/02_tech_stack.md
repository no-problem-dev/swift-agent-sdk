---
title: "Swift Agent SDK - 技術スタック"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, tech-stack]
references:
  - ./00_index.md
  - ../02_requirements/06_constraints.md
  - ../02_requirements/04_non_functional_requirements.md
---

# 技術スタック

## Intent（意図）

Swift Agent SDK で使用する技術要素を一覧化し、各選定の理由と代替案を明記する。
外部依存ゼロの方針（D-3）に基づき、Foundation のみで構成する根拠を示す。

---

## 1. 言語・ランタイム

| 技術要素 | 選定 | バージョン | 理由 |
|---------|------|-----------|------|
| 言語 | Swift | 6.0+ | Swift Concurrency の安定版。Sendable 強制が有効 |
| パッケージ管理 | Swift Package Manager | Swift 6.0 同梱 | Swift 公式。他の選択肢なし |
| ビルドシステム | SwiftPM | - | SPM がビルド・テスト・依存解決を統合提供 |

### 代替案

| 代替案 | 不採用理由 |
|--------|-----------|
| Swift 5.9 | `Sendable` の strict concurrency checking がデフォルト無効。Swift 6 を前提とすることで安全性を高める |

---

## 2. フレームワーク・ライブラリ

| 技術要素 | 選定 | 用途 | 理由 |
|---------|------|------|------|
| Foundation | `Process` | サブプロセス起動・管理 | 標準ライブラリ。POSIX fork/exec のラッパー |
| Foundation | `Pipe` / `FileHandle` | stdin/stdout パイプ通信 | Process と組み合わせて使用 |
| Foundation | `JSONEncoder` / `JSONDecoder` | JSONL エンコード・デコード | Codable との統合。サードパーティ不要 |
| Swift Concurrency | `AsyncThrowingStream` | ストリーミングメッセージ配信 | 標準ライブラリ。async/await との自然な統合 |
| Swift Concurrency | `Actor` | 状態管理（Transport の接続状態等） | データ競合を型レベルで防止 |
| Swift Concurrency | `Task` / `TaskGroup` | 非同期処理・キャンセレーション | 構造化並行性。キャンセル伝播が自動 |
| XCTest | - | ユニットテスト | Swift 標準テストフレームワーク |

### 検討・不採用のサードパーティライブラリ

| ライブラリ | 検討内容 | 不採用理由 |
|-----------|---------|-----------|
| swift-async-algorithms | `AsyncSequence` のユーティリティ | 現時点では `AsyncThrowingStream` で十分。必要になった時点で再検討 |
| swift-json-schema | JSON Schema の型安全な表現 | D-12 により外部依存ゼロを堅持。辞書型で表現 |
| SwiftNIO | 非同期 I/O | サーバーフレームワーク向け。サブプロセス制御には過剰 |
| swift-subprocess | Swift 6 の新しいサブプロセス API | macOS 15+ のみ。Foundation.Process で十分。将来的に移行を検討 |

---

## 3. 外部ランタイム依存

| 依存 | バージョン | 必須/任意 | 用途 |
|------|-----------|----------|------|
| Node.js | 18+ | 必須（いずれか1つ） | Claude Code CLI の実行 |
| Bun | latest | 任意（Node.js 代替） | CLI 実行用の代替ランタイム |
| Deno | latest | 任意（Node.js 代替） | CLI 実行用の代替ランタイム |
| `@anthropic-ai/claude-agent-sdk` | 0.2.x | 必須 | CLI バイナリ（cli.js）を含む npm パッケージ |

**注:** これらは Swift パッケージの依存ではなく、ランタイム時に利用者の環境に存在する必要がある外部依存である。

---

## 4. 互換性マトリクス

| 要素 | 最小バージョン | 推奨バージョン | 備考 |
|------|-------------|-------------|------|
| Swift | 6.0 | 6.0+ | strict concurrency |
| macOS | 15.0 (Sequoia) | 15.0+ | Foundation.Process の最新 API |
| Linux | 後回し（D-13） | - | 初期は macOS のみ |
| Node.js | 18 | 20 LTS | CLI の要件 |
| Agent SDK (npm) | 0.2.0 | 0.2.x | CLI 2.1.x と対応 |

---

## 5. ビルド・CI 環境

| 要素 | 選定 | 備考 |
|------|------|------|
| CI | GitHub Actions | macOS runner で Swift 6 + Node.js を使用 |
| テスト | `swift test` | SwiftPM 統合テスト。MockTransport でユニットテスト |
| リント | SwiftFormat / SwiftLint | コードスタイル統一（任意） |
| ドキュメント | DocC | Swift 公式ドキュメントツール |

---

## Rationale（根拠）

### 外部依存ゼロの方針（D-3）

**決定:** Swift パッケージとしてサードパーティ依存を持たない（Foundation のみ）

**採用理由:**
- 依存更新コストの排除（バージョン競合・セキュリティパッチ追従が不要）
- Foundation の Process / Pipe / JSONEncoder で全機能要件を満たせる
- ライブラリ SDK として、利用者の依存グラフを汚染しない

**検討した代替案:**

| 代替案 | 不採用理由 |
|--------|-----------|
| swift-async-algorithms 依存 | merge/zip 等は現要件で不要。AsyncThrowingStream で十分 |
| SwiftNIO 依存 | サーバーフレームワーク向けの大規模ライブラリ。サブプロセス制御には過剰 |

### Foundation.Process の選択

**決定:** Swift 6 の `Subprocess` API ではなく `Foundation.Process` を使用

**採用理由:**
- `Subprocess` は macOS 15+ / Swift 6 の新 API だが、Linux 対応が未検証
- `Foundation.Process` は十分な機能を持ち、実績がある
- 将来の `Subprocess` 移行は ClaudeCodeTransport 内部の変更のみで対応可能（Protocol 層に影響なし）

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
