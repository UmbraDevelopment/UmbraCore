/// Represents the severity level of a log message.
///
/// The log level determines how a message should be handled and displayed.
/// Levels are ordered from least severe (verbose) to most severe (fault).
///
/// Example:
/// ```swift
/// let level = UmbraLogLevel.warning
/// if level >= .error {
///     // Handle severe issues
/// }
/// ```
@frozen
public enum UmbraLogLevel: Int, Sendable, Comparable {
  /// Detailed information, typically only useful for debugging.
  case verbose

  /// Debug-level messages with more detail than info.
  case debug

  /// General information about program execution.
  case info

  /// Potentially harmful situations that might need attention.
  case warning

  /// Error conditions that should be addressed.
  case error

  /// Critical errors that may lead to program termination.
  case critical

  /// Implementation of Comparable protocol for log levels
  public static func < (lhs: UmbraLogLevel, rhs: UmbraLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
