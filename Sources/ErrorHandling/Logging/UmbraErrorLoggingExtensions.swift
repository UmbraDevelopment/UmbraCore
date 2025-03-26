import Foundation
import Interfaces
import UmbraErrorsCore
import UmbraLogging

// MARK: - Logging Extensions

/// Adds logging capabilities to UmbraError
@MainActor
extension UmbraErrorsCore.UmbraError {
  /// Logs this error at the error level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsError(
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    var message=errorDescription
    if let additionalMessage {
      message="\(additionalMessage): \(message)"
    }
    await logger.error(message, metadata: LogMetadata(context.asMetadataDictionary()))
  }

  /// Logs this error at the warning level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsWarning(
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    var message=errorDescription
    if let additionalMessage {
      message="\(additionalMessage): \(message)"
    }
    await logger.warning(message, metadata: LogMetadata(context.asMetadataDictionary()))
  }

  /// Logs this error at the info level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsInfo(
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    var message=errorDescription
    if let additionalMessage {
      message="\(additionalMessage): \(message)"
    }
    await logger.info(message, metadata: LogMetadata(context.asMetadataDictionary()))
  }

  /// Logs this error at the debug level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsDebug(
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    var message=errorDescription
    if let additionalMessage {
      message="\(additionalMessage): \(message)"
    }
    await logger.debug(message, metadata: LogMetadata(context.asMetadataDictionary()))
  }

  /// Logs this error at the critical level
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logAsCritical(
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    var message=errorDescription
    if let additionalMessage {
      message="\(additionalMessage): \(message)"
    }
    await logger.critical(message, metadata: LogMetadata(context.asMetadataDictionary()))
  }

  /// Logs this error at the appropriate level based on its severity
  /// - Parameters:
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func logWithSeverity(
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    switch severity {
      case .trace, .debug:
        await logAsDebug(additionalMessage: additionalMessage, logger: logger)
      case .info:
        await logAsInfo(additionalMessage: additionalMessage, logger: logger)
      case .warning:
        await logAsWarning(additionalMessage: additionalMessage, logger: logger)
      case .error:
        await logAsError(additionalMessage: additionalMessage, logger: logger)
      case .critical:
        await logAsCritical(additionalMessage: additionalMessage, logger: logger)
      @unknown default:
        await logAsError(additionalMessage: "Unknown severity", logger: logger)
    }
  }
}
