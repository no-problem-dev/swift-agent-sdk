---
title: "ClaudeAgent - 非機能要件の実現方式"
created: 2026-02-08
status: draft
tags: [design, nfr, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/04_non_functional_requirements.md
---

# 非機能要件の実現方式

## NFR-001: パフォーマンス

### UI フレームレート（30fps 以上）

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| @MainActor による UI 更新の最適化 | SessionState を @MainActor で分離。ストリーム処理は MainActor 上で直接更新 | Presentation |
| partial メッセージの効率的更新 | `streamingText` プロパティを上書き更新（配列追加ではなく単一 String の差し替え） | Presentation |
| メッセージリストの遅延描画 | SwiftUI `LazyVStack` で表示領域のみレンダリング | Presentation |

### アプリ起動時間（3 秒以内）

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| 軽量な永続化 | JSON ファイル読み込み（Core Data 不使用） | Infrastructure |
| セッション接続は遅延実行 | 起動時は SessionData の読み込みのみ。SDK 接続はユーザー操作時 | App (DI) |

### メモリ使用量（200MB 以下）

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| partial テキストの上書き | ストリーミング中は単一 String を更新（履歴を保持しない） | Presentation |
| メッセージの Codable 化 | 不要な参照型を避け struct ベースで管理 | Domain |

## NFR-002: 信頼性

### クラッシュ防止

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| SDK エラーの全キャッチ | `AgentSDKError` を AppError に変換し UI 表示 | Infrastructure → Presentation |
| ストリームエラーハンドリング | `for try await` の catch 節で graceful に処理 | Presentation (SessionState) |

### データ損失防止

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| アトミック書き込み | `Data.write(to:options:.atomic)` | Infrastructure (SessionStore) |
| 破損ファイルの graceful 処理 | デコード失敗時は空状態で起動（ログ出力） | Infrastructure (SessionStore) |

### セッション復旧

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| 再接続フロー | disconnected 状態で再接続ボタン → `resumeSession` | Presentation + Infrastructure |
| セッション期限切れ対応 | `sessionExpired` 時に新規作成を促す UI | Presentation |

## NFR-003: ユーザビリティ

### ダークモード対応

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| swift-design-system テーマ | `ThemeProvider` がシステム設定に追従 | Presentation |
| セマンティックカラー使用 | DesignSystem のカラーパレットを使用（ハードコード色を避ける） | Presentation |

### キーボードショートカット

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| SwiftUI `.keyboardShortcut` | Cmd+N, Enter, Esc, Cmd+W をバインド | Presentation |

### エラーメッセージ

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| AppError → ユーザーメッセージ変換 | Domain の AppError に `localizedDescription` を定義 | Domain |
| AlertPresenter でダイアログ表示 | swift-ui-routing の AlertPresenter を使用 | Presentation |

## NFR-004: 保守性

### Swift 6 準拠

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| strict concurrency | 全 Package.swift で `SWIFT_STRICT_CONCURRENCY=complete` 相当（Swift 6 デフォルト） | 全パッケージ |
| Sendable 準拠 | Domain の全型を Sendable に。struct + let プロパティで自動準拠 | Domain |

### MVVM 遵守

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| パッケージ境界で強制 | View (Presentation) から Infrastructure を直接参照不可（コンパイルエラー） | SPM 構造 |
| Store パターン | AppState / SessionState が ViewModel 役。View はバインディングのみ | Presentation |

### テスタビリティ

| 対策 | 実装方法 | 対応パッケージ |
|------|---------|--------------|
| プロトコル DI | AgentServiceProtocol / SessionStoreProtocol を Domain に定義 | Domain |
| MockTransport 活用 | AgentSDKTesting の MockTransport でテスト | Infrastructure テスト |
| パッケージ単体テスト | 各パッケージが `swift test --package-path` で独立テスト可能 | 全パッケージ |

## NFR-005: 互換性

| 対策 | 実装方法 |
|------|---------|
| macOS 15+ | 全 Package.swift の platforms に `.macOS(.v15)` |
| Universal Binary | XcodeGen の ARCHS 設定（デフォルトで arm64 + x86_64） |
| Swift 6.0 | swift-tools-version: 6.0 |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
