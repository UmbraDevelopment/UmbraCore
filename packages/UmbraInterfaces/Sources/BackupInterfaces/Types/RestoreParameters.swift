import Foundation

/**
 * Parameters for restoring from a backup.
 *
 * This struct encapsulates all the parameters needed to restore from a backup,
 * including snapshot ID, target path, included/excluded paths, and options.
 */
public struct RestoreParameters: Sendable {
  /// ID of the snapshot to restore from
  public let snapshotID: String

  /// Path to restore to
  public let targetPath: String

  /// Specific paths within the snapshot to restore
  public let includePaths: [String]?

  /// Paths within the snapshot to exclude from restoration
  public let excludePaths: [String]?

  /// Additional options for the restore operation
  public let options: RestoreOptions?

  /**
   * Creates a new set of restore parameters.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to restore from
   *   - targetPath: Path to restore to
   *   - includePaths: Specific paths within the snapshot to restore
   *   - excludePaths: Paths within the snapshot to exclude from restoration
   *   - options: Additional options for the restore operation
   */
  public init(
    snapshotID: String,
    targetPath: String,
    includePaths: [String]?=nil,
    excludePaths: [String]?=nil,
    options: RestoreOptions?=nil
  ) {
    self.snapshotID=snapshotID
    self.targetPath=targetPath
    self.includePaths=includePaths
    self.excludePaths=excludePaths
    self.options=options
  }
}

// Implement Equatable conformance manually
extension RestoreParameters: Equatable {
  public static func == (lhs: RestoreParameters, rhs: RestoreParameters) -> Bool {
    lhs.snapshotID == rhs.snapshotID &&
      lhs.targetPath == rhs.targetPath &&
      lhs.includePaths == rhs.includePaths &&
      lhs.excludePaths == rhs.excludePaths &&
      lhs.options == rhs.options
  }
}
