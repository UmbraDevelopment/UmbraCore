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
   * Executes a backup operation with progress reporting and cancellation support.
   *
   * - Parameters:
   *   - parameters: The operation parameters
   *   - operation: The operation to execute
   *   - progressReporter: Optional progress reporter
   *   - cancellationToken: Optional cancellation token
   * - Returns: The operation result
   * - Throws: BackupOperationError if the operation fails
   */
  public func execute<P: BackupOperationParameters, R>(
    parameters: P,
    operation: (P, BackupProgressReporter?, BackupCancellationToken?) async throws -> R,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> R {
    // Create a log context for this operation
    let logContext=BackupLogContextImpl(
      domainName: "BackupServices",
      source: "BackupOperationExecutor"
    )
    .withOperation(parameters.operationType)
    .withPublic(key: "operationID", value: parameters.operationID.uuidString)

    // Log operation start
    await logger.info(
      "Starting backup operation: \(parameters.operationType)",
      context: logContext
    )

    do {
      // Execute the operation
      let result=try await operation(parameters, progressReporter, cancellationToken)

      // Log operation completion
      await logger.info(
        "Completed backup operation: \(parameters.operationType)",
        context: logContext
      )

      return result
    } catch {
      // Check if operation was cancelled
      if let cancellationToken, await cancellationToken.isCancelled {
        // Log cancellation
        await logger.info(
          "Cancelled backup operation: \(parameters.operationType)",
          context: logContext
        )

        throw BackupOperationError.operationCancelled("Operation was cancelled by user")
      }

      // Log error
      await logger.error(
        "Failed backup operation: \(parameters.operationType) - \(error.localizedDescription)",
        context: logContext
      )

      // Rethrow error
      throw error
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
