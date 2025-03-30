import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes

/**
 # SecurityProvider Logging Extension

 This extension adds comprehensive logging capabilities to the SecurityProviderImpl,
 ensuring that all security operations are properly recorded with appropriate
 detail and context.

 ## Logging Standards

 Security logs follow these standards:
 - All sensitive data is redacted
 - Operation outcomes are always logged
 - Error details are captured without exposing sensitive information
 - Performance metrics are included where appropriate
 */
extension SecurityProviderImpl {
  /**
   Logs the start of a security operation.

   - Parameters:
     - operation: The security operation being performed
     - config: Configuration for the operation (sensitive data redacted)
   */
  func logOperationStart(operation: SecurityOperation, config: SecurityConfigDTO) async {
    // Create a safe version of config - don't log auth data
    let safeConfig="Algorithm: \(config.algorithm), KeySize: \(config.keySize), Mode: \(config.options["mode"] ?? "none")"

    let metadata = LoggingTypes.LogMetadata()
    metadata["operation"] = .string(operation.description)
    metadata["configuration"] = .string(safeConfig)
    metadata["timestamp"] = .string("\(Date())")

    await logInfo("Starting security operation: \(operation.description)", operation: "security_operation", additionalMetadata: [:])
  }

  /**
   Logs the successful completion of a security operation.

   - Parameters:
     - operation: The security operation that was performed
     - duration: The time taken to complete the operation in milliseconds
   */
  func logOperationSuccess(operation: SecurityOperation, duration: Double) async {
    let metadata = LoggingTypes.LogMetadata()
    metadata["operation"] = .string(operation.description)
    metadata["durationMs"] = .string(String(format: "%.2f", duration))
    metadata["timestamp"] = .string("\(Date())")

    await logInfo("Successfully completed security operation: \(operation.description)", operation: "security_operation", additionalMetadata: [:])
  }

  /**
   Logs the failure of a security operation.

   - Parameters:
     - operation: The security operation that failed
     - error: The error that occurred
     - duration: The time taken before failure in milliseconds
   */
  func logOperationFailure(operation: SecurityOperation, error: Error, duration: Double) async {
    let metadata = LoggingTypes.LogMetadata()
    metadata["operation"] = .string(operation.description)
    metadata["errorType"] = .string("\(type(of: error))")
    metadata["durationMs"] = .string(String(format: "%.2f", duration))
    metadata["timestamp"] = .string("\(Date())")

    await logError("Security operation failed: \(operation.description)", operation: "security_operation", error: error, additionalMetadata: [:])
  }

  /**
   Logs debug information with standardised metadata formatting.
   
   - Parameters:
     - message: The log message to record
     - operation: Operation identifier for tracking
     - additionalMetadata: Any extra metadata to include
   */
  internal func logDebug(
    _ message: String,
    operation: String,
    additionalMetadata: [String: String] = [:]
  ) async {
    guard let logger = _logger else { return }
    
    // Create base metadata
    let metadata = LoggingTypes.LogMetadata()
    metadata["component"] = .string("SecurityProvider")
    metadata["operation"] = .string(operation)
    
    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata[key] = .string(value)
    }
    
    await logger.debug(message, metadata: metadata, source: "SecurityProvider")
  }
  
  /**
   Logs informational messages with standardised metadata formatting.
   
   - Parameters:
     - message: The log message to record
     - operation: Operation identifier for tracking
     - additionalMetadata: Any extra metadata to include
   */
  internal func logInfo(
    _ message: String,
    operation: String,
    additionalMetadata: [String: String] = [:]
  ) async {
    guard let logger = _logger else { return }
    
    // Create base metadata
    let metadata = LoggingTypes.LogMetadata()
    metadata["component"] = .string("SecurityProvider")
    metadata["operation"] = .string(operation)
    
    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata[key] = .string(value)
    }
    
    await logger.info(message, metadata: metadata, source: "SecurityProvider")
  }
  
  /**
   Logs error information with standardised metadata formatting.
   
   - Parameters:
     - message: The error message to record
     - operation: Operation identifier for tracking
     - error: Optional error object to include details from
     - additionalMetadata: Any extra metadata to include
   */
  internal func logError(
    _ message: String,
    operation: String,
    error: Error? = nil,
    additionalMetadata: [String: String] = [:]
  ) async {
    guard let logger = _logger else { return }
    
    // Create base metadata
    let metadata = LoggingTypes.LogMetadata()
    metadata["component"] = .string("SecurityProvider")
    metadata["operation"] = .string(operation)
    
    // Add error details if provided
    if let error = error {
      metadata["errorType"] = .string("\(type(of: error))")
      metadata["errorDescription"] = .string(error.localizedDescription)
    }
    
    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata[key] = .string(value)
    }
    
    await logger.error(message, metadata: metadata, source: "SecurityProvider")
  }
}
