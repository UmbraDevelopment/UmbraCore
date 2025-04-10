import BackupInterfaces
import Foundation

/**
 * DTO for the difference between two snapshots.
 *
 * This type encapsulates the differences between two snapshots,
 * including counts of added, removed, modified, and unchanged files.
 */
public struct SnapshotComparisonDTO: Sendable, Equatable {
  /// ID of the first snapshot compared
  public let snapshotID1: String

  /// ID of the second snapshot compared
  public let snapshotID2: String

  /// Count of files added in the second snapshot
  public let addedCount: Int

  /// Count of files removed in the second snapshot
  public let removedCount: Int

  /// Count of files modified in the second snapshot
  public let modifiedCount: Int

  /// Count of files unchanged between snapshots
  public let unchangedCount: Int

  /// Detailed list of added files, if available
  public let addedFiles: [SnapshotFileDTO]?

  /// Detailed list of removed files, if available
  public let removedFiles: [SnapshotFileDTO]?

  /// Detailed list of modified files, if available
  public let modifiedFiles: [SnapshotFileDTO]?

  /**
   * Creates a new snapshot comparison DTO.
   *
   * - Parameters:
   *   - snapshotID1: ID of the first snapshot compared
   *   - snapshotID2: ID of the second snapshot compared
   *   - addedCount: Count of files added in the second snapshot
   *   - removedCount: Count of files removed in the second snapshot
   *   - modifiedCount: Count of files modified in the second snapshot
   *   - unchangedCount: Count of files unchanged between snapshots
   *   - addedFiles: Detailed list of added files, if available
   *   - removedFiles: Detailed list of removed files, if available
   *   - modifiedFiles: Detailed list of modified files, if available
   */
  public init(
    snapshotID1: String,
    snapshotID2: String,
    addedCount: Int,
    removedCount: Int,
    modifiedCount: Int,
    unchangedCount: Int,
    addedFiles: [SnapshotFileDTO]?=nil,
    removedFiles: [SnapshotFileDTO]?=nil,
    modifiedFiles: [SnapshotFileDTO]?=nil
  ) {
    self.snapshotID1=snapshotID1
    self.snapshotID2=snapshotID2
    self.addedCount=addedCount
    self.removedCount=removedCount
    self.modifiedCount=modifiedCount
    self.unchangedCount=unchangedCount
    self.addedFiles=addedFiles
    self.removedFiles=removedFiles
    self.modifiedFiles=modifiedFiles
  }

  /**
   * Converts this DTO to a BackupInterfaces.BackupSnapshotDifference.
   *
   * - Returns: A BackupSnapshotDifference compatible with the interfaces module
   */
  public func toDifferenceInterfaceType() -> BackupInterfaces.BackupSnapshotDifference {
    BackupInterfaces.BackupSnapshotDifference(
      snapshotID1: snapshotID1,
      snapshotID2: snapshotID2,
      addedCount: addedCount,
      removedCount: removedCount,
      modifiedCount: modifiedCount,
      unchangedCount: unchangedCount,
      addedFiles: addedFiles?.map { $0.toInterfaceType() },
      removedFiles: removedFiles?.map { $0.toInterfaceType() },
      modifiedFiles: modifiedFiles?.map { $0.toInterfaceType() }
    )
  }

  /**
   * Converts this DTO to a BackupInterfaces.BackupSnapshotComparisonResult.
   *
   * - Returns: A BackupSnapshotComparisonResult with the same data
   */
  public func toInterfaceType() -> BackupInterfaces.BackupSnapshotComparisonResult {
    // Convert files to BackupFile objects
    let added=(addedFiles ?? []).map { $0.toBackupFile() }
    let removed=(removedFiles ?? []).map { $0.toBackupFile() }
    let modified=(modifiedFiles ?? []).map { $0.toBackupFile() }

    // Calculate total change size
    let changeSize=UInt64(
      (addedFiles ?? []).reduce(0) { $0 + $1.size } +
        (modifiedFiles ?? []).reduce(0) { $0 + $1.size }
    )

    // Create the result
    return BackupInterfaces.BackupSnapshotComparisonResult(
      firstSnapshotID: snapshotID1,
      secondSnapshotID: snapshotID2,
      addedFiles: added,
      removedFiles: removed,
      modifiedFiles: modified,
      unchangedFiles: [], // We don't have this information
      changeSize: changeSize,
      comparisonTimestamp: Date()
    )
  }
}
