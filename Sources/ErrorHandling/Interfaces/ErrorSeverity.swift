import Foundation

/// Error severity levels for classification and logging
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

  /// Convert to a string representation for logging
  public var stringValue: String {
    rawValue.uppercased()
  }

  /// Convert from ErrorNotificationLevel to ErrorSeverity
  public static func from(notificationLevel: ErrorNotificationLevel) -> ErrorSeverity {
    switch notificationLevel {
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

  /// Convert to ErrorNotificationLevel
  public func toNotificationLevel() -> ErrorNotificationLevel {
    switch self {
      case .trace, .debug:
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
