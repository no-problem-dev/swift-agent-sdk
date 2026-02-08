---
title: "ClaudeAgent - オープンクエスチョン"
created: 2026-02-08
status: draft
tags: [claude-agent, open-questions]
references:
  - ./00_index.md
---

# オープンクエスチョン

## 未解決

（なし）

## 解決済み

| ID | 質問 | 決定 | 決定日 |
|----|------|------|--------|
| OQ-001 | Markdown レンダリング方法 | **swift-markdown-view** を使用。no-problem 製パッケージでシンタックスハイライト込み対応。サードパーティ禁止は「no-problem 製は許可」に修正 | 2026-02-08 |
| OQ-002 | 同時接続セッション数の上限 | **上限なし**。問題が出たら後から追加可能（アーキテクチャに影響しない） | 2026-02-08 |
| OQ-003 | Xcode プロジェクト生成方法 | **XcodeGen** を使用。project.yml で管理し .xcodeproj は git に含めない。.xcodeproj の直接編集は禁止 | 2026-02-08 |
| D-1〜D-5 | （参照: 00_index.md） | — | 2026-02-08 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
| 2026-02-08 | OQ-001〜003 を全件解決。no-problem 製パッケージ活用方針決定 |
