import Foundation

/**
 Represents file attributes.

 File attributes contain metadata about the file and provide
 information about its size, dates, permissions, and other properties.
 
 Note that this struct conforms to Sendable and all its properties are immutable.
 */
public struct FileAttributes: Sendable, Equatable {
  /// The size of the file in bytes
  public let size: UInt64
  
  /// The creation date of the file
  public let creationDate: Date
  
  /// The last modification date of the file
  public let modificationDate: Date
  
  /// The last access date of the file, if available
  public let accessDate: Date?
  
  /// The user ID of the file owner
  public let ownerID: UInt
  
  /// The group ID of the file
  public let groupID: UInt
  
  /// The file permissions (POSIX style)
  public let permissions: UInt16
  
  /// The file type, if available
  public let fileType: String?
  
  /// The file creator, if available
  public let creator: String?
  
  /// The file flags
  public let flags: UInt
  
  /// Type-safe extended attributes that maintain Sendable conformance
  public let safeExtendedAttributes: [String: SafeAttributeValue]

  /// Creates a new file attributes instance
  public init(
    size: UInt64,
    creationDate: Date,
    modificationDate: Date,
    accessDate: Date? = nil,
    ownerID: UInt = 0,
    groupID: UInt = 0,
    permissions: UInt16 = 0,
    fileType: String? = nil,
    creator: String? = nil,
    flags: UInt = 0,
    safeExtendedAttributes: [String: SafeAttributeValue] = [:]
  ) {
    self.size = size
    self.creationDate = creationDate
    self.modificationDate = modificationDate
    self.accessDate = accessDate
    self.ownerID = ownerID
    self.groupID = groupID
    self.permissions = permissions
    self.fileType = fileType
    self.creator = creator
    self.flags = flags
    self.safeExtendedAttributes = safeExtendedAttributes
  }
  
  /// Creates a file attributes instance from a dictionary of extended attributes
  public init(
    size: UInt64,
    creationDate: Date,
    modificationDate: Date,
    accessDate: Date? = nil,
    ownerID: UInt = 0,
    groupID: UInt = 0,
    permissions: UInt16 = 0,
    fileType: String? = nil,
    creator: String? = nil,
    flags: UInt = 0,
    extendedAttributes: [String: Any] = [:]
  ) {
    let safeAttributes = extendedAttributes.compactMapValues { value in
      SafeAttributeValue(from: value)
    }
    
    self.init(
      size: size,
      creationDate: creationDate,
      modificationDate: modificationDate,
      accessDate: accessDate,
      ownerID: ownerID,
      groupID: groupID,
      permissions: permissions,
      fileType: fileType,
      creator: creator,
      flags: flags,
      safeExtendedAttributes: safeAttributes
    )
  }
}

extension FileAttributes {
  public static func == (lhs: FileAttributes, rhs: FileAttributes) -> Bool {
    lhs.size == rhs.size &&
    lhs.creationDate == rhs.creationDate &&
    lhs.modificationDate == rhs.modificationDate &&
    lhs.accessDate == rhs.accessDate &&
    lhs.ownerID == rhs.ownerID &&
    lhs.groupID == rhs.groupID &&
    lhs.permissions == rhs.permissions &&
    lhs.fileType == rhs.fileType &&
    lhs.creator == rhs.creator &&
    lhs.flags == rhs.flags &&
    lhs.safeExtendedAttributes == rhs.safeExtendedAttributes
  }
}
