import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # File System Service Implementation

 This class provides the implementation for the FileSystemServiceProtocol, handling
 all file system operations in a thread-safe and efficient manner.

 The implementation is divided into logical extensions to maintain code organisation:
 - Core Operations: Basic file existence and metadata operations
 - Directory Operations: Creating, listing, and managing directories
 - File Operations: Reading, writing, copying, and deleting files
 - Path Operations: Path manipulation and validation
 - Streaming Operations: Efficient handling of large files
 - Temporary File Operations: Working with temporary files and directories
 - Extended Attribute Operations: Setting and retrieving extended attributes

 All operations are properly isolated through Swift's actor system to ensure thread safety.
 */
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor FileSystemServiceImpl: FileSystemServiceProtocol {

  /// The underlying file manager isolated within this actor
  let fileManager: FileManager

  /// Quality of service for background operations
  let operationQueueQoS: QualityOfService

  /// Logger for recording operations and errors
  let logger: any LoggingProtocol

  /**
   Initialises a new FileSystemServiceImpl instance.

   - Parameters:
      - fileManager: The FileManager to use for file operations (will be isolated within the actor)
      - operationQueueQoS: The quality of service for background operations
      - logger: The logger to use for recording operations
   */
  public init(
    fileManager: FileManager,
    operationQueueQoS: QualityOfService = .utility,
    logger: any LoggingProtocol
  ) {
    self.fileManager=fileManager
    self.operationQueueQoS=operationQueueQoS
    self.logger=logger
  }

  // MARK: - Core Operation Implementations

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The path to check
   - Returns: Boolean indicating whether the file exists
   */
  public func fileExists(at path: FilePath) async -> Bool {
    fileManager.fileExists(atPath: path.path)
  }

  /**
   Retrieves metadata for the file or directory at the specified path.

   - Parameter path: Path to the file or directory
   - Returns: FileSystemMetadata if the path exists, nil otherwise
   - Throws: FileSystemError if the metadata cannot be accessed
   */
  public func getMetadata(at path: FilePath) async throws -> FileSystemMetadata? {
    await logger.debug(
      "Getting metadata for \(path.path)",
      metadata: nil,
      source: "FileSystemService"
    )

    do {
      // Check if file exists
      guard fileManager.fileExists(atPath: path.path) else {
        return nil
      }

      // Get file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path.path)

      // Extract common attributes
      let size=attributes[.size] as? UInt64 ?? 0
      let creationDate=attributes[.creationDate] as? Date
      let modificationDate=attributes[.modificationDate] as? Date
      let fileType=attributes[.type] as? String

      // Determine file type
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let itemType: FileSystemItemType=isDirectory ? .directory : .file

      // Create and return the metadata
      return FileSystemMetadata(
        path: path,
        itemType: itemType,
        size: size,
        creationDate: creationDate,
        modificationDate: modificationDate
      )
    } catch {
      await logger.error(
        "Failed to get metadata for \(path.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )

      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Could not get file attributes: \(error.localizedDescription)"
      )
    }
  }

  /**
   Checks if the path points to a directory.

   - Parameter path: The path to check
   - Returns: True if the path is a directory, false otherwise
   - Throws: FileSystemError if the path does not exist or can't be accessed
   */
  public func isDirectory(at path: FilePath) async throws -> Bool {
    await logger.debug(
      "Checking if \(path.path) is a directory",
      metadata: nil,
      source: "FileSystemService"
    )

    // Check if the path exists at all
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

    if !exists {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    return isDir.boolValue
  }

  /**
   Lists contents of a directory.

   - Parameters:
      - directoryPath: Path to the directory to list
      - includeHidden: Whether to include hidden files in the listing
   - Returns: Array of file paths within the directory
   - Throws: FileSystemError if the directory cannot be read or does not exist
   */
  public func listDirectory(
    at directoryPath: FilePath,
    includeHidden: Bool=false
  ) async throws -> [FilePath] {
    await logger.debug(
      "Listing directory at \(directoryPath.path)",
      metadata: nil,
      source: "FileSystemService"
    )

    // Check if the path is a directory
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: directoryPath.path, isDirectory: &isDir)

    if !exists {
      await logger.warning(
        "Directory does not exist: \(directoryPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: directoryPath.path)
    }

    if !isDir.boolValue {
      await logger.warning(
        "Path is not a directory: \(directoryPath.path)",
        metadata: nil,
        source: "FileSystemService"
      )
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: directoryPath.path,
        reason: "Path is not a directory: \(directoryPath.path)"
      )
    }

    do {
      let contents=try fileManager.contentsOfDirectory(atPath: directoryPath.path)

      let filteredContents=contents.filter { name in
        if !includeHidden && name.hasPrefix(".") {
          return false
        }
        return true
      }

      // Convert to FilePath objects
      return filteredContents.map { name in
        let fullPath=directoryPath.path + "/" + name
        return FilePath(path: fullPath)
      }
    } catch {
      await logger.error(
        "Failed to list directory at \(directoryPath.path): \(error.localizedDescription)",
        metadata: nil,
        source: "FileSystemService"
      )

      throw FileSystemInterfaces.FileSystemError.readError(
        path: directoryPath.path,
        reason: "Could not list directory contents: \(error.localizedDescription)"
      )
    }
  }

  /**
   Lists files recursively within a directory.

   - Parameters:
      - directoryPath: Path to the directory to list
      - includeHidden: Whether to include hidden files in the listing
   - Returns: Array of file paths within the directory and its subdirectories
   - Throws: FileSystemError if the directory cannot be read or does not exist
   */
  public func listFilesRecursively(
    at directoryPath: FilePath,
    includeHidden: Bool=false
  ) async throws -> [FilePath] {
    // Get all items in the directory
    let items=try await listDirectory(at: directoryPath, includeHidden: includeHidden)

    var allFiles=[FilePath]()

    // Process each item
    for item in items {
      if try await isDirectory(at: item) {
        // If it's a directory, recursively list its contents
        let subItems=try await listFilesRecursively(at: item, includeHidden: includeHidden)
        allFiles.append(contentsOf: subItems)
      } else {
        // If it's a file, add it to the results
        allFiles.append(item)
      }
    }

    return allFiles
  }
}

// MARK: - Support for null logger when none is provided

/// A simple no-op logger implementation for when no logger is provided
private struct NullLogger: LoggingInterfaces.LoggingProtocol {
  // Add loggingActor property required by LoggingProtocol
  var loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  // Core method required by CoreLoggingProtocol
  func logMessage(_: LoggingTypes.LogLevel, _: String, context _: LoggingTypes.LogContext) async {
    // Empty implementation for this stub
  }

  // Implement all required methods with proper parameter types
  func debug(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func info(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func notice(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func warning(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func error(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func critical(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func trace(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}

  // Deprecated method kept for backwards compatibility
  func setContext(_: Any) {}
}
