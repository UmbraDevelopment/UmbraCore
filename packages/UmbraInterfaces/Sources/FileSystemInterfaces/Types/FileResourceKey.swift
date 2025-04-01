import Foundation

/**
 Represents resource keys for file system items.

 This enumeration defines the resource keys that can be used to retrieve
 specific information about files in the file system, providing a type-safe
 way to access file metadata.
 */
public enum FileResourceKey: String, Sendable, Hashable, Equatable, CaseIterable {
  /// Creation date resource key
  case creationDate="NSURLCreationDateKey"

  /// Content modification date resource key
  case contentModificationDate="NSURLContentModificationDateKey"

  /// Content access date resource key
  case contentAccessDate="NSURLContentAccessDateKey"

  /// Content type resource key
  case contentType="NSURLContentTypeKey"

  /// File size resource key
  case fileSize="NSURLFileSizeKey"

  /// File allocation size resource key
  case fileAllocatedSize="NSURLFileAllocatedSizeKey"

  /// Whether the item is a directory
  case isDirectory="NSURLIsDirectoryKey"

  /// Whether the item is a symbolic link
  case isSymbolicLink="NSURLIsSymbolicLinkKey"

  /// Whether the item is regular file
  case isRegularFile="NSURLIsRegularFileKey"

  /// Whether the item is readable
  case isReadable="NSURLIsReadableKey"

  /// Whether the item is writable
  case isWritable="NSURLIsWritableKey"

  /// Whether the item is executable
  case isExecutable="NSURLIsExecutableKey"

  /// Whether the item is hidden
  case isHidden="NSURLIsHiddenKey"

  /// The item's filename
  case filename="NSURLNameKey"

  /// The item's path
  case path="NSURLPathKey"

  /// Returns a human-readable localised description of the resource key
  public var localisedDescription: String {
    switch self {
      case .creationDate:
        "Creation Date"
      case .contentModificationDate:
        "Modification Date"
      case .contentAccessDate:
        "Access Date"
      case .contentType:
        "Content Type"
      case .fileSize:
        "File Size"
      case .fileAllocatedSize:
        "Allocated Size"
      case .isDirectory:
        "Is Directory"
      case .isSymbolicLink:
        "Is Symbolic Link"
      case .isRegularFile:
        "Is Regular File"
      case .isReadable:
        "Is Readable"
      case .isWritable:
        "Is Writable"
      case .isExecutable:
        "Is Executable"
      case .isHidden:
        "Is Hidden"
      case .filename:
        "Filename"
      case .path:
        "Path"
    }
  }
}
