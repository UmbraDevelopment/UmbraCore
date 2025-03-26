import Foundation
// Use the shared declarations instead of local ones
import Interfaces
import UmbraErrorsCore


/// Error domain namespace

/// Error context protocol

/// Base error context implementation

// Use the Network namespace from NetworkErrorBase.swift
extension UmbraErrors.Network {
  /// HTTP-specific network errors
  public enum HTTP: Error, UmbraErrorsCore.UmbraError, StandardErrorCapabilitiesProtocol {
    // Client errors (4xx)
    /// 400 Bad Request - The server cannot process the request due to client error
    case badRequest(reason: String)

    /// 401 Unauthorised - Authentication required for resource access
    case unauthorised(reason: String)

    /// 403 Forbidden - Server refuses to authorise the request
    case forbidden(resource: String, reason: String)

    /// 404 Not Found - The requested resource could not be found
    case notFound(resource: String)

    /// 405 Method Not Allowed - The request method is not supported for the resource
    case methodNotAllowed(method: String, allowedMethods: [String])

    /// 408 Request Timeout - The server timed out waiting for the request
    case requestTimeout(timeoutMs: Int)

    /// 409 Conflict - The request conflicts with the current state of the resource
    case conflict(resource: String, reason: String)

    /// 413 Payload Too Large - The request entity is larger than the server will process
    case payloadTooLarge(sizeBytes: Int, maxSizeBytes: Int)

    /// 429 Too Many Requests - The user has sent too many requests in a given time
    case tooManyRequests(retryAfterMs: Int)

    // Server errors (5xx)
    /// 500 Internal Server Error - The server encountered an unexpected condition
    case internalServerError(reason: String)

    /// 501 Not Implemented - The server does not support the functionality required
    case notImplemented(feature: String)

    /// 502 Bad Gateway - The server received an invalid response from an upstream server
    case badGateway(reason: String)

    /// 503 Service Unavailable - The server is not ready to handle the request
    case serviceUnavailable(reason: String, retryAfterMs: Int?)

    /// 504 Gateway Timeout - The server did not receive a timely response from an upstream server
    case gatewayTimeout(reason: String)

    // Other HTTP errors
    /// SSL/TLS error during HTTPS connection
    case secureConnectionFailed(reason: String)

    /// Redirect error or too many redirects
    case redirectError(reason: String, redirectCount: Int)

    /// Invalid or malformed HTTP headers
    case invalidHeaders(reason: String)

    /// Content type mismatch or unsupported content type
    case contentTypeMismatch(expected: String, received: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for HTTP errors
    public var domain: String {
      "Network.HTTP"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .badRequest:
          "bad_request"
        case .unauthorised:
          "unauthorised"
        case .forbidden:
          "forbidden"
        case .notFound:
          "not_found"
        case .methodNotAllowed:
          "method_not_allowed"
        case .requestTimeout:
          "request_timeout"
        case .conflict:
          "conflict"
        case .payloadTooLarge:
          "payload_too_large"
        case .tooManyRequests:
          "too_many_requests"
        case .internalServerError:
          "internal_server_error"
        case .notImplemented:
          "not_implemented"
        case .badGateway:
          "bad_gateway"
        case .serviceUnavailable:
          "service_unavailable"
        case .gatewayTimeout:
          "gateway_timeout"
        case .secureConnectionFailed:
          "secure_connection_failed"
        case .redirectError:
          "redirect_error"
        case .invalidHeaders:
          "invalid_headers"
        case .contentTypeMismatch:
          "content_type_mismatch"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .badRequest(reason):
          return "Bad request (400): \(reason)"
        case let .unauthorised(reason):
          return "Unauthorised (401): \(reason)"
        case let .forbidden(resource, reason):
          return "Forbidden (403): Access to '\(resource)' is forbidden. \(reason)"
        case let .notFound(resource):
          return "Not found (404): Resource '\(resource)' could not be found"
        case let .methodNotAllowed(method, allowedMethods):
          return "Method not allowed (405): '\(method)' not allowed. Allowed methods: \(allowedMethods.joined(separator: ", "))"
        case let .requestTimeout(timeoutMs):
          return "Request timeout (408): Server timed out after \(timeoutMs)ms"
        case let .conflict(resource, reason):
          return "Conflict (409): Resource '\(resource)' has a conflict. \(reason)"
        case let .payloadTooLarge(sizeBytes, maxSizeBytes):
          return "Payload too large (413): \(sizeBytes) bytes (maximum \(maxSizeBytes) bytes)"
        case let .tooManyRequests(retryAfterMs):
          return "Too many requests (429): Retry after \(retryAfterMs)ms"
        case let .internalServerError(reason):
          return "Internal server error (500): \(reason)"
        case let .notImplemented(feature):
          return "Not implemented (501): '\(feature)' is not implemented"
        case let .badGateway(reason):
          return "Bad gateway (502): \(reason)"
        case let .serviceUnavailable(reason, retryAfterMs):
          let retryText=retryAfterMs.map { " Retry after \($0)ms" } ?? ""
          return "Service unavailable (503): \(reason).\(retryText)"
        case let .gatewayTimeout(reason):
          return "Gateway timeout (504): \(reason)"
        case let .secureConnectionFailed(reason):
          return "Secure connection failed: \(reason)"
        case let .redirectError(reason, redirectCount):
          return "Redirect error: \(reason) (\(redirectCount) redirects)"
        case let .invalidHeaders(reason):
          return "Invalid HTTP headers: \(reason)"
        case let .contentTypeMismatch(expected, received):
          return "Content type mismatch: Expected '\(expected)', received '\(received)'"
      }
    }

