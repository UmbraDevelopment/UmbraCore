import Core
import Foundation
import Interfaces
import Recovery
import UmbraErrorsCore
import UmbraLogging

/// Central coordinating service for error notifications
@MainActor
public final class ErrorNotifier: ErrorNotificationProtocol {
  /// The shared instance
  public static let shared=ErrorNotifier()

  /// Registered notification services
  private var notificationServices: [ErrorNotificationService]=[]

  /// Initialises a new instance
  public init() {}

  /// Registers a notification service
  /// - Parameter service: The notification service to register
  public func registerNotificationService(_ service: ErrorNotificationService) {
    notificationServices.append(service)
  }

  /// Notifies the user about an error
  /// - Parameters:
  ///   - error: The error to notify about
  ///   - severity: The severity of the error
  ///   - level: The notification level
  ///   - recoveryOptions: The recovery options
  /// - Returns: The selected recovery option, if any
  public func notifyUser(
    about error: Error,
    severity _: ErrorSeverity,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]
  ) async -> (option: RecoveryOption, status: RecoveryStatus)? {
    guard !notificationServices.isEmpty else {
      UmbraLogger.shared.warning("No notification services registered")
      return nil
    }

    // Get the appropriate service for this notification level
    let service=selectService(for: level)

    // Log the notification
    UmbraLogger.shared.info("Notifying user about error: \(error.localizedDescription)")

    // Notify the user and get the selected recovery option
    return await service.notifyUser(
      about: error,
      level: level,
      recoveryOptions: recoveryOptions
    )
  }

  /// Notifies the user about an error and performs the selected recovery option
  /// - Parameters:
  ///   - error: The error to notify about
  ///   - severity: The severity of the error
  ///   - level: The notification level
  /// - Returns: Whether the recovery was successful
  public func notifyAndRecover(
    from error: Error,
    severity: ErrorSeverity,
    level: ErrorNotificationLevel
  ) async -> Bool {
    // Get recovery options
    let options=RecoveryManager.shared.recoveryOptions(for: error)

    // Skip if no options available
    guard !options.isEmpty else {
      UmbraLogger.shared.warning("No recovery options available for \(error.localizedDescription)")
      return false
    }

    // Notify user and get selected option
    let result=await notifyUser(
      about: error,
      severity: severity,
      level: level,
      recoveryOptions: options
    )

    // If no option was selected, return false
    guard let result else {
      UmbraLogger.shared.warning("No recovery option selected by user")
      return false
    }

    // Log the selected option
    UmbraLogger.shared.info("User selected recovery option: \(result.option.title)")

    // Return whether recovery was successful
    return result.status == .success
  }

  /// Selects an appropriate notification service for the given level
  /// - Parameter level: The notification level
  /// - Returns: The selected notification service
  private func selectService(for _: ErrorNotificationLevel) -> ErrorNotificationService {
    // In a real implementation, we would select based on level and available services
    // For simplicity, we'll just return the first service
    guard let service=notificationServices.first else {
      // If no service is available, add a default console service
      let defaultService=ConsoleNotificationService()
      notificationServices.append(defaultService)
      return defaultService
    }

    return service
  }
}

/// A simple console-based notification service for development and testing
public class ConsoleNotificationService: ErrorNotificationService {
  /// Initialises a new instance
  public init() {}

  /// Notifies the user about an error
  /// - Parameters:
  ///   - error: The error to notify about
  ///   - level: The notification level
  ///   - recoveryOptions: The recovery options
  /// - Returns: The selected recovery option
  @MainActor
  public func notifyUser(
    about error: Error,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]
  ) async -> (option: RecoveryOption, status: RecoveryStatus)? {
    // Print the error to the console
    print("ERROR [\(level)]: \(error.localizedDescription)")

    // Print recovery options
    if !recoveryOptions.isEmpty {
      print("Recovery options:")
      for (index, option) in recoveryOptions.enumerated() {
        print("[\(index + 1)] \(option.title)")
      }

      // For testing, just select the first option
      if let firstOption=recoveryOptions.first {
        print("Selected: \(firstOption.title)")
        await firstOption.perform()
        return (firstOption, .success)
      }
    } else {
      print("No recovery options available")
    }

    return nil
  }
}

// Extension to add convenience methods to UmbraError
extension UmbraError {
  /// Notifies the user about this error
  /// - Parameters:
  ///   - level: The notification level
  ///   - options: The recovery options
  /// - Returns: The selected recovery option
  @MainActor
  public func notify(
    level: ErrorNotificationLevel = .warning,
    options: [any RecoveryOption]=[]
  ) async -> (option: RecoveryOption, status: RecoveryStatus)? {
    await ErrorNotifier.shared.notifyUser(
      about: self,
      severity: .warning,
      level: level,
      recoveryOptions: options
    )
  }

  /// Notifies the user about this error and performs the selected recovery option
  /// - Parameters:
  ///   - level: The notification level
  /// - Returns: Whether the recovery was successful
  @MainActor
  public func notifyAndRecover(
    level: ErrorNotificationLevel = .warning
  ) async -> Bool {
    await ErrorNotifier.shared.notifyAndRecover(
      from: self,
      severity: .warning,
      level: level
    )
  }
}
