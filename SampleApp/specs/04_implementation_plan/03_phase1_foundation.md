---
title: "ClaudeAgent - Phase 1: プロジェクト基盤構築"
created: 2026-02-08
status: draft
tags: [implementation-plan, phase1, claude-agent]
references:
  - ./00_index.md
  - ./01_phase_overview.md
  - ../03_design_spec/01_architecture.md#プロジェクト構成
  - ../03_design_spec/01_architecture.md#project-yml
  - ../03_design_spec/02_tech_stack.md
---

# Phase 1: プロジェクト基盤構築

## 目的

XcodeGen + ローカル SPM パッケージ構成でプロジェクトの骨格を作成する。
全パッケージが空の状態でコンパイル成功し、App ターゲットが起動することを確認する。

## 前提

- なし（最初の Phase）

---

## Wave 1-1: ディレクトリ構造 + project.yml + Makefile

### 実装内容

1. ディレクトリ構造を作成する

```
SampleApp/ClaudeAgent/
├── project.yml
├── Makefile
├── .gitignore
├── Packages/
│   ├── Domain/
│   ├── Infrastructure/
│   └── Presentation/
├── App/
│   └── Sources/
└── Resources/
    └── Assets.xcassets
```

2. `project.yml` を作成する
   - `specs/03_design_spec/01_architecture.md#project-yml` の定義に準拠する
   - `localPackages` で 3 パッケージを参照する
   - `entitlements.properties` で App Sandbox を無効化する

3. `Makefile` を作成する
   - `specs/03_design_spec/01_architecture.md#Makefile` の定義に準拠する
   - `generate`, `build`, `test`, `clean` ターゲットを定義する

4. `.gitignore` を作成する
   - `*.xcodeproj` を除外（XcodeGen 生成物）
   - `.build/`, `DerivedData/` を除外

5. `Assets.xcassets` にアプリアイコン用プレースホルダーを配置する

### 完了基準

- [ ] ディレクトリ構造が Design Spec と一致する
- [ ] `project.yml` が構文的に正しい（`xcodegen generate` 前に lint 可能な状態）

---

## Wave 1-2: Package.swift 作成 + 依存解決

### 実装内容（並列実行可能）

#### Domain/Package.swift

- `specs/03_design_spec/03_layer_architecture.md#Domain-Package-swift` に準拠
- 外部依存なし
- Sources/Domain/ と Tests/DomainTests/ に空のプレースホルダーファイルを配置

#### Infrastructure/Package.swift

- `specs/03_design_spec/03_layer_architecture.md#Infrastructure-Package-swift` に準拠
- 依存: Domain（ローカルパス `../Domain`）、swift-agent-sdk（ローカルパス `../../../../`）
- AgentSDKClaudeCode, AgentSDKTesting の product 名を正しく指定

#### Presentation/Package.swift

- `specs/03_design_spec/03_layer_architecture.md#Presentation-Package-swift` に準拠
- 依存: Domain, swift-markdown-view, swift-design-system, swift-ui-routing
- GitHub URL + `from: "1.0.0"` で参照

#### プレースホルダーファイル

各パッケージに空の `.swift` ファイルを配置してコンパイルを通す:
- `Sources/{Package}/Placeholder.swift` — `// This file ensures the target compiles`
- `Tests/{Package}Tests/PlaceholderTests.swift` — 空のテストケース

### 完了基準

- [ ] `swift build --package-path Packages/Domain` 成功
- [ ] `swift build --package-path Packages/Infrastructure` 成功（依存解決含む）
- [ ] `swift build --package-path Packages/Presentation` 成功（依存解決含む）
- [ ] swift-agent-sdk のローカルパス参照が正しく解決される

---

## Wave 1-3: App ターゲット + エントリポイント + ビルド確認

### 実装内容

1. `App/Sources/ClaudeAgentApp.swift` を作成する

```swift
import SwiftUI

@main
struct ClaudeAgentApp: App {
    var body: some Scene {
        WindowGroup {
            Text("ClaudeAgent")
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}
```

> DI ワイヤリングは Phase 5 で実装。この時点では最小限のエントリポイントのみ。

2. `xcodegen generate` を実行し `.xcodeproj` を生成する

3. `xcodebuild build` でアプリターゲットをビルドする

4. ビルドした `.app` を起動し、ウィンドウが表示されることを確認する

### 完了基準

- [ ] `xcodegen generate` がエラーなく完了
- [ ] `xcodebuild build -project ClaudeAgent.xcodeproj -scheme ClaudeAgent -destination 'platform=macOS'` 成功
- [ ] アプリが起動し「ClaudeAgent」テキストが表示される

### 検討事項

- swift-agent-sdk のローカルパス `../../../../` がリポジトリ構成に依存する。実際の深さを確認し必要に応じて調整する

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
