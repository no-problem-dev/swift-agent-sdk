---
title: "Swift Agent SDK - 技術的学び"
created: 2026-02-08
status: active
tags: [swift, agent-sdk, implementation-log, learnings]
references:
  - ./01_completed_tasks.md
---

# 技術的学び

## 成功した実装パターン

### 1. Continuation ベースの非同期待機（MessageRouter, Handshake）
- `withCheckedContinuation` / `withCheckedThrowingContinuation` でリクエスト/レスポンス対応を actor 内で安全に管理
- request_id をキーにした辞書で continuation を保持し、対応するレスポンス到着時に resume

### 2. HandshakeFlag パターン（ClaudeCodeTransport）
- `CheckedContinuation` の exactly-once resume を保証する `@unchecked Sendable` クラス
- タイムアウト task と reader task の両方から resume を試みる場合に必須
- `NSLock` + `Bool` フラグで thread-safe に first-come-first-served

### 3. StreamHolder パターン（ClaudeCodeTransport）
- `AgentTransport.messages()` が non-async protocol 要件のため、async `connect()` で生成したストリームを同期的に返す必要がある
- `@unchecked Sendable` クラスに `NSLock` で保護した Optional stream を持たせて解決

### 4. MockTransport によるユニットテスト分離
- Client/Session テストはプロセス不要の MockTransport で実行
- 実プロセスを使うテストは Transport テストに限定
- テスト速度と安定性が向上

## 失敗から学んだこと

### 1. Actor 内でのブロッキング I/O はデッドロックを引き起こす（CLIProcess - 重大）
- **問題**: `CLIProcess` actor 内で `proc.waitUntilExit()` と `fileHandle.availableData` を呼ぶと actor のスレッドをブロックし、他の actor メソッド（`terminate()` 等）がデッドロック
- **影響**: テストスイート全体が 19 テストでハング（swift test が終了しない）
- **修正**:
  - `waitForExit()` → `withCheckedContinuation` + `terminationHandler` コールバックで resume
  - `stdoutStream()` → `nonisolated` + `Task.detached` でブロッキング read を actor 外に分離
- **教訓**: Swift actor 内では Foundation の同期ブロッキング API（waitUntilExit, availableData）を絶対に使ってはならない

### 2. シェルスクリプトベースのテストはハングリスクが高い
- **問題**: `sleep 30` + `read -r` を使うモックスクリプトで `close()` が効かない場合にテストが 30 秒以上ハング
- **影響**: CI で不安定、開発サイクルが遅延
- **対策**: Client/Session テストは MockTransport に移行。Transport テストには `.timeLimit()` を付与
- **教訓**: プロセス統合テストは最小限に。ユニットテストはプロトコルモックで行う

### 3. モジュール循環依存の回避（T19）
- **問題**: AgentSDK モジュールが AgentSDKClaudeCode をインポートすると循環依存
- **対策**: `AgentSDK.swift` は `public enum AgentSDK {}` のみとし、convenience API は `AgentSDKClaudeCode` モジュール内の extension として実装
- **教訓**: スタブを先に定義する設計では、本実装の配置先を早期に検討すべき

## 推奨される改善点

### 1. CLIProcess の標準出力読み取りを非同期化
- 現在 `Task.detached` + `availableData` でブロッキング read を actor 外に追い出しているが、DispatchIO や FileHandle.readabilityHandler を使った完全非同期実装が望ましい

### 2. Transport テストの安定化
- シェルスクリプトテストは `.timeLimit(.seconds(10))` で保護しているが、根本的には MockTransport パターンへの移行が必要
- 残っている Transport テストも将来的に安定化が課題

### 3. テスト実行の並列性
- Swift Testing の `@Suite` + `@Test` は並列実行されるため、プロセス系テストが互いに干渉する可能性
- `.serialized` trait の検討
