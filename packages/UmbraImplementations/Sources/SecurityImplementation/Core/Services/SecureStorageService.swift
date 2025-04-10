import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 * SecureStorageService handles secure data storage operations.
 *
 * This implementation follows the Alpha Dot Five architecture with:
 * - Privacy-aware logging
 * - Actor-based concurrency
 * - Enhanced error handling
 */
final class SecureStorageService: SecurityServiceBase {
  // MARK: - Properties
  
  /// The logger instance for recording operation details
  let logger: LoggingProtocol
  
  /**
   Initialises the service with required dependencies
   
   - Parameters:
       - logger: The logging service to use for operation logging
   */
  required init(logger: LoggingProtocol) {
    self.logger = logger
  }
  
  /**
   Creates standard logging metadata for security operations
   
   - Parameters:
       - operationID: Unique identifier for the operation
       - operation: The type of operation being performed
       - config: Configuration for the operation
   - Returns: A metadata collection for logging
   */
  func createOperationMetadata(
    operationID: String,
    operation: CoreSecurityTypes.SecurityOperation,
    config: SecurityConfigDTO
  ) -> LogMetadataDTOCollection {
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: operation.rawValue)
    
    // Add configuration metadata
    if let options = config.options, let optionsMetadata = options.metadata {
      for (key, value) in optionsMetadata where !key.starts(with: "sensitive_") {
        metadata = metadata.withPublic(key: key, value: value)
      }
    }
    
    return metadata
  }
  
  /**
   * Securely retrieves data with the specified configuration
   *
   * - Parameter config: The configuration for the retrieval operation
   * - Returns: A security result containing the retrieved data
   */
  func secureRetrieve(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = CoreSecurityTypes.SecurityOperation.retrieveKey // Using retrieveKey as the appropriate operation type
    
    // Create logging context with standard metadata
    let logContext = SecurityLogContext(
      operation: operation.rawValue,
      component: "SecureStorageService",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )
    
    await logger.info(
      "Starting secure retrieval operation", 
      context: logContext
    )
    
    do {
      // Extract required parameters from configuration
      guard let options = config.options, let identifier = options.metadata?["identifier"] else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }
      
      // Perform the retrieval operation
      let result = try await retrieveData(withIdentifier: identifier)
      
      switch result {
        case let .success(retrievalResult):
          // Calculate duration for metrics
          let duration = Date().timeIntervalSince(startTime) * 1000
          
          // Create success metadata for logging
          let successMetadata = LogMetadataDTOCollection()
            .withPublic(key: "operationId", value: operationID)
            .withPublic(key: "operation", value: operation.rawValue)
            .withPublic(key: "durationMs", value: String(format: "%.2f", duration))
            .withPublic(key: "storageIdentifier", value: identifier)
          
          // Create a context for logging success
          let successContext = SecurityLogContext(
            operation: operation.rawValue,
            component: "StorageService",
            correlationID: operationID,
            source: "SecurityImplementation",
            metadata: successMetadata
          )
          
          await logger.info(
            "Secure retrieval operation completed successfully",
            context: successContext
          )
          
          // Return successful result with retrieved data
          return SecurityResultDTO.success(
            resultData: retrievalResult.data,
            executionTimeMs: duration,
            metadata: [
              "durationMs": String(format: "%.2f", duration),
              "storageIdentifier": identifier,
              "algorithm": retrievalResult
                .metadata["algorithm"] ?? "unknown"
            ]
          )
          
        case let .failure(error):
          // Calculate duration before failure
          let duration = Date().timeIntervalSince(startTime) * 1000
          
          // Create failure metadata for logging with privacy annotations
          let errorMetadata = LogMetadataDTOCollection()
            .withPublic(key: "operationId", value: operationID)
            .withPublic(key: "operation", value: operation.rawValue)
            .withPublic(key: "durationMs", value: String(format: "%.2f", duration))
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
          
          // Create a proper context with privacy-aware metadata
          let errorContext = SecurityLogContext(
            operation: operation.rawValue,
            component: "StorageService",
            correlationID: operationID,
            source: "SecurityImplementation",
            metadata: errorMetadata
          )
          
          await logger.error(
            "Secure retrieval operation failed: \(error.localizedDescription)",
            context: errorContext
          )
          
          // Return failure result
          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: duration,
            metadata: [
              "durationMs": String(format: "%.2f", duration),
              "errorMessage": error.localizedDescription
            ]
          )
      }
    } catch {
      // This catch block now handles only errors thrown before the switch statement
      // Calculate duration before failure
      let duration = Date().timeIntervalSince(startTime) * 1000
      
      // Return failure result
      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "errorMessage": error.localizedDescription
        ]
      )
    }
  }
  
  /**
   * Simulates retrieving data securely
   *
   * In a real implementation, this would use a secure storage mechanism.
   */
  private func retrieveData(withIdentifier identifier: String) async throws -> Result<StorageResult, Error> {
    // This is a placeholder implementation
    // In a real implementation, this would retrieve data from a secure storage
    // For now, return a simulated result
    return .success(StorageResult(
      data: Data(), // Empty data as a placeholder
      metadata: [
        "algorithm": "AES-GCM",
        "storageIdentifier": identifier
      ]
    ))
  }
}

/**
 * Storage result model
 */
struct StorageResult {
  let data: Data
  let metadata: [String: String]
}
