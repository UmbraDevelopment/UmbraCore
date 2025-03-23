import Foundation

/// A Foundation-independent representation of file system metadata.
public struct FileSystemMetadataDTO: Sendable, Equatable {
  // MARK: - Properties

  /// Size of the file in bytes
  public let fileSize: UInt64

  /// Creation date as Unix timestamp (seconds since 1970)
  public let creationDate: UInt64

  /// Last modification date as Unix timestamp (seconds since 1970)
  public let modificationDate: UInt64

  /// Last access date as Unix timestamp (seconds since 1970)
  public let accessDate: UInt64?

  /// File or directory owner's numeric ID
  public let ownerID: UInt32?

  /// File or directory group's numeric ID
  public let groupID: UInt32?

  /// POSIX permissions mask
  public let permissions: UInt16?

  /// File extension (without leading dot)
  public let fileExtension: String?

  /// MIME type of the file, if known
  public let mimeType: String?

  /// Whether the file is hidden
  public let isHidden: Bool

  /// Whether the file is readable
  public let isReadable: Bool

  /// Whether the file is writable
  public let isWritable: Bool

  /// Whether the file is executable
  public let isExecutable: Bool

  /// Resource type
  public let resourceType: FilePathDTO.ResourceType

  /// Additional file system-specific attributes
  public let attributes: [String: String]

  // MARK: - Initialization

  /// Initialize a FileSystemMetadataDTO with specified values
  /// - Parameters:
  ///   - fileSize: Size of the file in bytes
  ///   - creationDate: Creation date as Unix timestamp
  ///   - modificationDate: Last modification date as Unix timestamp
  ///   - accessDate: Last access date as Unix timestamp
  ///   - ownerID: File owner's numeric ID
  ///   - groupID: File group's numeric ID
  ///   - permissions: POSIX permissions mask
  ///   - fileExtension: File extension (without leading dot)
  ///   - mimeType: MIME type of the file, if known
  ///   - isHidden: Whether the file is hidden
  ///   - isReadable: Whether the file is readable
  ///   - isWritable: Whether the file is writable
  ///   - isExecutable: Whether the file is executable
  ///   - resourceType: Resource type
  ///   - attributes: Additional file system-specific attributes
  public init(
    fileSize: UInt64,
    creationDate: UInt64,
    modificationDate: UInt64,
    accessDate: UInt64?=nil,
    ownerID: UInt32?=nil,
    groupID: UInt32?=nil,
    permissions: UInt16?=nil,
    fileExtension: String?=nil,
    mimeType: String?=nil,
    isHidden: Bool,
    isReadable: Bool,
    isWritable: Bool,
    isExecutable: Bool,
    resourceType: FilePathDTO.ResourceType,
    attributes: [String: String]=[:]
  ) {
    self.fileSize=fileSize
    self.creationDate=creationDate
    self.modificationDate=modificationDate
    self.accessDate=accessDate
    self.ownerID=ownerID
    self.groupID=groupID
    self.permissions=permissions
    self.fileExtension=fileExtension
    self.mimeType=mimeType
    self.isHidden=isHidden
    self.isReadable=isReadable
    self.isWritable=isWritable
    self.isExecutable=isExecutable
    self.resourceType=resourceType
    self.attributes=attributes
  }

  /// Create an empty metadata object for a file that doesn't exist or can't be accessed
  /// - Parameter resourceType: The resource type
  /// - Returns: A metadata object with defaults
  public static func empty(resourceType: FilePathDTO.ResourceType) -> FileSystemMetadataDTO {
    FileSystemMetadataDTO(
      fileSize: 0,
      creationDate: 0,
      modificationDate: 0,
      isHidden: false,
      isReadable: false,
      isWritable: false,
      isExecutable: false,
      resourceType: resourceType
    )
  }
}

/// Extension with convenience methods for FileSystemMetadataDTO
extension FileSystemMetadataDTO {
  /// Check if the file exists (has valid dates)
  public var exists: Bool {
    creationDate > 0 || modificationDate > 0
  }

  /// Check if the file is a directory
  public var isDirectory: Bool {
    resourceType == .directory
  }

  /// Check if the file is a regular file
  public var isRegularFile: Bool {
    resourceType == .file
  }

  /// Check if the file is a symbolic link
  public var isSymbolicLink: Bool {
    resourceType == .symbolicLink
  }

  /// Get a human-readable size string
  public var readableSize: String {
    let formatter=ByteCountFormatter()
    formatter.allowedUnits=[.useAll]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(fileSize))
  }

  /// Create a copy with updated permission flags
  /// - Parameters:
  ///   - isReadable: New isReadable value
  ///   - isWritable: New isWritable value
  ///   - isExecutable: New isExecutable value
  /// - Returns: Updated metadata
  public func withPermissions(
    isReadable: Bool?=nil,
    isWritable: Bool?=nil,
    isExecutable: Bool?=nil
  ) -> FileSystemMetadataDTO {
    FileSystemMetadataDTO(
      fileSize: fileSize,
      creationDate: creationDate,
      modificationDate: modificationDate,
      accessDate: accessDate,
      ownerID: ownerID,
      groupID: groupID,
      permissions: permissions,
      fileExtension: fileExtension,
      mimeType: mimeType,
      isHidden: isHidden,
      isReadable: isReadable ?? self.isReadable,
      isWritable: isWritable ?? self.isWritable,
      isExecutable: isExecutable ?? self.isExecutable,
      resourceType: resourceType,
      attributes: attributes
    )
  }
}
