import Foundation

/// Represents the level of notification for an error
public enum ErrorNotificationLevel: Int, Comparable, Sendable {
  case debug=0 // Developer-focused, typically not shown to end users
  case info=1 // Informational, non-critical
  case warning=2 // Warning that might need attention
  case error=3 // Error that needs attention
  case critical=4 // Critical error that requires immediate attention

  public static func < (lhs: ErrorNotificationLevel, rhs: ErrorNotificationLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// Protocol for services that can notify users about errors
@MainActor
public protocol ErrorNotificationService: Sendable {
  /// Present a notification to the user about an error
  /// - Parameters:
  ///   - error: The error to notify the user about
  ///   - level: The severity level of the notification
  ///   - recoveryOptions: Available recovery options to present
  /// - Returns: The ID of the chosen recovery option, if applicable
  func notifyUser(
    about error: some Error,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]
  ) async -> UUID?

  /// Whether this service can handle a particular error
  /// - Parameter error: The error to check
  /// - Returns: Whether this service can handle the error
  func canHandle(_ error: some Error) -> Bool

  /// The types of errors that this service can handle
  var supportedErrorDomains: [String] { get }

  /// The notification levels that this service supports
  var supportedLevels: [ErrorNotificationLevel] { get }
}
