import Foundation
import UmbraLogging
import UmbraErrorsCore
import Interfaces

// MARK: - Logging Extensions

/// Adds logging capabilities to UmbraError
@MainActor
extension ErrorHandlingInterfaces.UmbraError {
  /// Logs this error at the error level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsError(
    additionalMessage: String? = nil,
    logger: ErrorLogger = ErrorLogger.shared
  ) async {
    var message = self.errorDescription
    if let additionalMessage = additionalMessage {
      message = "\(additionalMessage): \(message)"
    }
    
    await logger.error(
      message,
      context: self.context,
      error: self.underlyingError
    )
  }

  /// Logs this error at the warning level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsWarning(
    additionalMessage: String? = nil,
    logger: ErrorLogger = ErrorLogger.shared
  ) async {
    var message = self.errorDescription
    if let additionalMessage = additionalMessage {
      message = "\(additionalMessage): \(message)"
    }
    
    await logger.warning(
      message,
      context: self.context,
      error: self.underlyingError
    )
  }

  /// Logs this error at the info level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsInfo(
    additionalMessage: String? = nil,
    logger: ErrorLogger = ErrorLogger.shared
  ) async {
    var message = self.errorDescription
    if let additionalMessage = additionalMessage {
      message = "\(additionalMessage): \(message)"
    }
    
    await logger.info(
      message,
      context: self.context,
      error: self.underlyingError
    )
  }

  /// Logs this error at the debug level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsDebug(
    additionalMessage: String? = nil,
    logger: ErrorLogger = ErrorLogger.shared
  ) async {
    var message = self.errorDescription
    if let additionalMessage = additionalMessage {
      message = "\(additionalMessage): \(message)"
    }
    
    await logger.debug(
      message,
      context: self.context,
      error: self.underlyingError
    )
  }
  
  /// Logs this error at the critical level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsCritical(
    additionalMessage: String? = nil,
    logger: ErrorLogger = ErrorLogger.shared
  ) async {
    var message = self.errorDescription
    if let additionalMessage = additionalMessage {
      message = "\(additionalMessage): \(message)"
    }
    
    await logger.critical(
      message,
      context: self.context,
      error: self.underlyingError
    )
  }
}
