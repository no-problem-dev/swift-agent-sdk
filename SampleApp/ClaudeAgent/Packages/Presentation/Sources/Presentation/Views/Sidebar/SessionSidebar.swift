import SwiftUI
import DesignSystem

/// セッション一覧サイドバー
struct SessionSidebar: View {
    @Bindable var appState: AppState
    @Binding var showingNewSession: Bool
    @State private var searchText = ""
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        Group {
            if appState.sessions.isEmpty {
                emptySidebar
            } else {
                sessionList
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
                .accessibilityLabel("新規セッション")
            }
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
        List(selection: $appState.activeSessionId) {
            if !searchText.isEmpty {
                // Search results
                ForEach(filteredSessions) { session in
                    sessionRowItem(session)
                }
            } else {
                // Grouped by date
                let grouped = groupedSessions
                ForEach(grouped.keys.sorted(), id: \.self) { group in
                    Section(group) {
                        ForEach(grouped[group] ?? []) { session in
                            sessionRowItem(session)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "セッションを検索")
    }

    private func sessionRowItem(_ session: SessionState) -> some View {
        SessionRow(session: session)
            .tag(session.id)
            .contextMenu {
                if session.status == .connected {
                    Button {
                        Task { await session.disconnect() }
                    } label: {
                        Label("セッションを終了", systemImage: "stop.circle")
                    }
                } else if session.status == .disconnected || session.status == .error {
                    Button {
                        Task { try? await session.reconnect() }
                    } label: {
                        Label("再接続", systemImage: "arrow.clockwise")
                    }
                }
                Divider()
                Button(role: .destructive) {
                    appState.deleteSession(id: session.id)
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
    }

    // MARK: - Empty State

    private var emptySidebar: some View {
        VStack(spacing: spacing.md) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32))
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.3))
            Text("セッションなし")
                .typography(.bodyMedium)
                .foregroundStyle(colors.onSurfaceVariant.opacity(0.5))
            Button {
                showingNewSession = true
            } label: {
                Label("新規作成", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filtering & Grouping

    private var filteredSessions: [SessionState] {
        let sorted = appState.sortedSessions
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { session in
            session.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedSessions: [String: [SessionState]] {
        let calendar = Calendar.current
        var groups: [String: [SessionState]] = [:]
        for session in appState.sortedSessions {
            let key: String
            if calendar.isDateInToday(session.lastActiveAt) {
                key = "今日"
            } else if calendar.isDateInYesterday(session.lastActiveAt) {
                key = "昨日"
            } else {
                key = "それ以前"
            }
            groups[key, default: []].append(session)
        }
        return groups
    }
}
