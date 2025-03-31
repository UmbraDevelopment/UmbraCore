import UmbraErrors

/**
 # API Errors

 Defines a comprehensive set of error types for API operations in the Umbra system.
 These errors provide rich context information and follow the Alpha Dot Five
 architecture principles of domain-specific error hierarchies.

 ## Error Categories

 Errors are categorised into different types to provide clear identification
 of the error source and appropriate handling strategies.
 */
public enum APIError: Error, Sendable {
  /// The operation was not found or not supported
  case operationNotSupported(String)

  /// The operation was invalid (e.g., invalid parameters)
  case invalidOperation(String)

  /// The operation failed due to an underlying error
  case operationFailed(Error)

  /// Authentication or authorisation failed
  case authenticationFailed(String)

  /// The requested resource was not found
  case resourceNotFound(String, identifier: String)

  /// The operation was cancelled
  case operationCancelled(String)

  /// The operation timed out
  case operationTimedOut(String, timeoutSeconds: Int)

  /// The service is currently unavailable
  case serviceUnavailable(String)

  /// The system is not in a valid state for the operation
  case invalidState(String, details: String)

  /// The operation would cause a conflict
  case conflict(String, details: String)

  /// The request rate limit was exceeded
  case rateLimitExceeded(String, resetTime: String?)
}

/**
 # API Error Context

 Provides structured context information for API errors, suitable for
 privacy-aware logging and user feedback.
 */
public struct APIErrorContext: Sendable {
  /// The operation that caused the error
  public let operation: String

  /// The domain of the operation
  public let domain: APIDomain

  /// General description of the error
  public let description: String

  /// More detailed information, potentially sensitive
  public let details: String

  /// Whether this error should be reported to the user
  public let userReportable: Bool

  /// Whether this error is expected in normal operation
  public let expected: Bool

  /**
   Initialises a new API error context.

   - Parameters:
      - operation: The operation that caused the error
      - domain: The domain of the operation
      - description: General description of the error
      - details: More detailed information, potentially sensitive
      - userReportable: Whether this error should be reported to the user
      - expected: Whether this error is expected in normal operation
   */
  public init(
    operation: String,
    domain: APIDomain,
    description: String,
    details: String,
    userReportable: Bool=true,
    expected: Bool=false
  ) {
    self.operation=operation
    self.domain=domain
    self.description=description
    self.details=details
    self.userReportable=userReportable
    self.expected=expected
  }
}

/// Extension to provide error context for API errors
extension APIError {
  /**
   Creates an error context for this API error.

   - Parameters:
      - operation: The operation that caused the error
      - domain: The domain of the operation

   - Returns: An API error context suitable for logging and user feedback
   */
  public func createContext(
    operation: String,
    domain: APIDomain
  ) -> APIErrorContext {
    let description: String
    let details: String
    let userReportable: Bool
    let expected: Bool

    switch self {
      case let .operationNotSupported(message):
        description="Operation Not Supported"
        details=message
        userReportable=true
        expected=false

      case let .invalidOperation(message):
        description="Invalid Operation"
        details=message
        userReportable=true
        expected=false

      case let .operationFailed(error):
        description="Operation Failed"
        details="\(error)"
        userReportable=true
        expected=false

      case let .authenticationFailed(message):
        description="Authentication Failed"
        details=message
        userReportable=true
        expected=true

      case let .resourceNotFound(message, identifier):
        description="Resource Not Found"
        details="\(message) (Identifier: \(identifier))"
        userReportable=true
        expected=true

      case let .operationCancelled(message):
        description="Operation Cancelled"
        details=message
        userReportable=false
        expected=true

      case let .operationTimedOut(message, timeout):
        description="Operation Timed Out"
        details="\(message) (Timeout: \(timeout) seconds)"
        userReportable=true
        expected=true

      case let .serviceUnavailable(message):
        description="Service Unavailable"
        details=message
        userReportable=true
        expected=true

      case let .invalidState(message, stateDetails):
        description="Invalid State"
        details="\(message) (Details: \(stateDetails))"
        userReportable=true
        expected=false

      case let .conflict(message, conflictDetails):
        description="Conflict"
        details="\(message) (Details: \(conflictDetails))"
        userReportable=true
        expected=true

      case let .rateLimitExceeded(message, resetTime):
        description="Rate Limit Exceeded"
        details="\(message)" + (resetTime.map { " (Reset Time: \($0))" } ?? "")
        userReportable=true
        expected=true
    }

    return APIErrorContext(
      operation: operation,
      domain: domain,
      description: description,
      details: details,
      userReportable: userReportable,
      expected: expected
    )
  }
}
