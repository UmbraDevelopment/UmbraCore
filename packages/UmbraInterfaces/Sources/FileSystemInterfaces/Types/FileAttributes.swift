import Foundation

/**
 Represents file attributes.

 This structure encapsulates file attributes such as size, creation date,
 modification date, and other system-level file metadata.
 */
public struct FileAttributes: Sendable, Equatable {
  /// File size in bytes
  public let size: UInt64

  /// File creation date
  public let creationDate: Date

  /// File modification date
  public let modificationDate: Date

  /// File access date
  public let accessDate: Date

  /// File permissions
  public let permissions: UInt16

  /// File owner ID
  public let ownerID: UInt

  /// File group ID
  public let groupID: UInt

  /// File flags (hidden, etc.)
  public let flags: UInt

  /// Additional attributes as a dictionary
  public let extendedAttributes: [String: Any]

  /// Creates a new file attributes instance
  public init(
    size: UInt64,
    creationDate: Date,
    modificationDate: Date,
    accessDate: Date,
    permissions: UInt16,
    ownerID: UInt,
    groupID: UInt,
    flags: UInt,
    extendedAttributes: [String: Any]=[:]
  ) {
    self.size=size
    self.creationDate=creationDate
    self.modificationDate=modificationDate
    self.accessDate=accessDate
    self.permissions=permissions
    self.ownerID=ownerID
    self.groupID=groupID
    self.flags=flags
    self.extendedAttributes=extendedAttributes
  }

  /// Equality implementation that ignores the extendedAttributes property
  public static func == (lhs: FileAttributes, rhs: FileAttributes) -> Bool {
    lhs.size == rhs.size &&
      lhs.creationDate == rhs.creationDate &&
      lhs.modificationDate == rhs.modificationDate &&
      lhs.accessDate == rhs.accessDate &&
      lhs.permissions == rhs.permissions &&
      lhs.ownerID == rhs.ownerID &&
      lhs.groupID == rhs.groupID &&
      lhs.flags == rhs.flags
  }
}
