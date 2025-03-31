import Foundation

/**
 * Represents the result of comparing two snapshots.
 *
 * This type provides a standardised way to represent differences between
 * snapshots, following the architecture's principles
 * for type safety and rich domain modelling.
 */
public struct BackupSnapshotComparisonResult: Sendable, Equatable {
  /// First snapshot ID used in the comparison
  public let firstSnapshotID: String

  /// Second snapshot ID used in the comparison
  public let secondSnapshotID: String

  /// Files that were added in the second snapshot
  public let addedFiles: [BackupFile]

  /// Files that were removed in the second snapshot
  public let removedFiles: [BackupFile]

  /// Files that were modified between snapshots
  public let modifiedFiles: [BackupFile]

  /// Files that remained unchanged between snapshots
  public let unchangedFiles: [BackupFile]

  /// Total size of changes in bytes
  public let changeSize: UInt64

  /// Timestamp when the comparison was performed
  public let comparisonTimestamp: Date

  /**
   * Creates a new snapshot comparison result.
   *
   * - Parameters:
   *   - firstSnapshotID: First snapshot ID used in the comparison
   *   - secondSnapshotID: Second snapshot ID used in the comparison
   *   - addedFiles: Files that were added in the second snapshot
   *   - removedFiles: Files that were removed in the second snapshot
   *   - modifiedFiles: Files that were modified between snapshots
   *   - unchangedFiles: Files that remained unchanged between snapshots
   *   - changeSize: Total size of changes in bytes
   *   - comparisonTimestamp: Timestamp when the comparison was performed
   */
  public init(
    firstSnapshotID: String,
    secondSnapshotID: String,
    addedFiles: [BackupFile],
    removedFiles: [BackupFile],
    modifiedFiles: [BackupFile],
    unchangedFiles: [BackupFile],
    changeSize: UInt64,
    comparisonTimestamp: Date=Date()
  ) {
    self.firstSnapshotID=firstSnapshotID
    self.secondSnapshotID=secondSnapshotID
    self.addedFiles=addedFiles
    self.removedFiles=removedFiles
    self.modifiedFiles=modifiedFiles
    self.unchangedFiles=unchangedFiles
    self.changeSize=changeSize
    self.comparisonTimestamp=comparisonTimestamp
  }

  /// Returns the total number of files that differ between snapshots
  public var totalChangedFiles: Int {
    addedFiles.count + removedFiles.count + modifiedFiles.count
  }

  /// Returns the total number of files examined in the comparison
  public var totalFilesExamined: Int {
    totalChangedFiles + unchangedFiles.count
  }

  /// Returns whether the snapshots are identical
  public var areSnapshotsIdentical: Bool {
    totalChangedFiles == 0
  }
}
