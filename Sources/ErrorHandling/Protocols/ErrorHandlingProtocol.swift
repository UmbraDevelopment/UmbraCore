import Foundation

/// Error Handling Protocol
/// Defines the public interface for error handling operations.
public protocol ErrorHandlingProtocol {
  // Protocol will be implemented
}

/// A protocol that all UmbraCore errors must conform to.
/// This provides a consistent interface for error handling across the codebase.
public protocol UmbraError: Error, Sendable, CustomStringConvertible {
  /// The domain that this error belongs to, e.g., "Security", "Repository"
  var domain: String { get }

  /// A unique code that identifies this error within its domain
  var code: String { get }

  /// A human-readable description of the error
  var errorDescription: String { get }

  /// Optional source information about where the error occurred
  var source: ErrorSource? { get }

  /// Optional underlying error that caused this error
  var underlyingError: Error? { get }

  /// Additional context information about the error
  var context: ErrorDetailContext { get }

  /// Creates a new instance of the error with additional context
  func with(context: ErrorDetailContext) -> Self

  /// Creates a new instance of the error with a specified underlying error
  func with(underlyingError: Error) -> Self

  /// Creates a new instance of the error with source information
  func with(source: ErrorSource) -> Self
}

/// Default implementation for UmbraError
extension UmbraError {
  public var description: String {
    var desc = "[\(domain):\(code)] \(errorDescription)"

    if let source {
      desc += " (at \(source.function) in \(source.file):\(source.line))"
    }

    return desc
  }

  /// Default implementation returns an empty context
  public var context: ErrorDetailContext {
    ErrorDetailContext(
      source: domain,
      operation: "unknown",
      details: errorDescription
    )
  }

  /// Default implementation returns the underlying error as is
  public func with(underlyingError _: Error) -> Self {
    self
  }

  /// Default implementation returns nil
  public var source: ErrorSource? {
    nil
  }
}

/// Extension to add conveniences for UmbraError
extension UmbraError {
  /// Create a new instance of the error with source location information
  ///
  /// - Parameters:
  ///   - file: The file where the error occurred (defaults to current file)
  ///   - line: The line where the error occurred (defaults to current line)
  ///   - function: The function where the error occurred (defaults to current function)
  /// - Returns: A new instance of the error with source information
  public func withSource(file: String = #file, function: String = #function, line: Int = #line) -> Self {
    with(source: ErrorSource(file: file, function: function, line: line))
  }
}

/// A protocol for domain-specific error types
public protocol DomainError: UmbraError {
  /// The domain identifier for this error type
  static var domain: String { get }
}

/// Default implementation for DomainError
extension DomainError {
  public var domain: String {
    Self.domain
  }
}

/// Protocol for recovery options that can be presented to the user
public protocol RecoveryOption: Sendable {
  /// Descriptive title for the recovery option
  var title: String { get }

  /// Action to perform when the recovery option is selected
  func perform() async
}

/// Protocol for providing recovery options for errors
public protocol RecoveryOptionsProvider: Sendable {
  /// Get recovery options for a specific error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Array of recovery options
  func recoveryOptions(for error: Error) -> [RecoveryOption]
}

/// Protocol for error logging services
public protocol ErrorLoggingProtocol {
  /// Log an error with the specified severity
  /// - Parameters:
  ///   - error: The error to log
  ///   - severity: The severity of the error
  func log<E: UmbraError>(error: E, severity: ErrorSeverity)

  /// Log an error with debug severity
  /// - Parameter error: The error to log
  func logDebug<E: UmbraError>(_ error: E)

  /// Log an error with info severity
  /// - Parameter error: The error to log
  func logInfo<E: UmbraError>(_ error: E)

  /// Log an error with warning severity
  /// - Parameter error: The error to log
  func logWarning<E: UmbraError>(_ error: E)

  /// Log an error with error severity
  /// - Parameter error: The error to log
  func logError<E: UmbraError>(_ error: E)

  /// Log an error with critical severity
  /// - Parameter error: The error to log
  func logCritical<E: UmbraError>(_ error: E)
}

/// Default implementation for ErrorLoggingProtocol
extension ErrorLoggingProtocol {
  public func logDebug(_ error: some UmbraError) {
    log(error: error, severity: .debug)
  }

  public func logInfo(_ error: some UmbraError) {
    log(error: error, severity: .info)
  }

  public func logWarning(_ error: some UmbraError) {
    log(error: error, severity: .warning)
  }

  public func logError(_ error: some UmbraError) {
    log(error: error, severity: .error)
  }

  public func logCritical(_ error: some UmbraError) {
    log(error: error, severity: .critical)
  }
}

/// Protocol for error notification services
public protocol ErrorNotificationProtocol {
  /// Present an error to the user
  /// - Parameters:
  ///   - error: The error to present
  ///   - recoveryOptions: Optional recovery options to present to the user
  func presentError<E: UmbraError>(_ error: E, recoveryOptions: [RecoveryOption])
}
