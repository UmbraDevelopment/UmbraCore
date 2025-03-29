import Foundation

/// Protocol for reporting progress of backup operations
///
/// This protocol defines the requirements for a component that can
/// receive progress updates during long-running backup operations.
public protocol BackupProgressReporter: Sendable {
  /// Reports the current progress of an operation
  /// - Parameters:
  ///   - progress: The progress information
  ///   - operation: The operation being performed
  func reportProgress(_ progress: BackupProgress, for operation: BackupOperation) async

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
}

/// Represents the progress of a backup operation
public struct BackupProgress: Sendable, Equatable {
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
  }

  /// Current phase of the operation
  public let phase: Phase

  /// Completed percentage (0.0 to 1.0)
  public let percentComplete: Double

  /// Optional current item being processed
  public let currentItem: String?

  /// Optional count of processed items
  public let processedItems: Int?

  /// Optional total items to process
  public let totalItems: Int?

  /// Optional bytes processed so far
  public let processedBytes: UInt64?

  /// Optional total bytes to process
  public let totalBytes: UInt64?

  /// Optional estimated time remaining in seconds
  public let estimatedTimeRemaining: TimeInterval?

  /// Optional rate of processing in bytes per second
  public let bytesPerSecond: Double?

  /// Creates a new progress instance
  /// - Parameters:
  ///   - phase: Current phase of the operation
  ///   - percentComplete: Completed percentage (0.0 to 1.0)
  ///   - currentItem: Optional current item being processed
  ///   - processedItems: Optional count of processed items
  ///   - totalItems: Optional total items to process
  ///   - processedBytes: Optional bytes processed so far
  ///   - totalBytes: Optional total bytes to process
  ///   - estimatedTimeRemaining: Optional estimated time remaining in seconds
  ///   - bytesPerSecond: Optional rate of processing in bytes per second
  public init(
    phase: Phase,
    percentComplete: Double,
    currentItem: String?=nil,
    processedItems: Int?=nil,
    totalItems: Int?=nil,
    processedBytes: UInt64?=nil,
    totalBytes: UInt64?=nil,
    estimatedTimeRemaining: TimeInterval?=nil,
    bytesPerSecond: Double?=nil
  ) {
    self.phase=phase
    self.percentComplete=min(max(percentComplete, 0.0), 1.0)
    self.currentItem=currentItem
    self.processedItems=processedItems
    self.totalItems=totalItems
    self.processedBytes=processedBytes
    self.totalBytes=totalBytes
    self.estimatedTimeRemaining=estimatedTimeRemaining
    self.bytesPerSecond=bytesPerSecond
  }

  /// Creates a new progress instance at the initialising phase
  /// - Returns: A progress instance at 0% in the initialising phase
  public static func initialising() -> BackupProgress {
    BackupProgress(phase: .initialising, percentComplete: 0.0)
  }

  /// Creates a new progress instance at the scanning phase
  /// - Parameters:
  ///   - percentComplete: Completed percentage (0.0 to 1.0)
  ///   - currentItem: Optional current item being scanned
  /// - Returns: A progress instance in the scanning phase
  public static func scanning(
    percentComplete: Double,
    currentItem: String?=nil
  ) -> BackupProgress {
    BackupProgress(
      phase: .scanning,
      percentComplete: percentComplete,
      currentItem: currentItem
    )
  }

  /// Creates a new progress instance for data transfer
  /// - Parameters:
  ///   - processedBytes: Bytes processed so far
  ///   - totalBytes: Total bytes to process
  ///   - bytesPerSecond: Optional rate of processing
  ///   - estimatedTimeRemaining: Optional estimated time remaining
  /// - Returns: A progress instance in the transferring phase
  public static func transferring(
    processedBytes: UInt64,
    totalBytes: UInt64,
    bytesPerSecond: Double?=nil,
    estimatedTimeRemaining: TimeInterval?=nil
  ) -> BackupProgress {
    let percent=totalBytes > 0 ? Double(processedBytes) / Double(totalBytes) : 0.0

    return BackupProgress(
      phase: .transferring,
      percentComplete: percent,
      processedBytes: processedBytes,
      totalBytes: totalBytes,
      estimatedTimeRemaining: estimatedTimeRemaining,
      bytesPerSecond: bytesPerSecond
    )
  }

  /// Creates a new progress instance for file processing
  /// - Parameters:
  ///   - processedItems: Items processed so far
  ///   - totalItems: Total items to process
  ///   - currentItem: Optional current item being processed
  /// - Returns: A progress instance in the processing phase
  public static func processing(
    processedItems: Int,
    totalItems: Int,
    currentItem: String?=nil
  ) -> BackupProgress {
    let percent=totalItems > 0 ? Double(processedItems) / Double(totalItems) : 0.0

    return BackupProgress(
      phase: .processing,
      percentComplete: percent,
      currentItem: currentItem,
      processedItems: processedItems,
      totalItems: totalItems
    )
  }

  /// Creates a new progress instance at the finalising phase
  /// - Parameter percentComplete: Completed percentage (0.0 to 1.0)
  /// - Returns: A progress instance in the finalising phase
  public static func finalising(percentComplete: Double=0.9) -> BackupProgress {
    BackupProgress(phase: .finalising, percentComplete: percentComplete)
  }

  /// Creates a new progress instance at the cleanup phase
  /// - Parameter percentComplete: Completed percentage (0.0 to 1.0)
  /// - Returns: A progress instance in the cleanup phase
  public static func cleanup(percentComplete: Double=0.95) -> BackupProgress {
    BackupProgress(phase: .cleanup, percentComplete: percentComplete)
  }

  /// Creates a new progress instance at the verifying phase
  /// - Parameters:
  ///   - percentComplete: Completed percentage (0.0 to 1.0)
  ///   - processedItems: Optional count of processed items
  ///   - totalItems: Optional total items to process
  /// - Returns: A progress instance in the verifying phase
  public static func verifying(
    percentComplete: Double,
    processedItems: Int?=nil,
    totalItems: Int?=nil
  ) -> BackupProgress {
    BackupProgress(
      phase: .verifying,
      percentComplete: percentComplete,
      processedItems: processedItems,
      totalItems: totalItems
    )
  }

  /// Returns a string representation of the progress
  public var description: String {
    var components: [String]=[]

    components.append("\(phase.rawValue.capitalized): \(Int(percentComplete * 100))%")

    if let processedItems, let totalItems {
      components.append("\(processedItems)/\(totalItems) items")
    }

    if let processedBytes, let totalBytes {
      let formatter=ByteCountFormatter()
      formatter.allowedUnits=[.useAll]
      formatter.countStyle = .file
      components
        .append(
          "\(formatter.string(fromByteCount: Int64(processedBytes)))/\(formatter.string(fromByteCount: Int64(totalBytes)))"
        )
    }

    if let bytesPerSecond {
      let formatter=ByteCountFormatter()
      formatter.allowedUnits=[.useAll]
      formatter.countStyle = .memory
      components.append("\(formatter.string(fromByteCount: Int64(bytesPerSecond)))/s")
    }

    if let estimatedTimeRemaining {
      let formatter=DateComponentsFormatter()
      formatter.allowedUnits=[.hour, .minute, .second]
      formatter.unitsStyle = .abbreviated
      if let formattedTime=formatter.string(from: estimatedTimeRemaining) {
        components.append("\(formattedTime) remaining")
      }
    }

    if let currentItem {
      components.append("\"\(currentItem)\"")
    }

    return components.joined(separator: " • ")
  }
}

