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

    await logger.debug("Checked if file exists at \(path.path): \(exists)", metadata: nil)

    return exists
  }

  /**
   Gets metadata for a file or directory at the specified path.

   - Parameter path: The path to get metadata for
   - Returns: The metadata, or nil if the item doesn't exist
   - Throws: `FileSystemError.readError` if the operation fails for reasons other than non-existence
   */
  public func getMetadata(at path: FilePath) async throws -> FileSystemMetadata? {
    guard !path.path.isEmpty else {
      return nil
    }

    do {
      let url=URL(fileURLWithPath: path.path)
      let resourceValues=try url.resourceValues(forKeys: [
        .isDirectoryKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .creationDateKey,
        .isSymbolicLinkKey,
        .isReadableKey,
        .isWritableKey
      ])

      let isDirectory=resourceValues.isDirectory ?? false
      let size=resourceValues.fileSize ?? 0
      let modificationDate=resourceValues.contentModificationDate ?? Date()
      let creationDate=resourceValues.creationDate ?? Date()
      let isSymbolicLink=resourceValues.isSymbolicLink ?? false

      // Determine the item type
      let itemType: FileSystemItemType=isDirectory ? .directory :
        isSymbolicLink ? .symbolicLink : .file

      let metadata=FileSystemMetadata(
        path: path,
        itemType: itemType,
        size: UInt64(size),
        creationDate: creationDate,
        modificationDate: modificationDate
      )

      await logger.debug("Retrieved metadata for \(path.path)", metadata: nil)

      return metadata
    } catch {
      // If the file doesn't exist, return nil instead of throwing an error
      if
        (error as NSError).domain == NSCocoaErrorDomain &&
        (error as NSError).code == NSFileReadNoSuchFileError
      {
        return nil
      }

      await logger.error(
        "Failed to get metadata for \(path.path): \(error.localizedDescription)",
        metadata: nil
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
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
      await logger.warning("Path does not exist for directory check: \(path.path)", metadata: nil)
      return false
    }

    await logger.debug(
      "Checked if path is directory at \(path.path): \(isDir.boolValue)",
      metadata: nil
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
