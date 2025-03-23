import UmbraCoreTypes

/// FoundationIndependent representation of backup operation status.
/// This data transfer object encapsulates status information for backup operations
/// without using any Foundation types.
public struct BackupStatusDTO: Sendable, Equatable {
  // MARK: - Types

  /// Represents the current status of a backup operation
  public enum Status: String, Sendable, Equatable {
    /// No operation in progress
    case idle
    /// Operation is currently running
    case running
    /// Operation completed successfully
    case succeeded
    /// Operation failed
    case failed
    /// Operation was cancelled by the user
    case cancelled
    /// Operation is paused
    case paused

    /// Whether this status represents a terminal state
    public var isTerminal: Bool {
      switch self {
        case .idle, .succeeded, .failed, .cancelled:
          true
        case .running, .paused:
          false
      }
    }

    /// Whether this status represents a success
    public var isSuccess: Bool {
      self == .succeeded
    }

    /// Whether this status represents a failure
    public var isFailure: Bool {
      self == .failed || self == .cancelled
    }
  }

  // MARK: - Properties

  /// Current status of the backup operation
  public let status: Status

  /// Repository ID associated with this backup
  public let repositoryID: String

  /// Snapshot ID if one was created
  public let snapshotID: String?

  /// Number of files processed
  public let filesProcessed: Int

  /// Number of files added
  public let filesAdded: Int

  /// Number of files changed
  public let filesChanged: Int

  /// Number of files unchanged
  public let filesUnchanged: Int

  /// Amount of data added in bytes
  public let dataAdded: UInt64

  /// Total duration in seconds
  public let totalDuration: UInt64

  /// Error messages if any occurred
  public let errors: [String]

  /// When the operation started (Unix timestamp - seconds since epoch)
  public let startTimestamp: UInt64

  /// When the operation ended (Unix timestamp - seconds since epoch)
  public let endTimestamp: UInt64?

  // MARK: - Initializers

  /// Full initializer with all status information
  /// - Parameters:
  ///   - status: Current status of the backup operation
  ///   - repositoryId: Repository ID associated with this backup
  ///   - snapshotId: Snapshot ID if one was created
  ///   - filesProcessed: Number of files processed
  ///   - filesAdded: Number of files added
  ///   - filesChanged: Number of files changed
  ///   - filesUnchanged: Number of files unchanged
  ///   - dataAdded: Amount of data added in bytes
  ///   - totalDuration: Total duration in seconds
  ///   - errors: Error messages if any occurred
  ///   - startTimestamp: When the operation started (Unix timestamp)
  ///   - endTimestamp: When the operation ended (Unix timestamp)
  public init(
    status: Status,
    repositoryID: String,
    snapshotID: String?=nil,
    filesProcessed: Int=0,
    filesAdded: Int=0,
    filesChanged: Int=0,
    filesUnchanged: Int=0,
    dataAdded: UInt64=0,
    totalDuration: UInt64=0,
    errors: [String]=[],
    startTimestamp: UInt64,
    endTimestamp: UInt64?=nil
  ) {
    self.status=status
    self.repositoryID=repositoryID
    self.snapshotID=snapshotID
    self.filesProcessed=filesProcessed
    self.filesAdded=filesAdded
    self.filesChanged=filesChanged
    self.filesUnchanged=filesUnchanged
    self.dataAdded=dataAdded
    self.totalDuration=totalDuration
    self.errors=errors
    self.startTimestamp=startTimestamp
    self.endTimestamp=endTimestamp
  }

  // MARK: - Factory Methods

  /// Create an initial backup status for a running operation
  /// - Parameters:
  ///   - repositoryId: Repository ID associated with this backup
  ///   - startTimestamp: When the operation started (Unix timestamp)
  /// - Returns: A BackupStatusDTO for a running operation
  public static func started(
    repositoryID: String,
    startTimestamp: UInt64
  ) -> BackupStatusDTO {
    BackupStatusDTO(
      status: .running,
      repositoryID: repositoryID,
      startTimestamp: startTimestamp
    )
  }

