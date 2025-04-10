import FileSystemTypes
import Foundation
import CoreDTOs

/**
 Represents metadata about a file in the file system.

 This structure provides a rich set of metadata about files, including paths,
 resource values, and other metadata that might be relevant to the application.
 */
public struct FileMetadata: Sendable, Equatable {
  /// The path to the file
  public let path: FilePathDTO

  /// File attributes
  public let attributes: FileAttributes

  /// Type-safe resource values, keyed by resource key
  public let safeResourceValues: [FileResourceKey: SafeAttributeValue]

  /// Whether the file exists
  public let exists: Bool

  /// Creates a new file metadata instance
  public init(
    path: FilePathDTO,
    attributes: FileAttributes,
    safeResourceValues: [FileResourceKey: SafeAttributeValue] = [:],
    exists: Bool = true
  ) {
    self.path = path
    self.attributes = attributes
    self.safeResourceValues = safeResourceValues
    self.exists = exists
  }

  /// Convenience initializer that converts legacy resource values to safe values
  public init(
    path: FilePathDTO,
    attributes: FileAttributes,
    resourceValues: [FileResourceKey: Any] = [:],
    exists: Bool = true
  ) {
    let safeValues = resourceValues.compactMapValues { value in
      SafeAttributeValue(from: value)
    }

    self.init(
      path: path,
      attributes: attributes,
      safeResourceValues: safeValues,
      exists: exists
    )
  }

  /// Custom equality implementation
  public static func == (lhs: FileMetadata, rhs: FileMetadata) -> Bool {
    lhs.path == rhs.path &&
      lhs.attributes == rhs.attributes &&
      lhs.safeResourceValues == rhs.safeResourceValues &&
      lhs.exists == rhs.exists
  }
}
