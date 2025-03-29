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
    await logger.error(message, metadata: createMetadata())
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
    await logger.warning(message, metadata: createMetadata())
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
    await logger.info(message, metadata: createMetadata())
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
    await logger.debug(message, metadata: createMetadata())
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
    await logger.critical(message, metadata: createMetadata())
  }

  /// Logs this error at the appropriate level based on severity
  /// - Parameters:
  ///   - severity: The severity level to log at (defaults to error)
  ///   - additionalMessage: Optional additional context message
  ///   - logger: The logger to use (defaults to shared instance)
  public func log(
    severity: UmbraErrorsCore.ErrorSeverity = .error,
    additionalMessage: String?=nil,
    logger: ErrorLogger=ErrorLogger.shared
  ) async {
    await logger.log(
      self,
      severity: severity,
      additionalContext: additionalMessage != nil ? ["additionalMessage": additionalMessage!] : nil
    )
  }

  /// Creates a LogMetadata instance from this error's context
  /// - Returns: A LogMetadata instance with error information
  private func createMetadata() -> LogMetadata {
    // Create a dictionary with error context information
    var metadataDict: [String: String]=[
      "domain": domain,
      "code": code,
      "description": errorDescription
    ]

    // Add source information if available
    if let source {
      metadataDict["source"]="\(source)"
    }

    // Add file, function, line information
    metadataDict["file"]=context.file
    metadataDict["function"]=context.function
    metadataDict["line"]="\(context.line)"

    // Add operation and details if available
    if let operation=context.operation {
      metadataDict["operation"]="\(operation)"
    }

    if let details=context.details {
      metadataDict["details"]="\(details)"
    }

    // Try to add common context values by known keys
    for key in ["errorCode", "errorDomain", "requestId", "timestamp", "additionalInfo"] {
      if let value=context.value(for: key) {
        metadataDict[key]="\(value)"
      }
    }

    return LogMetadata(metadataDict)
  }
}
