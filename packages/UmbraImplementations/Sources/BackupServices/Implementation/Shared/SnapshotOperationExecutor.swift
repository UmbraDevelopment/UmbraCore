import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 * Type alias to clarify we're using the DTO version of parameters
 */
typealias OperationParametersType=BackupServices.SnapshotOperationParameters

/**
 * Executor for snapshot operations that provides consistent
 * error handling, logging, and metric collection.
 *
 * This follows the Alpha Dot Five architecture pattern of using
 * a dedicated component for operation execution with cross-cutting
 * concerns like logging separated from business logic.
 */
public actor SnapshotOperationExecutor {
  // MARK: - Dependencies

  /// Service for executing Restic commands
  private let resticService: ResticServiceProtocol

  /// Handler for operation cancellation
  private let cancellationHandler: CancellationHandlerProtocol

  /// Collector for operation metrics
  private let metricsCollector: BackupMetricsCollector

  /// Logger for operation events
  private let logger: any LoggingProtocol

  /// Error mapper for consistent error handling
  private let errorMapper: BackupErrorMapper

  // MARK: - Initialization

  /**
   * Initialises a new snapshot operation executor.
   *
   * - Parameters:
   *   - resticService: Service to execute Restic commands
   *   - cancellationHandler: Handler for operation cancellation
   *   - metricsCollector: Collector for operation metrics
   *   - logger: Logger for operation events
   *   - errorMapper: Error mapper for consistent error handling
   */
  public init(
    resticService: ResticServiceProtocol,
    cancellationHandler: CancellationHandlerProtocol,
    metricsCollector: BackupMetricsCollector,
    logger: any LoggingProtocol,
    errorMapper: BackupErrorMapper
  ) {
    self.resticService=resticService
    self.cancellationHandler=cancellationHandler
    self.metricsCollector=metricsCollector
    self.logger=logger
    self.errorMapper=errorMapper
  }

  // MARK: - Public Methods

  /**
   * Executes a snapshot operation with consistent logging and error handling.
   *
   * - Parameters:
   *   - parameters: Parameters for the operation
   *   - progressReporter: Reporter for progress updates
   *   - cancellationToken: Token for cancellation
   *   - operation: The operation to execute
   * - Returns: The result of the operation
   * - Throws: BackupOperationError if the operation fails
   */
  public func execute<P: SnapshotOperationParameters, R>(
    parameters: P,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?,
    operation: @escaping (P, BackupProgressReporter?, BackupCancellationToken?) async throws -> R
  ) async throws -> R {
    // Extract operation type and snapshot ID for use throughout the method
    let operationType=parameters.operationType
    let snapshotID=getSnapshotID(from: parameters)

    // Create log context for privacy-aware logging
    let logContext=SnapshotLogContext(
      operation: operationType.rawValue,
      snapshotID: snapshotID
    )

    // Get source and metadata for logging
    let source="SnapshotService.\(operationType.rawValue)"
    let metadata=logContext.toPrivacyMetadata()

    // Start time for metrics
    let startTime=Date()

    // Log operation start
    await logger.info(
      "Starting snapshot operation: \(operationType.rawValue)",
      metadata: metadata,
      source: source
    )

    // Report progress start
    if let reporter=progressReporter {
      await reporter.reportProgress(
        BackupProgressInfo(
          phase: .initialising,
          percentComplete: 0.0,
          message: "Initialising \(operationType.rawValue) operation",
          itemsProcessed: 0,
          totalItems: 0,
          bytesProcessed: 0,
          totalBytes: 0,
          elapsedTime: 0,
          estimatedTimeRemaining: nil
        ),
        for: convertToBackupOperation(operationType)
      )
    }

    do {
      // Validate operation parameters
      try parameters.validate()

      // Execute the operation with cancellation support
      let result=try await cancellationHandler.withCancellationSupport({
        try await operation(parameters, progressReporter, cancellationToken)
      }, cancellationToken: cancellationToken)

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Report progress complete
      if let reporter=progressReporter {
        await reporter.reportProgress(
          BackupProgressInfo(
            phase: .completed,
            percentComplete: 1.0,
            message: "Completed \(operationType.rawValue) operation",
            itemsProcessed: 0,
            totalItems: 0,
            bytesProcessed: 0,
            totalBytes: 0,
            elapsedTime: 0,
            estimatedTimeRemaining: nil
          ),
          for: convertToBackupOperation(operationType)
        )
      }

      // Log successful completion
      var completionMetadata=metadata
      completionMetadata["duration"]=PrivacyMetadataValue(value: String(format: "%.2f", duration),
                                                          privacy: .public)

      await logger.info(
        "Completed snapshot operation: \(operationType.rawValue)",
        metadata: completionMetadata,
        source: source
      )

      // Record metrics
      await metricsCollector.recordOperationCompleted(
        operation: operationType.rawValue,
        duration: duration,
        success: true
      )

      return result
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Map error to domain-specific error with context
      let backupError=errorMapper.mapError(error, context: logContext)

      // Report progress failure
      if let reporter=progressReporter {
        await reporter.reportProgress(
          BackupProgressInfo(
            phase: .failed,
            percentComplete: 1.0,
            message: "Failed \(operationType.rawValue) operation",
            itemsProcessed: 0,
            totalItems: 0,
            bytesProcessed: 0,
            totalBytes: 0,
            elapsedTime: 0,
            estimatedTimeRemaining: nil
          ),
          for: convertToBackupOperation(operationType)
        )
      }

      // Create error context with privacy controls
      let errorContext=SnapshotLogContext(
        operation: operationType.rawValue,
        snapshotID: snapshotID,
        errorMessage: backupError.localizedDescription
      )

      // Log error with privacy-aware context
      await logger.error(
        "Failed snapshot operation: \(operationType.rawValue)",
        metadata: errorContext.toPrivacyMetadata(),
        source: source
      )

      // Record error metrics
      await metricsCollector.recordOperationCompleted(
        operation: operationType.rawValue,
        duration: duration,
        success: false
      )

      // Rethrow the mapped error
      throw backupError
    }
  }

  // MARK: - Helper Methods

  /**
   * Converts a SnapshotOperationType to the equivalent BackupOperation
   *
   * - Parameter type: The snapshot operation type
   * - Returns: The corresponding backup operation
   */
  private func convertToBackupOperation(_ type: SnapshotOperationType) -> BackupOperation {
    switch type {
      case .list:
        .listSnapshots
      case .get:
        .getSnapshotDetails
      case .compare:
        .compareSnapshots
      case .verify:
        .verifySnapshot
      case .restore:
        .restoreBackup
      case .delete:
        .deleteBackup
      case .find:
        .findFiles
      case .updateTags:
        .updateTags
      case .updateDescription:
        .updateDescription
      default:
        // For any other operations, default to the most relevant general operation
        .maintenance
    }
  }

  /// Extract snapshot ID from parameters if available
  /// - Parameter parameters: Operation parameters
  /// - Returns: Snapshot ID or "unknown" if not available
  private func getSnapshotID(from parameters: some SnapshotOperationParameters) -> String {
    if let params=parameters as? HasSnapshotID {
      return params.snapshotID
    }
    return "unknown"
  }
}
