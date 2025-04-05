import BackupInterfaces
import Foundation
import ResticInterfaces

/// Data Transfer Object for backup progress
///
/// This struct serves as an intermediary between the BackupProgress model from ResticInterfaces
/// and the BackupProgressInfo model from BackupInterfaces, allowing for clean conversion between
/// different module types without tight coupling.
public struct BackupProgressDTO: Sendable, Equatable {
  /// Current phase of the operation
  public enum PhaseDTO: String, Sendable, Equatable {
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

    /// Operation completed
    case completed

    /// Operation failed
    case failed
  }

  /// Current phase of the operation
  public let phase: PhaseDTO

  /// Percentage of operation completed (0-100)
  public let percentComplete: Double

  /// Number of items processed so far
  public let itemsProcessed: Int

  /// Total number of items to process
  public let totalItems: Int

  /// Number of bytes processed so far
  public let bytesProcessed: Int64

  /// Total number of bytes to process
  public let totalBytes: Int64

  /// Additional details about the operation
  public let details: String

  /// Whether the operation can be cancelled
  public let isCancellable: Bool

  /// Creates a new BackupProgressDTO instance
  public init(
    phase: PhaseDTO,
    percentComplete: Double,
    itemsProcessed: Int,
    totalItems: Int,
    bytesProcessed: Int64,
    totalBytes: Int64,
    details: String,
    isCancellable: Bool=true
  ) {
    self.phase=phase
    self.percentComplete=percentComplete
    self.itemsProcessed=itemsProcessed
    self.totalItems=totalItems
    self.bytesProcessed=bytesProcessed
    self.totalBytes=totalBytes
    self.details=details
    self.isCancellable=isCancellable
  }
}

// MARK: - Conversion Extensions

extension BackupProgressDTO {
  /// Convert from ResticInterfaces.BackupProgress to BackupProgressDTO
  public static func from(resticProgress: BackupProgress) -> BackupProgressDTO {
    let phase: PhaseDTO=switch resticProgress.status {
      case .scanning:
        .scanning
      case .processing:
        .processing
      case .saving:
        .finalising
    }

    let percentComplete=resticProgress.percentComplete

    return BackupProgressDTO(
      phase: phase,
      percentComplete: percentComplete,
      itemsProcessed: resticProgress.processedFiles,
      totalItems: resticProgress.totalFiles,
      bytesProcessed: resticProgress.processedBytes,
      totalBytes: resticProgress.totalBytes,
      details: resticProgress.currentFile ?? ""
    )
  }

  /// Convert from BackupProgressDTO to BackupInterfaces.BackupProgressInfo
  public func toBackupProgressInfo(for _: BackupOperation) -> BackupProgressInfo {
    let backupPhase: BackupProgressInfo.Phase=switch phase {
      case .initialising:
        .initialising
      case .scanning:
        .scanning
      case .processing:
        .processing
      case .transferring:
        .transferring
      case .finalising:
        .finalising
      case .cleanup:
        .cleanup
      case .completed:
        .completed
      case .failed:
        .failed
    }

    return BackupProgressInfo(
      phase: backupPhase,
      percentComplete: percentComplete,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      bytesProcessed: bytesProcessed,
      totalBytes: totalBytes,
      details: details,
      isCancellable: isCancellable
    )
  }
}

// MARK: - Convenience Factory Methods

extension BackupProgressDTO {
  /// Creates a progress instance for initialisation with a description
  public static func initialising(description: String) -> BackupProgressDTO {
    BackupProgressDTO(
      phase: .initialising,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: description
    )
  }

  /// Creates a progress instance for completed operation with a description
  public static func completed(description: String) -> BackupProgressDTO {
    BackupProgressDTO(
      phase: .completed,
      percentComplete: 100.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: description
    )
  }

  /// Creates a progress instance for failed operation with error information
  public static func failed(error: String) -> BackupProgressDTO {
    BackupProgressDTO(
      phase: .failed,
      percentComplete: 0.0,
      itemsProcessed: 0,
      totalItems: 0,
      bytesProcessed: 0,
      totalBytes: 0,
      details: "Failed: \(error)",
      isCancellable: false
    )
  }
}
