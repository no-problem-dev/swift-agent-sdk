---
title: "Swift Agent SDK - ロールアウト・ロールバック戦略"
created: 2026-02-08
status: draft
tags: [swift, agent-sdk, implementation-plan, rollout]
references:
  - ./00_index.md
  - ../03_design_spec/12_risks.md
  - ../02_requirements/06_constraints.md
---

# ロールアウト・ロールバック戦略

## Intent（意図）

SDK のリリース手順、バージョニング戦略、および問題発生時のロールバック手順を定義する。

---

## 1. バージョニング戦略

### 1.1 SemVer 準拠

| バージョン要素 | 変更条件 |
|-------------|---------|
| MAJOR (X.0.0) | Protocol 層の breaking change（Protocol メソッド追加/変更） |
| MINOR (0.X.0) | 新機能追加（新しい制御サブタイプ対応、新しい Options パラメータ） |
| PATCH (0.0.X) | バグ修正、ドキュメント修正、内部リファクタリング |

### 1.2 初期バージョン

| バージョン | 状態 |
|-----------|------|
| 0.1.0 | Phase 1〜3 完了。基本機能（query, session）が動作 |
| 0.2.0 | Phase 4 完了。テスト・ドキュメント整備 |
| 1.0.0 | 安定版。Protocol 層を固定 |

### 1.3 CLI バージョン対応表

| SDK バージョン | CLI バージョン | 備考 |
|-------------|-------------|------|
| 0.1.0 | @anthropic-ai/claude-agent-sdk 0.2.x | 初期対応 |

この表は SDK リリースごとに更新する。

---

## 2. リリース手順

### 2.1 リリースフロー

```
1. main ブランチの全テストが green であることを確認
2. CHANGELOG.md を更新
3. Package.swift / README のバージョン表記を更新
4. git tag vX.Y.Z を作成
5. GitHub Release を作成（CHANGELOG の該当バージョンを本文に）
6. SwiftPM で利用可能であることを確認
```

### 2.2 リリース前チェックリスト

| チェック項目 | 実行方法 |
|------------|---------|
| Unit Tests 全パス | `swift test` |
| Integration Tests 全パス | サブスクリプション認証済環境で `AGENT_SDK_INTEGRATION_TEST=1 swift test --filter IntegrationTests` |
| Swift 6 strict concurrency warning 0 | `swift build` with strict concurrency |
| DocC ビルド成功 | `swift package generate-documentation` |
| README の使用例が動作 | 手動確認 |
| CLI バージョン対応表が最新 | README 確認 |

---

## 3. ロールバック戦略

### 3.1 ロールバックトリガー

| トリガー | 深刻度 | 対応 |
|---------|--------|------|
| Protocol 層のバグ（型定義の誤り） | Critical | 即座にパッチリリース |
| Concrete 層のバグ（CLI 通信の問題） | High | パッチリリース |
| テストの抜け（偽陽性カバレッジ） | Medium | 次回リリースで修正 |
| ドキュメントの誤り | Low | 次回リリースで修正 |

### 3.2 ロールバック手順

```
1. 問題のある git tag を deprecated にマーク（削除はしない）
2. GitHub Release に ⚠️ 警告を追記
3. 修正を main にマージ
4. パッチバージョンで再リリース
5. README / CHANGELOG に注意書きを追加
```

### 3.3 SwiftPM 利用者への影響

- SwiftPM は git tag ベースでバージョン解決する
- `.upToNextMinor(from:)` 指定の利用者はパッチ更新が自動で入る
- `.exact()` 指定の利用者は手動更新が必要
- 破壊的変更時は MAJOR バージョンアップし、マイグレーションガイドを提供

---

## 4. リスク対応とリリースの関係

| リスク | リリースへの影響 | 対応 |
|--------|---------------|------|
| R-001 JSONL プロトコル変更 | SDK パッチ/マイナーリリース | CLI バージョン対応表を更新 |
| R-004 CLI バージョン非互換 | SDK マイナーリリース | 対応バージョン範囲を拡大 |
| R-007 Swift 6 Concurrency | リリース前に修正 | warning 0 をリリース条件に |

---

## 5. 検討事項

| 項目 | 内容 | 判断時期 |
|------|------|---------|
| CI での自動リリース | GitHub Actions でタグプッシュ時に自動リリース | Phase 4 実装時 |
| CLI 新バージョン追従の SLA | CLI リリース後何日以内に SDK を更新するか | 1.0.0 リリース後 |
| 複数 CLI バージョンの並行サポート | 何バージョンまで同時サポートするか | 1.0.0 リリース後 |

---

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|---------|--------|
| 2026-02-08 | 初版作成 | Claude Code |
