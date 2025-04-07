import ErrorCoreTypes
import Foundation

/**
 API error type for standardised error handling across the API service
 */
public enum APIError: Error, Sendable {
  case operationNotSupported(message: String, code: String)
  case invalidOperation(message: String, code: String)
  case operationFailed(message: String, code: String, underlyingError: Error?=nil)
  /// Operation not implemented
  case operationNotImplemented(message: String, code: String)
  /// Operation timed out
  case timeout(message: String, code: String)
  /// Network error occurred
  case networkError(message: String, code: String, underlyingError: Error?=nil)
  case authenticationFailed(message: String, code: String)
  case resourceNotFound(message: String, identifier: String)
  case resourceConflict(message: String, code: String)
  case resourceLocked(message: String, code: String)
  case resourceInvalid(message: String, code: String)
  case permissionDenied(message: String, code: String)
  case validationFailed(message: String, code: String)
  case operationCancelled(message: String, code: String)
  case operationTimedOut(message: String, timeoutSeconds: Int, code: String)
  case serviceUnavailable(message: String, code: String)
  case invalidState(message: String, details: String, code: String)
  case conflict(message: String, details: String, code: String)
  case rateLimitExceeded(message: String, resetTime: String?, code: String)
}
