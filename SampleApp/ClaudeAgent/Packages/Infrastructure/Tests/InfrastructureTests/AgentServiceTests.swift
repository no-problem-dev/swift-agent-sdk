import Foundation
import Testing
import AgentSDK
import AgentSDKClaudeCode
import AgentSDKTesting
import Domain
@testable import Infrastructure

@Suite(.serialized)
struct AgentServiceTests {

    private func makeService() -> AgentService {
        AgentService()
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
}
