import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection = LogMetadataDTOCollection()
  for (key, value) in dict {
    collection = collection.withPublic(key: key, value: value)
  }
  return collection
}

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
     - source: The source of the log entry (default: "SecurityProvider")
   */
  func logOperationStart(
    operation: SecurityOperation, 
    config: SecurityConfigDTO,
    source: String = "SecurityProvider"
  ) async {
    // Create a safe version of config - don't log auth data
    let safeConfig = "Algorithm: \(config.encryptionAlgorithm), Mode: \(config.options?["mode"] ?? "none")"

    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "operation", value: operation.rawValue)
    metadata = metadata.withPublic(key: "status", value: "started")
    metadata = metadata.withPublic(key: "config", value: safeConfig)
    
    if let operationId = config.operationId {
      metadata = metadata.withPublic(key: "operationId", value: operationId)
    }
    
    await logger.info(
      "Security operation started: \(operation.description)",
      metadata: metadata,
      source: source
    )
  }
  
  /**
   Logs the successful completion of a security operation with privacy-aware metadata.

   - Parameters:
     - operation: The security operation that was performed
     - durationMs: The duration of the operation in milliseconds
     - source: The source of the log entry (default: "SecurityProvider")
   */
  func logOperationSuccess(
    operation: SecurityOperation, 
    durationMs: Double,
    source: String = "SecurityProvider"
  ) async {
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "operation", value: operation.rawValue)
    metadata = metadata.withPublic(key: "status", value: "success")
    metadata = metadata.withPublic(key: "durationMs", value: String(format: "%.2f", durationMs))
    
    await logger.info(
      "Security operation completed successfully: \(operation.description)",
      metadata: metadata,
      source: source
    )
  }
  
  /**
   Logs the failure of a security operation with privacy-aware metadata.

   - Parameters:
     - operation: The security operation that was attempted
     - error: The error that occurred
     - durationMs: The duration of the operation in milliseconds
     - source: The source of the log entry (default: "SecurityProvider")
   */
  func logOperationFailure(
    operation: SecurityOperation, 
    error: Error, 
    durationMs: Double,
    source: String = "SecurityProvider"
  ) async {
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "operation", value: operation.rawValue)
    metadata = metadata.withPublic(key: "status", value: "failure")
    metadata = metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
    metadata = metadata.withPublic(key: "durationMs", value: String(format: "%.2f", durationMs))
    
    // Add error details with appropriate privacy level
    if let securityError = error as? SecurityError {
      metadata = metadata.withPublic(key: "errorCode", value: securityError.code)
      metadata = metadata.withPrivate(key: "errorMessage", value: securityError.message)
    } else if let coreError = error as? CoreSecurityError {
      metadata = metadata.withPublic(key: "errorCode", value: String(describing: coreError))
      metadata = metadata.withPrivate(key: "errorMessage", value: coreError.localizedDescription)
    } else {
      metadata = metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)
    }
    
    await logger.error(
      "Security operation failed: \(operation.description)",
      metadata: metadata,
      source: source
    )
  }
  
  /**
   Logs a key management operation with privacy-aware metadata.

   - Parameters:
     - operation: The key management operation being performed
     - keyType: The type of key being managed
     - source: The source of the log entry (default: "KeyManagement")
   */
  func logKeyManagementOperation(
    operation: String, 
    keyType: String,
    source: String = "KeyManagement"
  ) async {
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "operation", value: operation)
    metadata = metadata.withPublic(key: "keyType", value: keyType)
    
    await logger.info(
      "Key management operation: \(operation) for \(keyType)",
      metadata: metadata,
      source: source
    )
  }
  
  /**
   Logs a security policy check with privacy-aware metadata.

   - Parameters:
     - policyName: The name of the security policy being checked
     - result: The result of the policy check
     - source: The source of the log entry (default: "SecurityPolicy")
   */
  func logPolicyCheck(
    policyName: String, 
    result: Bool,
    source: String = "SecurityPolicy"
  ) async {
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "policy", value: policyName)
    metadata = metadata.withPublic(key: "result", value: result ? "pass" : "fail")
    
    await logger.info(
      "Security policy check: \(policyName) - \(result ? "Passed" : "Failed")",
      metadata: metadata,
      source: source
    )
  }
  
  /**
   Logs a sensitive security event with appropriate privacy controls.

   This method provides enhanced privacy controls for logging sensitive security events,
   ensuring that all sensitive information is properly tagged with privacy levels.

   - Parameters:
     - event: The security event being logged
     - level: The log level for this event
     - metadata: Additional metadata for the event
     - source: The source of the log entry (default: "SecurityEvent")
   */
  func logSecurityEvent(
    event: String, 
    level: LogLevel = .info,
    metadata: [String: String] = [:],
    source: String = "SecurityEvent"
  ) async {
    let metadataCollection = createMetadataCollection(metadata)
    
    switch level {
      case .debug:
        await logger.debug(event, metadata: metadataCollection, source: source)
      case .info:
        await logger.info(event, metadata: metadataCollection, source: source)
      case .notice:
        await logger.notice(event, metadata: metadataCollection, source: source)
      case .warning:
        await logger.warning(event, metadata: metadataCollection, source: source)
      case .error:
        await logger.error(event, metadata: metadataCollection, source: source)
      case .critical:
        await logger.critical(event, metadata: metadataCollection, source: source)
    }
  }
}
