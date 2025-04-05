import Darwin.C
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
      - logger: The logger to use for recording operations and errors
   */
  public init(
    fileManager: FileManager=FileManager.default,
    operationQueueQoS: QualityOfService = .default,
    logger: (any LoggingProtocol)?=nil
  ) {
    self.fileManager=fileManager
    self.operationQueueQoS=operationQueueQoS
    self.logger=logger ?? NoLogLogger()
  }

  // MARK: - Helper Methods

  /**
   Get the metadata for a file or directory.

   This method is used internally to get file metadata without throwing errors
   for files that don't exist, and is primarily used by the exists check methods.

   - Parameter path: The path to check
   - Returns: Metadata for the file/directory, or nil if it doesn't exist
   */
  func getBasicFileMetadata(at path: FilePath) async throws -> FileSystemMetadata? {
    guard !path.path.isEmpty else {
      return nil
    }

    do {
      let attributes=try fileManager.attributesOfItem(atPath: path.path)
      let size=attributes[.size] as? UInt64 ?? 0
      let creationDate=attributes[.creationDate] as? Date
      let modificationDate=attributes[.modificationDate] as? Date
      let fileType=attributes[.type] as? String

      // Determine file type - use the FileSystemItemType from FileSystemTypes to avoid ambiguity
      let isDirectory=fileType == FileAttributeType.typeDirectory.rawValue
      let itemType: FileSystemTypes.FileSystemItemType=isDirectory ? .directory : .file

      // Create and return the metadata
      return FileSystemMetadata(
        path: path,
        itemType: itemType,
        size: size,
        creationDate: creationDate,
        modificationDate: modificationDate
      )
    } catch {
      // If the file doesn't exist, return nil instead of throwing an error
      if
        (error as NSError).domain == NSCocoaErrorDomain &&
        (error as NSError).code == NSFileReadNoSuchFileError
      {
        return nil
      }

      // Otherwise, propagate the error
      await logger.error(
        "Failed to get metadata for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "stat",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
      )
      throw error
    }
  }

  /**
   Implements the getFileMetadata method required by the FileSystemServiceProtocol.

   - Parameters:
     - path: The path to the file or directory
     - options: Optional metadata options to control which metadata is retrieved
   - Returns: A FileMetadata object containing the requested metadata
   - Throws: FileSystemError if the metadata cannot be retrieved
   */
  public func getFileMetadata(
    at path: FilePath,
    options: FileMetadataOptions?
  ) async throws -> FileMetadata {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let url=URL(fileURLWithPath: path.path)

      // Build a set of resource keys to fetch
      var resourceKeys: Set<URLResourceKey>=[
        .contentModificationDateKey,
        .creationDateKey,
        .fileResourceTypeKey,
        .totalFileSizeKey,
        .isHiddenKey,
        .isDirectoryKey,
        .isReadableKey,
        .isWritableKey
      ]

      // Add any additional keys requested by the caller
      if let options {
        for key in options.resourceKeys {
          if let urlKey=key.toURLResourceKey() {
            resourceKeys.insert(urlKey)
          }
        }
      }

      // Check if the file exists
      var exists=true
      if !fileManager.fileExists(atPath: path.path) {
        exists=false

        // Create a minimal metadata for non-existent files
        let emptyAttributes=FileAttributes(
          size: 0,
          creationDate: Date(),
          modificationDate: Date(),
          accessDate: nil,
          ownerID: 0,
          groupID: 0,
          permissions: 0,
          fileType: nil,
          creator: nil,
          flags: 0,
          safeExtendedAttributes: [:]
        )

        return FileMetadata(
          path: path,
          attributes: emptyAttributes,
          safeResourceValues: [:],
          exists: false
        )
      }

      // Fetch file attributes
      let attributes=try fileManager.attributesOfItem(atPath: path.path)

      // Fetch URL resource values
      let urlResourceValues=try url.resourceValues(forKeys: resourceKeys)

      // Convert attributes to our FileAttributes type
      let fileAttributes=FileAttributes(
        size: attributes[.size] as? UInt64 ?? 0,
        creationDate: attributes[.creationDate] as? Date ?? Date(),
        modificationDate: attributes[.modificationDate] as? Date ?? Date(),
        accessDate: nil, // Not available in attributesOfItem
        ownerID: attributes[.ownerAccountID] as? UInt ?? 0,
        groupID: attributes[.groupOwnerAccountID] as? UInt ?? 0,
        permissions: attributes[.posixPermissions] as? UInt16 ?? 0,
        fileType: attributes[.type] as? String,
        creator: nil, // Not commonly used
        flags: 0, // Not commonly used
        safeExtendedAttributes: [:] // Will populate below if needed
      )

      // Convert URL resource values to our safe dictionary type
      var safeResourceValues=[FileResourceKey: SafeAttributeValue]()

      // Convert each resource value
      for key in resourceKeys {
        if
          let value=urlResourceValues.allValues[key],
          let safeValue=SafeAttributeValue(from: value),
          let fileKey=FileResourceKey(fromURLResourceKey: key)
        {
          safeResourceValues[fileKey]=safeValue
        }
      }

      // Create and return the file metadata
      let metadata=FileMetadata(
        path: path,
        attributes: fileAttributes,
        safeResourceValues: safeResourceValues,
        exists: exists
      )

      await logger.debug(
        "Retrieved metadata for \(path.path)",
        context: FileSystemLogContext(
          operation: "stat",
          path: path.path,
          source: "FileSystemService"
        )
      )

      return metadata
    } catch {
      await logger.error(
        "Failed to get metadata for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "stat",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
      )

      if let fsError=error as? FileSystemInterfaces.FileSystemError {
        throw fsError
      } else {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path.path,
          reason: "Failed to get metadata: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Gets an extended attribute from a file.

   - Parameters:
     - path: The file to query
     - attributeName: The name of the extended attribute
   - Returns: The attribute value as a SafeAttributeValue
   - Throws: FileSystemError if the attribute cannot be retrieved
   */
  public func getExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws -> SafeAttributeValue {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    do {
      // Get the attribute data using the C API
      var dataSize=0
      let result=try url.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in
        // First get the size of the attribute
        dataSize=getxattr(fileSystemPath, attributeName, nil, 0, 0, 0)
        if dataSize == -1 {
          throw FileSystemInterfaces.FileSystemError.readError(
            path: path.path,
            reason: "Failed to get extended attribute size: \(String(cString: strerror(errno)))"
          )
        }

        // Now allocate a buffer and read the attribute data
        var data=Data(count: dataSize)
        let readResult=data.withUnsafeMutableBytes { buffer in
          getxattr(fileSystemPath, attributeName, buffer.baseAddress, dataSize, 0, 0)
        }

        if readResult == -1 {
          throw FileSystemInterfaces.FileSystemError.readError(
            path: path.path,
            reason: "Failed to read extended attribute: \(String(cString: strerror(errno)))"
          )
        }

        return data
      }

      // Try to interpret the data as various types
      // First try UTF-8 string
      if let string=String(data: result, encoding: .utf8) {
        return .string(string)
      }

      // If not a string, return as raw data
      return .data(result)
    } catch {
      await logger.error(
        "Failed to get extended attribute \(attributeName) for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "getxattr",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
      )

      if let fsError=error as? FileSystemInterfaces.FileSystemError {
        throw fsError
      } else {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path.path,
          reason: "Failed to get extended attribute: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Sets an extended attribute on a file.

   - Parameters:
     - path: The file to modify
     - attributeName: The name of the extended attribute
     - attributeValue: The value to set
   - Throws: FileSystemError if the attribute cannot be set
   */
  public func setExtendedAttribute(
    at path: FilePath,
    name attributeName: String,
    value attributeValue: SafeAttributeValue
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)

    // Convert the SafeAttributeValue to Data
    guard let data=convertSafeAttributeToData(attributeValue) else {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Cannot convert attribute value to data"
      )
    }

    do {
      // Set the attribute using the C API
      try url.withUnsafeFileSystemRepresentation { fileSystemPath in
        let result=setxattr(
          fileSystemPath,
          attributeName,
          [UInt8](data),
          data.count,
          0,
          0
        )

        if result != 0 {
          throw FileSystemInterfaces.FileSystemError.writeError(
            path: path.path,
            reason: "Failed to set extended attribute: \(String(cString: strerror(errno)))"
          )
        }
      }

      await logger.debug(
        "Set extended attribute \(attributeName) for \(path.path)",
        context: FileSystemLogContext(
          operation: "setxattr",
          path: path.path,
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to set extended attribute \(attributeName) for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "setxattr",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
      )

      if let fsError=error as? FileSystemInterfaces.FileSystemError {
        throw fsError
      } else {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: path.path,
          reason: "Failed to set extended attribute: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Converts a SafeAttributeValue to Data for use with extended attributes.

   - Parameter value: The SafeAttributeValue to convert
   - Returns: Data representation if possible, nil otherwise
   */
  private func convertSafeAttributeToData(_ value: SafeAttributeValue) -> Data? {
    switch value {
      case let .string(strValue):
        return strValue.data(using: .utf8)
      case let .int(intValue):
        return withUnsafeBytes(of: intValue) { Data($0) }
      case let .uint(uintValue):
        return withUnsafeBytes(of: uintValue) { Data($0) }
      case let .int64(int64Value):
        return withUnsafeBytes(of: int64Value) { Data($0) }
      case let .uint64(uint64Value):
        return withUnsafeBytes(of: uint64Value) { Data($0) }
      case let .bool(boolValue):
        return withUnsafeBytes(of: boolValue) { Data($0) }
      case let .date(dateValue):
        return withUnsafeBytes(of: dateValue.timeIntervalSince1970) { Data($0) }
      case let .double(doubleValue):
        return withUnsafeBytes(of: doubleValue) { Data($0) }
      case let .data(dataValue):
        return dataValue
      case let .url(urlValue):
        return urlValue.absoluteString.data(using: .utf8)
      case .array, .dictionary:
        // These would need more complex serialization (e.g., JSON)
        do {
          let encoder=JSONEncoder()
          let data=try encoder.encode(String(describing: value))
          return data
        } catch {
          return nil
        }
    }
  }

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
      "Retrieving metadata for \(path.path)",
      context: FileSystemLogContext(
        operation: "stat",
        path: path.path,
        source: "FileSystemService"
      )
    )

    do {
      // Check if file exists
      guard fileManager.fileExists(atPath: path.path) else {
        throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
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
      let itemType: FileSystemTypes.FileSystemItemType=isDirectory ? .directory : .file

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
        context: FileSystemLogContext(
          operation: "stat",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
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
      context: FileSystemLogContext(
        operation: "isDirectory",
        path: path.path,
        source: "FileSystemService"
      )
    )

    // Check if the path exists at all
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.path, isDirectory: &isDir)

    if !exists {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    if !isDir.boolValue {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "directory",
        actual: "file"
      )
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
      "Listing directory \(directoryPath.path)",
      context: FileSystemLogContext(
        operation: "listDirectory",
        path: directoryPath.path,
        source: "FileSystemService"
      )
    )

    // Check if the path is a directory
    var isDir: ObjCBool=false
    let exists=fileManager.fileExists(atPath: directoryPath.path, isDirectory: &isDir)

    if !exists {
      await logger.warning(
        "Directory \(directoryPath.path) does not exist",
        context: FileSystemLogContext(
          operation: "listDirectory",
          path: directoryPath.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPublic(key: "reason", value: "Directory does not exist")
        )
      )
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: directoryPath.path)
    }

    if !isDir.boolValue {
      await logger.warning(
        "\(directoryPath.path) is not a directory",
        context: FileSystemLogContext(
          operation: "listDirectory",
          path: directoryPath.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPublic(key: "reason", value: "Path is not a directory")
        )
      )
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: directoryPath.path,
        expected: "directory",
        actual: "file"
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
        "Failed to list directory \(directoryPath.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "listDirectory",
          path: directoryPath.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
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

  /**
   Reads a file and returns its contents as Data.

   - Parameter path: The path to the file to read
   - Returns: The file contents as Data
   - Throws: FileSystemError if the file cannot be read
   */
  public func readFile(at path: FilePath) async throws -> Data {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let data=try Data(contentsOf: URL(fileURLWithPath: path.path))

      await logger.debug(
        "Read file \(path.path)",
        context: FileSystemLogContext(
          operation: "readFile",
          path: path.path,
          source: "FileSystemService"
        ).withFileSize(Int64(data.count))
      )

      return data
    } catch {
      await logger.error(
        "Failed to read file \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "readFile",
          path: path.path,
          source: "FileSystemService"
        ).withUpdatedMetadata(
          LogMetadataDTOCollection().withPrivate(key: "error", value: error.localizedDescription)
        )
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Implements directoryExists method required by the protocol.

   - Parameter path: The path to check
   - Returns: True if the path exists and is a directory
   - Throws: FileSystemError if the check fails
   */
  public func directoryExists(at path: FilePath) async throws -> Bool {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    var isDirectory: ObjCBool=false
    let exists=fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)

    if !exists {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    if !isDirectory.boolValue {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "directory",
        actual: "file"
      )
    }

    return isDirectory.boolValue
  }

  /**
   Lists directory contents recursively.

   - Parameters:
     - path: The directory path to list
     - includeHidden: Whether to include hidden files
   - Returns: Array of file paths
   - Throws: FileSystemError if the directory cannot be read
   */
  public func listDirectoryRecursive(
    at path: FilePath,
    includeHidden: Bool
  ) async throws -> [FilePath] {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let url=URL(fileURLWithPath: path.path)
      let contents=try fileManager.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: includeHidden ? [] : [.skipsHiddenFiles]
      )

      var results: [FilePath]=[]

      for fileURL in contents {
        let relativePath=fileURL.path.replacingOccurrences(of: url.path, with: "")
        let filePath=FilePath(
          path: relativePath
            .hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        )
        results.append(filePath)

        // If it's a directory, recursively list its contents
        let resourceValues=try fileURL.resourceValues(forKeys: [.isDirectoryKey])
        if let isDirectory=resourceValues.isDirectory, isDirectory {
          let subpaths=try await listDirectoryRecursive(
            at: FilePath(path: fileURL.path),
            includeHidden: includeHidden
          )

          for subpath in subpaths {
            let combinedPath=FilePath(path: "\(relativePath)/\(subpath.path)")
            results.append(combinedPath)
          }
        }
      }

      return results
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to list directory: \(error.localizedDescription)"
      )
    }
  }

  /**
   Creates a file with the given data.

   - Parameters:
     - path: The path to create the file at
     - data: The data to write to the file
     - overwrite: Whether to overwrite an existing file
   - Throws: FileSystemError if the file cannot be created
   */
  public func createFile(
    at path: FilePath,
    data: Data,
    overwrite: Bool
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    if !overwrite && fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
    }

    do {
      try data.write(to: URL(fileURLWithPath: path.path))

      await logger.debug(
        "Created file \(path.path)",
        context: FileSystemLogContext(
          operation: "createFile",
          path: path.path,
          source: "FileSystemService"
        ).withFileSize(Int64(data.count))
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to create file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Updates an existing file with new data.

   - Parameters:
     - path: The path of the file to update
     - data: The new data to write
   - Throws: FileSystemError if the file cannot be updated
   */
  public func updateFile(
    at path: FilePath,
    data: Data
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    do {
      try data.write(to: URL(fileURLWithPath: path.path))

      await logger.debug(
        "Updated file \(path.path)",
        context: FileSystemLogContext(
          operation: "updateFile",
          path: path.path,
          source: "FileSystemService"
        ).withFileSize(Int64(data.count))
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to update file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Deletes a file.

   - Parameters:
     - path: The path of the file to delete
     - secure: Whether to use secure deletion
   - Throws: FileSystemError if the file cannot be deleted
   */
  public func deleteFile(
    at path: FilePath,
    secure: Bool
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    // Check if it's a file
    var isDirectory: ObjCBool=false
    if !fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    if isDirectory.boolValue {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "file",
        actual: "directory"
      )
    }

    do {
      let fileSize = try fileManager.attributesOfItem(atPath: path.path)[.size] as? UInt64 ?? 0
      
      if secure {
        // Secure deletion: overwrite with random data before deleting
        if fileSize > 0 {
          var randomData=Data(count: Int(fileSize))
          _=randomData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, bytes.baseAddress!)
          }
          try randomData.write(to: URL(fileURLWithPath: path.path))
        }
      }

      try fileManager.removeItem(atPath: path.path)

      await logger.debug(
        "Deleted file \(path.path)",
        context: FileSystemLogContext(
          operation: "deleteFile",
          path: path.path,
          source: "FileSystemService"
        ).withFileSize(Int64(fileSize))
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: "Failed to delete file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Deletes a directory.

   - Parameters:
     - path: The path of the directory to delete
     - secure: Whether to use secure deletion for files in the directory
   - Throws: FileSystemError if the directory cannot be deleted
   */
  public func deleteDirectory(
    at path: FilePath,
    secure: Bool
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    // Check if it's a directory
    var isDirectory: ObjCBool=false
    if !fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    if !isDirectory.boolValue {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "directory",
        actual: "file"
      )
    }

    do {
      if secure {
        // For secure deletion, first delete each file securely
        let contents=try fileManager.contentsOfDirectory(atPath: path.path)
        for item in contents {
          let itemPath=FilePath(path: "\(path.path)/\(item)")
          var isItemDirectory: ObjCBool=false
          if fileManager.fileExists(atPath: itemPath.path, isDirectory: &isItemDirectory) {
            if isItemDirectory.boolValue {
              try await deleteDirectory(at: itemPath, secure: true)
            } else {
              try await deleteFile(at: itemPath, secure: true)
            }
          }
        }
      }

      try fileManager.removeItem(atPath: path.path)

      await logger.debug(
        "Deleted directory \(path.path)",
        context: FileSystemLogContext(
          operation: "deleteDirectory",
          path: path.path,
          source: "FileSystemService"
        )
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: "Failed to delete directory: \(error.localizedDescription)"
      )
    }
  }

  /**
   Copies an item (file or directory).

   - Parameters:
     - sourcePath: The source path
     - destinationPath: The destination path
     - overwrite: Whether to overwrite existing files
   - Throws: FileSystemError if the copy operation fails
   */
  public func copyItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool
  ) async throws {
    guard !sourcePath.path.isEmpty && !destinationPath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path.isEmpty ? "source" : "destination",
        reason: "Empty path provided"
      )
    }

    if !fileManager.fileExists(atPath: sourcePath.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    if fileManager.fileExists(atPath: destinationPath.path) && !overwrite {
      throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(
        path: destinationPath.path
      )
    }

    do {
      if fileManager.fileExists(atPath: destinationPath.path) {
        try fileManager.removeItem(atPath: destinationPath.path)
      }

      try fileManager.copyItem(
        atPath: sourcePath.path,
        toPath: destinationPath.path
      )

      await logger.debug(
        "Copied item from \(sourcePath.path) to \(destinationPath.path)",
        context: FileSystemLogContext(
          operation: "copyItem",
          path: destinationPath.path,
          source: "FileSystemService"
        )
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.copyError(
        source: sourcePath.path,
        destination: destinationPath.path,
        reason: "Failed to copy item: \(error.localizedDescription)"
      )
    }
  }

  /**
   Converts a FilePath to a URL.

   - Parameter path: The path to convert
   - Returns: The equivalent URL
   - Throws: FileSystemError if the conversion fails
   */
  public func pathToURL(_ path: FilePath) async throws -> URL {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    return URL(fileURLWithPath: path.path)
  }

  /**
   Removes an extended attribute from a file.

   - Parameters:
     - path: The file path
     - attributeName: The name of the attribute to remove
   - Throws: FileSystemError if the attribute cannot be removed
   */
  public func removeExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    do {
      guard let fileSystemPath=(path.path as NSString).utf8String else {
        throw FileSystemInterfaces.FileSystemError.invalidPath(
          path: path.path,
          reason: "Could not convert path to C string"
        )
      }

      let result=removexattr(fileSystemPath, attributeName, 0)
      if result != 0 {
        throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
          path: path.path,
          attribute: attributeName,
          operation: "remove",
          reason: "Failed to remove attribute: \(String(cString: strerror(errno)))"
        )
      }

      await logger.debug(
        "Removed extended attribute \(attributeName) from \(path.path)",
        context: FileSystemLogContext(
          operation: "removexattr",
          path: path.path,
          source: "FileSystemService"
        )
      )
    } catch let fsError as FileSystemInterfaces.FileSystemError {
      throw fsError
    } catch {
      throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
        path: path.path,
        attribute: attributeName,
        operation: "remove",
        reason: "Failed to remove attribute: \(error.localizedDescription)"
      )
    }
  }

  /**
   Creates a security-scoped bookmark for the given file path.

   - Parameters:
     - path: The path to create a bookmark for
     - readOnly: Whether the bookmark should be read-only
   - Returns: The bookmark data
   - Throws: FileSystemError if the bookmark cannot be created
   */
  public func createSecurityBookmark(
    for path: FilePath,
    readOnly: Bool
  ) async throws -> Data {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    do {
      let url=URL(fileURLWithPath: path.path)
      let bookmarkData=try url.bookmarkData(
        options: [.withSecurityScope, readOnly ? .securityScopeAllowOnlyReadAccess : []],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      await logger.debug(
        "Created security bookmark for \(path.path)",
        context: FileSystemLogContext(
          operation: "createSecurityBookmark",
          path: path.path,
          source: "FileSystemService"
        )
      )

      return bookmarkData
    } catch {
      throw FileSystemInterfaces.FileSystemError.unknown(
        message: "Failed to create bookmark: \(error.localizedDescription)"
      )
    }
  }

  /**
   Resolves a security-scoped bookmark to a file path.

   - Parameter bookmark: The bookmark data to resolve
   - Returns: The file path and whether it is stale
   - Throws: FileSystemError if the bookmark cannot be resolved
   */
  public func resolveSecurityBookmark(
    _ bookmark: Data
  ) async throws -> (FilePath, Bool) {
    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      let path=FilePath(path: url.path)

      await logger.debug(
        "Resolved security bookmark to \(path.path)",
        context: FileSystemLogContext(
          operation: "resolveSecurityBookmark",
          path: path.path,
          source: "FileSystemService"
        )
      )

      return (path, isStale)
    } catch {
      throw FileSystemInterfaces.FileSystemError.unknown(
        message: "Failed to resolve bookmark: \(error.localizedDescription)"
      )
    }
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to start accessing
   - Returns: Whether access was successfully started
   - Throws: FileSystemError if access cannot be started
   */
  public func startAccessingSecurityScopedResource(
    at path: FilePath
  ) async throws -> Bool {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    let url=URL(fileURLWithPath: path.path)
    let success=url.startAccessingSecurityScopedResource()

    await logger.debug(
      "Started accessing security-scoped resource \(path.path)",
      context: FileSystemLogContext(
        operation: "startAccessingSecurityScopedResource",
        path: path.path,
        source: "FileSystemService"
      )
    )

    return success
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  public func stopAccessingSecurityScopedResource(
    at path: FilePath
  ) async {
    guard !path.path.isEmpty else {
      return
    }

    let url=URL(fileURLWithPath: path.path)
    url.stopAccessingSecurityScopedResource()

    await logger.debug(
      "Stopped accessing security-scoped resource \(path.path)",
      context: FileSystemLogContext(
        operation: "stopAccessingSecurityScopedResource",
        path: path.path,
        source: "FileSystemService"
      )
    )
  }

  /**
   Creates a temporary file.

   - Parameters:
     - prefix: Optional prefix for the filename
     - suffix: Optional suffix for the filename
     - options: Optional temporary file options
   - Returns: The path to the created temporary file
   - Throws: FileSystemError if the temporary file cannot be created
   */
  public func createTemporaryFile(
    prefix: String?,
    suffix: String?,
    options: TemporaryFileOptions?
  ) async throws -> FilePath {
    do {
      let tempDir=try fileManager.url(
        for: .itemReplacementDirectory,
        in: .userDomainMask,
        appropriateFor: URL(fileURLWithPath: NSHomeDirectory()),
        create: true
      )

      let fileName=[
        prefix ?? "temp",
        UUID().uuidString,
        suffix ?? ""
      ].compactMap { $0.isEmpty ? nil : $0 }.joined()

      let fileURL=tempDir.appendingPathComponent(fileName)

      // Create an empty file
      fileManager.createFile(atPath: fileURL.path, contents: nil)

      // Set attributes if specified
      if let options, let attributes=options.attributes {
        try fileManager.setAttributes(
          attributes.toDictionary(),
          ofItemAtPath: fileURL.path
        )
      }

      await logger.debug(
        "Created temporary file \(fileURL.path)",
        context: FileSystemLogContext(
          operation: "createTemporaryFile",
          path: fileURL.path,
          source: "FileSystemService"
        )
      )

      return FilePath(path: fileURL.path)
    } catch {
      throw FileSystemInterfaces.FileSystemError.unknown(
        message: "Failed to create temporary file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Creates a temporary directory.

   - Parameters:
     - prefix: Optional prefix for the directory name
     - options: Optional temporary file options
   - Returns: The path to the created temporary directory
   - Throws: FileSystemError if the temporary directory cannot be created
   */
  public func createTemporaryDirectory(
    prefix: String?,
    options: TemporaryFileOptions?
  ) async throws -> FilePath {
    do {
      let tempDir=try fileManager.url(
        for: .itemReplacementDirectory,
        in: .userDomainMask,
        appropriateFor: URL(fileURLWithPath: NSHomeDirectory()),
        create: true
      )

      let dirName=[
        prefix ?? "temp",
        UUID().uuidString
      ].compactMap { $0.isEmpty ? nil : $0 }.joined(separator: "-")

      let dirURL=tempDir.appendingPathComponent(dirName)

      try fileManager.createDirectory(
        at: dirURL,
        withIntermediateDirectories: true,
        attributes: options?.attributes?.toDictionary()
      )

      await logger.debug(
        "Created temporary directory \(dirURL.path)",
        context: FileSystemLogContext(
          operation: "createTemporaryDirectory",
          path: dirURL.path,
          source: "FileSystemService"
        )
      )

      return FilePath(path: dirURL.path)
    } catch {
      throw FileSystemInterfaces.FileSystemError.unknown(
        message: "Failed to create temporary directory: \(error.localizedDescription)"
      )
    }
  }
}

// MARK: - Helper Extensions

extension FileAttributes {
  /// Convert FileAttributes to a Dictionary suitable for FileManager APIs
  func toDictionary() -> [FileAttributeKey: Any] {
    var result: [FileAttributeKey: Any]=[:]

    result[.size]=size
    result[.creationDate]=creationDate
    result[.modificationDate]=modificationDate

    if let accessDate {
      result[.modificationDate]=accessDate
    }

    result[.posixPermissions]=permissions
    result[.ownerAccountID]=ownerID
    result[.groupOwnerAccountID]=groupID

    if let fileType {
      result[.type]=fileType
    }

    return result
  }
}

// MARK: - Support for null logger when none is provided

/// A simple no-op logger implementation for when no logger is provided
@preconcurrency
private actor NoLogLogger: LoggingInterfaces.LoggingProtocol {
  // Add loggingActor property required by LoggingProtocol
  nonisolated let loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  // Implement the required log method from CoreLoggingProtocol
  func log(_ level: LoggingInterfaces.LogLevel, _ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation for no-op logger
  }
  
  // Convenience methods with empty implementations
  func trace(_ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
  
  func debug(_ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
  
  func info(_ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
  
  func warning(_ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
  
  func error(_ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
  
  func critical(_ message: String, context: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
}
