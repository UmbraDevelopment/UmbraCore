import Foundation

/// Protocol for reporting progress of backup operations
///
/// This protocol defines the requirements for a component that can
/// receive progress updates during long-running backup operations.
public protocol BackupProgressReporter: Sendable {
  /// Reports the current progress of an operation
  /// - Parameters:
  ///   - progressInfo: The progress information
  ///   - operation: The operation being performed
  func reportProgress(_ progressInfo: BackupProgressInfo, for operation: BackupOperation) async

  /// Reports that an operation has been cancelled
  /// - Parameter operation: The operation that was cancelled
  func reportCancellation(for operation: BackupOperation) async

  /// Reports that an operation has failed
  /// - Parameters:
  ///   - error: The error that caused the failure
  ///   - operation: The operation that failed
  func reportFailure(_ error: Error, for operation: BackupOperation) async

  /// Reports that an operation has completed successfully
  /// - Parameter operation: The operation that completed
  func reportCompletion(for operation: BackupOperation) async
}

/// Represents a backup operation type
public enum BackupOperation: String, Sendable, Equatable {
  /// Creating a backup
  case createBackup

  /// Restoring from a backup
  case restoreBackup

  /// Deleting a backup
  case deleteBackup

  /// Listing snapshots
  case listSnapshots

  /// Getting snapshot details
  case getSnapshotDetails

  /// Comparing snapshots
  case compareSnapshots

  /// Verifying a snapshot
  case verifySnapshot

  /// Performing repository maintenance
  case maintenance

  /// Searching for files within a snapshot
  case findFiles

  /// Updating snapshot tags
  case updateTags

  /// Updating snapshot description
  case updateDescription

  /// Exporting a snapshot
  case exportSnapshot

  /// Copying a snapshot to another repository
  case copySnapshot
}

/// Represents the progress of a backup operation
public struct BackupProgressInfo: Sendable, Equatable {
  /// Current phase of the operation
  public enum Phase: String, Sendable, Equatable {
    /// Initialising the operation
    case initialising

    /// Scanning files or directories
    case scanning

    /// Processing files or directories
    case processing

    /// Transferring data
    case transferring

    /// Finalising the operation
    case finalising

    /// Cleaning up resources
    case cleanup

    /// Verifying data integrity
    case verifying

    /// Operation completed successfully
    case completed

    /// Operation was cancelled
    case cancelled

    /// Operation failed
    case failed
  }

  /// The current phase of the operation
  public let phase: Phase

  /// Percentage complete (0-100)
  public let percentComplete: Double

  /// Number of items processed
  public let itemsProcessed: Int

  /// Total number of items
  public let totalItems: Int

  /// Number of bytes processed
  public let bytesProcessed: Int64

  /// Total number of bytes
  public let totalBytes: Int64

  /// Estimated time remaining in seconds
  public let estimatedTimeRemaining: TimeInterval?

  /// Error if in failed phase
  public let error: Error?

  /// Current operation details
  public let details: String?

  /// Whether the operation can be cancelled
  public let isCancellable: Bool

  /// Creates a new progress info
  public init(
    phase: Phase,
    percentComplete: Double,
    itemsProcessed: Int,
    totalItems: Int,
    bytesProcessed: Int64,
    totalBytes: Int64,
    estimatedTimeRemaining: TimeInterval? = nil,
    error: Error? = nil,
    details: String? = nil,
    isCancellable: Bool = true
  ) {
    self.phase = phase
    self.percentComplete = max(0.0, min(100.0, percentComplete))
    self.itemsProcessed = itemsProcessed
    self.totalItems = totalItems
    self.bytesProcessed = bytesProcessed
    self.totalBytes = totalBytes
    self.estimatedTimeRemaining = estimatedTimeRemaining
    self.error = error
    self.details = details
    self.isCancellable = isCancellable
  }

  /// Creates a progress in the initialising phase
  public static func initialising() -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .initialising,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: nil,
      details: "Initialising operation"
    )
  }

  /// Creates a progress in the completed phase
  public static func completed() -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .completed,
      percentComplete: 100.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: 0,
      details: "Operation completed"
    )
  }

  /// Creates a progress in the cancelled phase
  public static func cancelled() -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .cancelled,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: 0,
      details: "Operation cancelled",
      isCancellable: false
    )
  }

  /// Creates a progress in the failed phase
  public static func failed(_ error: Error) -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .failed,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      estimatedTimeRemaining: 0,
      error: error,
      details: "Operation failed: \(error.localizedDescription)",
      isCancellable: false
    )
  }

  /// Creates a progress in the scanning phase
  public static func scanning(
    itemsScanned: Int,
    details: String? = nil
  ) -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .scanning,
      percentComplete: 0.0,
      itemsProcessed: itemsScanned,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: details ?? "Scanning files"
    )
  }

  /// Creates a progress in the processing phase
  public static func processing(
    itemsProcessed: Int,
    totalItems: Int,
    details: String? = nil
  ) -> BackupProgressInfo {
    let percent = totalItems > 0 ? Double(itemsProcessed) / Double(totalItems) * 100.0 : 0.0

    return BackupProgressInfo(
      phase: .processing,
      percentComplete: percent,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      bytesProcessed: 0,
      totalBytes: 0,
      details: details ?? "Processing items"
    )
  }

  /// Creates a progress in the transferring phase
  public static func transferring(
    processedBytes: Int64,
    totalBytes: Int64,
    itemsProcessed: Int = 0,
    totalItems: Int = 0,
    details: String? = nil
  ) -> BackupProgressInfo {
    let percent = totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) * 100.0 : 0.0

    return BackupProgressInfo(
      phase: .transferring,
      percentComplete: percent,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      bytesProcessed: processedBytes,
      totalBytes: totalBytes,
      details: details ?? "Transferring data"
    )
  }

  /// Creates a progress in the finalising phase
  public static func finalising(details: String? = nil) -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .finalising,
      percentComplete: 99.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: details ?? "Finalising"
    )
  }

  /// Creates a progress in the cleanup phase
  public static func cleanup(details: String? = nil) -> BackupProgressInfo {
    return BackupProgressInfo(
      phase: .cleanup,
      percentComplete: 99.5,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: details ?? "Cleaning up"
    )
  }

  /// Creates a progress in the verifying phase
  public static func verifying(
    itemsVerified: Int,
    totalItems: Int,
    details: String? = nil
  ) -> BackupProgressInfo {
    let percent = totalItems > 0 ? Double(itemsVerified) / Double(totalItems) * 100.0 : 0.0

    return BackupProgressInfo(
      phase: .verifying,
      percentComplete: percent,
      itemsProcessed: itemsVerified,
      totalItems: totalItems,
      bytesProcessed: 0,
      totalBytes: 0,
      details: details ?? "Verifying data"
    )
  }
}

