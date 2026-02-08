---
title: "ClaudeAgent - テスト戦略"
created: 2026-02-08
status: draft
tags: [implementation-plan, testing, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/04_non_functional_requirements.md#NFR-004
  - ../03_design_spec/11_nfr_realization.md
---

# テスト戦略

## 1. テストピラミッド

```
        ┌─────────────┐
        │  Manual QA   │  ← Wave 5-4
        │  (UC テスト)  │
        ├─────────────┤
        │   E2E Test   │  ← Wave 5-3
        │ (実 SDK 接続) │
        ├──────────────┤
        │ Integration   │  ← Wave 3-3, 5-2
        │ (MockTransport│
        │  + Store テスト)│
        ├───────────────┤
        │   Unit Test    │  ← Wave 2-1〜2-3, 3-1〜3-2, 4-5
        │ (型・ロジック)  │
        └───────────────┘
```

## 2. テストレベル別戦略

### 2.1 Unit Test

| 対象パッケージ | テスト対象 | ツール | カバレッジ目標 |
|-------------|----------|------|-------------|
| Domain | エンティティの Codable、computed property、AgentEvent | Swift Testing | 80% |
| Infrastructure | AgentMessageMapper、JSONSessionStore | Swift Testing + AgentSDKTesting | 70% |
| Presentation | AppState/SessionState のアクション | Swift Testing + Mock | 60% |

**Unit Test の配置ルール:**
- 各パッケージの `Tests/{Package}Tests/` に配置
- ファイル名: `{対象型名}Tests.swift`
- テストは `@Test` アトリビュート（Swift Testing）を使用
- `@Suite(.serialized)` でスイート内の直列実行を保証（並行テスト問題を回避）

**TDD 適用範囲:**
- Domain の全型: テストファーストで実装
- Infrastructure のロジック: テストファーストで実装
- Presentation の Store: テストファーストで実装
- Presentation の View: テストなし（Xcode Preview で確認）

### 2.2 Integration Test

| テスト対象 | テスト方法 | Phase/Wave |
|-----------|----------|-----------|
| AgentService + MockTransport | SDK の MockTransport でストリーム処理全体を検証 | P3-W3 |
| AppState + Mock Services | Mock AgentService + Mock SessionStore で状態遷移を検証 | P4-W5 |
| App + 実 SDK | 実際の Claude Code CLI に接続してシナリオテスト | P5-W2 |

### 2.3 E2E Test

| テスト内容 | Phase/Wave |
|-----------|-----------|
| UC-1〜UC-4 のユースケースベーステスト | P5-W3 |
| 手動操作でのフルシナリオ確認 | P5-W3 |

### 2.4 Manual QA

| テスト内容 | Phase/Wave |
|-----------|-----------|
| NFR 検証（パフォーマンス、メモリ、ダークモード等） | P5-W4 |
| エッジケース確認（長文メッセージ、多数セッション等） | P5-W4 |

## 3. Mock 構成

### 3.1 Infrastructure テスト用

| Mock | 提供元 | 用途 |
|------|-------|------|
| `MockTransport` | swift-agent-sdk (AgentSDKTesting) | AgentService テスト |

AgentSDKTesting は SDK パッケージに含まれるテスト支援モジュール。
`MockTransport` を使うことで実際の CLI を起動せずに SDK の振る舞いをテストできる。

### 3.2 Presentation テスト用

| Mock | 定義場所 | 用途 |
|------|---------|------|
| `MockAgentService` | PresentationTests/ | AppState / SessionState テスト |
| `MockSessionStore` | PresentationTests/ | AppState テスト |

```swift
// PresentationTests/Mocks/MockAgentService.swift
final class MockAgentService: AgentServiceProtocol, @unchecked Sendable {
    var createSessionResult: (String, AsyncThrowingStream<AgentEvent, Error>)?
    var sendResult: AsyncThrowingStream<AgentEvent, Error>?
    // ... テストごとに返り値を設定

    func createSession(config: SessionConfig) async throws
        -> (sessionId: String, stream: AsyncThrowingStream<AgentEvent, Error>) {
        guard let result = createSessionResult else { throw AppError.notConnected }
        return result
    }
    // ...
}
```

## 4. テストフェーズの Phase/Wave 配置

| テストレベル | 配置先 Wave | 理由 |
|------------|-----------|------|
| Domain Unit Test | P2-W1, P2-W3 | TDD: 型実装と同時 |
| Infrastructure Unit Test | P3-W1, P3-W2 | TDD: Mapper, Store 実装と同時 |
| Infrastructure Integration Test | P3-W3 | MockTransport でのストリーム処理検証 |
| Presentation Unit Test | P4-W5 | Store ロジック完全実装後 |
| App Integration Test | P5-W2 | 実 SDK 接続でのシナリオテスト |
| E2E Test | P5-W3 | 全ユースケースの動作確認 |
| Manual QA | P5-W4 | NFR 検証 + エッジケース |

## 5. テスト実行コマンド

```bash
# 個別パッケージテスト
swift test --package-path Packages/Domain
swift test --package-path Packages/Infrastructure
swift test --package-path Packages/Presentation

# 全パッケージテスト（Makefile 経由）
make test

# 統合ビルド確認
make build-app
```

## 6. CI での考慮事項

- GitHub Actions で `make test` を実行
- macOS 15 ランナーが必要（Observation framework）
- Integration Test（P5-W2）は CI 対象外（実 SDK 接続が必要なため）
- Unit Test + ビルド確認のみ CI で自動化

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
