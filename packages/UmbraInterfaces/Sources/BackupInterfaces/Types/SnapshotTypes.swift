import Foundation

/// Types of file modifications
public enum ModificationType: String, Sendable, Equatable, CaseIterable {
  /// Content changed
  case content
  /// Permissions changed
  case permissions
  /// Owner changed
  case owner
  /// Type changed
  case type
  /// Multiple attributes changed
  case multiple
}

/// Represents a file that was modified between snapshots
public struct ModifiedFile: Sendable, Equatable, Identifiable {
  /// Unique identifier for the file
  public let id: String

  /// Path of the file
  public let path: String

  /// Original size in bytes
  public let originalSize: UInt64

  /// New size in bytes
  public let newSize: UInt64

  /// Original modification time
  public let originalModTime: Date

  /// New modification time
  public let newModTime: Date

  /// Type of modification
  public let modificationType: ModificationType

  /// Creates a new modified file
  /// - Parameters:
  ///   - id: Unique identifier
  ///   - path: File path
  ///   - originalSize: Original size
  ///   - newSize: New size
  ///   - originalModTime: Original modification time
  ///   - newModTime: New modification time
  ///   - modificationType: Type of modification
  public init(
    id: String,
    path: String,
    originalSize: UInt64,
    newSize: UInt64,
    originalModTime: Date,
    newModTime: Date,
    modificationType: ModificationType
  ) {
    self.id=id
    self.path=path
    self.originalSize=originalSize
    self.newSize=newSize
    self.originalModTime=originalModTime
    self.newModTime=newModTime
    self.modificationType=modificationType
  }
}

/// File types in a snapshot
public enum FileType: String, Sendable, Equatable, CaseIterable {
  /// Regular file
  case file
  /// Directory
  case directory
  /// Symbolic link
  case symlink
  /// Hard link
  case hardlink
  /// Block device
  case blockDevice
  /// Character device
  case charDevice
  /// Named pipe
  case pipe
  /// Socket
  case socket
  /// Other special file
  case special
}