/// Defines a token that can be used to cancel an operation related to progress reporting
public protocol ProgressCancellationToken: Sendable {
  /// Checks if the operation has been cancelled
  var isCancelled: Bool { get }

  /// Attempts to cancel the operation
  func cancel()
}

/// Simple implementation of a cancellation token
public final class SimpleCancellationToken: ProgressCancellationToken {
  /// Whether the token has been cancelled
  public private(set) var isCancelled: Bool = false

  /// The action to perform when cancellation is requested
  private let onCancel: () -> Void

  /// Creates a new cancellation token
  /// - Parameter onCancel: Action to perform when cancellation is requested
  public init(onCancel: @escaping () -> Void = {}) {
    self.onCancel = onCancel
  }

  /// Attempts to cancel the operation
  public func cancel() {
    isCancelled = true
    onCancel()
  }
}

/// A basic implementation of a progress reporter
///
/// This class provides a simple implementation of `BackupProgressReporter`
/// that tracks progress and can be observed by clients.
public actor BackupProgressMonitor: BackupProgressReporter {
  /// The current progress of the operation
  private var _currentProgress: [BackupOperation: BackupProgressInfo]=[:]

  /// Operation start times for calculating rates
  private var operationStartTimes: [BackupOperation: Date]=[:]

  /// List of operations currently in progress
  public var activeOperations: [BackupOperation] {
    Array(_currentProgress.keys)
  }

  /// Closure called when progress is updated
  public var onProgressUpdated: ((BackupOperation, BackupProgressInfo) async -> Void)?

  /// Closure called when an operation is cancelled
  public var onOperationCancelled: ((BackupOperation) async -> Void)?

  /// Closure called when an operation fails
  public var onOperationFailed: ((BackupOperation, Error) async -> Void)?

  /// Closure called when an operation completes
  public var onOperationCompleted: ((BackupOperation) async -> Void)?

  /// Creates a new progress monitor
  public init() {}

  /// Gets the current progress for an operation
  /// - Parameter operation: The operation to get progress for
  /// - Returns: The current progress, or nil if no progress is available
  public func currentProgress(for operation: BackupOperation) -> BackupProgressInfo? {
    _currentProgress[operation]
  }

  /// Gets the elapsed time for an operation
  /// - Parameter operation: The operation to get elapsed time for
  /// - Returns: The elapsed time in seconds, or nil if the operation hasn't started
  public func elapsedTime(for operation: BackupOperation) -> TimeInterval? {
    guard let startTime=operationStartTimes[operation] else {
      return nil
    }

    return Date().timeIntervalSince(startTime)
  }

  /// Reports the current progress of an operation
  /// - Parameters:
  ///   - progressInfo: The progress information
  ///   - operation: The operation being performed
  public func reportProgress(_ progressInfo: BackupProgressInfo, for operation: BackupOperation) async {
    // Record start time if this is the first progress report
    if operationStartTimes[operation] == nil {
      operationStartTimes[operation]=Date()
    }

    // Update current progress
    _currentProgress[operation]=progressInfo

    // Notify observers
    if let onProgressUpdated {
      await onProgressUpdated(operation, progressInfo)
    }
  }

  /// Reports that an operation has been cancelled
  /// - Parameter operation: The operation that was cancelled
  public func reportCancellation(for operation: BackupOperation) async {
    // Clean up tracking
    _currentProgress[operation]=nil
    operationStartTimes[operation]=nil

    // Notify observers
    if let onOperationCancelled {
      await onOperationCancelled(operation)
    }
  }

  /// Reports that an operation has failed
  /// - Parameters:
  ///   - error: The error that caused the failure
  ///   - operation: The operation that failed
  public func reportFailure(_ error: Error, for operation: BackupOperation) async {
    // Clean up tracking
    _currentProgress[operation]=nil
    operationStartTimes[operation]=nil

    // Notify observers
    if let onOperationFailed {
      await onOperationFailed(operation, error)
    }
  }

  /// Reports that an operation has completed successfully
  /// - Parameter operation: The operation that completed
  public func reportCompletion(for operation: BackupOperation) async {
    // Clean up tracking
    _currentProgress[operation]=nil
    operationStartTimes[operation]=nil

    // Notify observers
    if let onOperationCompleted {
      await onOperationCompleted(operation)
    }
  }
}
