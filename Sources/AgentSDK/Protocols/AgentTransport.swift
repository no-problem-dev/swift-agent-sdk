import Foundation

/// Communication layer abstraction for backend-independent transport.
///
/// `AgentTransport` provides the low-level interface for establishing connections,
/// sending and receiving raw data, and managing the lifecycle of the transport layer.
/// Implementations handle the specific details of different backend protocols
/// (e.g., WebSocket, HTTP, stdio).
public protocol AgentTransport: Sendable {
    /// Establish connection to the backend.
    ///
    /// This method should initialize the underlying transport mechanism and prepare
    /// it for sending and receiving messages. It may throw if the connection cannot
    /// be established.
    ///
    /// - Throws: An error if the connection fails to establish.
    func connect() async throws

    /// Write raw data to the backend.
    ///
    /// Sends the provided data through the established transport channel.
    /// The format and encoding of the data is determined by the higher-level protocol.
    ///
    /// - Parameter message: The raw data to send to the backend.
    /// - Throws: An error if the write operation fails.
    func write(_ message: Data) async throws

    /// Stream of raw messages from the backend.
    ///
    /// Returns an asynchronous stream that yields data received from the backend.
    /// The stream will throw errors if the connection is interrupted or messages
    /// cannot be received.
    ///
    /// - Returns: An async throwing stream of raw message data.
    func messages() -> AsyncThrowingStream<Data, Error>

    /// Close the connection.
    ///
    /// Gracefully shuts down the transport layer and releases any associated resources.
    /// After calling this method, the transport should not be used for further communication.
    ///
    /// - Throws: An error if the connection cannot be closed cleanly.
    func close() async throws

    /// Whether the transport is connected and ready.
    ///
    /// This property indicates the current state of the transport connection.
    /// It should return `true` only when the transport is fully connected and
    /// ready to send and receive messages.
    var isReady: Bool { get async }
}
