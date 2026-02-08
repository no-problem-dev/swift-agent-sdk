---
title: "ClaudeAgent - ロールアウト・ロールバック手順"
created: 2026-02-08
status: draft
tags: [implementation-plan, rollout, claude-agent]
references:
  - ./00_index.md
  - ../03_design_spec/12_risks.md
---

# ロールアウト・ロールバック手順

## 1. ロールアウト戦略

### 1.1 概要

ClaudeAgent はサンプルアプリのため、App Store 配布は行わない。
リポジトリの `SampleApp/ClaudeAgent/` ディレクトリにソースコードとして配布する。

### 1.2 リリースフロー

```
develop ブランチ
  ↓ 全 Phase 完了 + Manual QA 合格
feat/sample-app ブランチ
  ↓ PR レビュー
develop にマージ
  ↓ タグ付け（v0.2.0 等）
リリース
```

### 1.3 配布形態

| 形態 | 内容 |
|------|------|
| ソースコード | `SampleApp/ClaudeAgent/` ディレクトリ |
| ビルド手順 | README.md に記載（`xcodegen generate` → `xcodebuild build`） |
| バイナリ配布 | 行わない（ユーザーが自分でビルド） |

### 1.4 前提条件チェックリスト

リリース前に確認する項目:

- [ ] 全 Unit Test パス（`make test`）
- [ ] 統合ビルド成功（`make build-app`）
- [ ] Manual QA 合格（Wave 5-4 の全項目）
- [ ] README.md 作成済み
- [ ] コード量 3,000 行以下
- [ ] Swift 6 strict concurrency 警告ゼロ
- [ ] `.gitignore` に `*.xcodeproj` が含まれている
- [ ] `project.yml` が最新

## 2. ロールバック手順

### 2.1 Git ベースのロールバック

問題が発見された場合:

```bash
# 直前のコミットに戻す
git revert HEAD

# 特定の Wave の変更を取り消す
git revert <commit-hash>

# PR 単位で revert
gh pr revert <pr-number>
```

### 2.2 パッケージ単位の切り戻し

各パッケージが独立しているため、問題のあるパッケージのみ切り戻し可能:

| 問題箇所 | 切り戻し方法 |
|---------|------------|
| Presentation のバグ | Presentation パッケージの該当コミットを revert |
| Infrastructure のバグ | Infrastructure パッケージの該当コミットを revert |
| Domain の型変更 | Domain を revert → 依存する全パッケージの調整が必要（影響大） |

### 2.3 データ移行

ローカル永続化データ（sessions.json）に破壊的変更を入れた場合:

1. 旧フォーマットからの移行コードを Infrastructure に追加
2. sessions.json のバックアップを取得してから移行
3. 移行失敗時は空状態で起動（データロスは許容）

## 3. リスク対策の実装確認

`specs/03_design_spec/12_risks.md` の対策が実装されていることを確認する。

| リスク ID | 対策 | 確認方法 |
|----------|------|---------|
| R-1 | ローディング UI | セッション接続中にインジケータ表示 |
| R-2 | 再接続フロー | disconnected セッションで再接続ボタン動作 |
| R-3 | CLI 未インストール検知 | CLI なし環境でエラーメッセージ表示 |
| R-4 | メモリ管理 | 100 メッセージで 200MB 以下 |
| R-5 | ゾンビプロセス対策 | アプリ終了時に全セッション close |
| R-7 | アトミック書き込み | sessions.json が中途半端な状態にならない |
| R-8 | ローカルパス依存 | README にリポジトリ構成の説明 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
