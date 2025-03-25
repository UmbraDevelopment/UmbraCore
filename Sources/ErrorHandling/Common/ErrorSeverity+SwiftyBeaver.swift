import Foundation
import UmbraLogging
import UmbraErrorsCore
import Interfaces

/// Logging extensions for ErrorSeverity
///
/// This file provides extensions to the ErrorSeverity enum to enable direct
/// logging functionality without requiring the client code to manually convert
/// between ErrorSeverity and LogLevel.
///
/// ## Role in the Logging Isolation Pattern
///
/// This extension is part of the Logger Isolation Pattern implemented in UmbraCore:
///
/// 1. It imports UmbraLogging instead of LoggingWrapperInterfaces
/// 2. It provides a simple API for logging directly from error severity
/// 3. It uses a simple console fallback when no logger is configured
///
/// By depending on the UmbraLogging module, this extension maintains compatibility
/// with the library evolution support required by ErrorHandlingCommon while still
/// providing logging functionality.
///
/// ## Usage Example
///
/// ```swift
/// // Log directly from an error severity
/// ErrorSeverity.warning.log("This is a warning message")
///
/// // Or from an error that has a severity property
/// let error = SomeError(severity: .error)
/// error.severity.log("Failed to process request: \(error.localizedDescription)")
/// ```
extension ErrorSeverity {
  /// Basic logging functionality that forwards to a logger implementation when available
  ///
  /// This method provides a convenient way to log messages directly from an error
  /// severity level without needing to first convert to a LogLevel.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - file: The file where the log is called from
  ///   - function: The function where the log is called from
  ///   - line: The line where the log is called from
  public func log(
    _ message: @autoclosure () -> Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    // Forward to the UmbraLogging implementation
    switch self {
    case .debug:
      Logger.debug(message(), file: file, function: function, line: line)
    case .info:
      Logger.info(message(), file: file, function: function, line: line)
    case .warning:
      Logger.warning(message(), file: file, function: function, line: line)
    case .error:
      Logger.error(message(), file: file, function: function, line: line)
    case .critical:
      Logger.critical(message(), file: file, function: function, line: line)
    }
  }
}
