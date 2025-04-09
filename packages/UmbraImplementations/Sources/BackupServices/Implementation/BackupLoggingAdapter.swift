import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Modern Backup Logging Adapter

 A privacy-aware logging adapter for backup operations that integrates with
 the modern progress reporting system using AsyncStream.

 This adapter implements the Alpha Dot Five architecture principles with
 proper British spelling in documentation and follows the privacy-enhanced
 logging system design.
 */
public struct BackupLoggingAdapter {
  /// The underlying logger
  private let logger: LoggingProtocol

  /**
   Creates a new backup logging adapter.

   - Parameter logger: The core logger to wrap
   */
  public init(logger: LoggingProtocol) {
    self.logger=logger
  }

  /**
   Logs the start of a backup operation using a structured log context.

   - Parameters:
      - logContext: The structured log context with privacy metadata
      - message: Optional custom message override
   */
  public func logOperationStart(
    logContext: BackupLogContext,
    message: String?=nil
  ) async {
    let operation=logContext.operation ?? "unknown"
    let defaultMessage="Starting backup operation: \(operation)"

    await logger.info(
      message ?? defaultMessage,
      context: logContext,
      source: "BackupService"
    )
  }

  /**
   Logs the successful completion of a backup operation using a structured log context.

   - Parameters:
      - logContext: The structured log context with privacy metadata
      - message: Optional custom message override
   */
  public func logOperationSuccess(
    logContext: BackupLogContext,
    message: String?=nil
  ) async {
    let operation=logContext.operation ?? "unknown"
    let defaultMessage="Completed backup operation: \(operation)"

    let updatedContext = logContext.withPublic(key: "status", value: "success")

    await logger.info(
      message ?? defaultMessage,
      context: updatedContext,
      source: "BackupService"
    )
  }

  /**
   Logs the cancellation of a backup operation.

   - Parameters:
      - logContext: The structured log context with privacy metadata
      - message: Optional custom message override
   */
  public func logOperationCancelled(
    logContext: BackupLogContext,
    message: String?=nil
  ) async {
    let operation=logContext.operation ?? "unknown"
    let defaultMessage="Cancelled backup operation: \(operation)"

    let updatedContext = logContext.withPublic(key: "status", value: "cancelled")

    await logger.info(
      message ?? defaultMessage,
      context: updatedContext,
      source: "BackupService"
    )
  }

  /**
   Logs a specific backup error with structured context.

   - Parameters:
      - error: The error that occurred
      - logContext: Structured context with privacy metadata
      - message: Optional custom message override
   */
  public func logOperationFailure(
    error: Error,
    logContext: BackupLogContext,
    message: String?=nil
  ) async {
    let operation=logContext.operation ?? "unknown"
    let defaultMessage="Error during backup operation: \(operation)"

    var updatedContext = logContext.withPublic(key: "status", value: "error")

    // Add error details with appropriate privacy levels
    if let backupError=error as? BackupError {
      updatedContext = updatedContext
        .withPublic(key: "errorCode", value: String(describing: backupError.code))
        .withPrivate(key: "errorMessage", value: backupError.localizedDescription)

      // Add structured error context if available
      if let errorContext=backupError.context {
        for (key, value) in errorContext {
          updatedContext = updatedContext
            .withPrivate(key: "error_\(key)", value: value)
        }
      }
    } else {
      updatedContext = updatedContext
        .withPublic(key: "errorType", value: String(describing: type(of: error)))
        .withPrivate(key: "errorMessage", value: error.localizedDescription)
    }

    await logger.error(
      message ?? defaultMessage,
      context: updatedContext,
      source: "BackupService"
    )
  }

  /**
   Logs a progress update for a backup operation.

   - Parameters:
      - progress: The progress update
      - operation: The backup operation
      - logContext: Optional additional context to include
   */
  public func logProgressUpdate(
    _ progress: BackupProgress,
    for operation: BackupOperation,
    logContext: BackupLogContext?=nil
  ) async {
    let baseContext = logContext ?? BackupLogContext()
    var updatedContext = baseContext.withPublic(key: "operation", value: String(describing: operation))

    // Add appropriate metadata based on the progress state
    switch progress {
      case let .initialising(description):
        updatedContext = updatedContext
          .withPublic(key: "progressPhase", value: "initialising")
          .withPublic(key: "description", value: description)

        await logger.info(
          "Initialising backup operation: \(operation)",
          context: updatedContext,
          source: "BackupService"
        )

      case let .processing(phase, percentComplete):
        updatedContext = updatedContext
          .withPublic(key: "progressPhase", value: "processing")
          .withPublic(key: "description", value: phase)
          .withPublic(key: "percentComplete", value: String(format: "%.1f%%", percentComplete * 100))

        await logger.info(
          "Processing backup operation: \(operation) - \(phase) (\(String(format: "%.1f%%", percentComplete * 100)))",
          context: updatedContext,
          source: "BackupService"
        )

      case .completed:
        updatedContext = updatedContext
          .withPublic(key: "progressPhase", value: "completed")

        await logger.info(
          "Completed backup operation: \(operation)",
          context: updatedContext,
          source: "BackupService"
        )

      case .cancelled:
        updatedContext = updatedContext
          .withPublic(key: "progressPhase", value: "cancelled")

        await logger.info(
          "Cancelled backup operation: \(operation)",
          context: updatedContext,
          source: "BackupService"
        )

      case let .failed(error):
        updatedContext = updatedContext
          .withPublic(key: "progressPhase", value: "error")
          .withPublic(key: "errorType", value: String(describing: type(of: error)))
          .withPrivate(key: "errorMessage", value: error.localizedDescription)

        await logger.error(
          "Error during backup operation: \(operation) - \(error.localizedDescription)",
          context: updatedContext,
          source: "BackupService"
        )
    }
  }
}
