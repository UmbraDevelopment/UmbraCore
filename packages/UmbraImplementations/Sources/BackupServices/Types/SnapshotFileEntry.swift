import Foundation

/**
 * Represents a file within a backup snapshot.
 *
 * This model provides information about files stored within backups.
 */
public struct SnapshotFileEntry: Sendable, Equatable, Codable {
  /// The file path relative to the repository root
  public let path: String

  /// The file type (regular, directory, symlink)
  public let type: String

  /// The file size in bytes
  public let size: UInt64

  /// The modification time of the file
  public let modTime: Date

  /// The file mode and permissions
  public let mode: UInt32

  /// The user ID of the file owner
  public let uid: UInt32

  /// The group ID of the file group
  public let gid: UInt32

  /**
   * Creates a new SnapshotFileEntry instance.
   *
   * - Parameters:
   *   - path: The file path
   *   - type: The file type
   *   - size: The file size
   *   - modTime: The modification time
   *   - mode: The file mode
   *   - uid: The user ID
   *   - gid: The group ID
   */
  public init(
    path: String,
    type: String,
    size: UInt64,
    modTime: Date,
    mode: UInt32,
    uid: UInt32,
    gid: UInt32
  ) {
    self.path=path
    self.type=type
    self.size=size
    self.modTime=modTime
    self.mode=mode
    self.uid=uid
    self.gid=gid
  }
}
