import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/**
 # SecurityProvider Logging Extension

 This extension adds comprehensive logging capabilities to the CoreSecurityProviderService,
 ensuring that all security operations are properly recorded with appropriate
 detail and context.

 ## Logging Standards

 Security logs follow these standards:
 - All sensitive data is redacted using privacy-aware tagging
 - Operation outcomes are always logged with appropriate privacy levels
 - Error details are captured without exposing sensitive information
 - Performance metrics are included where appropriate
 
 ## Privacy-Aware Logging
 
 This extension implements privacy-aware logging through SecureLoggerActor,
 ensuring that sensitive information is properly tagged with privacy levels
 according to the Alpha Dot Five architecture principles.
 */
extension CoreSecurityProviderService {
  /**
   Logs the start of a security operation with privacy-aware metadata.

   - Parameters:
     - operation: The security operation being performed
     - config: Configuration for the operation (sensitive data redacted)
   */
  func logOperationStart(operation: SecurityOperation, config: SecurityConfigDTO) async {
    // Create a safe version of config - don't log auth data
    let safeConfig = "Algorithm: \(config.encryptionAlgorithm), Mode: \(config.options?["mode"] ?? "none")"

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
    
    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: operation.description,
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: UUID().uuidString, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: config.encryptionAlgorithm, privacyLevel: .public),
        "mode": PrivacyTaggedValue(value: config.options?["mode"] ?? "none", privacyLevel: .public)
      ]
    )
  }

  /**
   Logs the successful completion of a security operation with privacy-aware metadata.

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
    
    // Log success with secure logger
    await secureLogger.securityEvent(
      action: operation.description,
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
        "durationMs": PrivacyTaggedValue(value: Int(durationMs), privacyLevel: .public),
        "resultSize": PrivacyTaggedValue(value: result.processedData.count, privacyLevel: .public)
      ]
    )
  }

  /**
   Logs a security operation failure with privacy-aware metadata.

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
    let safeError = if let securityError = error as? SecurityProtocolError {
      "SecurityError: \(securityError.localizedDescription)"
    } else {
      "Error: \(type(of: error))"
    }

    await logger.error(
      "Security operation failed: \(operation.description) - \(safeError)",
      metadata: metadata,
      source: "SecurityProvider.logOperationFailure"
    )
    
    // Log failure with secure logger
    await secureLogger.securityEvent(
      action: operation.description,
      status: .failed,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
        "durationMs": PrivacyTaggedValue(value: Int(duration), privacyLevel: .public),
        "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)), privacyLevel: .public),
        "errorDescription": PrivacyTaggedValue(value: safeError, privacyLevel: .public)
      ]
    )
  }

  /**
   Logs a general security information event with privacy-aware metadata.

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
    
    // Prepare privacy-tagged metadata for secure logger
    var secureMetadata: [String: PrivacyTaggedValue] = [
      "operation": PrivacyTaggedValue(value: operation, privacyLevel: .public)
    ]
    
    // Add additional metadata with privacy tagging
    for (key, value) in additionalMetadata {
      secureMetadata[key] = PrivacyTaggedValue(value: value, privacyLevel: .public)
    }
    
    // Log with secure logger
    await secureLogger.securityEvent(
      action: "InfoEvent",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: secureMetadata
    )
  }

  /**
   Logs a security warning event with privacy-aware metadata.

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
    
    // Prepare privacy-tagged metadata for secure logger
    var secureMetadata: [String: PrivacyTaggedValue] = [
      "operation": PrivacyTaggedValue(value: operation, privacyLevel: .public)
    ]
    
    // Add additional metadata with privacy tagging
    for (key, value) in additionalMetadata {
      secureMetadata[key] = PrivacyTaggedValue(value: value, privacyLevel: .public)
    }
    
    // Log with secure logger
    await secureLogger.securityEvent(
      action: "WarningEvent",
      status: .warning,
      subject: nil,
      resource: nil,
      additionalMetadata: secureMetadata
    )
  }
  
  /**
   Logs a sensitive security event with appropriate privacy controls.
   
   This method provides enhanced privacy controls for logging sensitive security events,
   ensuring that all sensitive information is properly tagged with privacy levels.
   
   - Parameters:
     - action: The security action being performed
     - status: The status of the action (success, warning, failed)
     - subject: The subject of the action (e.g., user identifier)
     - resource: The resource being accessed or modified
     - metadata: Additional metadata with privacy tagging
   */
  func logSecurityEvent(
    action: String,
    status: SecurityEventStatus,
    subject: String?,
    resource: String?,
    metadata: [String: PrivacyTaggedValue] = [:]
  ) async {
    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: action,
      status: status,
      subject: subject,
      resource: resource,
      additionalMetadata: metadata
    )
    
    // Also log a summary to the standard logger (with sensitive data redacted)
    var standardMetadata: [String: String] = [
      "action": action,
      "status": status.rawValue
    ]
    
    if let subject = subject {
      standardMetadata["subject"] = "[REDACTED]"
    }
    
    if let resource = resource {
      standardMetadata["resource"] = resource
    }
    
    // Log at appropriate level based on status
    switch status {
    case .success:
      await logger.info(
        "Security event: \(action)",
        metadata: standardMetadata,
        source: "SecurityProvider.logSecurityEvent"
      )
    case .warning:
      await logger.warning(
        "Security event warning: \(action)",
        metadata: standardMetadata,
        source: "SecurityProvider.logSecurityEvent"
      )
    case .failed:
      await logger.error(
        "Security event failure: \(action)",
        metadata: standardMetadata,
        source: "SecurityProvider.logSecurityEvent"
      )
    }
  }
}
