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
    let safeConfig = "Algorithm: \(config.algorithm), KeySize: \(config.keySize), Mode: \(config.options["mode"] ?? "none")"

    let metadata = LogMetadata([
      "operation": operation.description,
      "configuration": safeConfig,
      "timestamp": "\(Date())"
    ])

    await logger.info("Starting security operation: \(operation.description)", metadata: metadata)
  }

  /**
   Logs the successful completion of a security operation.

   - Parameters:
     - operation: The security operation that was performed
     - duration: The time taken to complete the operation in milliseconds
   */
  func logOperationSuccess(operation: SecurityOperation, duration: Double) async {
    let metadata = LogMetadata([
      "operation": operation.description,
      "durationMs": String(format: "%.2f", duration),
      "timestamp": "\(Date())"
    ])

    await logger.info(
      "Successfully completed security operation: \(operation.description)",
      metadata: metadata
    )
  }

  /**
   Logs the failure of a security operation.

   - Parameters:
     - operation: The security operation that failed
     - error: The error that occurred
     - duration: The time taken before failure in milliseconds
   */
  func logOperationFailure(operation: SecurityOperation, error: Error, duration: Double) async {
    let metadata = LogMetadata([
      "operation": operation.description,
      "errorType": "\(type(of: error))",
      "durationMs": String(format: "%.2f", duration),
      "timestamp": "\(Date())"
    ])

    await logger.error("Security operation failed: \(operation.description)", metadata: metadata)
  }
}
