import Foundation
import AgentSDK

/// Manages the lifecycle of a CLI subprocess.
internal actor CLIProcess {

    enum State: Sendable {
        case idle
        case starting
        case running
        case terminating
        case terminated(exitCode: Int32)
        case failed(Error)
    }

    private(set) var state: State = .idle
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var stderrData: Data = Data()

    /// Start the CLI process.
    ///
    /// - Parameters:
    ///   - executable: Path to the JS runtime (e.g., /usr/bin/node)
    ///   - arguments: CLI arguments including the cli.js path
    ///   - environment: Environment variables
    ///   - cwd: Working directory
    func start(
        executable: URL,
        arguments: [String],
        environment: [String: String]? = nil,
        cwd: String? = nil
    ) throws {
        guard case .idle = state else {
            throw AgentSDKError.processLaunchFailed(
                underlying: NSError(domain: "CLIProcess", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Process already started"])
            )
        }

        state = .starting

        let proc = Process()
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()

        proc.executableURL = executable
        proc.arguments = arguments
        proc.standardInput = stdin
        proc.standardOutput = stdout
        proc.standardError = stderr

        if let env = environment {
            proc.environment = ProcessInfo.processInfo.environment.merging(env) { _, new in new }
        }

        if let cwd {
            proc.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }

        // Capture stderr asynchronously
        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { [weak self] in
                await self?.appendStderr(data)
            }
        }

        proc.terminationHandler = { [weak self] proc in
            Task { [weak self] in
                await self?.handleTermination(exitCode: proc.terminationStatus)
            }
        }

        do {
            try proc.run()
        } catch {
            state = .failed(error)
            throw AgentSDKError.processLaunchFailed(underlying: error)
        }

        self.process = proc
        self.stdinPipe = stdin
        self.stdoutPipe = stdout
        self.stderrPipe = stderr
        self.state = .running
    }

    /// Write data to stdin.
    func writeToStdin(_ data: Data) async throws {
        guard case .running = state, let pipe = stdinPipe else {
            throw AgentSDKError.notConnected
        }
        pipe.fileHandleForWriting.write(data)
    }

    /// Close stdin pipe. Useful for signaling EOF to processes like cat.
    func closeStdin() throws {
        guard let pipe = stdinPipe else {
            throw AgentSDKError.notConnected
        }
        try pipe.fileHandleForWriting.close()
    }

    /// Return an async stream of stdout lines (newline-delimited Data).
    func stdoutStream() -> AsyncThrowingStream<Data, Error> {
        guard let pipe = stdoutPipe else {
            return AsyncThrowingStream { $0.finish(throwing: AgentSDKError.notConnected) }
        }

        let fileHandle = pipe.fileHandleForReading

        return AsyncThrowingStream { continuation in
            // Read stdout line by line
            Task {
                var buffer = Data()
                let newline = UInt8(0x0A) // '\n'

                while true {
                    let chunk = fileHandle.availableData
                    if chunk.isEmpty {
                        // EOF - yield remaining buffer if non-empty
                        if !buffer.isEmpty {
                            continuation.yield(buffer)
                        }
                        continuation.finish()
                        break
                    }

                    buffer.append(chunk)

                    // Split by newlines
                    while let newlineIndex = buffer.firstIndex(of: newline) {
                        let line = buffer[buffer.startIndex...newlineIndex]
                        continuation.yield(Data(line))
                        buffer = Data(buffer[buffer.index(after: newlineIndex)...])
                    }
                }
            }
        }
    }

    /// Get accumulated stderr content.
    func stderrContent() -> String {
        String(data: stderrData, encoding: .utf8) ?? ""
    }

    /// Terminate the process. Sends SIGTERM, then SIGKILL after 5 seconds.
    func terminate() async {
        guard case .running = state, let proc = process else { return }
        state = .terminating
        proc.terminate() // SIGTERM

        // Wait up to 5 seconds, then SIGKILL
        Task {
            try? await Task.sleep(for: .seconds(5))
            if proc.isRunning {
                kill(proc.processIdentifier, SIGKILL)
            }
        }
    }

    /// Wait for process exit and return exit code.
    func waitForExit() async -> Int32 {
        guard let proc = process else { return -1 }
        proc.waitUntilExit()
        return proc.terminationStatus
    }

    // MARK: - Private

    private func appendStderr(_ data: Data) {
        stderrData.append(data)
    }

    private func handleTermination(exitCode: Int32) {
        if case .terminating = state {
            state = .terminated(exitCode: exitCode)
        } else {
            state = .terminated(exitCode: exitCode)
        }
        // Clean up
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
    }
}
