import Foundation
import LoggingTypes

/// Defines the severity levels for error logging
///
/// This enumeration provides a standardised way to categorise errors
/// by their severity, which determines how they are logged.
public enum ErrorLoggingLevel: String, Sendable, Comparable, CaseIterable {
  /// Errors that are helpful for debugging but not significant in normal operation
  case debug

  /// General errors that should be noted but don't affect critical functionality
  case info

  /// Errors that indicate potential problems that should be addressed
  case warning

  /// Serious errors that may affect application functionality
  case error

  /// Critical errors that may cause the application to fail
  case critical

  /// Support comparison for filtering by severity
  public static func < (lhs: ErrorLoggingLevel, rhs: ErrorLoggingLevel) -> Bool {
    let order: [ErrorLoggingLevel]=[.debug, .info, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }

  /// Convert to the corresponding UmbraLogLevel
  /// - Returns: The matching UmbraLogLevel
  public func toUmbraLogLevel() -> UmbraLogLevel {
    switch self {
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }

  /// Create an ErrorLoggingLevel from an UmbraLogLevel
  /// - Parameter logLevel: The UmbraLogLevel to convert
  /// - Returns: The corresponding ErrorLoggingLevel
  public static func from(_ logLevel: UmbraLogLevel) -> ErrorLoggingLevel {
    switch logLevel {
      case .verbose:
        .debug
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }
}
