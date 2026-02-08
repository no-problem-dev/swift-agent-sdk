import SwiftUI
import Domain
import Infrastructure
import Presentation

@main
struct ClaudeAgentApp: App {
    @State private var appState: AppState

    init() {
        let agentService = ServiceFactory.makeAgentService()
        let sessionStore = ServiceFactory.makeSessionStore()

        _appState = State(initialValue: AppState(
            agentService: agentService,
            sessionStore: sessionStore
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    appState.loadSavedSessions()
                    registerTerminationHandler()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Session") {
                    NotificationCenter.default.post(
                        name: .showNewSessionSheet, object: nil
                    )
                }
                .keyboardShortcut("n")
            }
        }
    }

    private func registerTerminationHandler() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            appState.saveAllSessions()
        }
    }
}
