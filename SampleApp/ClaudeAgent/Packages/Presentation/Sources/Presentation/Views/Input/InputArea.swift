import SwiftUI
import Domain

/// メッセージ入力エリア
struct InputArea: View {
    @Bindable var session: SessionState
    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 36, maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
                .focused($isFocused)
                .onKeyPress(.return, phases: .down) { keyPress in
                    if keyPress.modifiers.contains(.shift) {
                        return .ignored
                    }
                    sendMessage()
                    return .handled
                }

            if session.isProcessing {
                Button {
                    Task { await session.interrupt() }
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            } else {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(cannotSend)
            }
        }
        .padding()
    }

    private var cannotSend: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || session.status != .connected
    }

    private func sendMessage() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, session.status == .connected else { return }
        let message = trimmed
        text = ""
        Task { await session.send(message) }
    }
}
