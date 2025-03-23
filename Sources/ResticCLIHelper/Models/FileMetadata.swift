import Foundation

/// Represents file metadata in a backup
public struct FileMetadata: Codable, Sendable {
  /// File name
  public let name: String

  /// File type (file, directory, symlink, etc.)
  public let type: String

  /// File mode and permissions
  public let mode: UInt32

  /// Last modification time
  public let modTime: Date

  /// Last access time
  public let accessTime: Date

  /// Last change time
  public let changeTime: Date

  /// User ID
  public let uid: UInt32

  /// Group ID
  public let gid: UInt32

  /// User name
  public let user: String

  /// Group name
  public let group: String

  /// Inode number
  public let inode: UInt64

  /// File size in bytes
  public let size: Int64

  /// Number of hard links
  public let links: UInt32

  /// Target path for symlinks
  public let linkTarget: String?

  /// Device ID if applicable
  public let device: UInt64?

  /// Extended attributes
  public let extendedAttributes: [String: String]?

  private enum CodingKeys: String, CodingKey {
    case name
    case type
    case mode
    case modTime="mod_time"
    case accessTime="access_time"
    case changeTime="change_time"
    case uid
    case gid
    case user
    case group
    case inode
    case size
    case links
    case linkTarget="link_target"
    case device
    case extendedAttributes="extended_attributes"
  }
}