  /// Create a status for a successful backup operation
  /// - Parameters:
  ///   - repositoryId: Repository ID associated with this backup
  ///   - snapshotId: Snapshot ID created by this backup
  ///   - filesProcessed: Number of files processed
  ///   - filesAdded: Number of files added
  ///   - filesChanged: Number of files changed
  ///   - filesUnchanged: Number of files unchanged
  ///   - dataAdded: Amount of data added in bytes
  ///   - totalDuration: Total duration in seconds
  ///   - startTimestamp: When the operation started (Unix timestamp)
  ///   - endTimestamp: When the operation ended (Unix timestamp)
  /// - Returns: A BackupStatusDTO for a successful operation
  public static func succeeded(
    repositoryID: String,
    snapshotID: String,
    filesProcessed: Int,
    filesAdded: Int,
    filesChanged: Int,
    filesUnchanged: Int,
    dataAdded: UInt64,
    totalDuration: UInt64,
    startTimestamp: UInt64,
    endTimestamp: UInt64
  ) -> BackupStatusDTO {
    BackupStatusDTO(
      status: .succeeded,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: dataAdded,
      totalDuration: totalDuration,
      errors: [],
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a status for a failed backup operation
  /// - Parameters:
  ///   - repositoryId: Repository ID associated with this backup
  ///   - errors: Error messages
  ///   - filesProcessed: Number of files processed
  ///   - totalDuration: Total duration in seconds
  ///   - startTimestamp: When the operation started (Unix timestamp)
  ///   - endTimestamp: When the operation ended (Unix timestamp)
  /// - Returns: A BackupStatusDTO for a failed operation
  public static func failed(
    repositoryID: String,
    errors: [String],
    filesProcessed: Int=0,
    totalDuration: UInt64,
    startTimestamp: UInt64,
    endTimestamp: UInt64
  ) -> BackupStatusDTO {
    BackupStatusDTO(
      status: .failed,
      repositoryID: repositoryID,
      filesProcessed: filesProcessed,
      totalDuration: totalDuration,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a status for a cancelled backup operation
  /// - Parameters:
  ///   - repositoryId: Repository ID associated with this backup
  ///   - filesProcessed: Number of files processed
  ///   - totalDuration: Total duration in seconds
  ///   - startTimestamp: When the operation started (Unix timestamp)
  ///   - endTimestamp: When the operation ended (Unix timestamp)
  /// - Returns: A BackupStatusDTO for a cancelled operation
  public static func cancelled(
    repositoryID: String,
    filesProcessed: Int=0,
    totalDuration: UInt64,
    startTimestamp: UInt64,
    endTimestamp: UInt64
  ) -> BackupStatusDTO {
    BackupStatusDTO(
      status: .cancelled,
      repositoryID: repositoryID,
      filesProcessed: filesProcessed,
      totalDuration: totalDuration,
      errors: ["Operation cancelled by user"],
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  // MARK: - Computed Properties

  /// Whether the backup is currently in progress
  public var isInProgress: Bool {
    status == .running || status == .paused
  }

  /// Whether the backup has any errors
  public var hasErrors: Bool {
    !errors.isEmpty
  }

  /// Total files modified (added + changed)
  public var totalFilesModified: Int {
    filesAdded + filesChanged
  }

  /// Primary error message if any
  public var primaryError: String? {
    errors.first
  }

  // MARK: - Utility Methods

  /// Create a copy of this status with updated status
  /// - Parameter newStatus: The new status
  /// - Returns: A new BackupStatusDTO with updated status
  public func withStatus(_ newStatus: Status) -> BackupStatusDTO {
    BackupStatusDTO(
      status: newStatus,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: dataAdded,
      totalDuration: totalDuration,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a copy of this status with updated snapshot ID
  /// - Parameter id: The new snapshot ID
  /// - Returns: A new BackupStatusDTO with updated snapshot ID
  public func withSnapshotID(_ id: String) -> BackupStatusDTO {
    BackupStatusDTO(
      status: status,
      repositoryID: repositoryID,
      snapshotID: id,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: dataAdded,
      totalDuration: totalDuration,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a copy of this status with updated file counts
  /// - Parameters:
  ///   - processed: Number of files processed
  ///   - added: Number of files added
  ///   - changed: Number of files changed
  ///   - unchanged: Number of files unchanged
  /// - Returns: A new BackupStatusDTO with updated file counts
  public func withFileStats(
    processed: Int,
    added: Int,
    changed: Int,
    unchanged: Int
  ) -> BackupStatusDTO {
    BackupStatusDTO(
      status: status,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: processed,
      filesAdded: added,
      filesChanged: changed,
      filesUnchanged: unchanged,
      dataAdded: dataAdded,
      totalDuration: totalDuration,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a copy of this status with updated data added
  /// - Parameter bytes: Amount of data added in bytes
  /// - Returns: A new BackupStatusDTO with updated data added
  public func withDataAdded(_ bytes: UInt64) -> BackupStatusDTO {
    BackupStatusDTO(
      status: status,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: bytes,
      totalDuration: totalDuration,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a copy of this status with updated duration
  /// - Parameter seconds: Total duration in seconds
  /// - Returns: A new BackupStatusDTO with updated duration
  public func withDuration(_ seconds: UInt64) -> BackupStatusDTO {
    BackupStatusDTO(
      status: status,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: dataAdded,
      totalDuration: seconds,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a copy of this status with added error messages
  /// - Parameter messages: Error messages to add
  /// - Returns: A new BackupStatusDTO with added error messages
  public func withAddedErrors(_ messages: [String]) -> BackupStatusDTO {
    var newErrors=errors
    newErrors.append(contentsOf: messages)

    return BackupStatusDTO(
      status: status,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: dataAdded,
      totalDuration: totalDuration,
      errors: newErrors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }

  /// Create a copy of this status marked as complete
  /// - Parameters:
  ///   - succeeded: Whether the operation succeeded
  ///   - endTimestamp: When the operation ended (Unix timestamp)
  /// - Returns: A new BackupStatusDTO marked as complete
  public func completed(
    succeeded: Bool,
    endTimestamp: UInt64
  ) -> BackupStatusDTO {
    BackupStatusDTO(
      status: succeeded ? .succeeded : .failed,
      repositoryID: repositoryID,
      snapshotID: snapshotID,
      filesProcessed: filesProcessed,
      filesAdded: filesAdded,
      filesChanged: filesChanged,
      filesUnchanged: filesUnchanged,
      dataAdded: dataAdded,
      totalDuration: totalDuration,
      errors: errors,
      startTimestamp: startTimestamp,
      endTimestamp: endTimestamp
    )
  }
}
