import SwiftUI
import Combine
import Domain
import DesignSystem

/// アプリのルートビュー
public struct ContentView: View {
    @Bindable var appState: AppState
    @State private var showingNewSession = false
    @State private var snackbarState = SnackbarState()
    @Environment(\.colorPalette) private var colors
    @Environment(\.spacingScale) private var spacing

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ZStack {
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
                        HStack(spacing: spacing.sm) {
                            Text(session.config.model.displayName)
                                .typography(.labelSmall)
                                .foregroundStyle(colors.onSurfaceVariant)

                            if session.totalCostUsd > 0 {
                                Text(String(format: "$%.4f", session.totalCostUsd))
                                    .typography(.labelSmall)
                                    .foregroundStyle(colors.onSurfaceVariant.opacity(0.6))
                                    .padding(.horizontal, spacing.xs)
                                    .padding(.vertical, 1)
                                    .background(colors.surfaceVariant.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("モデル: \(session.config.model.displayName)" +
                            (session.totalCostUsd > 0 ? ", コスト: \(String(format: "$%.4f", session.totalCostUsd))" : ""))
                    }
                }
            }
            .sheet(isPresented: $showingNewSession) {
                NewSessionSheet(appState: appState)
            }
            .onReceive(NotificationCenter.default.publisher(for: .showNewSessionSheet)) { _ in
                showingNewSession = true
            }

            Snackbar(state: snackbarState)
        }
    }
}

extension Notification.Name {
    public static let showNewSessionSheet = Notification.Name("showNewSessionSheet")
}
