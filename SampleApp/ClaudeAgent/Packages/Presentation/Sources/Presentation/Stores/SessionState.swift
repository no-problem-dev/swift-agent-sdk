import Foundation
import Domain

/// 個別セッションの状態管理
@MainActor @Observable
public final class SessionState: Identifiable {
    public let id: String
    public let config: SessionConfig
    public let createdAt: Date

    public private(set) var messages: [ChatMessage] = []
    public var status: SessionStatus = .disconnected
    public private(set) var streamingText: String = ""
    public internal(set) var isProcessing: Bool = false
    public private(set) var totalCostUsd: Double = 0
    public private(set) var lastTokenUsage: TokenUsage?
    public var lastActiveAt: Date

    public var displayName: String {
        config.name ?? messages.first?.textPreview ?? "New Session"
    }

    private let agentService: any AgentServiceProtocol
    private var streamTask: Task<Void, Never>?

    public init(
        id: String,
        config: SessionConfig,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        messages: [ChatMessage] = [],
        totalCostUsd: Double = 0,
        agentService: any AgentServiceProtocol
    ) {
        self.id = id
        self.config = config
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.messages = messages
        self.totalCostUsd = totalCostUsd
        self.agentService = agentService
    }

    // MARK: - Actions

    public func send(_ message: String) async {
        let userMessage = ChatMessage(role: .user, content: [.text(message)])
        messages.append(userMessage)
        isProcessing = true

        do {
            let stream = try await agentService.send(sessionId: id, message: message)
            await processStream(stream)
        } catch {
            status = .error
            isProcessing = false
        }
    }

    public func interrupt() async {
        streamTask?.cancel()
        try? await agentService.interrupt(sessionId: id)
        isProcessing = false
        streamingText = ""
    }

    public func reconnect() async throws {
        status = .connecting
        do {
            let stream = try await agentService.resumeSession(id: id, config: config)
            status = .connected
            await processStream(stream)
        } catch {
            status = .error
            throw error
        }
    }

    public func disconnect() async {
        streamTask?.cancel()
        try? await agentService.close(sessionId: id)
        status = .disconnected
    }

    public func setModel(_ model: ModelSelection) async throws {
        try await agentService.setModel(sessionId: id, model: model)
    }

    // MARK: - Internal

    func processStream(_ stream: AsyncThrowingStream<AgentEvent, Error>) async {
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            do {
                for try await event in stream {
                    guard let self, !Task.isCancelled else { break }
                    switch event {
                    case .initialized:
                        break
                    case .partialText(let text):
                        self.streamingText = text
                    case .assistantMessage(let content):
                        self.messages.append(ChatMessage(role: .assistant, content: content))
                        self.streamingText = ""
                    case .turnCompleted(let cost, let input, let output):
                        self.totalCostUsd += cost
                        self.lastTokenUsage = TokenUsage(inputTokens: input, outputTokens: output)
                        self.isProcessing = false
                        self.lastActiveAt = Date()
                    }
                }
            } catch {
                guard let self else { return }
                self.isProcessing = false
                if !Task.isCancelled {
                    self.status = .error
                }
            }
        }
        await streamTask?.value
    }

    func toSessionData() -> SessionData {
        SessionData(
            id: id,
            config: config,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt,
            messages: messages,
            totalCostUsd: totalCostUsd
        )
    }
}
