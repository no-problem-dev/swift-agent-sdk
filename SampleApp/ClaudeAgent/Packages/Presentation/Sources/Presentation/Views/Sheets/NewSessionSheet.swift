import SwiftUI
import AppKit
import Domain
import DesignSystem

/// 新規セッション作成シート
struct NewSessionSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    @State private var workingDirectory = ""
    @State private var model: ModelSelection = .sonnet
    @State private var systemPrompt = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("新規セッション")
                    .typography(.titleMedium)
                    .foregroundStyle(colors.onSurface)
                Spacer()
            }
            .padding(.horizontal, spacing.xl)
            .padding(.top, spacing.xl)
            .padding(.bottom, spacing.md)

            Divider().foregroundStyle(colors.outlineVariant.opacity(0.3))

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.xl) {
                    // Working directory
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        Text("作業ディレクトリ")
                            .typography(.labelLarge)
                            .foregroundStyle(colors.onSurface)
                        HStack(spacing: spacing.sm) {
                            TextField("パスを入力", text: $workingDirectory)
                                .textFieldStyle(.roundedBorder)
                            Button("選択...") { selectDirectory() }
                                .controlSize(.regular)
                        }
                        if !workingDirectory.isEmpty && !FileManager.default.fileExists(atPath: workingDirectory) {
                            Label("指定されたパスが存在しません", systemImage: "exclamationmark.triangle")
                                .typography(.labelSmall)
                                .foregroundStyle(colors.error)
                        }
                    }

                    // Model selection
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        Text("モデル")
                            .typography(.labelLarge)
                            .foregroundStyle(colors.onSurface)
                        Picker("モデル", selection: $model) {
                            ForEach(ModelSelection.allCases, id: \.self) { m in
                                Text(m.displayName).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text(modelDescription)
                            .typography(.labelSmall)
                            .foregroundStyle(colors.onSurfaceVariant.opacity(0.6))
                    }

                    // System prompt
                    VStack(alignment: .leading, spacing: spacing.sm) {
                        HStack {
                            Text("システムプロンプト")
                                .typography(.labelLarge)
                                .foregroundStyle(colors.onSurface)
                            Text("(任意)")
                                .typography(.labelSmall)
                                .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))
                        }
                        TextEditor(text: $systemPrompt)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80, maxHeight: 120)
                            .padding(spacing.sm)
                            .background(colors.surfaceVariant.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: radius.md)
                                    .stroke(colors.outlineVariant.opacity(0.3), lineWidth: 0.5)
                            )
                    }

                    // Error
                    if let errorMessage {
                        HStack(spacing: spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(colors.error)
                            Text(errorMessage)
                                .typography(.bodySmall)
                                .foregroundStyle(colors.error)
                        }
                        .padding(spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.errorContainer.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: radius.md))
                    }
                }
                .padding(.horizontal, spacing.xl)
                .padding(.vertical, spacing.lg)
            }

            Divider().foregroundStyle(colors.outlineVariant.opacity(0.3))

            // Actions
            HStack {
                Button("キャンセル") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                if isCreating {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("作成") { createSession() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(workingDirectory.isEmpty || isCreating)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, spacing.xl)
            .padding(.vertical, spacing.md)
        }
        .frame(width: 500, height: 440)
        .background(colors.surface)
    }

    private var modelDescription: String {
        switch model {
        case .opus: "最も高性能。複雑な推論や分析に最適"
        case .sonnet: "バランスの良い性能。日常的なタスクに推奨"
        case .haiku: "最速・低コスト。シンプルなタスクに最適"
        }
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "作業ディレクトリを選択してください"
        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
        }
    }

    private func createSession() {
        isCreating = true
        errorMessage = nil
        let config = SessionConfig(
            model: model,
            workingDirectory: workingDirectory,
            systemPrompt: systemPrompt.isEmpty ? nil : systemPrompt
        )
        Task {
            do {
                try await appState.createSession(config: config)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}
