import Foundation
import UmbraErrorsCore

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
    level: UmbraErrorsCore.ErrorNotificationLevel,
    recoveryOptions: [any UmbraErrorsCore.RecoveryOption]
  ) async -> UUID?

  /// Whether this service can handle a particular error
  /// - Parameter error: The error to check
  /// - Returns: Whether this service can handle the error
  func canHandle(_ error: some Error) -> Bool

  /// The types of errors that this service can handle
  var supportedErrorDomains: [String] { get }

  /// The notification levels that this service supports
  var supportedLevels: [UmbraErrorsCore.ErrorNotificationLevel] { get }
}
