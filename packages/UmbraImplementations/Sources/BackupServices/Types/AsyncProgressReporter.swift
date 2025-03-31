import BackupInterfaces
import Foundation

/**
 * A progress reporter that can produce an AsyncStream of progress updates.
 *
 * This implementation enables the Alpha Dot Five architecture pattern for
 * providing streaming progress updates to UI components while maintaining
 * clear separation of responsibilities.
 */
public actor AsyncProgressReporter<Progress: Sendable> {
  /// Continuation for the progress stream
  private var continuation: AsyncStream<Progress>.Continuation?

  /// Latest progress value
  private var latestProgress: Progress?

  /// The AsyncStream that returns progress updates
  public var stream: AsyncStream<Progress> {
    createProgressStream()
  }

  /// Creates a new async progress reporter
  public init() {}

  /**
   * Creates an AsyncStream of progress updates.
   *
   * - Returns: A stream of progress updates that will receive all future updates
   */
  private func createProgressStream() -> AsyncStream<Progress> {
    AsyncStream { continuation in
      self.continuation=continuation

      // If we already have progress, send it immediately
      if let progress=latestProgress {
        continuation.yield(progress)
      }

      // When stream is terminated, clean up
      continuation.onTermination={ [weak self] _ in
        Task { [weak self] in
          await self?.cleanup()
        }
      }
    }
  }

  /**
   * Reports a progress update.
   *
   * - Parameter progress: The progress to report
   */
  public func reportProgress(_ progress: Progress) {
    // Store the latest progress
    latestProgress=progress

    // Send to stream if available
    continuation?.yield(progress)
  }

  /**
   * Cleans up resources when the stream is no longer needed.
   */
  private func cleanup() {
    continuation=nil
  }
}

/**
 * Extension for BackupProgressInfo-specific reporting.
 *
 * This extension provides convenience methods specifically for BackupProgressInfo
 * to handle standard progress reporting operations.
 */
extension AsyncProgressReporter where Progress == BackupProgressInfo {
  /**
   * Reports that an operation has completed successfully.
   *
   * - Parameter detail: Optional completion detail message
   */
  public func reportCompletion(detail: String?=nil) async {
    if let detail {
      let completionProgress=BackupProgressInfo(
        phase: .completed,
        percentComplete: 100.0,
        itemsProcessed: 0,
        totalItems: 0,
        bytesProcessed: 0,
        totalBytes: 0,
        details: detail
      )
      await reportProgress(completionProgress)
    } else {
      await reportProgress(.completed())
    }
  }

  /**
   * Reports that an operation has been cancelled.
   *
   * - Parameter detail: Optional cancellation detail message
   */
  public func reportCancellation(detail: String?=nil) async {
    let cancellationProgress=BackupProgressInfo(
      phase: .cancelled,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: detail ?? "Operation cancelled",
      isCancellable: false
    )
    await reportProgress(cancellationProgress)
  }

  /**
   * Reports that an operation has failed.
   *
   * - Parameters:
   *   - error: The error that caused the failure
   *   - detail: Optional additional detail message
   */
  public func reportError(_ error: Error, detail: String?=nil) async {
    let errorProgress=BackupProgressInfo(
      phase: .failed,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      error: error,
      details: detail ?? "Operation failed: \(error.localizedDescription)",
      isCancellable: false
    )
    await reportProgress(errorProgress)
  }
}

/**
 * Adapter to make AsyncProgressReporter conform to BackupProgressReporter.
 *
 * This struct bridges the AsyncProgressReporter to the BackupProgressReporter
 * protocol, enabling its use in contexts that expect the protocol.
 */
public struct ProgressReporterAdapter: BackupProgressReporter {
  /// The underlying progress reporter
  private let reporter: AsyncProgressReporter<BackupProgressInfo>

  /**
   * Creates a new progress reporter adapter.
   *
   * - Parameter reporter: The underlying AsyncProgressReporter
   */
  public init(reporter: AsyncProgressReporter<BackupProgressInfo>) {
    self.reporter=reporter
  }

  /**
   * Reports progress for an operation.
   *
   * - Parameters:
   *   - progress: The progress update
   *   - operation: The operation being performed
   */
  public func reportProgress(_ progress: BackupProgressInfo, for _: BackupOperation) async {
    await reporter.reportProgress(progress)
  }

  /**
   * Reports that an operation has been cancelled.
   *
   * - Parameter operation: The operation that was cancelled
   */
  public func reportCancellation(for _: BackupOperation) async {
    await reporter.reportCancellation()
  }

  /**
   * Reports that an operation has failed.
   *
   * - Parameters:
   *   - error: The error that caused the failure
   *   - operation: The operation that failed
   */
  public func reportFailure(_ error: Error, for _: BackupOperation) async {
    await reporter.reportError(error)
  }

  /**
   * Reports that an operation has completed successfully.
   *
   * - Parameter operation: The operation that completed
   */
  public func reportCompletion(for _: BackupOperation) async {
    await reporter.reportCompletion()
  }
}
