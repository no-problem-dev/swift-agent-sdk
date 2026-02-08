---
title: "Swift Agent SDK - 次にやるべきこと"
created: 2026-02-08
status: active
tags: [swift, agent-sdk, handoff, next-actions]
references:
  - ./01_status.md
  - ./06_issues.md
  - ../06_implementation_log/02_learnings.md
---

# 次にやるべきこと

## 即時対応（ブロッカー解消）

### 1. テストハング問題の解消と `swift test` 全パスの確認

**問題**: `swift test` を実行すると19テストがハングしてプロセスが終了しない

**修正済みの内容**（未コミット）:
- `CLIProcess.waitForExit()`: `proc.waitUntilExit()` → continuation ベースに変更
- `CLIProcess.stdoutStream()`: actor isolated → `nonisolated` + `Task.detached` に変更
- `ClaudeCodeTransportTests`: ハングしやすいテスト削除、`.timeLimit(.seconds(10))` 追加
- `ClaudeCodeClientTests` / `ClaudeCodeSessionTests`: シェルスクリプト → MockTransport に変更

**確認手順**:
```bash
# ビルド確認
swift build --build-tests

# テスト実行（フィルタで段階的に確認）
swift test --filter "AgentSDKTests"                    # Phase 1 テスト（110件）
swift test --filter "JSONLCodecTests"                  # T9
swift test --filter "CLILocatorTests"                  # T10
swift test --filter "CLIArgBuilderTests"               # T11
swift test --filter "CLIProcessTests"                  # T12 ← ハングしやすい
swift test --filter "CLIMessageTests"                  # T13
swift test --filter "SDKMessageTests"                  # T13
swift test --filter "HandshakeTests"                   # T14
swift test --filter "MessageRouterTests"               # T15
swift test --filter "ClaudeCodeTransportTests"         # T16 ← ハングしやすい
swift test --filter "ClaudeCodeClientTests"            # T17
swift test --filter "ClaudeCodeSessionTests"           # T18

# 全テスト一括（上記が全通過した場合のみ）
swift test
```

**まだハングする場合の対処**:
- `CLIProcessTests` の `terminateProcess` テスト: `/bin/sleep 60` を使っており terminate() 後に stdoutStream が EOF にならない可能性
  - → `nonisolated stdoutStream()` 内の `Task.detached` が `fileHandle.availableData` でブロックし続ける
  - → `terminate()` で pipe の close も必要かもしれない
- `ClaudeCodeTransportTests` のシェルスクリプトテスト: `read -r input` がプロセス kill 後もストリーム EOF にならない可能性
  - → Transport の `close()` 内で stdin/stdout pipe を明示的に close する

### 2. 未コミット変更のコミット

テスト全パス確認後、以下の順でコミット:
```bash
# T12 修正（CLIProcess ブロッキングI/O修正）
git add Sources/AgentSDKClaudeCode/Internal/CLIProcess.swift Tests/AgentSDKClaudeCodeTests/CLIProcessTests.swift
git commit -m "fix: CLIProcess blocking I/O deadlock in waitForExit and stdoutStream"

# T16 テスト修正
git add Tests/AgentSDKClaudeCodeTests/ClaudeCodeTransportTests.swift
git commit -m "fix: Remove hanging transport tests, add timeLimit"

# T17 ClaudeCodeClient
git add Sources/AgentSDKClaudeCode/ClaudeCodeClient.swift Tests/AgentSDKClaudeCodeTests/ClaudeCodeClientTests.swift Tests/AgentSDKClaudeCodeTests/Helpers/MockTransport.swift
git commit -m "feat: T17 Implement ClaudeCodeClient"

# T18 ClaudeCodeSession
git add Sources/AgentSDKClaudeCode/ClaudeCodeSession.swift Tests/AgentSDKClaudeCodeTests/ClaudeCodeSessionTests.swift
git commit -m "feat: T18 Implement ClaudeCodeSession"

# T19 AgentSDK convenience API
git add Sources/AgentSDKClaudeCode/AgentSDK+Convenience.swift Sources/AgentSDK/AgentSDK.swift
git commit -m "feat: T19 Implement AgentSDK convenience API"
```

---

## 短期（次セッション内）

### 3. **T20**: Implement MockTransport（AgentSDKTesting モジュール）
- テスト用 MockTransport を public API として `AgentSDKTesting` モジュールに実装
- 現在 `Tests/Helpers/MockTransport.swift` に internal 版があるので参考にする

### 4. **T21**: Implement MockFixtures
- テスト用の固定 JSON レスポンスファクトリ

### 5. **T22**: Test ClaudeCodeClient（Mock）
- MockTransport を使った本格的な Client/Session テスト

---

## 中期（Phase 4 完了まで）

### 6. **T23**: EndToEnd 統合テスト
- 実際の Claude Code CLI（または完全なモック）を使った統合テスト

### 7. **T24**: README + DocC
- 使用例、API リファレンス

### 8. **T25**: GitHub Actions CI
- テストの自動実行設定
