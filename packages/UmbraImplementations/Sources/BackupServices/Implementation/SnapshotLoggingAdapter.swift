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
      metadata: logContext.metadata.toPrivacyMetadata(),
      source: "SnapshotService"
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
      metadata: logContext.metadata.toPrivacyMetadata(),
      source: "SnapshotService"
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
      metadata: logContext.metadata.toPrivacyMetadata(),
      source: "SnapshotService"
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
    let errorDescription=error.localizedDescription
    let message="Operation failed: \(errorDescription)"
    
    // Create a new metadata collection with error information
    var metadataCollection=logContext.metadata
    metadataCollection=metadataCollection.withPrivate(key: "error", value: errorDescription)
    metadataCollection=metadataCollection.withPublic(key: "errorType", value: String(describing: type(of: error)))

    await logger.error(
      message,
      metadata: metadataCollection.toPrivacyMetadata(),
      source: logContext.getSource()
    )
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
      metadata: logContext.metadata.toPrivacyMetadata(),
      source: logContext.getSource()
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
    var metadataCollection=LogMetadataDTOCollection()

    if let snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let repositoryID {
      metadataCollection=metadataCollection.withPublic(key: "repositoryID", value: repositoryID)
    }

    metadataCollection=metadataCollection.withPublic(key: "operation", value: operation)

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      let stringValue=String(describing: value)
      metadataCollection=metadataCollection.withAuto(key: key, value: stringValue)
    }

    await logger.info(
      "Starting snapshot operation: \(operation)",
      metadata: metadataCollection.toPrivacyMetadata(),
      source: "SnapshotService"
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
    var metadataCollection=LogMetadataDTOCollection()

    if let snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let repositoryID {
      metadataCollection=metadataCollection.withPublic(key: "repositoryID", value: repositoryID)
    }

    metadataCollection=metadataCollection.withPublic(key: "operation", value: operation)
    metadataCollection=metadataCollection.withPublic(key: "status", value: "success")

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      let stringValue=String(describing: value)
      metadataCollection=metadataCollection.withAuto(key: key, value: stringValue)
    }

    // Add result information
    for (key, value) in result {
      let stringValue=String(describing: value)
      metadataCollection=metadataCollection.withAuto(key: key, value: stringValue)
    }

    await logger.info(
      "Snapshot operation completed: \(operation)",
      metadata: metadataCollection.toPrivacyMetadata(),
      source: "SnapshotService"
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
    var metadataCollection=LogMetadataDTOCollection()

    if let snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let repositoryID {
      metadataCollection=metadataCollection.withPublic(key: "repositoryID", value: repositoryID)
    }

    metadataCollection=metadataCollection.withPublic(key: "operation", value: operation)
    metadataCollection=metadataCollection.withPrivate(key: "error", value: error.localizedDescription)
    metadataCollection=metadataCollection.withPublic(key: "errorType", value: String(describing: type(of: error)))

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      let stringValue=String(describing: value)
      metadataCollection=metadataCollection.withAuto(key: key, value: stringValue)
    }

    await logger.error(
      "Error during snapshot operation: \(operation)",
      metadata: metadataCollection.toPrivacyMetadata(),
      source: "SnapshotService"
    )
  }
}