    /// Source information about where the error occurred
    public var source: UmbraErrorsCore.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: UmbraErrorsCore.ErrorContext {
      UmbraErrorsCore.ErrorContext(
        source: domain,
        operation: "http_request",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: UmbraErrorsCore.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .badRequest(reason):
          .badRequest(reason: reason)
        case let .unauthorised(reason):
          .unauthorised(reason: reason)
        case let .forbidden(resource, reason):
          .forbidden(resource: resource, reason: reason)
        case let .notFound(resource):
          .notFound(resource: resource)
        case let .methodNotAllowed(method, allowedMethods):
          .methodNotAllowed(method: method, allowedMethods: allowedMethods)
        case let .requestTimeout(timeoutMs):
          .requestTimeout(timeoutMs: timeoutMs)
        case let .conflict(resource, reason):
          .conflict(resource: resource, reason: reason)
        case let .payloadTooLarge(sizeBytes, maxSizeBytes):
          .payloadTooLarge(sizeBytes: sizeBytes, maxSizeBytes: maxSizeBytes)
        case let .tooManyRequests(retryAfterMs):
          .tooManyRequests(retryAfterMs: retryAfterMs)
        case let .internalServerError(reason):
          .internalServerError(reason: reason)
        case let .notImplemented(feature):
          .notImplemented(feature: feature)
        case let .badGateway(reason):
          .badGateway(reason: reason)
        case let .serviceUnavailable(reason, retryAfterMs):
          .serviceUnavailable(reason: reason, retryAfterMs: retryAfterMs)
        case let .gatewayTimeout(reason):
          .gatewayTimeout(reason: reason)
        case let .secureConnectionFailed(reason):
          .secureConnectionFailed(reason: reason)
        case let .redirectError(reason, redirectCount):
          .redirectError(reason: reason, redirectCount: redirectCount)
        case let .invalidHeaders(reason):
          .invalidHeaders(reason: reason)
        case let .contentTypeMismatch(expected, received):
          .contentTypeMismatch(expected: expected, received: received)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source: UmbraErrorsCore.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Network.HTTP {
  /// Create an error from HTTP status code
  public static func makeFromStatusCode(
    _ statusCode: Int,
    reason: String,
    resource: String?=nil,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self? {
    switch statusCode {
      case 400:
        .badRequest(reason: reason)
      case 401:
        .unauthorised(reason: reason)
      case 403:
        .forbidden(resource: resource ?? "unknown", reason: reason)
      case 404:
        .notFound(resource: resource ?? "unknown")
      case 408:
        .requestTimeout(timeoutMs: 30000) // Default timeout
      case 409:
        .conflict(resource: resource ?? "unknown", reason: reason)
      case 413:
        .payloadTooLarge(sizeBytes: 0, maxSizeBytes: 0) // Would need actual size info
      case 429:
        .tooManyRequests(retryAfterMs: 60000) // Default retry after 1 minute
      case 500:
        .internalServerError(reason: reason)
      case 501:
        .notImplemented(feature: reason)
      case 502:
        .badGateway(reason: reason)
      case 503:
        .serviceUnavailable(reason: reason, retryAfterMs: nil)
      case 504:
        .gatewayTimeout(reason: reason)
      default:
        nil // Not a standard HTTP error we handle
    }
  }

  /// Create an error for a not found resource
  public static func makeNotFound(
    resource: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .notFound(resource: resource)
  }

  /// Create an unauthorised error
  public static func makeUnauthorised(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .unauthorised(reason: reason)
  }
}
