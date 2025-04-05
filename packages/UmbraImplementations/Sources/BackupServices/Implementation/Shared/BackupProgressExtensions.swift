import BackupInterfaces
import Foundation
import ResticInterfaces

extension BackupProgress {
  /// Converts a ResticInterfaces.BackupProgress to a BackupInterfaces.BackupProgressInfo
  ///
  /// - Parameter operation: The operation this progress relates to
  /// - Returns: A BackupProgressInfo instance
  public func toBackupProgressInfo(for operation: BackupOperation) -> BackupProgressInfo {
    // Use the DTO as an intermediate adapter layer
    let dto = BackupProgressDTO.from(resticProgress: self)
    return dto.toBackupProgressInfo(for: operation)
  }
}

// MARK: - BackupProgress Extensions for Phase Conversion

extension BackupProgressInfo.Phase {
  /// Initialises a Phase from a BackupProgress.Status
  ///
  /// - Parameter status: The status to convert from
  init(from status: BackupProgress.Status) {
    switch status {
      case .scanning:
        self = .scanning
      case .processing:
        self = .processing
      case .saving:
        self = .finalising
    }
  }
}

extension BackupProgressInfo {
  /// Creates a progress instance for initialisation with a description
  /// - Parameter description: Description of the initialisation
  /// - Returns: A progress instance in the initialising phase
  public static func initialising(description: String) -> BackupProgressInfo {
    BackupProgressInfo(
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
  /// - Parameter description: Description of the completion
  /// - Returns: A progress instance with 100% completion
  public static func completed(description: String) -> BackupProgressInfo {
    BackupProgressInfo(
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
  /// - Parameter error: Description of the error
  /// - Returns: A progress instance indicating failure
  public static func failed(error: String) -> BackupProgressInfo {
    BackupProgressInfo(
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
