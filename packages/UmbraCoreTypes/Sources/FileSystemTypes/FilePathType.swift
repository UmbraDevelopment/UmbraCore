import Foundation

/// Represents a file path in the system
public struct FilePath: Sendable, Equatable, Hashable {
  /// The string representation of the path
  public let path: String

  /// Creates a new file path
  /// - Parameter path: The string representation of the path
  public init(path: String) {
    self.path=path
  }
}

/// Represents a file system item type
public enum FileSystemItemType: String, Sendable, Equatable, Hashable {
  /// Regular file
  case file
  /// Directory
  case directory
  /// Symbolic link
  case symbolicLink
  /// Unknown item type
  case unknown
}

/// Represents metadata for a file system item
public struct FileSystemMetadata: Sendable, Equatable, Hashable {
  /// The path of the file system item
  public let path: FilePath
  /// The type of the file system item
  public let itemType: FileSystemItemType
  /// The size of the file system item in bytes
  public let size: UInt64
  /// The creation date of the file system item
  public let creationDate: Date?
  /// The modification date of the file system item
  public let modificationDate: Date?

  /// Creates a new file system metadata
  /// - Parameters:
  ///   - path: The path of the file system item
  ///   - itemType: The type of the file system item
  ///   - size: The size of the file system item in bytes
  ///   - creationDate: The creation date of the file system item
  ///   - modificationDate: The modification date of the file system item
  public init(
    path: FilePath,
    itemType: FileSystemItemType,
    size: UInt64,
    creationDate: Date?,
    modificationDate: Date?
  ) {
    self.path=path
    self.itemType=itemType
    self.size=size
    self.creationDate=creationDate
    self.modificationDate=modificationDate
  }
}
