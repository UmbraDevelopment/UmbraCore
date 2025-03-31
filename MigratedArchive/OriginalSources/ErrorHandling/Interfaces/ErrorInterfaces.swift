import Foundation
import UmbraErrorsCore

/// Protocol defining the fundamental error interface
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
  var context: ErrorContext { get }

  /// Creates a new instance of the error with additional context
  func with(context: ErrorContext) -> Self

  /// Creates a new instance of the error with a specified underlying error
  func with(underlyingError: Error) -> Self

  /// Creates a new instance of the error with source information
  func with(source: ErrorSource) -> Self
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

/// Protocol for error handling services
@MainActor
public protocol ErrorHandlingService: Sendable {
  /// Handle an error
  /// - Parameters:
  ///   - error: The error to handle
  ///   - severity: The severity of the error
  ///   - file: Source file where the error occurred
  ///   - function: Function where the error occurred
  ///   - line: Line number where the error occurred
  func handle(
    _ error: some UmbraError,
    severity: ErrorSeverity,
    file: String,
    function: String,
    line: Int
  )

  /// Get recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: Available recovery options
  func getRecoveryOptions(for error: some UmbraError) -> [any RecoveryOption]

  /// Set the logger to use for logging errors
  /// - Parameter logger: The logger to use
  func setLogger(_ logger: ErrorLoggingProtocol)

  /// Set the notification handler to use for presenting errors to users
  /// - Parameter handler: The notification handler to use
  func setNotificationHandler(_ handler: ErrorNotificationProtocol)

  /// Register a provider of recovery options
  /// - Parameter provider: The provider to register
  func registerRecoveryProvider(_ provider: RecoveryOptionsProvider)
}
