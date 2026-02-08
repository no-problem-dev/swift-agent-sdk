import SwiftUI
import Combine
import Domain
import DesignSystem

/// アプリのルートビュー
public struct ContentView: View {
    @Bindable var appState: AppState
    @State private var showingNewSession = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            SessionSidebar(appState: appState, showingNewSession: $showingNewSession)
        } detail: {
            if let session = appState.activeSession {
                ChatView(session: session)
            } else {
                EmptySessionView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if let session = appState.activeSession {
                    HStack(spacing: 8) {
                        Text(session.config.model.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if session.totalCostUsd > 0 {
                            Text(String(format: "$%.4f", session.totalCostUsd))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            NewSessionSheet(appState: appState)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewSessionSheet)) { _ in
            showingNewSession = true
        }
    }
}

extension Notification.Name {
    public static let showNewSessionSheet = Notification.Name("showNewSessionSheet")
}
