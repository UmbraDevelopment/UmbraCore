import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * Executes backup operations with consistent error handling, logging, and metrics collection.
 *
 * This actor provides a centralised execution flow for all backup operations,
 * ensuring consistent treatment of logging, error handling, cancellation, and metrics.
 */
public actor BackupOperationExecutor {
  /// Logger for operation tracking
  private let logger: any LoggingProtocol

  /// Handler for operation cancellation
  private let cancellationHandler: CancellationHandlerProtocol

  /// Collector for metrics
  private let metricsCollector: BackupMetricsCollector

  /// Error mapper for creating privacy-aware error contexts
  private let errorLogContextMapper: ErrorLogContextMapper

  /// Error mapper for converting errors to backup errors
  private let errorMapper: BackupErrorMapper

  /**
   * Initialises a new operation executor.
   *
   * - Parameters:
   *   - logger: Logger for operation tracking
   *   - cancellationHandler: Handler for cancellation
   *   - metricsCollector: Collector for metrics
   *   - errorLogContextMapper: Error log context mapper
   *   - errorMapper: Error mapper
   */
  public init(
    logger: any LoggingProtocol,
    cancellationHandler: CancellationHandlerProtocol,
    metricsCollector: BackupMetricsCollector,
    errorLogContextMapper: ErrorLogContextMapper,
    errorMapper: BackupErrorMapper
  ) {
    self.logger=logger
    self.cancellationHandler=cancellationHandler
    self.metricsCollector=metricsCollector
    self.errorLogContextMapper=errorLogContextMapper
    self.errorMapper=errorMapper
  }

  /**
   * Executes an operation with consistent error handling, logging, and metrics.
   *
   * - Parameters:
   *   - parameters: The operation parameters
   *   - operation: The operation to execute
   *   - progressReporter: Optional progress reporter
   *   - cancellationToken: Optional cancellation token
   * - Returns: The operation result
   * - Throws: BackupError if the operation fails
   */
  public func execute<P: BackupOperationParameters, R>(
    parameters: P,
    operation: (P, BackupProgressReporter?, CancellationToken?) async throws -> R,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) async throws -> R {
    // Create a log context for this operation
    let logContext=BackupLogContextAdapter(
      snapshotID: getSnapshotID(from: parameters),
      operation: String(describing: parameters.operationType)
    )

    // Log the start of the operation
    await logger.info(
      "Starting backup operation: \(parameters.operationType)",
      metadata: nil,
      source: logContext.getSource()
    )

    // Record operation start for metrics
    await metricsCollector.recordOperationStarted(operation: parameters.operationType)

    // Start timing
    let startTime=Date()

    do {
      // Check for cancellation
      if let token=cancellationToken, await cancellationHandler.isOperationCancelled(id: token.id) {
        throw CancellationError()
      }

      // Validate parameters
      try parameters.validate()

      // Execute the operation
      let result=try await operation(parameters, progressReporter, cancellationToken)

      // Record operation completion for metrics
      await metricsCollector.recordOperationCompleted(
        operation: parameters.operationType,
        duration: Date().timeIntervalSince(startTime),
        success: true
      )

      // Log the completion of the operation
      await logger.info(
        "Completed backup operation: \(parameters.operationType)",
        metadata: nil,
        source: logContext.getSource()
      )

      return result
    } catch is CancellationError {
      // Record operation completion for metrics
      await metricsCollector.recordOperationCompleted(
        operation: parameters.operationType,
        duration: Date().timeIntervalSince(startTime),
        success: false
      )

      // Log the cancellation of the operation
      await logger.info(
        "Cancelled backup operation: \(parameters.operationType)",
        metadata: nil,
        source: logContext.getSource()
      )

      throw BackupError.invalidConfiguration(
        details: "Operation '\(parameters.operationType)' was cancelled"
      )
    } catch {
      // Record operation completion for metrics
      await metricsCollector.recordOperationCompleted(
        operation: parameters.operationType,
        duration: Date().timeIntervalSince(startTime),
        success: false
      )

      // Map the error to a BackupError
      let backupError=errorMapper.mapError(error, context: logContext)

      // Log the failure of the operation
      await logger.error(
        "Failed backup operation: \(parameters.operationType) - \(error.localizedDescription)",
        context: logContext
      )

      throw backupError
    }
  }

  /// Extract snapshot ID from parameters if available
  /// - Parameter parameters: Operation parameters
  /// - Returns: Snapshot ID or "unknown" if not available
  private func getSnapshotID(from parameters: some BackupOperationParameters) -> String {
    if let params=parameters as? HasSnapshotID {
      return params.snapshotID
    }
    return "unknown"
  }
}

/// Protocol for parameters that include a snapshot ID
public protocol HasSnapshotID {
  var snapshotID: String { get }
}
