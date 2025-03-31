import Foundation
import Interfaces
import UmbraErrorsCore
import UmbraLogging

/// Error Handling Protocol
/// Defines the public interface for error handling operations.
public protocol ErrorHandlingProtocol {
  // Protocol will be implemented
}

/// A protocol that all UmbraCore errors must conform to.
/// This provides a consistent interface for error handling across the codebase.
public protocol UmbraError: Error, Sendable, CustomStringConvertible {
  /// Unique identifier for the error
  var id: String { get }

  /// Error domain for categorisation
  var domain: String { get }

  /// Specific error code within the domain
  var code: Int { get }

  /// Human-readable description of the error
  var description: String { get }

  /// Optional source information about where the error occurred
  var source: UmbraErrorsCore.ErrorSource? { get }

  /// Optional underlying error that caused this error
  var underlyingError: Error? { get }

  /// Creates a new instance of the error with additional context
  func with(context: UmbraErrorsCore.ErrorContext) -> Self

  /// Creates a new instance of the error with a specified underlying error
  func with(underlyingError: Error) -> Self

  /// Creates a new instance of the error with source information
  func with(source: UmbraErrorsCore.ErrorSource) -> Self

  /// Gets or creates an error context from this error
  var context: UmbraErrorsCore.ErrorContext { get }

  /// Severity level of this error
  var severity: UmbraErrorsCore.ErrorSeverity { get }
}

extension UmbraError {
  /// Default implementation assumes no underlying error
  public var underlyingError: Error? { nil }

  /// Default implementation assumes no source information
  public var source: UmbraErrorsCore.ErrorSource? { nil }

  /// Default implementation returns the error as is
  public func with(context _: UmbraErrorsCore.ErrorContext) -> Self {
    self
  }

  /// Default implementation returns the error as is
  public func with(underlyingError _: Error) -> Self {
    self
  }

  /// Default implementation returns the error as is
  public func with(source _: UmbraErrorsCore.ErrorSource) -> Self {
    self
  }

  /// Default implementation creates a context from the error properties
  public var context: UmbraErrorsCore.ErrorContext {
    UmbraErrorsCore.ErrorContext.create(
      domain: domain,
      code: code,
      description: description,
      underlyingError: underlyingError
    )
  }

  /// Default implementation for error severity
  public var severity: UmbraErrorsCore.ErrorSeverity {
    .error
  }

  /// Helper method to include source information using #file, #function, #line
  /// - Parameters:
  ///   - file: Source file where the error occurred
  ///   - function: Function where the error occurred
  ///   - line: Line number where the error occurred
  /// - Returns: A new instance of the error with source information
  public func withSource(file: String=#file, function: String=#function, line: Int=#line) -> Self {
    with(source: UmbraErrorsCore.ErrorSource(file: file, line: line, function: function))
  }
}

/// Protocol for domain-specific error types
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
  func log<E: UmbraError>(error: E, severity: UmbraErrorsCore.ErrorSeverity)

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
    log(error: error, severity: UmbraErrorsCore.ErrorSeverity.debug)
  }

  public func logInfo(_ error: some UmbraError) {
    log(error: error, severity: UmbraErrorsCore.ErrorSeverity.info)
  }

  public func logWarning(_ error: some UmbraError) {
    log(error: error, severity: UmbraErrorsCore.ErrorSeverity.warning)
  }

  public func logError(_ error: some UmbraError) {
    log(error: error, severity: UmbraErrorsCore.ErrorSeverity.error)
  }

  public func logCritical(_ error: some UmbraError) {
    log(error: error, severity: UmbraErrorsCore.ErrorSeverity.critical)
  }
}

/// Protocol for error notification services
public protocol ErrorNotificationProtocol {
  /// Present an error to the user
  /// - Parameters:
  ///   - error: The error to present
  ///   - severity: The error severity
  ///   - level: The notification level for the UI
  ///   - recoveryOptions: Optional recovery options to present to the user
  /// - Returns: The selected recovery option and status, if any
  @discardableResult
  func notifyUser<E: UmbraError>(
    about error: E,
    severity: UmbraErrorsCore.ErrorSeverity,
    level: UmbraErrorsCore.ErrorNotificationLevel,
    recoveryOptions: [any UmbraErrorsCore.RecoveryOption]
  ) async -> (option: any UmbraErrorsCore.RecoveryOption, status: UmbraErrorsCore.RecoveryStatus)?
}
