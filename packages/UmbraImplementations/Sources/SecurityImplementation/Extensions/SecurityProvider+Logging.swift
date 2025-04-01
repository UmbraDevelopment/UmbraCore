import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import CoreSecurityTypes

/**
 # SecurityProvider Logging Extension

 This extension adds comprehensive logging capabilities to the CoreSecurityProviderService,
 ensuring that all security operations are properly recorded with appropriate
 detail and context.

 ## Logging Standards

 Security logs follow these standards:
 - All sensitive data is redacted
 - Operation outcomes are always logged
 - Error details are captured without exposing sensitive information
 - Performance metrics are included where appropriate
 */
extension CoreSecurityProviderService {
  /**
   Logs the start of a security operation.

   - Parameters:
     - operation: The security operation being performed
     - config: Configuration for the operation (sensitive data redacted)
   */
  func logOperationStart(operation: SecurityOperation, config: SecurityConfigDTO) async {
    // Create a safe version of config - don't log auth data
    let safeConfig = "Algorithm: \(config.encryptionAlgorithm), Mode: \(config.options?.["mode"] ?? "none")"

    let metadata = PrivacyMetadata([
      "operation": (value: operation.description, privacy: .public),
      "configuration": (value: safeConfig, privacy: .public),
      "timestamp": (value: "\(Date())", privacy: .public)
    ])

    await logger.info(
      "Starting security operation: \(operation.description)",
      metadata: metadata,
      source: "SecurityProvider.logOperationStart"
    )
  }

  /**
   Logs the successful completion of a security operation.

   - Parameters:
     - operation: The security operation that was performed
     - durationMs: Duration of the operation in milliseconds
     - result: Result of the operation (sensitive data redacted)
   */
  func logOperationSuccess(
    operation: SecurityOperation,
    durationMs: Double,
    result: SecurityResultDTO
  ) async {
    // Create a success log with detailed metrics
    let metadata = PrivacyMetadata([
      "operation": (value: operation.description, privacy: .public),
      "status": (value: "success", privacy: .public),
      "durationMs": (value: String(format: "%.2f", durationMs), privacy: .public),
      "resultSize": (value: String(result.processedData.count), privacy: .public)
    ])

    await logger.info(
      "Security operation completed successfully: \(operation.description)",
      metadata: metadata,
      source: "SecurityProvider.logOperationSuccess"
    )
  }

  /**
   Logs a security operation failure.

   - Parameters:
     - operation: The security operation that failed
     - error: The error that occurred
     - duration: Duration of the operation before failure
   */
  func logOperationFailure(
    operation: SecurityOperation,
    error: Error,
    duration: Double
  ) async {
    let metadata = PrivacyMetadata([
      "operation": (value: operation.description, privacy: .public),
      "status": (value: "failure", privacy: .public),
      "errorType": (value: "\(type(of: error))", privacy: .public),
      "durationMs": (value: String(format: "%.2f", duration), privacy: .public)
    ])

    // Create a safe error message that doesn't expose sensitive data
    let safeError: String
    if let securityError = error as? SecurityProtocolError {
      safeError = "SecurityError: \(securityError.localizedDescription)"
    } else {
      safeError = "Error: \(type(of: error))"
    }

    await logger.error(
      "Security operation failed: \(operation.description) - \(safeError)",
      metadata: metadata,
      source: "SecurityProvider.logOperationFailure"
    )
  }

  /**
   Logs a general security information event.

   - Parameters:
     - message: The message to log
     - operation: The security operation context
     - additionalMetadata: Any additional metadata to include
   */
  func logInfo(
    _ message: String,
    operation: String,
    additionalMetadata: [String: String] = [:]
  ) async {
    var metadataDict: [String: (value: Any, privacy: LogPrivacyLevel)] = [
      "securityOperation": (value: operation, privacy: .public)
    ]
    
    // Add additional metadata
    for (key, value) in additionalMetadata {
      metadataDict[key] = (value: value, privacy: .public)
    }
    
    let metadata = PrivacyMetadata(metadataDict)

    await logger.info(
      message,
      metadata: metadata,
      source: "SecurityProvider.logInfo"
    )
  }

  /**
   Logs a security warning event.

   - Parameters:
     - message: The warning message
     - operation: The security operation context
     - additionalMetadata: Any additional metadata to include
   */
  func logWarning(
    _ message: String,
    operation: String,
    additionalMetadata: [String: String] = [:]
  ) async {
    var metadataDict: [String: (value: Any, privacy: LogPrivacyLevel)] = [
      "securityOperation": (value: operation, privacy: .public)
    ]
    
    // Add additional metadata
    for (key, value) in additionalMetadata {
      metadataDict[key] = (value: value, privacy: .public)
    }
    
    let metadata = PrivacyMetadata(metadataDict)

    await logger.warning(
      message,
      metadata: metadata,
      source: "SecurityProvider.logWarning"
    )
  }
}
