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
 * Extension for BackupProgress-specific reporting.
 */
extension AsyncProgressReporter where Progress == BackupProgress {
  /**
   * Reports completion.
   */
  public func reportCompletion() {
    // Create completion progress if needed
    if latestProgress?.phase != .completed {
      let completionProgress=BackupProgress(
        phase: .completed,
        percentComplete: 1.0
      )
      reportProgress(completionProgress)
    }
  }

  /**
   * Reports cancellation.
   */
  public func reportCancellation() {
    // Create cancellation progress
    let cancellationProgress=BackupProgress(
      phase: .cancelled,
      percentComplete: latestProgress?.percentComplete ?? 0
    )
    reportProgress(cancellationProgress)
  }

  /**
   * Reports an error.
   *
   * - Parameter error: The error to report
   */
  public func reportError(_ error: Error) {
    // Create error progress
    let errorProgress=BackupProgress(
      phase: .failed,
      percentComplete: latestProgress?.percentComplete ?? 0,
      error: error
    )
    reportProgress(errorProgress)
  }
}

/**
 * Adapter to make AsyncProgressReporter conform to BackupProgressReporter.
 */
public struct ProgressReporterAdapter: BackupProgressReporter {
  /// The wrapped async progress reporter
  private let reporter: AsyncProgressReporter<BackupProgress>

  /**
   * Creates a new adapter.
   *
   * - Parameter reporter: The reporter to adapt
   */
  public init(reporter: AsyncProgressReporter<BackupProgress>) {
    self.reporter=reporter
  }

  public func reportProgress(_ progress: BackupProgress, for _: BackupOperation) async {
    await reporter.reportProgress(progress)
  }

  public func reportCancellation(for _: BackupOperation) async {
    await reporter.reportCancellation()
  }

  public func reportFailure(_ error: Error, for _: BackupOperation) async {
    await reporter.reportError(error)
  }

  public func reportCompletion(for _: BackupOperation) async {
    await reporter.reportCompletion()
  }
}