/// Defines a token that can be used to cancel an operation
public protocol CancellationToken: Sendable {
  /// Checks if the operation has been cancelled
  var isCancelled: Bool { get }

  /// Cancels the operation
  func cancel()
}

/// A concrete implementation of a cancellation token
public final class BackupCancellationToken: CancellationToken, @unchecked Sendable {
  /// Lock for thread-safe access to _isCancelled
  private let lock=NSLock()

  /// Internal cancelled state
  private var _isCancelled=false

  /// Checks if the operation has been cancelled
  public var isCancelled: Bool {
    lock.lock()
    defer { lock.unlock() }
    return _isCancelled
  }

  /// Creates a new cancellation token
  public init() {}

  /// Cancels the operation
  public func cancel() {
    lock.lock()
    _isCancelled=true
    lock.unlock()
  }
}

/// A basic implementation of a progress reporter
///
/// This class provides a simple implementation of `BackupProgressReporter`
/// that tracks progress and can be observed by clients.
public actor BackupProgressMonitor: BackupProgressReporter {
  /// The current progress of the operation
  private var _currentProgress: [BackupOperation: BackupProgress]=[:]

  /// Operation start times for calculating rates
  private var operationStartTimes: [BackupOperation: Date]=[:]

  /// List of operations currently in progress
  public var activeOperations: [BackupOperation] {
    Array(_currentProgress.keys)
  }

  /// Closure called when progress is updated
  public var onProgressUpdated: ((BackupOperation, BackupProgress) async -> Void)?

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
  public func currentProgress(for operation: BackupOperation) -> BackupProgress? {
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
  ///   - progress: The progress information
  ///   - operation: The operation being performed
  public func reportProgress(_ progress: BackupProgress, for operation: BackupOperation) async {
    // Record start time if this is the first progress report
    if operationStartTimes[operation] == nil {
      operationStartTimes[operation]=Date()
    }

    // Update current progress
    _currentProgress[operation]=progress

    // Notify observers
    if let onProgressUpdated {
      await onProgressUpdated(operation, progress)
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
