import Foundation

/// Type alias for log metadata
///
/// This allows us to enforce a consistent type for metadata across
/// the logging system while maintaining flexibility for different
/// metadata value types.
public typealias LogMetadata=[String: String]

/// Log level for filtering log messages
public enum LogLevel: String, Sendable, Comparable {
  /// Debug-level information (most verbose)
  case debug

  /// Informational messages
  case info

  /// Warning messages
  case warning

  /// Error messages
  case error

  /// Critical errors (most severe)
  case critical

  public static func < (lhs: Self, rhs: Self) -> Bool {
    let order: [LogLevel]=[.debug, .info, .warning, .error, .critical]
    guard
      let lhsIndex=order.firstIndex(of: lhs),
      let rhsIndex=order.firstIndex(of: rhs)
    else {
      return false
    }
    return lhsIndex < rhsIndex
  }
}
