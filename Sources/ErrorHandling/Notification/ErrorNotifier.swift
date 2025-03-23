import Foundation
import UmbraLogging

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Central coordinating service for error notifications
@MainActor
public final class ErrorNotifier: ErrorNotificationProtocol {
  /// The shared instance
  public static let shared = ErrorNotifier()

  /// Registered notification services
  private var notificationServices: [ErrorNotificationService] = []

  /// The minimum level for notifications
  public var minimumNotificationLevel: ErrorNotificationLevel = .warning

  /// Whether automatic notification is enabled
  public var automaticNotificationEnabled: Bool = true

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /// Register a notification service
  /// - Parameter service: The service to register
  public func register(_ service: ErrorNotificationService) {
    notificationServices.append(service)
  }

  /// Set the minimum notification level
  /// - Parameter level: The minimum level
  public func setMinimumLevel(_ level: ErrorNotificationLevel) {
    minimumNotificationLevel = level
  }

  /// Set whether automatic notification is enabled
  /// - Parameter enabled: Whether to enable automatic notification
  public func setAutomaticNotification(_ enabled: Bool) {
    automaticNotificationEnabled = enabled
  }

  /// Process an error automatically if automatic notification is enabled
  /// - Parameters:
  ///   - error: The error to process
  ///   - severity: The severity of the error
  ///   - file: Source file where the error occurred
  ///   - function: Function where the error occurred
  ///   - line: Line number where the error occurred
  public func processError(
    _ error: ErrorHandlingInterfaces.UmbraError,
    severity: ErrorHandlingCommon.ErrorSeverity,
    file _: String,
    function _: String,
    line _: Int
  ) {
    guard automaticNotificationEnabled else {
      return
    }

    // Map severity to notification level
    let level = severity.toNotificationLevel()

    // Only notify if level is sufficient
    guard level >= minimumNotificationLevel else {
      return
    }

    // Create task to avoid UI blocking
    Task {
      await notifyUser(about: error, level: level)
    }
  }

  /// Present an error to the user
  /// - Parameters:
  ///   - error: The error to present
  ///   - recoveryOptions: Optional recovery options
  public nonisolated func presentError(
    _ error: some UmbraError,
    recoveryOptions: [any RecoveryOption]
  ) {
    Task { @MainActor [self] in
      // Default to error notification level if not specified
      await notifyUser(about: error, level: .error, recoveryOptions: recoveryOptions)
    }
  }

  /// Notify the user about an error
  /// - Parameters:
  ///   - error: The error to notify about
  ///   - level: The notification level
  ///   - recoveryOptions: Optional recovery options
  /// - Returns: The ID of the selected recovery option, if any
  public func notifyUser(
    about error: ErrorHandlingInterfaces.UmbraError,
    level: ErrorNotificationLevel,
    recoveryOptions: [any RecoveryOption]? = nil
  ) async -> UUID? {
    // Skip if level is below minimum
    guard level >= minimumNotificationLevel else {
      return nil
    }

    // Find appropriate notification services for this error's domain
    let applicableServices = notificationServices.filter { service in
      service.supportedErrorDomains.contains(error.domain) &&
        service.supportedLevels.contains(level)
    }

    // Get recovery options if not provided
    let options = recoveryOptions ?? ErrorRecoveryRegistry.shared.recoveryOptions(for: error)

    // Try each service until one handles the notification
    for service in applicableServices {
      if
        let chosenOptionID = await service.notifyUser(
          about: error,
          level: level,
          recoveryOptions: options
        ) {
        return chosenOptionID
      }
    }

    // No service could handle the notification or no option was chosen
    return nil
  }

  /// Notifies the user about an error and attempts recovery if an option is chosen
  /// - Parameters:
  ///   - error: The error to notify about and recover from
  ///   - level: The notification level
  /// - Returns: Whether recovery was successful
  public func notifyAndRecover(
    from error: ErrorHandlingInterfaces.UmbraError,
    level: ErrorNotificationLevel
  ) async -> Bool {
    // Get recovery options
    let options = ErrorRecoveryRegistry.shared.recoveryOptions(for: error)

    // Skip if no options available
    guard !options.isEmpty else {
      // Just notify without recovery options
      _ = await notifyUser(about: error, level: level)
      return false
    }

    // Notify and get selected option
    if
      let selectedOptionID = await notifyUser(
        about: error,
        level: level,
        recoveryOptions: options
      ) {
      // Find the selected option
      for option in options where option.id == selectedOptionID {
        // Perform recovery
        await option.perform()
        return true
      }
    }

    // No option was selected or recovery failed
    return false
  }
}

// Extension to add convenience methods to UmbraError
extension ErrorHandlingInterfaces.UmbraError {
  /// Notifies the user about this error
  /// - Parameters:
  ///   - level: The notification level
  ///   - logError: Whether to also log the error
  public func notify(
    level: ErrorNotificationLevel = .error,
    logError _: Bool = true
  ) {
    Task {
      await ErrorNotifier.shared.notifyUser(about: self, level: level)
    }
  }

  /// Notifies the user about this error and attempts recovery
  /// - Parameters:
  ///   - level: The notification level
  ///   - logError: Whether to also log the error
  /// - Returns: Whether recovery was successful
  public func notifyAndRecover(
    level: ErrorNotificationLevel = .error,
    logError _: Bool = true
  ) async -> Bool {
    await ErrorNotifier.shared.notifyAndRecover(from: self, level: level)
  }
}
