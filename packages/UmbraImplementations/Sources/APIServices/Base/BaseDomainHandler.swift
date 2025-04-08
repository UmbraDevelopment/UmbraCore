import APIInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 # Base Domain Handler
 
 Provides common functionality for all domain handlers within the Alpha Dot Five architecture.
 This base implementation standardises logging, error handling, and operation execution patterns
 across all domain handlers.
 
 ## Actor-Based Concurrency
 
 This handler is implemented as an actor to ensure thread safety and memory isolation
 throughout all operations. The actor-based design provides automatic synchronisation
 and eliminates potential race conditions when handling concurrent requests.
 
 ## Privacy-Enhanced Logging
 
 All operations are logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.
 
 ## Standardised Error Handling
 
 Error handling is standardised across all domain handlers, with proper mapping
 from domain-specific errors to API errors.
 */
public actor BaseDomainHandler {
  /// The domain name for this handler
  public nonisolated let domain: String
  
  /// Logger with privacy controls
  private let logger: (any LoggingProtocol)?
  
  /**
   Initialises a new base domain handler.
   
   - Parameters:
      - domain: The domain name for this handler
      - logger: Optional logger for privacy-aware operation recording
   */
  public init(domain: String, logger: (any LoggingProtocol)? = nil) {
    self.domain = domain
    self.logger = logger
  }
  
  // MARK: - Logging Helpers
  
  /**
   Creates base metadata for logging with common fields.
   
   - Parameters:
     - operation: The operation name
     - event: The event type (start, success, failure)
   - Returns: Metadata collection with common fields
   */
  public func createBaseMetadata(operation: String, event: String) -> LogMetadataDTOCollection {
    LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "event", value: event)
      .withPublic(key: "domain", value: domain)
  }
  
  /**
   Logs the start of an operation with optimised metadata creation.
   
   - Parameters:
     - operationName: The name of the operation being executed
     - source: The source of the log (typically the handler class name)
   */
  public func logOperationStart(operationName: String, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .info) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "start")
      
      await logger?.info(
        "Starting \(domain) operation: \(operationName)",
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Logs the successful completion of an operation with optimised metadata creation.
   
   - Parameters:
     - operationName: The name of the operation that completed
     - source: The source of the log (typically the handler class name)
   */
  public func logOperationSuccess(operationName: String, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .info) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "success")
        .withPublic(key: "status", value: "completed")
      
      await logger?.info(
        "\(domain) operation completed successfully",
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Logs the failure of an operation with optimised metadata creation.
   
   - Parameters:
     - operationName: The name of the operation that failed
     - error: The error that caused the failure
     - source: The source of the log (typically the handler class name)
   */
  public func logOperationFailure(operationName: String, error: Error, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .error) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "failure")
        .withPublic(key: "status", value: "failed")
        .withPrivate(key: "error", value: error.localizedDescription)
      
      await logger?.error(
        "\(domain) operation failed: \(error.localizedDescription)",
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Logs a critical error with optimised metadata creation.
   
   - Parameters:
     - message: The error message
     - operationName: The name of the operation that encountered the critical error
     - source: The source of the log (typically the handler class name)
   */
  public func logCriticalError(message: String, operationName: String, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .critical) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "critical_error")
        .withPublic(key: "error_domain", value: domain)
      
      await logger?.critical(
        message,
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Logs a debug message with optimised metadata creation.
   
   - Parameters:
     - message: The debug message
     - operationName: The name of the operation
     - source: The source of the log (typically the handler class name)
     - additionalMetadata: Optional additional metadata to include
   */
  public func logDebug(
    message: String,
    operationName: String,
    source: String,
    additionalMetadata: LogMetadataDTOCollection? = nil
  ) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .debug) == true {
      var metadata = createBaseMetadata(operation: operationName, event: "debug")
      
      // Add additional metadata if provided
      if let additionalMetadata = additionalMetadata {
        metadata = metadata.merging(with: additionalMetadata)
      }
      
      await logger?.debug(
        message,
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  // MARK: - Error Handling
  
  /**
   Maps domain-specific errors to standardised API errors.
   
   This is a base implementation that should be overridden by subclasses
   to provide domain-specific error mapping.
   
   - Parameter error: The original error
   - Returns: An APIError instance
   */
  public func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError = error as? APIError {
      return apiError
    }
    
    // Default to internal error for unhandled error types
    return APIError.internalError(
      message: "An unexpected error occurred: \(error.localizedDescription)",
      underlyingError: error
    )
  }
}
