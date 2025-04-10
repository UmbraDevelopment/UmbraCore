import Foundation

/**
 * Represents information about a file in a snapshot.
 *
 * This type provides comprehensive metadata about files within
 * backup snapshots, facilitating efficient analysis and retrieval.
 */
public struct FileInfo: Sendable, Equatable, Hashable {
  /// Path of the file
  public let path: String

  /// Size of the file in bytes
  public let size: UInt64

  /// Last modification time
  public let modificationTime: Date

  /// Type of the file
  public let type: BackupInterfaces.FileType

  /// Permissions of the file
  public let permissions: BackupInterfaces.FilePermissions

  /// Owner of the file
  public let owner: String

  /// Group of the file
  public let group: String

  /// Hash of the file content (for integrity checks)
  public let contentHash: String?

  /**
   * Initialises a new file info object.
   *
   * - Parameters:
   *   - path: Path of the file
   *   - size: Size of the file in bytes
   *   - modificationTime: Last modification time
   *   - type: Type of the file
   *   - permissions: Permissions of the file
   *   - owner: Owner of the file
   *   - group: Group of the file
   *   - contentHash: Hash of the file content
   */
  public init(
    path: String,
    size: UInt64,
    modificationTime: Date,
    type: BackupInterfaces.FileType,
    permissions: BackupInterfaces.FilePermissions,
    owner: String,
    group: String,
    contentHash: String?=nil
  ) {
    self.path=path
    self.size=size
    self.modificationTime=modificationTime
    self.type=type
    self.permissions=permissions
    self.owner=owner
    self.group=group
    self.contentHash=contentHash
  }

  /**
   * Gets the filename from the path.
   */
  public var filename: String {
    URL(fileURLWithPath: path).lastPathComponent
  }

  /**
   * Gets the file extension (without the dot).
   */
  public var fileExtension: String {
    URL(fileURLWithPath: path).pathExtension
  }

  // MARK: - Hashable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(path)
    hasher.combine(size)
    hasher.combine(modificationTime)
    hasher.combine(type)
    hasher.combine(permissions)
    hasher.combine(owner)
    hasher.combine(group)
    hasher.combine(contentHash)
  }

  public static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
    lhs.path == rhs.path &&
      lhs.size == rhs.size &&
      lhs.modificationTime == rhs.modificationTime &&
      lhs.type == rhs.type &&
      lhs.permissions == rhs.permissions &&
      lhs.owner == rhs.owner &&
      lhs.group == rhs.group &&
      lhs.contentHash == rhs.contentHash
  }
}
