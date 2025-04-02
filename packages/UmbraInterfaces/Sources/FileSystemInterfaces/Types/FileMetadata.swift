import FileSystemTypes
import Foundation

/**
 Represents metadata about a file in the file system.

 This structure encapsulates information about a file, including its attributes,
 resource values, and other metadata that might be relevant to the application.
 */
public struct FileMetadata: Sendable, Equatable {
  /// The path to the file
  public let path: FilePath

  /// File attributes
  public let attributes: FileAttributes

  /// Resource values, keyed by resource key
  /// Note: Using @unchecked Sendable as [FileResourceKey: Any] isn't Sendable by default
  @available(
    *,
    deprecated,
    message: "This property will be replaced with a safer alternative in Swift 6"
  )
  public let resourceValues: @unchecked Sendable[FileResourceKey: Any]

  /// Whether the file exists
  public let exists: Bool

  /// Creates a new file metadata instance
  public init(
    path: FilePath,
    attributes: FileAttributes,
    resourceValues: [FileResourceKey: Any]=[:],
    exists: Bool=true
  ) {
    self.path=path
    self.attributes=attributes
    self.resourceValues=resourceValues
    self.exists=exists
  }

  /// Custom equality implementation that ignores resourceValues which isn't Equatable
  public static func == (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
    lhs.path == rhs.path &&
      lhs.attributes == rhs.attributes &&
      lhs.exists == rhs.exists
  }
}
