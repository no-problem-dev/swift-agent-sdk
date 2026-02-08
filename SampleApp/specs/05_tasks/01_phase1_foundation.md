---
title: "ClaudeAgent - Phase 1: プロジェクト基盤構築タスク"
created: 2026-02-08
status: draft
tags: [tasks, phase1, claude-agent]
references:
  - ../04_implementation_plan/03_phase1_foundation.md
  - ../03_design_spec/01_architecture.md
  - ../03_design_spec/03_layer_architecture.md
---

# Phase 1: プロジェクト基盤構築 (T1-T5)

## Wave 1-1: ディレクトリ構造 + project.yml + Makefile

---

## T1: Initialize プロジェクト構造セットアップ

- description:
  - XcodeGen + ローカル SPM パッケージ構成でプロジェクトの骨格を作成する
  - ディレクトリ構造、project.yml、Makefile、.gitignore、Assets.xcassets を作成する
  - 完了時: ディレクトリ構造が Design Spec と一致し、project.yml が構文的に正しい状態

- spec_refs:
  - specs/04_implementation_plan/03_phase1_foundation.md#Wave-1-1
  - specs/03_design_spec/01_architecture.md#プロジェクト構成
  - specs/03_design_spec/01_architecture.md#project-yml
  - specs/03_design_spec/01_architecture.md#Makefile

- agent:
  - general-purpose

- deps:
  - none

- files:
  - create: SampleApp/ClaudeAgent/project.yml
  - create: SampleApp/ClaudeAgent/Makefile
  - create: SampleApp/ClaudeAgent/.gitignore
  - create: SampleApp/ClaudeAgent/Packages/Domain/.gitkeep
  - create: SampleApp/ClaudeAgent/Packages/Infrastructure/.gitkeep
  - create: SampleApp/ClaudeAgent/Packages/Presentation/.gitkeep
  - create: SampleApp/ClaudeAgent/App/Sources/.gitkeep
  - create: SampleApp/ClaudeAgent/Resources/Assets.xcassets/Contents.json
  - create: SampleApp/ClaudeAgent/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json

- unit_test:
  - required: false

- verification:
  - [ ] ディレクトリ構造が Design Spec と一致する
  - [ ] project.yml が `specs/03_design_spec/01_architecture.md#project-yml` の定義に準拠
  - [ ] Makefile に generate, build, test, clean ターゲットが定義されている
  - [ ] .gitignore に `*.xcodeproj`, `.build/`, `DerivedData/` が含まれている

---

## Wave 1-2: Package.swift 作成 + 依存解決

---

## T2: Configure Domain Package.swift

- description:
  - Domain パッケージの Package.swift とプレースホルダーファイルを作成する
  - 外部依存なし、Foundation のみ
  - 完了時: `swift build --package-path Packages/Domain` が成功する状態

- spec_refs:
  - specs/04_implementation_plan/03_phase1_foundation.md#Wave-1-2
  - specs/03_design_spec/03_layer_architecture.md#Domain-Package-swift

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: SampleApp/ClaudeAgent/Packages/Domain/Package.swift
  - create: SampleApp/ClaudeAgent/Packages/Domain/Sources/Domain/Placeholder.swift
  - create: SampleApp/ClaudeAgent/Packages/Domain/Tests/DomainTests/PlaceholderTests.swift

- unit_test:
  - required: false

- verification:
  - [ ] `swift build --package-path Packages/Domain` 成功
  - [ ] `swift test --package-path Packages/Domain` 成功
  - [ ] Package.swift が `specs/03_design_spec/03_layer_architecture.md` に準拠

---

## T3: Configure Infrastructure Package.swift

- description:
  - Infrastructure パッケージの Package.swift とプレースホルダーファイルを作成する
  - 依存: Domain（ローカルパス `../Domain`）、swift-agent-sdk（ローカルパス `../../../../`）
  - 完了時: `swift build --package-path Packages/Infrastructure` が成功する状態

- spec_refs:
  - specs/04_implementation_plan/03_phase1_foundation.md#Wave-1-2
  - specs/03_design_spec/03_layer_architecture.md#Infrastructure-Package-swift

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: SampleApp/ClaudeAgent/Packages/Infrastructure/Package.swift
  - create: SampleApp/ClaudeAgent/Packages/Infrastructure/Sources/Infrastructure/Placeholder.swift
  - create: SampleApp/ClaudeAgent/Packages/Infrastructure/Tests/InfrastructureTests/PlaceholderTests.swift

- unit_test:
  - required: false

- verification:
  - [ ] `swift build --package-path Packages/Infrastructure` 成功
  - [ ] swift-agent-sdk のローカルパス参照が正しく解決される
  - [ ] AgentSDKClaudeCode, AgentSDKTesting の product 名が正しい

---

## T4: Configure Presentation Package.swift

- description:
  - Presentation パッケージの Package.swift とプレースホルダーファイルを作成する
  - 依存: Domain, swift-markdown-view, swift-design-system, swift-ui-routing
  - 完了時: `swift build --package-path Packages/Presentation` が成功する状態

- spec_refs:
  - specs/04_implementation_plan/03_phase1_foundation.md#Wave-1-2
  - specs/03_design_spec/03_layer_architecture.md#Presentation-Package-swift

- agent:
  - general-purpose

- deps:
  - T1

- files:
  - create: SampleApp/ClaudeAgent/Packages/Presentation/Package.swift
  - create: SampleApp/ClaudeAgent/Packages/Presentation/Sources/Presentation/Placeholder.swift
  - create: SampleApp/ClaudeAgent/Packages/Presentation/Tests/PresentationTests/PlaceholderTests.swift

- unit_test:
  - required: false

- verification:
  - [ ] `swift build --package-path Packages/Presentation` 成功
  - [ ] GitHub URL での依存解決が成功する
  - [ ] MarkdownView, DesignSystem, UIRouting が解決される

---

## Wave 1-3: App ターゲット + エントリポイント + ビルド確認

---

## T5: Implement App エントリポイント + 統合ビルド

- description:
  - ClaudeAgentApp.swift のエントリポイントを作成する
  - `xcodegen generate` で .xcodeproj を生成し、`xcodebuild build` で統合ビルドを確認する
  - DI ワイヤリングは Phase 5 で実装。この時点では最小限の Text 表示のみ
  - 完了時: アプリが起動し「ClaudeAgent」テキストが表示される状態

- spec_refs:
  - specs/04_implementation_plan/03_phase1_foundation.md#Wave-1-3
  - specs/03_design_spec/03_layer_architecture.md#App-ターゲット

- agent:
  - general-purpose

- deps:
  - T2
  - T3
  - T4

- files:
  - create: SampleApp/ClaudeAgent/App/Sources/ClaudeAgentApp.swift
  - modify: SampleApp/ClaudeAgent/project.yml

- unit_test:
  - required: false

- verification:
  - [ ] `xcodegen generate` がエラーなく完了
  - [ ] `xcodebuild build -project ClaudeAgent.xcodeproj -scheme ClaudeAgent -destination 'platform=macOS'` 成功
  - [ ] アプリが起動し「ClaudeAgent」テキストが表示される

## 更新履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-02-08 | 初版作成 |
