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
    let _operationType=parameters.operationType
    let snapshotID=getSnapshotID(from: parameters)

    // Create log context for privacy-aware logging
    let logContext = SnapshotLogContext(
      operation: parameters.operationType.rawValue,
      source: "SnapshotOperationExecutor"
    )
    .withPublic(key: "operation_type", value: parameters.operationType.rawValue)
    .withPublic(key: "operation_id", value: parameters.operationID)
    
    // Add snapshot ID if available
    if let snapshotID = snapshotID, !snapshotID.isEmpty {
      logContext.withPublic(key: "snapshot_id", value: snapshotID)
    }
    
    // Add repository ID if available
    if let repositoryID = parameters.repositoryID, !repositoryID.isEmpty {
      logContext.withPublic(key: "repository_id", value: repositoryID)
    }

    // Start time for metrics
    let startTime=Date()

    // Log operation start
    await logger.info(
      "Starting snapshot operation: \(parameters.operationType.rawValue)",
      context: logContext
    )

    // Report initial progress
    if let reporter=progressReporter {
      await reporter.reportProgress(
        BackupProgressInfo(
          phase: .initialising,
          percentComplete: 0.0,
          itemsProcessed: 0,
          totalItems: 0,
          bytesProcessed: 0,
          totalBytes: 0,
          estimatedTimeRemaining: nil,
          error: nil,
          details: "Initialising backup operation",
          isCancellable: cancellationToken != nil
        ),
        for: convertToBackupOperation(parameters.operationType)
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

      // Report completion progress
      if let reporter=progressReporter {
        await reporter.reportProgress(
          BackupProgressInfo(
            phase: .completed,
            percentComplete: 100.0,
            itemsProcessed: 0,
            totalItems: 0,
            bytesProcessed: 0,
            totalBytes: 0,
            estimatedTimeRemaining: 0,
            error: nil,
            details: "Operation completed successfully",
            isCancellable: false
          ),
          for: convertToBackupOperation(parameters.operationType)
        )
      }

      // Log successful completion
      await logger.info(
        "Completed snapshot operation: \(parameters.operationType.rawValue)",
        context: logContext
      )

      // Record metrics
      await metricsCollector.recordOperationCompleted(
        operation: parameters.operationType.rawValue,
        duration: duration,
        success: true
      )

      return result
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Map error to domain-specific error with context
      let backupError=errorMapper.mapError(error, context: logContext)

      // Report failure progress
      if let reporter=progressReporter {
        await reporter.reportProgress(
          BackupProgressInfo(
            phase: .failed,
            percentComplete: 100.0,
            itemsProcessed: 0,
            totalItems: 0,
            bytesProcessed: 0,
            totalBytes: 0,
            estimatedTimeRemaining: nil,
            error: backupError,
            details: "Operation failed: \(backupError.localizedDescription)",
            isCancellable: false
          ),
          for: convertToBackupOperation(parameters.operationType)
        )
      }

      // Create error context with privacy controls
      let errorContext=SnapshotLogContext(
        operation: parameters.operationType.rawValue,
        snapshotID: snapshotID,
        errorMessage: backupError.localizedDescription
      )

      // Log error with privacy-aware context
      await logger.error(
        "Failed snapshot operation: \(parameters.operationType.rawValue) - \(backupError.localizedDescription)",
        context: errorContext
      )

      // Record error metrics
      await metricsCollector.recordOperationCompleted(
        operation: parameters.operationType.rawValue,
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
