import SwiftUI
import AppKit
import Domain

/// 新規セッション作成シート
struct NewSessionSheet: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var workingDirectory = ""
    @State private var model: ModelSelection = .sonnet
    @State private var systemPrompt = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("作業ディレクトリ") {
                    HStack {
                        TextField("パスを入力", text: $workingDirectory)
                            .textFieldStyle(.roundedBorder)
                        Button("選択...") { selectDirectory() }
                    }
                }

                Section("モデル") {
                    Picker("モデル", selection: $model) {
                        ForEach(ModelSelection.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("システムプロンプト（任意）") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 80)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            Divider()

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
            }
            .padding()
        }
        .frame(width: 480, height: 400)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
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
