import BackupInterfaces
import Foundation

/**
 * DTO for a file within a backup snapshot.
 *
 * This type provides information about a specific file in a snapshot,
 * including its path, size, and modification time.
 */
public struct SnapshotFileDTO: Sendable, Equatable {
  /// The path of the file relative to the snapshot root
  public let path: String

  /// The size of the file in bytes
  public let size: UInt64

  /// The modification time of the file
  public let modificationTime: Date

  /// The file type (file, directory, etc.)
  public let type: String

  /// The permissions of the file
  public let permissions: String?

  /// The owner of the file
  public let owner: String?

  /// The group of the file
  public let group: String?

  /// Optional hash of the file contents
  public let contentHash: String?

  /**
   * Creates a new snapshot file DTO.
   *
   * - Parameters:
   *   - path: The path of the file relative to the snapshot root
   *   - size: The size of the file in bytes
   *   - modificationTime: The modification time of the file
   *   - type: The file type (file, directory, etc.)
   *   - permissions: The permissions of the file
   *   - owner: The owner of the file
   *   - group: The group of the file
   *   - contentHash: Optional hash of the file contents
   */
  public init(
    path: String,
    size: UInt64,
    modificationTime: Date,
    type: String,
    permissions: String?=nil,
    owner: String?=nil,
    group: String?=nil,
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
   * Converts this DTO to a SnapshotFile.
   *
   * - Returns: A SnapshotFile with the same data
   */
  public func toInterfaceType() -> BackupInterfaces.SnapshotFile {
    // Convert the file type
    let fileType=convertFileType(type)

    // Parse the mode from permissions
    let mode: UInt16=parsePermissions(permissions)?.mode ?? 0

    // Create the snapshot file
    return BackupInterfaces.SnapshotFile(
      path: path,
      size: size,
      modificationTime: modificationTime,
      mode: mode,
      uid: 0, // Default value as we don't have this information
      gid: 0, // Default value as we don't have this information
      fileType: fileType,
      contentHash: contentHash
    )
  }

  /**
   * Converts this DTO to a BackupFile.
   *
   * - Returns: A BackupFile with the same data
   */
  public func toBackupFile() -> BackupInterfaces.BackupFile {
    // Create the backup file
    BackupInterfaces.BackupFile(
      path: path,
      size: size,
      modifiedTime: modificationTime,
      type: BackupInterfaces.BackupFileType.file, // Use the correct file type
      permissions: permissions,
      ownerName: owner,
      groupName: group
    )
  }

  /**
   * Converts a string file type to the enum type.
   *
   * - Parameter type: String representation of file type
   * - Returns: The corresponding FileType enum value
   */
  private func convertFileType(_ type: String) -> BackupInterfaces.FileType {
    switch type.lowercased() {
      case "file":
        .regular
      case "directory", "dir":
        .directory
      case "symlink":
        .symlink
      case "socket":
        .socket
      case "pipe":
        .pipe
      case "device":
        .device
      default:
        .unknown
    }
  }

  /**
   * Parses a permissions string to a FilePermissions object.
   *
   * - Parameter permissions: The permissions string (e.g., "rwxr-xr--")
   * - Returns: A FilePermissions object, or nil if the string is invalid
   */
  private func parsePermissions(_ permissions: String?) -> BackupInterfaces.FilePermissions? {
    guard let permissions else {
      // Default permissions (rw-r--r--)
      return BackupInterfaces.FilePermissions(mode: 0o644)
    }

    // Convert the permissions string to a mode value
    var mode: UInt16=0

    // Owner permissions
    if !permissions.isEmpty && permissions[permissions.startIndex] == "r" { mode |= 0o400 }
    if
      permissions
        .count > 1 && permissions[permissions.index(permissions.startIndex, offsetBy: 1)] ==
        "w" { mode |= 0o200 }
    if
      permissions
        .count > 2 && permissions[permissions.index(permissions.startIndex, offsetBy: 2)] ==
        "x" { mode |= 0o100 }

    // Group permissions
    if
      permissions
        .count > 3 && permissions[permissions.index(permissions.startIndex, offsetBy: 3)] ==
        "r" { mode |= 0o040 }
    if
      permissions
        .count > 4 && permissions[permissions.index(permissions.startIndex, offsetBy: 4)] ==
        "w" { mode |= 0o020 }
    if
      permissions
        .count > 5 && permissions[permissions.index(permissions.startIndex, offsetBy: 5)] ==
        "x" { mode |= 0o010 }

    // Others permissions
    if
      permissions
        .count > 6 && permissions[permissions.index(permissions.startIndex, offsetBy: 6)] ==
        "r" { mode |= 0o004 }
    if
      permissions
        .count > 7 && permissions[permissions.index(permissions.startIndex, offsetBy: 7)] ==
        "w" { mode |= 0o002 }
    if
      permissions
        .count > 8 && permissions[permissions.index(permissions.startIndex, offsetBy: 8)] ==
        "x" { mode |= 0o001 }

    return BackupInterfaces.FilePermissions(mode: mode)
  }
}
