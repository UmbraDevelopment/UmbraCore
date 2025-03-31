import Foundation

/// Represents the difference between two snapshots
///
/// This type encapsulates the differences between two snapshots,
/// including counts of added, removed, modified, and unchanged files.
public struct BackupSnapshotDifference: Sendable, Equatable {
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

  /// Total difference count (added + removed + modified)
  public var totalDifferenceCount: Int {
    addedCount + removedCount + modifiedCount
  }

  /// Detailed list of added files, if available
  public let addedFiles: [SnapshotFile]?

  /// Detailed list of removed files, if available
  public let removedFiles: [SnapshotFile]?

  /// Detailed list of modified files, if available
  public let modifiedFiles: [SnapshotFile]?

  /// Creates a new snapshot difference
  /// - Parameters:
  ///   - snapshotID1: ID of the first snapshot compared
  ///   - snapshotID2: ID of the second snapshot compared
  ///   - addedCount: Count of files added in the second snapshot
  ///   - removedCount: Count of files removed in the second snapshot
  ///   - modifiedCount: Count of files modified in the second snapshot
  ///   - unchangedCount: Count of files unchanged between snapshots
  ///   - addedFiles: Detailed list of added files, if available
  ///   - removedFiles: Detailed list of removed files, if available
  ///   - modifiedFiles: Detailed list of modified files, if available
  public init(
    snapshotID1: String,
    snapshotID2: String,
    addedCount: Int,
    removedCount: Int,
    modifiedCount: Int,
    unchangedCount: Int,
    addedFiles: [SnapshotFile]?=nil,
    removedFiles: [SnapshotFile]?=nil,
    modifiedFiles: [SnapshotFile]?=nil
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

  /// Returns a textual summary of the differences
  public var summary: String {
    """
    Comparison between \(snapshotID1) and \(snapshotID2):
    - \(addedCount) files added
    - \(removedCount) files removed
    - \(modifiedCount) files modified
    - \(unchangedCount) files unchanged
    """
  }

  /// Indicates whether there are any differences between the snapshots
  public var hasDifferences: Bool {
    totalDifferenceCount > 0
  }
}
