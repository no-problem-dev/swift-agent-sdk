import SwiftUI

/// セッション一覧サイドバー
struct SessionSidebar: View {
    @Bindable var appState: AppState
    @Binding var showingNewSession: Bool

    var body: some View {
        List(selection: $appState.activeSessionId) {
            ForEach(appState.sortedSessions) { session in
                SessionRow(session: session)
                    .tag(session.id)
                    .contextMenu {
                        if session.status == .connected {
                            Button("セッションを終了") {
                                Task { await session.disconnect() }
                            }
                        } else {
                            Button("再接続") {
                                Task { try? await session.reconnect() }
                            }
                        }
                        Divider()
                        Button("削除", role: .destructive) {
                            appState.deleteSession(id: session.id)
                        }
                    }
            }
        }
        .navigationTitle("セッション")
        .toolbar {
            ToolbarItem {
                Button {
                    showingNewSession = true
                } label: {
                    Image(systemName: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
