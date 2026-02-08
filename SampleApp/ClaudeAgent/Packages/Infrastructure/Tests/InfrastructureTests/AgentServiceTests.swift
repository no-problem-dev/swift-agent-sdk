import Foundation
import Testing
import AgentSDK
import AgentSDKClaudeCode
import AgentSDKTesting
import Domain
@testable import Infrastructure

@Suite(.serialized)
struct AgentServiceTests {

    private func makeService(
        transport: MockTransport = MockTransport()
    ) -> AgentService<MockTransport> {
        let client = ClaudeCodeClient(transport: transport)
        return AgentService(client: client)
    }

    // MARK: - Session Not Found

    @Test func sendWithUnknownSessionThrowsNotConnected() async {
        let service = makeService()
        do {
            _ = try await service.send(sessionId: "non-existent", message: "hello")
            Issue.record("Expected error to be thrown")
        } catch let error as AppError {
            guard case .notConnected = error else {
                Issue.record("Expected .notConnected, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    @Test func interruptWithUnknownSessionThrowsNotConnected() async {
        let service = makeService()
        do {
            try await service.interrupt(sessionId: "non-existent")
            Issue.record("Expected error to be thrown")
        } catch let error as AppError {
            guard case .notConnected = error else {
                Issue.record("Expected .notConnected, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    @Test func closeWithUnknownSessionThrowsNotConnected() async {
        let service = makeService()
        do {
            try await service.close(sessionId: "non-existent")
            Issue.record("Expected error to be thrown")
        } catch let error as AppError {
            guard case .notConnected = error else {
                Issue.record("Expected .notConnected, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    @Test func setModelWithUnknownSessionThrowsNotConnected() async {
        let service = makeService()
        do {
            try await service.setModel(sessionId: "non-existent", model: .opus)
            Issue.record("Expected error to be thrown")
        } catch let error as AppError {
            guard case .notConnected = error else {
                Issue.record("Expected .notConnected, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    // MARK: - ModelSelection SDK Mapping

    @Test func modelSelectionSdkValueMapsToCorrectSdkEnum() {
        #expect(Domain.ModelSelection.opus.sdkValue == .opus)
        #expect(Domain.ModelSelection.sonnet.sdkValue == .sonnet)
        #expect(Domain.ModelSelection.haiku.sdkValue == .haiku)
    }

    // MARK: - Error Mapping

    @Test func createSessionWithDisconnectedTransportMapsError() async {
        let transport = MockTransport()
        transport.simulatedIsReady = false
        let service = makeService(transport: transport)

        let config = SessionConfig(model: .sonnet, workingDirectory: "/tmp")
        do {
            _ = try await service.createSession(config: config)
            Issue.record("Expected error to be thrown")
        } catch let error as AppError {
            // MockTransport throws notConnected when simulatedIsReady is false
            guard case .notConnected = error else {
                Issue.record("Expected .notConnected, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }

    @Test func resumeSessionWithDisconnectedTransportMapsError() async {
        let transport = MockTransport()
        transport.simulatedIsReady = false
        let service = makeService(transport: transport)

        let config = SessionConfig(model: .sonnet, workingDirectory: "/tmp")
        do {
            _ = try await service.resumeSession(id: "sess-1", config: config)
            Issue.record("Expected error to be thrown")
        } catch let error as AppError {
            guard case .notConnected = error else {
                Issue.record("Expected .notConnected, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected AppError, got \(error)")
        }
    }
}
