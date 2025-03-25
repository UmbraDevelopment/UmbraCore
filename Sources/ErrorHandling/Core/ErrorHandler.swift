import Foundation
import UmbraErrorsCore
import Interfaces
import Protocols

/// Main error handler for the UmbraCore framework
@MainActor
public final class ErrorHandler {
  /// Shared instance of the error handler
  @MainActor
  public static let shared=ErrorHandler()

  /// The logger used for error logging
  private var logger: ErrorLoggingService?

  /// The notification handler for presenting errors to the user
  private var notificationHandler: ErrorNotificationService?

  /// Registered recovery options providers
  private var recoveryProviders: [Interfaces.RecoveryOptionsProvider]

  /// Private initialiser to enforce singleton pattern
  private init() {
    recoveryProviders=[]
  }

  /// Set the logger to use for error logging
  /// - Parameter logger: Logger to use
  public func setLogger(_ logger: ErrorLoggingService) {
    self.logger=logger
  }

  /// Set the notification handler for presenting errors
  /// - Parameter handler: Handler to use
  public func setNotificationHandler(_ handler: ErrorNotificationService) {
    notificationHandler=handler
  }

  /// Register a recovery options provider
  /// - Parameter provider: The provider to register
  public func registerRecoveryProvider(_ provider: Interfaces.RecoveryOptionsProvider) {
    recoveryProviders.append(provider)
  }

  /// Handle an error with given severity
  /// - Parameters:
  ///   - error: Error to handle
  ///   - severity: Severity of the error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  public func handle(
    _ error: UmbraErrorsCore.UmbraError,
    severity: UmbraErrorsCore.ErrorSeverity = .error,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Log the error
    logger?.log(error, withSeverity: severity)
    
    // Present error notification if appropriate
    if let notification = notificationHandler, severity.rawValue >= UmbraErrorsCore.ErrorSeverity.error.rawValue {
      Task {
        _ = await notification.notifyUser(
          about: error,
          level: severity.toNotificationLevel(),
          recoveryOptions: getRecoveryOptions(for: error)
        )
      }
    }
  }

  /// Get recovery options for an error
  /// - Parameter error: The error to get recovery options for
  /// - Returns: An array of recovery options
  public func getRecoveryOptions(for error: UmbraErrorsCore.UmbraError) -> [UmbraErrorsCore.RecoveryOption] {
    // Call the recoveryOptions method on each provider and combine the results
    var options: [UmbraErrorsCore.RecoveryOption] = []
    
    for provider in recoveryProviders {
      let providerOptions = provider.getRecoveryOptions(for: error)
      options.append(contentsOf: providerOptions)
    }
    
    return options
  }
}

// Extension for domain-specific error handling
extension ErrorHandler {
  /// Handle a security error
  /// - Parameters:
  ///   - error: The security error to handle
  ///   - severity: The severity of the error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  public func handleSecurity(
    _ error: UmbraErrorsCore.UmbraError,
    severity: UmbraErrorsCore.ErrorSeverity = .error,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Domain-specific handling for security errors
    handle(error, severity: severity, file: file, function: function, line: line)
  }
  
  /// Handle a repository error
  /// - Parameters:
  ///   - error: The repository error to handle
  ///   - severity: The severity of the error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  public func handleRepository(
    _ error: UmbraErrorsCore.UmbraError,
    severity: UmbraErrorsCore.ErrorSeverity = .error,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) {
    // Domain-specific handling for repository errors
    handle(error, severity: severity, file: file, function: function, line: line)
  }
}
