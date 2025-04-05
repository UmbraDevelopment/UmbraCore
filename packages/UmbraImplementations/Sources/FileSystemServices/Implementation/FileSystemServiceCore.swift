import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import UmbraLogging

/**
 # File System Service Implementation

 A comprehensive implementation of the FileSystemServiceProtocol that provides
 secure and reliable file system operations with proper error handling.

 This is the core component of the file system service, which handles the
 initialization and basic operations. Specific functionality is provided
 through extensions in separate files.
 */
@preconcurrency
public actor FileSystemServiceImpl: FileSystemServiceProtocol {
  /// The underlying file manager
  let fileManager: FileManager

  /// The QoS class for background operations
  let operationQueueQoS: DispatchQoS.QoSClass

  /// Default buffer size for streaming operations (default: 64KB)
  let defaultBufferSize: Int

  /// Security options for file operations
  let securityOptions: SecurityOptions

  /// Whether to run operations in the background
  let runInBackground: Bool

  /// The logger instance for recording file operations
  let logger: any LoggingInterfaces.LoggingProtocol

  /// The operation queue for background operations
  let operationQueue: DispatchQueue

  /**
   Initialises a new FileSystemServiceImpl with detailed configuration options.

   - Parameters:
      - fileManager: The FileManager to use for operations (defaults to .default)
      - operationQueueQoS: QoS class for background operations (defaults to .utility)
      - defaultBufferSize: Default buffer size for streaming operations (defaults to 65536 bytes)
      - securityOptions: Security-related settings for file operations (defaults to standard settings)
      - runInBackground: Whether to run operations in the background (defaults to false)
      - logger: Optional logger for recording file operations
   */
  public init(
    fileManager: FileManager = .default,
    operationQueueQoS: DispatchQoS.QoSClass = .utility,
    defaultBufferSize: Int=65536,
    securityOptions: SecurityOptions=SecurityOptions(
      preservePermissions: true,
      enforceSandboxing: true,
      allowSymlinks: true
    ),
    runInBackground: Bool=false,
    logger: (any LoggingInterfaces.LoggingProtocol)?=nil
  ) {
    self.fileManager=fileManager
    self.operationQueueQoS=operationQueueQoS
    self.defaultBufferSize=defaultBufferSize
    self.securityOptions=securityOptions
    self.runInBackground=runInBackground
    operationQueue=DispatchQueue(
      label: "com.umbra.filesystemservice",
      qos: DispatchQoS(qosClass: operationQueueQoS, relativePriority: 0),
      attributes: .concurrent
    )
    // Use a NullLogger if no logger is provided
    self.logger=logger ?? NullLogger()
  }

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The path to check
   - Returns: Boolean indicating whether the file exists
   */
  public func fileExists(at path: FilePath) async -> Bool {
    guard !path.path.isEmpty else {
      return false
    }

    let exists=fileManager.fileExists(atPath: path.path)

    await logger.debug(
      "Checked file existence",
      context: FileSystemLogContext(
        operation: "fileExists",
        path: path.path,
        source: "FileSystemService"
      ).withUpdatedMetadata(
        LogMetadataDTOCollection().withPublic(key: "exists", value: String(exists))
      )
    )

    return exists
  }

  /**
   Gets metadata for a file or directory at the specified path.

   If the path doesn't exist, returns nil instead of throwing an error.
   This is useful for checking existence without causing an error path.

   - Parameter path: The file path to check
   - Returns: File metadata or nil if the path doesn't exist
   - Throws: `FileSystemError.readError` if the operation fails for reasons other than non-existence
   */
  public func getFileMetadata(
    at path: FilePath,
    options: FileMetadataOptions?
  ) async throws -> FileMetadata {
    guard !path.path.isEmpty else {
      throw FileSystemError.invalidPath("Path cannot be empty")
    }

    do {
      let url=URL(fileURLWithPath: path.path)

      // Build a set of resource keys to fetch
      var resourceKeys: Set<URLResourceKey>=[
        .isDirectoryKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .creationDateKey,
        .isSymbolicLinkKey,
        .isReadableKey,
        .isWritableKey,
        .fileOwnerAccountIDKey,
        .fileGroupOwnerAccountIDKey,
        .filePosixPermissionsKey
      ]

      // Add any additional keys requested by the caller
      if let options {
        for key in options.resourceKeys {
          if let urlKey=key.toURLResourceKey() {
            resourceKeys.insert(urlKey)
          }
        }
      }

      // Fetch resource values from the URL
      let urlResourceValues=try url.resourceValues(forKeys: resourceKeys)

      // Convert URLResourceValues to our safe dictionary type
      var safeResourceValues=[FileResourceKey: SafeAttributeValue]()

      // Convert each resource value to our SafeAttributeValue type
      for key in resourceKeys {
        if
          let value=urlResourceValues.allValues[key],
          let safeValue=SafeAttributeValue(from: value)
        {
          if let fileKey=FileResourceKey(fromURLResourceKey: key) {
            safeResourceValues[fileKey]=safeValue
          }
        }
      }

      // Extract basic file attributes
      let isDirectory=urlResourceValues.isDirectory ?? false
      let size=urlResourceValues.fileSize ?? 0
      let modificationDate=urlResourceValues.contentModificationDate ?? Date()
      let creationDate=urlResourceValues.creationDate ?? Date()
      let ownerID=urlResourceValues.fileOwnerAccountID.flatMap(UInt.init) ?? 0
      let groupID=urlResourceValues.fileGroupOwnerAccountID.flatMap(UInt.init) ?? 0
      let permissions=urlResourceValues.filePosixPermissions ?? 0

      // Create file attributes
      let fileAttributes=FileAttributes(
        size: UInt64(size),
        creationDate: creationDate,
        modificationDate: modificationDate,
        accessDate: nil, // Not available through URLResourceValues
        ownerID: ownerID,
        groupID: groupID,
        permissions: UInt16(permissions),
        fileType: nil, // Could populate from UTI if needed
        creator: nil, // macOS specific, not usually needed
        flags: 0, // Would need to be extracted separately
        safeExtendedAttributes: [:] // Would need separate call to get extended attributes
      )

      // Determine if the file exists
      let exists=true // If we got this far, the file exists

      // Create and return the file metadata
      let metadata=FileMetadata(
        path: path,
        attributes: fileAttributes,
        safeResourceValues: safeResourceValues,
        exists: exists
      )

      await logger.debug(
        "Retrieved metadata",
        context: FileSystemLogContext(
          operation: "getMetadata",
          path: path.path,
          source: "FileSystemService"
        )
      )

      return metadata
    } catch {
      // If the file doesn't exist, create a metadata object with exists=false
      if
        (error as NSError).domain == NSCocoaErrorDomain &&
        (error as NSError).code == NSFileReadNoSuchFileError
      {

        // Create minimal metadata for non-existent file
        let emptyAttributes=FileAttributes(
          size: 0,
          creationDate: Date(),
          modificationDate: Date(),
          accessDate: nil,
          ownerID: 0,
          groupID: 0,
          permissions: 0,
          safeExtendedAttributes: [:]
        )

        return FileMetadata(
          path: path,
          attributes: emptyAttributes,
          safeResourceValues: [:],
          exists: false
        )
      }

      await logger.error(
        "Failed to get metadata",
        context: FileSystemLogContext(
          operation: "getMetadata",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
      )

      throw FileSystemError.readError(
        path: path.path,
        reason: "Failed to get metadata: \(error.localizedDescription)"
      )
    }
  }

  /**
   Checks if a path points to a directory.

   - Parameter path: The path to check
   - Returns: Whether the path is a directory
   - Throws: `FileSystemError.readError` if the operation fails
   */
  public func isDirectory(at path: FilePath) async throws -> Bool {
    guard !path.path.isEmpty else {
      return false
    }

    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

    if !exists {
      await logger.warning(
        "Path does not exist for directory check",
        context: FileSystemLogContext(
          operation: "isDirectory",
          path: path.path,
          source: "FileSystemService"
        )
      )
      return false
    }

    await logger.debug(
      "Checked if path is directory",
      context: FileSystemLogContext(
        operation: "isDirectory",
        path: path.path,
        source: "FileSystemService"
      ).withUpdatedMetadata(
        LogMetadataDTOCollection().withPublic(key: "isDirectory", value: String(isDir.boolValue))
      )
    )

    return isDir.boolValue
  }
}

/**
 A no-op logger implementation that conforms to LoggingProtocol.
 Used as a fallback when no logger is provided.
 */
private struct NullLogger: LoggingInterfaces.LoggingProtocol {
  func debug(_: String, metadata _: LoggingTypes.LogMetadata?) async {
    // No-op implementation
  }

  func info(_: String, metadata _: LoggingTypes.LogMetadata?) async {
    // No-op implementation
  }

  func warning(_: String, metadata _: LoggingTypes.LogMetadata?) async {
    // No-op implementation
  }

  func error(_: String, metadata _: LoggingTypes.LogMetadata?) async {
    // No-op implementation
  }
}
