import Foundation
import UmbraErrorsCore

// Use the shared declarations instead of local ones
import Interfaces

/// Network error domain general definitions
/// These are supplementary to the more specialised definitions in dedicated files
extension UmbraErrors {
  /// Network-related general error domains
  /// For specialised error types, see:
  /// - NetworkCoreErrors.swift
  /// - NetworkHTTPErrors.swift
  /// - NetworkSocketErrors.swift
  public enum GeneralNetwork {
    /// Common network errors spanning all network operations
    public enum Core: Error, Sendable, Equatable {
      /// Failed to establish connection
      case connectionFailed(reason: String)

      /// Connection timed out
      case timeout(operation: String, durationMs: Int)

      /// Could not reach the remote host
      case hostUnreachable(host: String)

      /// DNS resolution failed
      case dnsResolutionFailed(host: String)

      /// Authentication failed
      case authenticationFailed(reason: String)

      /// Connection was closed unexpectedly
      case connectionClosed(reason: String)

      /// Invalid request format
      case invalidRequest(reason: String)

      /// Received invalid or unexpected response
      case invalidResponse(reason: String)

      /// Service unavailable
      case serviceUnavailable(service: String)

      /// Protocol error
      case protocolError(protocol: String, reason: String)

      /// Request rejected by server
      case requestRejected(code: Int, reason: String)

      /// Rate limit exceeded
      case rateLimitExceeded(limit: Int, resetTimeSeconds: Int)

      /// Insecure connection
      case insecureConnection(reason: String)

      /// Network interface unavailable
      case networkUnavailable(interface: String)

      /// Network configuration error
      case configurationError(reason: String)

      /// Certificate validation failed
      case certificateError(reason: String)

      /// Unexpected internal error
      case internalError(String)
    }

    /// HTTP-specific network errors
    public enum HTTP: Error, Sendable, Equatable {
      /// Invalid HTTP method
      case invalidMethod(method: String)

      /// Invalid URL format
      case invalidURL(url: String)

      /// Invalid HTTP header
      case invalidHeader(name: String, value: String)

      /// Client error (4xx status code)
      case clientError(statusCode: Int, message: String)

      /// Server error (5xx status code)
      case serverError(statusCode: Int, message: String)

      /// Redirect error
      case redirectError(statusCode: Int, location: String?, message: String)

      /// Invalid content type
      case invalidContentType(expected: String, received: String)

      /// Invalid response format
      case invalidResponseFormat(reason: String)

      /// Request body too large
      case requestTooLarge(sizeByte: Int, maxSizeByte: Int)

      /// Response body too large
      case responseTooLarge(sizeByte: Int, maxSizeByte: Int)

      /// Missing required header
      case missingHeader(name: String)

      /// Missing required parameter
      case missingParameter(name: String)

      /// Too many redirects
      case tooManyRedirects(count: Int, maxRedirects: Int)

      /// Invalid cookie
      case invalidCookie(name: String, reason: String)

      /// Content encoding error
      case contentEncodingError(encoding: String, reason: String)

      /// Internal HTTP error
      case internalError(String)
    }

    /// Socket-specific network errors
    public enum Socket: Error, Sendable, Equatable {
      /// Failed to create socket
      case creationFailed(reason: String)

      /// Failed to bind socket to address
      case bindFailed(address: String, port: Int, reason: String)

      /// Failed to listen on socket
      case listenFailed(reason: String)

      /// Failed to accept connection
      case acceptFailed(reason: String)

      /// Failed to connect to remote address
      case connectFailed(address: String, port: Int, reason: String)

      /// Socket read operation failed
      case readFailed(reason: String)

      /// Socket write operation failed
      case writeFailed(reason: String)

      /// Socket operation timed out
      case timeout(operation: String, durationMs: Int)

      /// Socket was closed unexpectedly
      case unexpectedlyClosed

      /// Address already in use
      case addressInUse(address: String, port: Int)

      /// Connection refused by peer
      case connectionRefused(address: String, port: Int)

      /// Invalid socket option
      case invalidOption(option: String, value: String)

      /// Socket is not connected
      case notConnected

      /// Socket is already connected
      case alreadyConnected

      /// Invalid socket address
      case invalidAddress(address: String)

      /// Socket operation would block
      case wouldBlock

      /// Internal socket error
      case internalError(String)
    }
  }
}
