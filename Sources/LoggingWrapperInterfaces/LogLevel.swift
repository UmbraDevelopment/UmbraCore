import Foundation

/// Standard logging levels for classification of log messages
///
/// This enum provides a consistent set of severity levels for logging throughout the
/// UmbraCore framework. It establishes a clear hierarchy of message importance,
/// with critical messages being the most severe and trace messages the least severe.
///
/// The enum is marked as `@frozen` to ensure binary stability across module boundaries,
/// and conforms to `Comparable` to allow for filtering based on minimum severity levels.
///
/// Usage example:
/// ```swift
/// // Filter logs above warning level
/// func shouldLog(level: LogLevel) -> Bool {
///     return level >= .warning
/// }
/// ```
@frozen
public enum LogLevel: Int, Comparable, Sendable {
  /// Critical issues that require immediate attention
  /// These are severe errors that may lead to application termination or data loss
  case critical=50

  /// Standard errors that should be addressed
  /// These indicate functionality is impaired but the application can continue running
  case error=40

  /// Warning messages that indicate potential issues
  /// These highlight abnormal or unexpected system behaviour that might lead to errors
  case warning=30

  /// Informational messages about system operation
  /// These provide runtime information about the normal functioning of the system
  case info=20

  /// Debug information for development purposes
  /// These provide detailed information useful during development and troubleshooting
  case debug=10

  /// Detailed trace information for in-depth debugging
  /// These provide extremely detailed information about code execution paths
  case trace=0

  /// Comparison implementation for Comparable protocol
  ///
  /// Lower numeric values represent lower severity.
  /// This ordering makes `critical > error > warning > info > debug > trace`
  /// which allows for natural comparison operations when filtering by severity.
  public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    // Lower numeric values represent lower severity
    // This makes critical > error > warning > info > debug > trace
    lhs.rawValue < rhs.rawValue
  }
}
