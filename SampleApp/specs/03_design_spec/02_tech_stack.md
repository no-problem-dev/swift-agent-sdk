---
title: "ClaudeAgent - 技術スタック"
created: 2026-02-08
status: draft
tags: [design, tech-stack, claude-agent]
references:
  - ./00_index.md
  - ../02_requirements/06_constraints.md
---

# 技術スタック

## 1. コア技術

| カテゴリ | 技術 | バージョン |
|---------|------|----------|
| 言語 | Swift | 6.0 |
| UI フレームワーク | SwiftUI | macOS 15+ |
| 状態管理 | Observation framework (@Observable) | macOS 15+ |
| 並行性 | Swift Concurrency (async/await, AsyncThrowingStream) | Swift 6.0 |
| プロジェクト生成 | XcodeGen | latest |
| パッケージ管理 | Swift Package Manager (ローカル) | 6.0 |
| IDE | Xcode | 16.0+ |

## 2. 外部依存パッケージ一覧

### 2.1 no-problem 製パッケージ

| パッケージ | 用途 | 割り当て先 | 主要 API |
|-----------|------|-----------|---------|
| **swift-agent-sdk** | Claude Code SDK 連携 | Infrastructure | `AgentSDK.createSession()`, `session.send()`, `AgentMessage` |
| **swift-markdown-view** | Markdown + シンタックスハイライト | Presentation | `MarkdownView(source:)` |
| **swift-design-system** | テーマ・UI コンポーネント | Presentation | `ThemeProvider`, `Card`, カラーパレット |
| **swift-ui-routing** | ナビゲーション・モーダル管理 | Presentation | `SplitViewPresenter`, `SheetPresenter`, `AlertPresenter` |

### 2.2 swift-statable の判断

| 項目 | 判断 |
|------|------|
| パッケージ | swift-statable (`@Statable` マクロ) |
| 判断 | **実装時に判断**。手動 `@Observable` + `isProcessing` フラグで十分な可能性が高い |
| 理由 | SessionState の非同期処理管理は手動でシンプルに実装可能。マクロの恩恵が限定的 |

## 3. 外部依存割り当て表

```
┌─────────────────────────────────────────────────────┐
│                    App ターゲット                      │
│  DI ワイヤリング / エントリポイント / entitlements      │
│  依存: Domain + Infrastructure + Presentation        │
└───────────┬──────────────┬──────────────┬───────────┘
            │              │              │
┌───────────▼──────┐ ┌────▼──────────────▼───────────┐
│  Infrastructure   │ │  Presentation                  │
│                   │ │                                │
│  swift-agent-sdk  │ │  swift-markdown-view           │
│  (AgentSDK        │ │  swift-design-system           │
│   ClaudeCode)     │ │  swift-ui-routing              │
│                   │ │                                │
│  依存: Domain     │ │  依存: Domain                  │
└───────────┬──────┘ └────────────────┬──────────────┘
            │                          │
            └──────────┬───────────────┘
                       │
            ┌──────────▼──────────┐
            │  Domain              │
            │                      │
            │  外部依存: なし       │
            │  (Foundation のみ)   │
            └─────────────────────┘
```

## 4. 依存パッケージ参照方法

| パッケージ | 参照方法 | 場所 |
|-----------|---------|------|
| swift-agent-sdk | ローカルパス (`../../../../`) | Infrastructure/Package.swift |
| swift-markdown-view | GitHub URL (from: "1.0.0") | Presentation/Package.swift |
| swift-design-system | GitHub URL (from: "1.0.0") | Presentation/Package.swift |
| swift-ui-routing | GitHub URL (from: "1.0.0") | Presentation/Package.swift |
| Domain | ローカルパス (`../Domain`) | Infrastructure, Presentation の Package.swift |

> **注意**: swift-agent-sdk のパスは `SampleApp/ClaudeAgent/Packages/Infrastructure/` から
> `swift-agent-sdk/` のルートへの相対パス。実際の深さに応じて調整。

## 5. ビルドツールチェーン

| ツール | 用途 | 備考 |
|-------|------|------|
| XcodeGen | project.yml → .xcodeproj 生成 | `brew install xcodegen` |
| xcodebuild | 統合ビルド | App ターゲットのビルド |
| swift build | パッケージ単体ビルド | `--package-path` で各パッケージを個別ビルド |
| swift test | パッケージ単体テスト | `--package-path` で各パッケージを個別テスト |

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
