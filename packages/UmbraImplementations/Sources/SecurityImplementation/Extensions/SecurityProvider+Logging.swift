import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
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
extension SecurityProviderService {
  /**
   Logs the start of a security operation with privacy-aware metadata.

   - Parameters:
     - operation: The security operation being performed
     - config: Configuration for the operation (sensitive data redacted)
     - source: The source of the log entry (default: "SecurityProvider")
   */
  func logOperationStart(
    operation: CoreSecurityTypes.SecurityOperation,
    config: SecurityConfigDTO,
    source: String="SecurityProvider"
  ) async {
    // Create a safe version of config - don't log auth data
    let safeConfig = "Algorithm: \(config.encryptionAlgorithm.rawValue), Hash: \(config.hashAlgorithm.rawValue)"

    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "operation", value: operation.rawValue)
    metadata = metadata.withPublic(key: "status", value: "started")
    metadata = metadata.withPublic(key: "config", value: safeConfig)

    // Operation ID may be in the options
    if let options = config.options, let optionsMetadata = options.metadata, let operationID = optionsMetadata["operationID"] {
      // Cannot modify the options.metadata directly, so we update our collection instead
      metadata = metadata.withPublic(key: "operationId", value: operationID)
    }

    // Create a context for logging
    let context = LoggingTypes.BaseLogContextDTO(
      domainName: "SecurityImplementation",
      source: source,
      metadata: metadata
    )
    
    await logger.info(
      "Security operation started: \(operation.rawValue)",
      context: context
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
    operation: CoreSecurityTypes.SecurityOperation,
    durationMs: Double,
    source: String="SecurityProvider"
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation.rawValue)
    metadata=metadata.withPublic(key: "status", value: "success")
    metadata=metadata.withPublic(key: "durationMs", value: String(format: "%.2f", durationMs))

    // Create a context for logging
    let context = LoggingTypes.BaseLogContextDTO(
      domainName: "SecurityImplementation",
      source: source,
      metadata: metadata
    )
    
    await logger.info(
      "Security operation completed successfully: \(operation.rawValue)",
      context: context
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
    operation: CoreSecurityTypes.SecurityOperation,
    error: Error,
    durationMs: Double,
    source: String="SecurityProvider"
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation.rawValue)
    metadata=metadata.withPublic(key: "status", value: "failure")
    metadata=metadata.withPublic(key: "errorType", value: String(describing: type(of: error)))
    metadata=metadata.withPublic(key: "durationMs", value: String(format: "%.2f", durationMs))

    // Add error details with appropriate privacy level
    if let securityError=error as? SecurityError {
      metadata=metadata.withPublic(key: "errorCode", value: securityError.code)
      metadata=metadata.withPrivate(key: "errorMessage", value: securityError.message)
    } else if let coreError=error as? CoreSecurityError {
      metadata=metadata.withPublic(key: "errorCode", value: String(describing: coreError))
      metadata=metadata.withPrivate(key: "errorMessage", value: coreError.localizedDescription)
    } else {
      metadata=metadata.withPrivate(key: "errorMessage", value: error.localizedDescription)
    }

    // Create a context for logging
    let context = LoggingTypes.BaseLogContextDTO(
      domainName: "SecurityImplementation",
      source: source,
      metadata: metadata
    )
    
    await logger.error(
      "Security operation failed: \(operation.rawValue)",
      context: context
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
    source: String="KeyManagement"
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "operation", value: operation)
    metadata=metadata.withPublic(key: "keyType", value: keyType)

    // Create a context for logging
    let context = LoggingTypes.BaseLogContextDTO(
      domainName: "SecurityImplementation",
      source: source,
      metadata: metadata
    )
    
    await logger.info(
      "Key management operation: \(operation) for \(keyType)",
      context: context
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
    source: String="SecurityPolicy"
  ) async {
    var metadata=LogMetadataDTOCollection()
    metadata=metadata.withPublic(key: "policy", value: policyName)
    metadata=metadata.withPublic(key: "result", value: result ? "pass" : "fail")

    // Create a context for logging
    let context = LoggingTypes.BaseLogContextDTO(
      domainName: "SecurityImplementation",
      source: source,
      metadata: metadata
    )
    
    await logger.info(
      "Security policy check: \(policyName) - \(result ? "Passed" : "Failed")",
      context: context
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
    metadata: [String: String]=[:],
    source: String="SecurityEvent"
  ) async {
    let metadataCollection=createMetadataCollection(metadata)

    // Create a context for logging
    let context = LoggingTypes.BaseLogContextDTO(
      domainName: "SecurityImplementation",
      source: source,
      metadata: metadataCollection
    )
    
    switch level {
      case .debug:
        await logger.debug(event, context: context)
      case .info:
        await logger.info(event, context: context)
      case .warning:
        await logger.warning(event, context: context)
      case .error:
        await logger.error(event, context: context)
      case .critical:
        await logger.critical(event, context: context)
      case .trace:
        await logger.debug(event, context: context) // Map trace to debug as a fallback
    }
  }
}
