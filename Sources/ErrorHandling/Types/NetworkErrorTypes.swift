import Foundation
import Interfaces

/// Core network error types used throughout the UmbraCore framework
///
/// This enum defines all network-related errors in a single, flat structure
/// rather than nested within multiple levels. This approach simplifies
/// error handling and promotes a more maintainable codebase.
public enum NetworkError: Error, Equatable, Sendable {
  // MARK: - Connection Errors

  /// Connection to service failed
  case connectionFailed(service: String, reason: String)

  /// Connection timeout occurred
  case connectionTimeout(service: String, timeoutMs: Int)

  /// No network connectivity
  case noConnectivity(reason: String)

  /// Network connection lost during operation
  case connectionLost(operation: String, reason: String)

  // MARK: - HTTP Errors

  /// HTTP request invalid
  case invalidRequest(reason: String)

  /// HTTP request failed
  case requestFailed(statusCode: Int, reason: String)

  /// HTTP authentication failed
  case authenticationFailed(service: String, reason: String)

  /// HTTP authorization failed
  case authorizationFailed(service: String, resource: String)

  /// HTTP redirect error
  case redirectError(from: String, to: String, reason: String)

  /// HTTP client error (4xx)
  case clientError(statusCode: Int, message: String)

  /// HTTP server error (5xx)
  case serverError(statusCode: Int, message: String)

  // MARK: - Response Errors

  /// Response invalid
  case invalidResponse(reason: String)

  /// Response parsing failed
  case responseParseFailed(type: String, reason: String)

  /// Unexpected empty response
  case emptyResponse(expectation: String)

  /// Response format mismatch
  case responseFormatMismatch(expected: String, received: String)

  /// Response validation failed
  case responseValidationFailed(reason: String)

  // MARK: - Service Errors

  /// Service unavailable
  case serviceUnavailable(service: String, reason: String)

  /// Service rate limit exceeded
  case rateLimitExceeded(service: String, retryAfterSeconds: Int?)

  /// Service maintenance in progress
  case serviceMaintenance(service: String, estimatedCompletionTime: String?)

  /// Incompatible API version
  case incompatibleApiVersion(service: String, used: String, supported: String)

  // MARK: - Security Errors

  /// Certificate validation failed
  case certificateValidationFailed(reason: String)

  /// SSL/TLS error
  case tlsError(reason: String)

  /// Secure connection failed
  case secureConnectionFailed(reason: String)
}

extension NetworkError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .connectionFailed(service, reason):
        "Connection to \(service) failed: \(reason)"
      case let .connectionTimeout(service, timeoutMs):
        "Connection to \(service) timed out after \(timeoutMs)ms"
      case let .noConnectivity(reason):
        "No network connectivity: \(reason)"
      case let .connectionLost(operation, reason):
        "Connection lost during \(operation): \(reason)"
      case let .invalidRequest(reason):
        "Invalid HTTP request: \(reason)"
      case let .requestFailed(statusCode, reason):
        "HTTP request failed with status \(statusCode): \(reason)"
      case let .authenticationFailed(service, reason):
        "Authentication failed for \(service): \(reason)"
      case let .authorizationFailed(service, resource):
        "Authorization failed for \(resource) on \(service)"
      case let .redirectError(from, to, reason):
        "Redirect error from \(from) to \(to): \(reason)"
      case let .clientError(statusCode, message):
        "HTTP client error (\(statusCode)): \(message)"
      case let .serverError(statusCode, message):
        "HTTP server error (\(statusCode)): \(message)"
      case let .invalidResponse(reason):
        "Invalid response: \(reason)"
      case let .responseParseFailed(type, reason):
        "Failed to parse \(type) response: \(reason)"
      case let .emptyResponse(expectation):
        "Unexpected empty response. Expected: \(expectation)"
      case let .responseFormatMismatch(expected, received):
        "Response format mismatch: expected \(expected), received \(received)"
      case let .responseValidationFailed(reason):
        "Response validation failed: \(reason)"
      case let .serviceUnavailable(service, reason):
        "Service \(service) unavailable: \(reason)"
      case let .rateLimitExceeded(service, retryAfterSeconds):
        if let retryAfter = retryAfterSeconds {
          "Rate limit exceeded for \(service). Retry after \(retryAfter) seconds."
        } else {
          "Rate limit exceeded for \(service)."
        }
      case let .serviceMaintenance(service, estimatedCompletionTime):
        if let completionTime = estimatedCompletionTime {
          "Service \(service) in maintenance. Estimated completion: \(completionTime)"
        } else {
          "Service \(service) in maintenance."
        }
      case let .incompatibleApiVersion(service, used, supported):
        "Incompatible API version for \(service): used \(used), supported \(supported)"
      case let .certificateValidationFailed(reason):
        "Certificate validation failed: \(reason)"
      case let .tlsError(reason):
        "TLS error: \(reason)"
      case let .secureConnectionFailed(reason):
        "Secure connection failed: \(reason)"
    }
  }
}

extension NetworkError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}
