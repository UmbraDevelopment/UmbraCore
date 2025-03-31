import Foundation
import XPC

/// A protocol that defines the requirements for XPC communication.
///
/// This protocol provides a type-safe interface for establishing XPC connections
/// and sending messages between processes. It handles connection lifecycle
/// and message delivery with proper error handling.
///
/// Example:
/// ```swift
/// class MyXPCService: XPCConnectionProtocol {
///     let endpoint = "com.example.xpc-service"
///
///     func connect() async throws {
///         // Establish connection
///     }
///
///     func send(_ message: [String: Any], replyHandler: ((xpc_object_t) -> Void)?) {
///         // Send message
///     }
/// }
/// ```
public protocol XPCConnectionProtocol: Sendable {
  /// The unique identifier for the XPC endpoint.
  ///
  /// This should be a reverse-DNS style identifier that uniquely
  /// identifies the XPC service (e.g., "com.example.service").
  var endpoint: String { get }

  /// Establishes a connection to the XPC service.
  ///
  /// This method should be called before attempting to send any messages.
  /// It sets up the connection and performs any necessary authentication.
  ///
  /// - Throws: `XPCError.connectionFailed` if the connection cannot be
  ///           established or if authentication fails.
  func connect() async throws

  /// Gracefully closes the XPC connection.
  ///
  /// This method should clean up any resources and ensure all pending
  /// messages are properly handled before disconnecting.
  func disconnect()

  /// Sends a message to the XPC service.
  ///
  /// - Parameters:
  ///   - message: A dictionary containing the message payload. All values
  ///             must be XPC-compatible types.
  ///   - replyHandler: An optional closure to handle the service's response.
  ///                   The handler receives the raw XPC object containing
  ///                   the reply.
  func send(_ message: [String: Any], replyHandler: ((xpc_object_t) -> Void)?)
}

/// Errors that can occur during XPC operations.
///
/// This enum provides specific error cases for different types of
/// failures that can occur when working with XPC services.
public enum XPCConnectionError: LocalizedError, Sendable {
  /// The connection to the XPC service failed.
  ///
  /// - Parameter reason: A description of why the connection failed.
  case connectionFailed(String)

  /// Failed to send a message over the XPC connection.
  ///
  /// - Parameter reason: A description of why the message failed.
  case messageFailed(String)

  /// The message format is invalid for XPC transmission.
  ///
  /// - Parameter reason: A description of what made the message invalid.
  case invalidMessage(String)

  /// The request is invalid.
  ///
  /// - Parameter message: A description of why the request is invalid.
  case invalidRequest(message: String)

  /// The data is invalid.
  ///
  /// - Parameter message: A description of why the data is invalid.
  case invalidData(message: String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
      case let .connectionFailed(reason):
        "XPC connection failed: \(reason)"
      case let .messageFailed(reason):
        "Failed to send XPC message: \(reason)"
      case let .invalidMessage(reason):
        "Invalid XPC message format: \(reason)"
      case let .invalidRequest(message):
        "XPC invalid request: \(message)"
      case let .invalidData(message):
        "XPC invalid data: \(message)"
    }
  }
}
