import Foundation

/**
 * Represents a file stored in a backup snapshot.
 *
 * This type provides a standardised representation of file metadata
 * that can be used across different backup backends, following
 * the Alpha Dot Five architecture's principles for type safety.
 */
public struct BackupFile: Sendable, Equatable, Hashable {
  /// Path to the file relative to the repository root
  public let path: String

  /// Size of the file in bytes
  public let size: UInt64

  /// Modified time of the file
  public let modifiedTime: Date

  /// Type of the file
  public let type: BackupFileType

  /// Optional file permissions in octal format (e.g. "0644")
  public let permissions: String?

  /// Optional file owner username
  public let ownerName: String?

  /// Optional file group name
  public let groupName: String?

  /**
   * Creates a new BackupFile instance.
   *
   * - Parameters:
   *   - path: Path to the file relative to the repository root
   *   - size: Size of the file in bytes
   *   - modifiedTime: Modified time of the file
   *   - type: Type of the file
   *   - permissions: Optional file permissions in octal format
   *   - ownerName: Optional file owner username
   *   - groupName: Optional file group name
   */
  public init(
    path: String,
    size: UInt64,
    modifiedTime: Date,
    type: BackupFileType,
    permissions: String?=nil,
    ownerName: String?=nil,
    groupName: String?=nil
  ) {
    self.path=path
    self.size=size
    self.modifiedTime=modifiedTime
    self.type=type
    self.permissions=permissions
    self.ownerName=ownerName
    self.groupName=groupName
  }
}

/**
 * Enumeration of file types that can be stored in a backup.
 */
public enum BackupFileType: String, Sendable, Equatable, Hashable, Codable {
  /// Regular file
  case file
  /// Directory
  case directory
  /// Symbolic link
  case symlink
  /// Device file
  case device
  /// Named pipe (FIFO)
  case pipe
  /// Socket
  case socket
  /// Unknown file type
  case unknown
}
