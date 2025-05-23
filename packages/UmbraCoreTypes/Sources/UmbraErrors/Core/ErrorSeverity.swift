import Foundation

/// Error notification levels for user interface presentation
///
/// This enum provides standardised levels for presenting notifications to users,
/// allowing for consistent error notifications across the application.
public enum ErrorNotificationLevel: Int, Comparable, Sendable {
  /// Critical notification that requires immediate user attention
  case critical=0

  /// Error notification for significant problems
  case error=1

  /// Warning notification for potential issues
  case warning=2

  /// Informational notification
  case info=3

  /// Debug notification for developer information
  case debug=4

  /// Implementation of Comparable protocol
  public static func < (lhs: ErrorNotificationLevel, rhs: ErrorNotificationLevel) -> Bool {
    lhs.rawValue > rhs.rawValue
  }
}

/// Error severity levels for classification and logging
///
/// This enum provides a standardised way to categorise errors by severity throughout
/// the UmbraCore framework. It establishes a clear hierarchy of error importance,
/// with critical errors being the most severe and trace being the least severe.
///
/// ErrorSeverity is designed to work seamlessly with the logging system,
/// allowing for consistent error handling and logging across the entire codebase.
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
///             // Log based on severity
///             print("Error occurred: \(appError.localizedDescription)")
///         } else {
///             // Use default severity
///             print("Unknown error: \(error.localizedDescription)")
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

  /// Convert from notification level to severity
  /// - Parameter notificationLevel: The notification level to convert
  /// - Returns: Corresponding error severity
  public static func from(notificationLevel: ErrorNotificationLevel) -> ErrorSeverity {
    switch notificationLevel {
      case .critical: .critical
      case .error: .error
      case .warning: .warning
      case .info: .info
      case .debug: .debug
    }
  }

  /// Convert severity to notification level
  /// - Returns: Corresponding notification level
  public func toNotificationLevel() -> ErrorNotificationLevel {
    switch self {
      case .critical: .critical
      case .error: .error
      case .warning: .warning
      case .info: .info
      case .debug, .trace: .debug
    }
  }
}
