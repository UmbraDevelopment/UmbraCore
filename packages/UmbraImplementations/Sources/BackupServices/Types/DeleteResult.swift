import BackupInterfaces
import Foundation

/**
 * Represents the result of a delete operation.
 */
public struct DeleteResult: Sendable {
  /// The ID of the snapshot that was deleted
  public let snapshotID: String

  /// Whether the deletion was successful
  public let successful: Bool

  /// Number of files deleted
  public let filesDeleted: Int

  /// Size of data deleted in bytes
  public let sizeDeleted: UInt64

  /// When the deletion was completed
  public let deletionTimestamp: Date

  /**
   * Initialises a new delete result.
   *
   * - Parameters:
   *   - snapshotID: The ID of the snapshot that was deleted
   *   - successful: Whether the deletion was successful
   *   - filesDeleted: Number of files deleted
   *   - sizeDeleted: Size of data deleted in bytes
   *   - deletionTimestamp: When the deletion was completed
   */
  public init(
    snapshotID: String,
    successful: Bool,
    filesDeleted: Int=0,
    sizeDeleted: UInt64=0,
    deletionTimestamp: Date=Date()
  ) {
    self.snapshotID=snapshotID
    self.successful=successful
    self.filesDeleted=filesDeleted
    self.sizeDeleted=sizeDeleted
    self.deletionTimestamp=deletionTimestamp
  }

  /**
   * Converts this result to the interface type.
   *
   * - Returns: The interface type representation
   */
  public func toInterfaceType() -> BackupInterfaces.BackupDeleteResult {
    BackupInterfaces.BackupDeleteResult(
      snapshotID: snapshotID,
      completionTime: deletionTimestamp,
      reclaimedBytes: sizeDeleted,
      pruned: successful
    )
  }
}
