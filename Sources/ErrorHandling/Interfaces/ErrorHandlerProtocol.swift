import Foundation

/// Protocol defining common error handling capabilities
///
/// This protocol establishes a consistent interface for error handling
/// across the UmbraCore framework, enabling standardised error processing,
/// logging, and recovery strategies regardless of the specific error domain.
public protocol ErrorHandler {
  /// The domain this handler operates on
  var domain: String { get }

  /// Handle an error and return a recovery strategy
  /// - Parameter error: The error to handle
  /// - Returns: A recovery strategy for addressing the error
  func handle(_ error: Error) -> ErrorRecoveryStrategy

  /// Log an error with appropriate severity
  /// - Parameters:
  ///   - error: The error to log
  ///   - severity: The severity level
  ///   - context: Additional context for the error
  func log(_ error: Error, severity: ErrorSeverity, context: [String: Any]?)

  /// Determine if this handler can process the given error
  /// - Parameter error: The error to check
  /// - Returns: `true` if this handler can handle the error, otherwise `false`
  func canHandle(_ error: Error) -> Bool
}

/// Recovery strategies for error handling
public enum ErrorRecoveryStrategy {
  /// Retry the operation that caused the error
  case retry

  /// Retry the operation after a delay
  case retryAfterDelay(milliseconds: Int)

  /// Abort the operation
  case abort

  /// Attempt an alternative approach
  case useAlternative(description: String)

  /// Request user intervention to resolve the issue
  case requireUserIntervention(message: String)

  /// The issue has been resolved
  case resolved
}

/// Base protocol for domain-specific error handlers
public protocol DomainErrorHandler: ErrorHandler {
  /// The specific error type this handler processes
  associatedtype ErrorType: Error

  /// Handle a typed error
  /// - Parameter error: The domain-specific error
  /// - Returns: A recovery strategy
  func handleTyped(_ error: ErrorType) -> ErrorRecoveryStrategy
}

/// Default implementation for common error handler functionality
extension DomainErrorHandler {
  public func handle(_ error: Error) -> ErrorRecoveryStrategy {
    if let typedError=error as? ErrorType {
      return handleTyped(typedError)
    }

    // Attempt to map the error if it's not already the handled type
    if let mappedError=mapToHandledType(error) {
      return handleTyped(mappedError)
    }

    // Default handling for unknown errors
    log(error, severity: .warning, context: ["reason": "Unhandled error type"])
    return .abort
  }

  /// Attempt to map a general error to the specific type handled by this handler
  /// - Parameter error: The error to map
  /// - Returns: A mapped error of the handler's type, or nil if mapping isn't possible
  func mapToHandledType(_: Error) -> ErrorType? {
    // Default implementation returns nil
    // Specific handlers should override this to provide mapping logic
    nil
  }
}

/// Registry for error handlers
public protocol ErrorHandlerRegistry {
  /// Register an error handler with the registry
  /// - Parameter handler: The handler to register
  func register(handler: ErrorHandler)

  /// Get the appropriate handler for an error
  /// - Parameter error: The error to find a handler for
  /// - Returns: The appropriate handler, or nil if none is found
  func handler(for error: Error) -> ErrorHandler?

  /// Remove a handler from the registry
  /// - Parameter domain: The domain of the handler to remove
  func removeHandler(for domain: String)
}
