import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 A simple adapter that enables privacy-aware snapshot logging without requiring
 modifications to the core logging infrastructure.

 This adapter handles the conversion between existing logging types and the new
 privacy-enhanced logging structures, allowing the SnapshotServiceImpl to continue
 functioning while we transition to the new privacy-aware logging system.
 */
public struct SnapshotLoggingAdapter {
  /// The underlying logger
  private let logger: LoggingProtocol

  /**
   Creates a new snapshot logging adapter.

   - Parameter logger: The core logger to wrap
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   Logs the start of a snapshot operation using a structured log context.

   - Parameters:
      - logContext: The structured log context with privacy metadata
      - message: Optional custom message override
   */
  public func logOperationStart(
    logContext: SnapshotLogContext,
    message: String?=nil
  ) async {
    let defaultMessage="Starting snapshot operation: \(logContext.operation)"

    await logger.info(
      message ?? defaultMessage,
      context: logContext // Pass the whole context
    )
  }

  /**
   Logs the successful completion of a snapshot operation using a structured log context.

   - Parameters:
      - logContext: The structured log context with privacy metadata
      - message: Optional custom message override
   */
  public func logOperationSuccess(
    logContext: SnapshotLogContext,
    message: String?=nil
  ) async {
    let defaultMessage="Completed snapshot operation: \(logContext.operation)"

    await logger.info(
      message ?? defaultMessage,
      context: logContext // Pass the whole context
    )
  }

  /**
   Logs an error that occurred during a snapshot operation using a structured log context.

   - Parameters:
      - logContext: The structured log context with privacy metadata
      - message: Optional custom message override
      - error: Optional specific error to log (if not included in context)
   */
  public func logOperationError(
    logContext: SnapshotLogContext,
    message: String?=nil,
    error _: Error?=nil
  ) async {
    let defaultMessage="Error during snapshot operation: \(logContext.operation)"

    await logger.error(
      message ?? defaultMessage,
      context: logContext // Pass the whole context
    )
  }

  /**
   Logs an operation failure with the error that occurred.

   - Parameters:
      - error: The error that occurred during the operation
      - logContext: The structured log context with privacy metadata
   */
  public func logOperationFailure(
    error: Error,
    logContext: LogContextDTO
  ) async {
    let errorDescription = error.localizedDescription
    let message = "Operation failed: \(errorDescription)"

    // For type safety, create a proper SnapshotLogContext if needed
    let snapshotContext: SnapshotLogContext
    if let context = logContext as? SnapshotLogContext {
      snapshotContext = context
    } else {
      // Create a new context with the existing metadata
      snapshotContext = SnapshotLogContext(
        operation: "unknown",
        metadata: logContext.metadata
      )
    }
    
    // Add error information with proper privacy annotations
    let updatedContext = snapshotContext
      .withPublic(key: "status", value: "error")
      .withPublic(key: "errorType", value: String(describing: type(of: error)))
      .withPrivate(key: "errorMessage", value: errorDescription)

    await logger.error(
      message,
      context: updatedContext
    )
  }

  /**
   Logs a snapshot operation with detailed progress information.

   - Parameters:
      - operation: The operation being performed
      - phase: The current phase of the operation
      - progress: Optional progress percentage (0.0-1.0)
      - details: Optional additional details about the operation
   */
  public func logSnapshotOperation(
    operation: String,
    phase: String,
    progress: Double? = nil,
    details: [String: String]? = nil
  ) async {
    // Create a context with all the information using proper privacy annotations
    var context = SnapshotLogContext(operation: operation)
      .withPublic(key: "phase", value: phase)
    
    if let progress = progress {
      context = context.withPublic(
        key: "progress", 
        value: String(format: "%.1f%%", progress * 100)
      )
    }
    
    // Add any additional details with appropriate privacy levels
    if let details = details {
      for (key, value) in details {
        // Determine privacy level based on the key
        if key.contains("path") || key.contains("file") || key.contains("directory") {
          // Paths may contain sensitive information
          context = context.withPrivate(key: key, value: value)
        } else if key.contains("id") || key.contains("hash") {
          // IDs and hashes are generally public
          context = context.withPublic(key: key, value: value)
        } else if key.contains("user") || key.contains("password") || key.contains("key") {
          // User data and credentials are sensitive
          context = context.withSensitive(key: key, value: value)
        } else {
          // Default to private for unknown keys
          context = context.withPrivate(key: key, value: value)
        }
      }
    }
    
    let message = progress != nil
      ? "Snapshot operation: \(operation) - \(phase) (\(String(format: "%.1f%%", progress! * 100)))"
      : "Snapshot operation: \(operation) - \(phase)"
    
    await logger.info(message, context: context)
  }

