import Foundation

/**
 * Parameters for comparing two snapshots.
 *
 * This struct defines the parameters required for comparing two snapshots,
 * including optional filters for narrowing the comparison.
 */
public struct SnapshotComparisonParameters: Sendable, Equatable {
  /// ID of the operation
  public let operationID: String

  /// ID of the first snapshot to compare
  public let firstSnapshotID: String

  /// ID of the second snapshot to compare
  public let secondSnapshotID: String

  /// Optional date to filter before
  public let before: Date?

  /// Optional date to filter after
  public let after: Date?

  /// Optional host to filter by
  public let host: String?

  /// Optional path that must be included in the backup
  public let path: String?

  /**
   * Creates a new set of snapshot comparison parameters.
   *
   * - Parameters:
   *   - operationID: ID of the operation
   *   - firstSnapshotID: ID of the first snapshot to compare
   *   - secondSnapshotID: ID of the second snapshot to compare
   *   - before: Optional date to filter before
   *   - after: Optional date to filter after
   *   - host: Optional host to filter by
   *   - path: Optional path that must be included
   */
  public init(
    operationID: String,
    firstSnapshotID: String,
    secondSnapshotID: String,
    before: Date?=nil,
    after: Date?=nil,
    host: String?=nil,
    path: String?=nil
  ) {
    self.operationID=operationID
    self.firstSnapshotID=firstSnapshotID
    self.secondSnapshotID=secondSnapshotID
    self.before=before
    self.after=after
    self.host=host
    self.path=path
  }
}
