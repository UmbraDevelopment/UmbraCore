import BackupInterfaces
import Foundation

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
