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
      metadata: logContext.toPrivacyMetadata(),
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
      metadata: logContext.toPrivacyMetadata(),
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
      metadata: logContext.toPrivacyMetadata(),
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
    var metadata=logContext.toPrivacyMetadata()

    // Add error information to metadata
    metadata["error"]=PrivacyMetadataValue(value: errorDescription, privacy: .private)
    metadata["errorType"]=PrivacyMetadataValue(value: String(describing: type(of: error)),
                                               privacy: .public)

    await logger.error(
      message,
      metadata: metadata,
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
      metadata: logContext.toPrivacyMetadata(),
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
    var metadata=PrivacyMetadata()

    if let snapshotID {
      metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)
    }

    if let repositoryID {
      metadata["repositoryID"]=PrivacyMetadataValue(value: repositoryID, privacy: .public)
    }

    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata[key]=PrivacyMetadataValue(anyValue: value, privacy: .auto)
    }

    await logger.info(
      "Starting snapshot operation: \(operation)",
      metadata: metadata,
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
    var metadata=PrivacyMetadata()

    if let snapshotID {
      metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)
    }

    if let repositoryID {
      metadata["repositoryID"]=PrivacyMetadataValue(value: repositoryID, privacy: .public)
    }

    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)
    metadata["status"]=PrivacyMetadataValue(value: "success", privacy: .public)

    // Add result information
    for (key, value) in result {
      metadata[key]=PrivacyMetadataValue(anyValue: value, privacy: .auto)
    }

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata[key]=PrivacyMetadataValue(anyValue: value, privacy: .auto)
    }

    await logger.info(
      "Completed snapshot operation: \(operation)",
      metadata: metadata,
      source: "SnapshotService"
    )
  }

  /**
   Logs an error that occurred during a snapshot operation.

   - Parameters:
      - snapshotID: Optional ID of the snapshot
      - repositoryID: Optional ID of the repository
      - operation: The operation where the error occurred
      - error: The error that occurred
      - additionalMetadata: Any additional metadata to include
   */
  public func logOperationError(
    snapshotID: String?=nil,
    repositoryID: String?=nil,
    operation: String,
    error: Error,
    additionalMetadata: [String: Any]=[:]
  ) async {
    var metadata=PrivacyMetadata()

    if let snapshotID {
      metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)
    }

    if let repositoryID {
      metadata["repositoryID"]=PrivacyMetadataValue(value: repositoryID, privacy: .public)
    }

    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)
    metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
    metadata["errorType"]=PrivacyMetadataValue(value: String(describing: type(of: error)),
                                               privacy: .public)

    // Add any additional metadata
    for (key, value) in additionalMetadata {
      metadata[key]=PrivacyMetadataValue(anyValue: value, privacy: .auto)
    }

    await logger.error(
      "Error during snapshot operation: \(operation)",
      metadata: metadata,
      source: "SnapshotService"
    )
  }
}
