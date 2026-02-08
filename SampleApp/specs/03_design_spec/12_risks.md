---
title: "ClaudeAgent - 技術リスクと対策"
created: 2026-02-08
status: draft
tags: [design, risks, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/06_constraints.md
---

# 技術リスクと対策

## リスク一覧

| ID | リスク | 影響度 | 発生確率 | 対策 |
|----|-------|--------|---------|------|
| R-1 | SDK コールドスタート遅延 | 中 | 高 | ローディング UI 必須。接続完了まで入力を無効化 |
| R-2 | セッション失効（~10 分） | 中 | 中 | disconnected 検知 → 再接続ボタン表示。resumeSession で復旧 |
| R-3 | CLI 未インストール | 高 | 低 | 起動時に CLI 存在チェック。cliNotFound でインストール手順を表示 |
| R-4 | ストリーミング中のメモリ増大 | 中 | 低 | partial テキストは上書き更新。完了時に解放。100 メッセージで 200MB 以下を目標 |
| R-5 | サブプロセスのゾンビ化 | 中 | 低 | SDK の close() を確実に呼ぶ。アプリ終了時に全セッション close |
| R-6 | no-problem パッケージの API 変更 | 低 | 低 | バージョン固定（from: "1.0.0"）。SemVer でマイナーバージョン互換を期待 |
| R-7 | JSON 永続化ファイルの破損 | 中 | 低 | アトミック書き込み（.atomic オプション）。破損時は空状態で起動 |
| R-8 | swift-agent-sdk ローカルパス依存 | 低 | 中 | リポジトリ構成の README に記載。相対パスが合わない場合のエラーメッセージ |

## 詳細

### R-1: SDK コールドスタート遅延

Claude Code CLI のサブプロセス起動には ~12 秒かかる。

**対策:**
- SessionStatus `.connecting` 中はプログレスインジケータを表示
- 入力欄を disabled にして送信不可にする
- 接続完了（`.connected`）でインジケータを非表示にし入力欄を有効化

### R-2: セッション失効

非活動 10 分程度でセッションが失効する。

**対策:**
- `processExited` / `sessionExpired` エラーをキャッチ
- ステータスを `.disconnected` に遷移
- 再接続ボタンを表示し `resumeSession` を試行
- 再接続不可の場合は新規セッション作成を促す

### R-5: サブプロセスのゾンビ化

SDK 内部で Claude Code CLI をサブプロセスとして起動する。
アプリがクラッシュした場合、サブプロセスが残る可能性がある。

**対策:**
- AppDelegate / SwiftUI `onDisappear` で全セッション close
- `NSApplication.willTerminateNotification` で最終クリーンアップ
- 次回起動時にゾンビプロセスを検知・終了する仕組みは SDK に委ねる

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