  /**
   Logs an operation with a general LogContextDTO, providing compatibility with the new adapter pattern.

   - Parameters:
      - logContext: Any log context that implements LogContextDTO
      - message: Optional custom message override
   */
  public func logOperationSuccess(
    logContext: LogContextDTO,
    message: String?=nil
  ) async {
    let defaultMessage="Operation completed successfully"

    await logger.info(
      message ?? defaultMessage,
      context: logContext // Pass the whole context
    )
  }

  /**
   Logs the start of a snapshot operation.

   - Parameters:
      - snapshotID: Optional ID of the snapshot
      - repositoryID: Optional ID of the repository
      - operation: The operation being performed
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationStart(
    snapshotID: String?=nil,
    repositoryID: String?=nil,
    operation: String,
    additionalMetadata: [String: Any]=[:]
  ) async {
    // Create a metadata collection with all the information
    var metadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)

    if let snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let repositoryID {
      metadataCollection=metadataCollection.withPublic(key: "repositoryID", value: repositoryID)
    }

    // Add any additional metadata with appropriate privacy levels
    for (key, value) in additionalMetadata {
      if let stringValue=value as? String {
        metadataCollection=metadataCollection.withPrivate(key: key, value: stringValue)
      } else {
        metadataCollection=metadataCollection.withPrivate(key: key, value: String(describing: value))
      }
    }

    // Create a context for this log message
    let context=BaseLogContextDTO(
      domainName: "SnapshotService",
      source: "SnapshotService.\(operation)",
      metadata: metadataCollection
    )

    await logger.info(
      "Starting snapshot operation: \(operation)",
      context: context
    )
  }

  /**
   Logs the successful completion of a snapshot operation.

   - Parameters:
      - snapshotID: Optional ID of the snapshot
      - repositoryID: Optional ID of the repository
      - operation: The operation that was performed
      - result: Optional result information
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationSuccess(
    snapshotID: String?=nil,
    repositoryID: String?=nil,
    operation: String,
    result: [String: Any]=[:],
    additionalMetadata: [String: Any]=[:]
  ) async {
    // Create a metadata collection with all the information
    var metadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "status", value: "success")

    if let snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let repositoryID {
      metadataCollection=metadataCollection.withPublic(key: "repositoryID", value: repositoryID)
    }

    // Add any additional metadata with appropriate privacy levels
    for (key, value) in additionalMetadata {
      if let stringValue=value as? String {
        metadataCollection=metadataCollection.withPrivate(key: key, value: stringValue)
      } else {
        metadataCollection=metadataCollection.withPrivate(key: key, value: String(describing: value))
      }
    }

    // Create a context for this log message
    let context=BaseLogContextDTO(
      domainName: "SnapshotService",
      source: "SnapshotService.\(operation)",
      metadata: metadataCollection
    )

    await logger.info(
      "Completed snapshot operation: \(operation)",
      context: context
    )
  }

  /**
   Logs an error during a snapshot operation.

   - Parameters:
      - error: The error that occurred
      - snapshotID: Optional ID of the snapshot
      - repositoryID: Optional ID of the repository
      - operation: The operation that was performed
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationError(
    error: Error,
    snapshotID: String?=nil,
    repositoryID: String?=nil,
    operation: String,
    additionalMetadata: [String: Any]=[:]
  ) async {
    // Create a metadata collection with all the information
    var metadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "status", value: "error")

    if let snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let repositoryID {
      metadataCollection=metadataCollection.withPublic(key: "repositoryID", value: repositoryID)
    }

    // Add error information with appropriate privacy levels
    metadataCollection=metadataCollection.withPrivate(key: "errorMessage", value: error.localizedDescription)
    metadataCollection=metadataCollection.withPublic(key: "errorType", value: String(describing: type(of: error)))

    // Add any additional metadata with appropriate privacy levels
    for (key, value) in additionalMetadata {
      if let stringValue=value as? String {
        metadataCollection=metadataCollection.withPrivate(key: key, value: stringValue)
      } else {
        metadataCollection=metadataCollection.withPrivate(key: key, value: String(describing: value))
      }
    }

    // Create a context for this log message
    let context=BaseLogContextDTO(
      domainName: "SnapshotService",
      source: "SnapshotService.\(operation)",
      metadata: metadataCollection
    )

    await logger.error(
      "Error during snapshot operation: \(operation) - \(error.localizedDescription)",
      context: context
    )
  }
}
