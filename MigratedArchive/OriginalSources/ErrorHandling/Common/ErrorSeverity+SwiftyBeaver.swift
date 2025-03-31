import Foundation
import Interfaces
import UmbraErrorsCore
import UmbraLogging

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
extension UmbraErrorsCore.ErrorSeverity {
  /// Default logger instance used for severity-based logging
  private static let defaultLogger: LoggingProtocol=SeverityConsoleLogger()

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
    _ message: @autoclosure () -> String,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    let messageString=message()
    let metadata=LogMetadata([
      "file": file,
      "function": function,
      "line": String(line)
    ])

    // Forward to the UmbraLogging implementation
    Task {
      switch self {
        case .critical:
          await Self.defaultLogger.error(messageString, metadata: metadata)
        case .error:
          await Self.defaultLogger.error(messageString, metadata: metadata)
        case .warning:
          await Self.defaultLogger.warning(messageString, metadata: metadata)
        case .info:
          await Self.defaultLogger.info(messageString, metadata: metadata)
        case .debug, .trace:
          await Self.defaultLogger.debug(messageString, metadata: metadata)
      }
    }
  }
}

/// A simple console logger implementation for use by the ErrorSeverity extensions
private final class SeverityConsoleLogger: LoggingProtocol {
  func debug(_ message: String, metadata: LogMetadata?) async {
    print("DEBUG: \(message)" + (metadata != nil ? " \(String(describing: metadata!))" : ""))
  }

  func info(_ message: String, metadata: LogMetadata?) async {
    print("INFO: \(message)" + (metadata != nil ? " \(String(describing: metadata!))" : ""))
  }

  func warning(_ message: String, metadata: LogMetadata?) async {
    print("WARNING: \(message)" + (metadata != nil ? " \(String(describing: metadata!))" : ""))
  }

  func error(_ message: String, metadata: LogMetadata?) async {
    print("ERROR: \(message)" + (metadata != nil ? " \(String(describing: metadata!))" : ""))
  }
}
