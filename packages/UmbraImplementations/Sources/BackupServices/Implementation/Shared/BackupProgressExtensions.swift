import BackupInterfaces
import Foundation

extension BackupProgress {
  /// Creates a progress instance for initialisation with a description
  /// - Parameter description: Description of the initialisation
  /// - Returns: A progress instance in the initialising phase
  public static func initialising(description: String) -> BackupProgress {
    BackupProgress(
      phase: .initialising,
      percentComplete: 0.0,
      currentItem: description
    )
  }

  /// Creates a progress instance for completed operation with a description
  /// - Parameter description: Description of the completion
  /// - Returns: A progress instance with 100% completion
  public static func completed(description: String) -> BackupProgress {
    BackupProgress(
      phase: .finalising,
      percentComplete: 1.0,
      currentItem: description
    )
  }

  /// Creates a progress instance for failed operation with error information
  /// - Parameter error: Description of the error
  /// - Returns: A progress instance indicating failure
  public static func failed(error: String) -> BackupProgress {
    BackupProgress(
      phase: .finalising,
      percentComplete: 0.0,
      currentItem: "Failed: \(error)"
    )
  }
}
