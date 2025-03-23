import Foundation

/// Represents the progress of a backup operation.
/// This struct provides detailed information about:
/// - Current backup phase (scanning, processing, saving)
/// - File and byte counts for total and processed data
/// - Time metrics including elapsed time and estimated remaining time
/// - Processing speed in bytes per second
public struct BackupProgress: Codable, Sendable {
  /// The current status of the backup operation.
  public enum Status: String, Codable, Sendable {
    /// Scanning for files to backup.
    case scanning
    /// Processing files for backup.
    case processing
    /// Saving snapshot.
    case saving
  }

  /// The current status of the backup operation.
  public let status: Status

  /// Total number of files found during scan.
  public let totalFiles: Int

  /// Total size of files in bytes.
  public let totalBytes: Int64

  /// Number of files processed so far.
  public let processedFiles: Int

  /// Number of bytes processed so far.
  public let processedBytes: Int64

  /// Current file being processed.
  public let currentFile: String?

  /// Time elapsed in seconds.
  public let secondsElapsed: TimeInterval

  /// Percentage complete (0-100).
  public var percentComplete: Double {
    guard totalBytes > 0 else { return 0 }
    return Double(processedBytes) / Double(totalBytes) * 100.0
  }

  /// Estimated time remaining in seconds.
  public var secondsRemaining: TimeInterval {
    guard percentComplete > 0 else { return 0 }
    return (secondsElapsed / percentComplete) * (100 - percentComplete)
  }

  /// Transfer speed in bytes per second.
  public var bytesPerSecond: Int64 {
    guard secondsElapsed > 0 else { return 0 }
    return Int64(Double(processedBytes) / secondsElapsed)
  }

  private enum CodingKeys: String, CodingKey {
    case status = "message_type"
    case totalFiles = "total_files"
    case totalBytes = "total_bytes"
    case processedFiles = "files_done"
    case processedBytes = "bytes_done"
    case currentFile = "current_file"
    case secondsElapsed = "seconds_elapsed"
  }
}

/// Represents the progress of a restore operation.
/// This struct provides detailed information about:
/// - Current restore phase
/// - File and byte counts for total and restored data
/// - Time metrics including elapsed time and estimated remaining time
/// - Processing speed in bytes per second
public struct RestoreProgress: Codable, Sendable {
  /// The current status of the restore operation.
  public enum Status: String, Codable, Sendable {
    /// Preparing for restore.
    case preparing
    /// Restoring files.
    case restoring
    /// Cleaning up after restore.
    case cleaning
  }

  /// The current status of the restore operation.
  public let status: Status

  /// Total number of files to restore.
  public let totalFiles: Int

  /// Total size of files to restore in bytes.
  public let totalBytes: Int64

  /// Number of files restored so far.
  public let restoredFiles: Int

  /// Number of bytes restored so far.
  public let restoredBytes: Int64

  /// Current file being restored.
  public let currentFile: String?

  /// Time elapsed in seconds.
  public let secondsElapsed: TimeInterval

  /// Percentage complete (0-100).
  public var percentComplete: Double {
    guard totalBytes > 0 else { return 0 }
    return Double(restoredBytes) / Double(totalBytes) * 100.0
  }

  /// Estimated time remaining in seconds.
  public var secondsRemaining: TimeInterval {
    guard percentComplete > 0 else { return 0 }
    return (secondsElapsed / percentComplete) * (100 - percentComplete)
  }

  /// Transfer speed in bytes per second.
  public var bytesPerSecond: Int64 {
    guard secondsElapsed > 0 else { return 0 }
    return Int64(Double(restoredBytes) / secondsElapsed)
  }

  private enum CodingKeys: String, CodingKey {
    case status = "message_type"
    case totalFiles = "total_files"
    case totalBytes = "total_bytes"
    case restoredFiles = "files_done"
    case restoredBytes = "bytes_done"
    case currentFile = "current_file"
    case secondsElapsed = "seconds_elapsed"
  }
}

/// Protocol for types that can report Restic operation progress
public protocol ResticProgressReporting {
  /// Called when progress is updated
  /// - Parameter progress: The current progress
  func progressUpdated(_ progress: Any)
}
