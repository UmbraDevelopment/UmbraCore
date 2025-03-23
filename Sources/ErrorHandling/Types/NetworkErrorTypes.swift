import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
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
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Core network error types used throughout the UmbraCore framework
///
/// This enum defines all network-related errors in a single, flat structure
/// rather than nested within multiple levels. This approach simplifies
/// error handling and promotes a more maintainable codebase.
public enum NetworkError: Error, Equatable, Sendable {
  // MARK: - Connection Errors

  /// Connection to service failed
  case connectionFailed(reason: String)

  /// Service is unavailable
  case serviceUnavailable(service: String, reason: String)

  /// Timeout occurred while waiting for response
  case timeout(operation: String, durationMs: Int)

  /// Network request was interrupted
  case interrupted(reason: String)

  // MARK: - Request Errors

  /// Request contains invalid parameters or format
  case invalidRequest(reason: String)

  /// Request was rejected by the server
  case requestRejected(code: Int, reason: String)

  /// Request is too large to process
  case requestTooLarge(sizeByte: Int, maxSizeByte: Int)

  /// Rate limit has been exceeded
  case rateLimitExceeded(limitPerHour: Int, retryAfterMs: Int)

  // MARK: - Response Errors

  /// Response format is invalid
  case invalidResponse(reason: String)

  /// Response is too large to process
  case responseTooLarge(sizeByte: Int, maxSizeByte: Int)

  /// Response data is corrupted or incomplete
  case dataCorruption(reason: String)

  /// Unable to parse response data
  case parsingFailed(reason: String)

  // MARK: - Security Errors

  /// SSL/TLS certificate validation failed
  case certificateError(reason: String)

  /// The host is untrusted
  case untrustedHost(hostname: String)

  // MARK: - General Errors

  /// Internal error occurred
  case internalError(reason: String)

  /// Unknown network error
  case unknown(reason: String)
}

// MARK: - CustomStringConvertible

extension NetworkError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .connectionFailed(reason):
        "Connection failed: \(reason)"
      case let .serviceUnavailable(service, reason):
        "Service '\(service)' unavailable: \(reason)"
      case let .timeout(operation, durationMs):
        "Timeout occurred during \(operation) after \(durationMs)ms"
      case let .interrupted(reason):
        "Network request interrupted: \(reason)"
      case let .invalidRequest(reason):
        "Invalid request: \(reason)"
      case let .requestRejected(code, reason):
        "Request rejected (code \(code)): \(reason)"
      case let .requestTooLarge(sizeByte, maxSizeByte):
        "Request too large: \(sizeByte) bytes (maximum \(maxSizeByte) bytes)"
      case let .rateLimitExceeded(limitPerHour, retryAfterMs):
        "Rate limit exceeded: \(limitPerHour) requests per hour, retry after \(retryAfterMs)ms"
      case let .invalidResponse(reason):
        "Invalid response: \(reason)"
      case let .responseTooLarge(sizeByte, maxSizeByte):
        "Response too large: \(sizeByte) bytes (maximum \(maxSizeByte) bytes)"
      case let .dataCorruption(reason):
        "Data corruption: \(reason)"
      case let .parsingFailed(reason):
        "Parsing failed: \(reason)"
      case let .certificateError(reason):
        "Certificate error: \(reason)"
      case let .untrustedHost(hostname):
        "Untrusted host: \(hostname)"
      case let .internalError(reason):
        "Internal error: \(reason)"
      case let .unknown(reason):
        "Unknown network error: \(reason)"
    }
  }
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}
