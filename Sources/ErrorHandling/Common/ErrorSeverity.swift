import Foundation
import LoggingWrapperInterfaces

/// Error severity levels for classification and logging
///
/// This enum provides a standardised way to categorise errors by severity throughout
/// the UmbraCore framework. It establishes a clear hierarchy of error importance,
/// with critical errors being the most severe and trace being the least severe.
///
/// ErrorSeverity is designed to work seamlessly with the logging system through
/// the LoggingWrapperInterfaces module, allowing for consistent error handling
/// and logging across the entire codebase.
///
/// ## Integration with Logging System
///
/// ErrorSeverity directly maps to the LogLevel enum from LoggingWrapperInterfaces,
/// providing a unified approach to error severity and log levels:
///
/// - `.critical` → LogLevel.critical
/// - `.error` → LogLevel.error
/// - `.warning` → LogLevel.warning
/// - `.info` → LogLevel.info
/// - `.debug` → LogLevel.debug
/// - `.trace` → LogLevel.trace
///
/// ## Usage Example
///
/// ```swift
/// func processResult(_ result: Result<Data, Error>) {
///     switch result {
///     case .success(let data):
///         // Process data
///     case .failure(let error):
///         if let appError = error as? AppError {
///             appError.severity.log("Error occurred: \(appError.localizedDescription)")
///         } else {
///             ErrorSeverity.error.log("Unknown error: \(error.localizedDescription)")
///         }
///     }
/// }
/// ```
public enum ErrorSeverity: String, Comparable, Sendable {
  /// Critical error that requires immediate attention
  case critical="Critical"

  /// Error that indicates a significant problem
  case error="Error"

  /// Warning about potential issues
  case warning="Warning"

  /// Informational message about error conditions
  case info="Info"

  /// Debug-level severity for minor issues
  case debug="Debug"

  /// Trace-level severity for detailed debugging
  case trace="Trace"

  /// Comparison implementation for Comparable protocol
  public static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
    // Reverse order: critical > error > warning > info > debug > trace
    let order: [ErrorSeverity]=[.trace, .debug, .info, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }

  /// Indicates whether errors of this severity should be shown to the user
  public var shouldNotify: Bool {
    switch self {
      case .critical, .error, .warning:
        true
      case .info, .debug, .trace:
        false
    }
  }

  /// Maps the severity level to an integer value that can be used for notification level mapping
  /// - Returns: An integer representing the notification level (0-4)
  public var notificationLevel: Int {
    switch self {
      case .critical:
        4 // Critical
      case .error:
        3 // Error
      case .warning:
        2 // Warning
      case .info:
        1 // Info
      case .debug, .trace:
        0 // Debug
    }
  }

  /// Convert ErrorSeverity to the corresponding LogLevel
  ///
  /// This method provides a direct mapping between ErrorSeverity and
  /// LoggingWrapperInterfaces.LogLevel, allowing for seamless integration
  /// with the logging system.
  ///
  /// - Returns: The equivalent LogLevel value
  public func toLogLevel() -> LogLevel {
    switch self {
      case .critical:
        .critical
      case .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug:
        .debug
      case .trace:
        .trace
    }
  }

  /// Creates an ErrorSeverity from a LogLevel
  /// - Parameter logLevel: The log level to convert
  /// - Returns: The corresponding ErrorSeverity
  public static func from(logLevel: LogLevel) -> ErrorSeverity {
    switch logLevel {
      case .critical:
        .critical
      case .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug:
        .debug
      case .trace:
        .trace
    }
  }

  /// String representation of the severity level (in uppercase)
  public var stringValue: String {
    rawValue.uppercased()
  }
}
