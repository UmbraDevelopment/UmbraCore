import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

// Use the Network namespace from NetworkErrorBase.swift
extension UmbraErrors.Network {
  /// Socket-specific network errors
  public enum Socket: Error, UmbraError, StandardErrorCapabilities {
    // Socket connection errors
    /// Failed to create socket
    case socketCreationFailed(reason: String)

    /// Failed to bind socket to address
    case bindFailed(address: String, port: Int, reason: String)

    /// Failed to listen on socket
    case listenFailed(reason: String)

    /// Failed to accept connection
    case acceptFailed(reason: String)

    /// Connection refused by remote host
    case connectionRefused(host: String, port: Int)

    /// Socket closed unexpectedly
    case socketClosed(reason: String)

    // Socket I/O errors
    /// Failed to read from socket
    case readFailed(reason: String)

    /// Failed to write to socket
    case writeFailed(reason: String)

    /// Socket operation timed out
    case timeout(operation: String, timeoutMs: Int)

    /// Socket address already in use
    case addressInUse(address: String, port: Int)

    /// Invalid socket option
    case invalidOption(option: String, reason: String)

    /// Socket buffer overflow
    case bufferOverflow(bufferSize: Int)

    // MARK: - UmbraError Protocol

    /// Domain identifier for socket errors
    public var domain: String {
      "Network.Socket"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .socketCreationFailed:
          "socket_creation_failed"
        case .bindFailed:
          "bind_failed"
        case .listenFailed:
          "listen_failed"
        case .acceptFailed:
          "accept_failed"
        case .connectionRefused:
          "connection_refused"
        case .socketClosed:
          "socket_closed"
        case .readFailed:
          "read_failed"
        case .writeFailed:
          "write_failed"
        case .timeout:
          "timeout"
        case .addressInUse:
          "address_in_use"
        case .invalidOption:
          "invalid_option"
        case .bufferOverflow:
          "buffer_overflow"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .socketCreationFailed(reason):
          "Failed to create socket: \(reason)"
        case let .bindFailed(address, port, reason):
          "Failed to bind socket to \(address):\(port): \(reason)"
        case let .listenFailed(reason):
          "Failed to listen on socket: \(reason)"
        case let .acceptFailed(reason):
          "Failed to accept connection: \(reason)"
        case let .connectionRefused(host, port):
          "Connection refused by \(host):\(port)"
        case let .socketClosed(reason):
          "Socket closed unexpectedly: \(reason)"
        case let .readFailed(reason):
          "Failed to read from socket: \(reason)"
        case let .writeFailed(reason):
          "Failed to write to socket: \(reason)"
        case let .timeout(operation, timeoutMs):
          "Socket operation '\(operation)' timed out after \(timeoutMs)ms"
        case let .addressInUse(address, port):
          "Socket address \(address):\(port) already in use"
        case let .invalidOption(option, reason):
          "Invalid socket option '\(option)': \(reason)"
        case let .bufferOverflow(bufferSize):
          "Socket buffer overflow (buffer size: \(bufferSize) bytes)"
      }
    }

    /// Source information about where the error occurred
    public var source: ErrorHandlingInterfaces.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: ErrorHandlingInterfaces.ErrorContext {
      ErrorHandlingInterfaces.ErrorContext(
        source: domain,
        operation: "socket_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .socketCreationFailed(reason):
          .socketCreationFailed(reason: reason)
        case let .bindFailed(address, port, reason):
          .bindFailed(address: address, port: port, reason: reason)
        case let .listenFailed(reason):
          .listenFailed(reason: reason)
        case let .acceptFailed(reason):
          .acceptFailed(reason: reason)
        case let .connectionRefused(host, port):
          .connectionRefused(host: host, port: port)
        case let .socketClosed(reason):
          .socketClosed(reason: reason)
        case let .readFailed(reason):
          .readFailed(reason: reason)
        case let .writeFailed(reason):
          .writeFailed(reason: reason)
        case let .timeout(operation, timeoutMs):
          .timeout(operation: operation, timeoutMs: timeoutMs)
        case let .addressInUse(address, port):
          .addressInUse(address: address, port: port)
        case let .invalidOption(option, reason):
          .invalidOption(option: option, reason: reason)
        case let .bufferOverflow(bufferSize):
          .bufferOverflow(bufferSize: bufferSize)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Network.Socket {
  /// Create a connection refused error
  public static func makeConnectionRefused(
    host: String,
    port: Int,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .connectionRefused(host: host, port: port)
  }

  /// Create a socket read error
  public static func makeReadError(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .readFailed(reason: reason)
  }

  /// Create a socket write error
  public static func makeWriteError(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .writeFailed(reason: reason)
  }
}
