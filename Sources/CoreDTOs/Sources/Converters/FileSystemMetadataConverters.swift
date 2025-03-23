import Foundation

/// Extension for converting between Foundation types and FileSystemMetadataDTO
extension FileSystemMetadataDTO {
  /// Create a FileSystemMetadataDTO from Foundation FileManager attributes
  /// - Parameters:
  ///   - attributes: File attributes dictionary from FileManager
  ///   - path: Path to the file or directory
  ///   - resourceType: Resource type, or nil to determine from attributes
  /// - Returns: A FileSystemMetadataDTO
  public static func from(
    attributes: [FileAttributeKey: Any],
    path: String,
    resourceType: FilePathDTO.ResourceType?=nil
  ) -> FileSystemMetadataDTO {
    // Get file size
    let fileSize=(attributes[FileAttributeKey.size] as? NSNumber)?.uint64Value ?? 0

    // Get dates
    let creationDate=(attributes[FileAttributeKey.creationDate] as? Date)?
      .timeIntervalSince1970 ?? 0
    let modificationDate=(attributes[FileAttributeKey.modificationDate] as? Date)?
      .timeIntervalSince1970 ?? 0

    // macOS supports access date
    var accessDate: UInt64?
    if let date=attributes[FileAttributeKey(rawValue: "NSFileAccessDate")] as? Date {
      accessDate=UInt64(date.timeIntervalSince1970)
    }

    // Get owner and group IDs
    let ownerID=(attributes[FileAttributeKey.ownerAccountID] as? NSNumber)?.uint32Value
    let groupID=(attributes[FileAttributeKey.groupOwnerAccountID] as? NSNumber)?.uint32Value

    // Get permissions
    let permissions=(attributes[FileAttributeKey.posixPermissions] as? NSNumber)?.uint16Value

    // Determine if hidden (starts with dot on Unix systems)
    let filename=URL(fileURLWithPath: path).lastPathComponent
    // Use filename-based check only, as isHidden is not a standard FileAttributeKey
    let isHidden=filename.hasPrefix(".")

    // Get type from attributes if not provided
    let type: FilePathDTO.ResourceType=if let providedType=resourceType {
      providedType
    } else if let fileType=attributes[FileAttributeKey.type] as? String {
      switch fileType {
        case FileAttributeType.typeDirectory.rawValue:
          .directory
        case FileAttributeType.typeSymbolicLink.rawValue:
          .symbolicLink
        default:
          .file
      }
    } else {
      .file
    }

    // Get extension from path
    let fileExtension=URL(fileURLWithPath: path).pathExtension
      .isEmpty ? nil : URL(fileURLWithPath: path).pathExtension

    // Check permissions
    let fileManager=FileManager.default
    let isReadable=fileManager.isReadableFile(atPath: path)
    let isWritable=fileManager.isWritableFile(atPath: path)
    let isExecutable=fileManager.isExecutableFile(atPath: path)

    // Determine MIME type
    let mimeType=getMimeType(for: path)

    // Additional attributes
    var additionalAttributes=[String: String]()

    // Add creator and type codes if available (macOS)
    if let creator=attributes[FileAttributeKey.hfsCreatorCode] as? NSNumber {
      additionalAttributes["hfsCreatorCode"]=String(format: "%08X", creator.uint32Value)
    }
    if let type=attributes[FileAttributeKey.hfsTypeCode] as? NSNumber {
      additionalAttributes["hfsTypeCode"]=String(format: "%08X", type.uint32Value)
    }

    return FileSystemMetadataDTO(
      fileSize: fileSize,
      creationDate: UInt64(creationDate),
      modificationDate: UInt64(modificationDate),
      accessDate: accessDate,
      ownerID: ownerID,
      groupID: groupID,
      permissions: permissions,
      fileExtension: fileExtension,
      mimeType: mimeType,
      isHidden: isHidden,
      isReadable: isReadable,
      isWritable: isWritable,
      isExecutable: isExecutable,
      resourceType: type,
      attributes: additionalAttributes
    )
  }

  /// Attempt to determine MIME type based on file extension
  private static func getMimeType(for path: String) -> String? {
    let url=URL(fileURLWithPath: path)
    let ext=url.pathExtension.lowercased()

    let mimeTypes=[
      "html": "text/html",
      "htm": "text/html",
      "css": "text/css",
      "js": "application/javascript",
      "json": "application/json",
      "txt": "text/plain",
      "md": "text/markdown",
      "xml": "application/xml",
      "csv": "text/csv",
      "jpg": "image/jpeg",
      "jpeg": "image/jpeg",
      "png": "image/png",
      "gif": "image/gif",
      "svg": "image/svg+xml",
      "webp": "image/webp",
      "pdf": "application/pdf",
      "doc": "application/msword",
      "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "xls": "application/vnd.ms-excel",
      "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "ppt": "application/vnd.ms-powerpoint",
      "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "zip": "application/zip",
      "tar": "application/x-tar",
      "gz": "application/gzip",
      "mp3": "audio/mpeg",
      "mp4": "video/mp4",
      "webm": "video/webm",
      "mov": "video/quicktime",
      "avi": "video/x-msvideo",
      "swift": "text/x-swift",
      "c": "text/x-c",
      "cpp": "text/x-c++",
      "h": "text/x-c",
      "hpp": "text/x-c++",
      "py": "text/x-python",
      "java": "text/x-java",
      "rb": "text/x-ruby",
      "sh": "application/x-sh"
    ]

    return mimeTypes[ext]
  }

  /// Convert to FileManager attributes dictionary
  /// - Returns: Dictionary of file attributes suitable for FileManager
  public func toFileAttributes() -> [FileAttributeKey: Any] {
    var attributes=[FileAttributeKey: Any]()

    // Set dates
    if creationDate > 0 {
      attributes[
        FileAttributeKey
          .creationDate
      ]=Date(timeIntervalSince1970: TimeInterval(creationDate))
    }
    if modificationDate > 0 {
      attributes[
        FileAttributeKey
          .modificationDate
      ]=Date(timeIntervalSince1970: TimeInterval(modificationDate))
    }

    // Set permissions if available
    if let permissions {
      attributes[FileAttributeKey.posixPermissions]=NSNumber(value: permissions)
    }

    // Set owner/group if available
    if let ownerID {
      attributes[FileAttributeKey.ownerAccountID]=NSNumber(value: ownerID)
    }
    if let groupID {
      attributes[FileAttributeKey.groupOwnerAccountID]=NSNumber(value: groupID)
    }

    // Parse HFS codes if present in additional attributes
    if
      let hfsCreator=self.attributes["hfsCreatorCode"],
      let creatorCode=UInt32(hfsCreator, radix: 16)
    {
      attributes[FileAttributeKey.hfsCreatorCode]=NSNumber(value: creatorCode)
    }

    if
      let hfsType=self.attributes["hfsTypeCode"],
      let typeCode=UInt32(hfsType, radix: 16)
    {
      attributes[FileAttributeKey.hfsTypeCode]=NSNumber(value: typeCode)
    }

    return attributes
  }
}
