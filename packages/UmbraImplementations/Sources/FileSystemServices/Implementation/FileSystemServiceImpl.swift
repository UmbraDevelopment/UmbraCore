import Darwin.C
import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingAdapters

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
  let fileManager: Foundation.FileManager
  
  /// Logger for this service
  private let logger: any LoggingProtocol
  
  /// Secure operations implementation
  public let secureOperations: SecureFileOperationsProtocol
  
  /**
   Initialises a new file system service.
   
   - Parameters:
     - fileManager: Optional custom file manager to use
     - logger: Optional logger for recording operations
     - secureOperations: Optional secure operations implementation
   */
  public init(
    fileManager: Foundation.FileManager = .default,
    logger: (any LoggingProtocol)? = nil,
    secureOperations: SecureFileOperationsProtocol? = nil
  ) {
    self.fileManager = fileManager
    self.logger = logger ?? NullLogger()
    self.secureOperations = secureOperations ?? SecureFileOperationsImpl()
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
          source: "FileSystemService"
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
          source: "FileSystemService"
        )
      )

      return metadata
    } catch {
      await logger.error(
        "Failed to get metadata for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "stat",
          source: "FileSystemService"
        )
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to get metadata: \(error.localizedDescription)"
      )
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
          source: "FileSystemService"
        )
      )
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to get extended attribute: \(error.localizedDescription)"
      )
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
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to set extended attribute \(attributeName) for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "setxattr",
          source: "FileSystemService"
        )
      )
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to set extended attribute: \(error.localizedDescription)"
      )
    }
  }

  /**
   Removes an extended attribute from a file or directory.
   
   - Parameters:
     - path: The path to the file or directory
     - attributeName: The name of the extended attribute to remove
   - Throws: FileSystemError if the attribute cannot be removed
   */
  public func removeExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws {
    await logger.debug(
      "Removing extended attribute \(attributeName) from \(path.path)",
      context: FileSystemLogContext(
        operation: "removexattr",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    guard !attributeName.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Empty attribute name provided"
      )
    }
    
    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    do {
      // Remove the extended attribute
      try Foundation.FileManager.default.removeExtendedAttribute(
        withName: attributeName,
        fromItemAtPath: path.path
      )
      
      await logger.debug(
        "Removed extended attribute \(attributeName) from \(path.path)",
        context: FileSystemLogContext(
          operation: "removexattr",
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to remove extended attribute \(attributeName) from \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "removexattr",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
        path: path.path,
        attribute: attributeName,
        operation: "remove",
        reason: "Failed to remove extended attribute: \(error.localizedDescription)"
      )
    }
  }

  /**
   Lists all extended attributes on a file or directory.

   - Parameter path: The file to query
   - Returns: An array of attribute names
   - Throws: FileSystemError if the attributes cannot be retrieved
   */
  public func listExtendedAttributes(
    at path: FilePath
  ) async throws -> [String] {
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }

    // Check if file exists
    if !fileManager.fileExists(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    await logger.debug(
      "Listing extended attributes",
      context: FileSystemLogContext(
        operation: "listExtendedAttributes",
        source: "FileSystemService"
      )
    )

    do {
      let attributes = try Foundation.FileManager.default.listExtendedAttributes(atPath: path.path)
      
      await logger.debug(
        "Listed extended attributes",
        context: FileSystemLogContext(
          operation: "listExtendedAttributes",
          source: "FileSystemService"
        )
      )

      return attributes
    } catch {
      await logger.error(
        "Failed to list extended attributes",
        context: FileSystemLogContext(
          operation: "listExtendedAttributes",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to list extended attributes: \(error.localizedDescription)"
      )
    }
  }

  /**
   Creates a file with the specified data.
   
   - Parameters:
     - path: The path where the file should be created
     - data: The data to write to the file
     - overwrite: Whether to overwrite an existing file
   - Throws: FileSystemError if the file cannot be created
   */
  public func createFile(
    at path: FilePath,
    data: Data,
    overwrite: Bool = false
  ) async throws {
    await logger.debug(
      "Creating file at \(path.path)",
      context: FileSystemLogContext(
        operation: "createFile",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the file already exists
    if fileManager.fileExists(atPath: path.path) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
      }
      
      // If we're overwriting, make sure we can write to the file
      if !fileManager.isWritableFile(atPath: path.path) {
        throw FileSystemInterfaces.FileSystemError.permissionDenied(
          path: path.path,
          message: "File is not writable"
        )
      }
    }
    
    // Ensure the directory exists
    let directory = (path.path as NSString).deletingLastPathComponent
    if !directory.isEmpty && !fileManager.fileExists(atPath: directory) {
      do {
        try Foundation.FileManager.default.createDirectory(
          atPath: directory,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        await logger.error(
          "Failed to create parent directory for \(path.path): \(error.localizedDescription)",
          context: FileSystemLogContext(
            operation: "createFile",
            source: "FileSystemService"
          )
        )
        
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: directory,
          reason: "Failed to create parent directory: \(error.localizedDescription)"
        )
      }
    }
    
    do {
      // Write the data to the file
      try data.write(to: URL(fileURLWithPath: path.path), options: .atomic)
      
      await logger.debug(
        "Created file at \(path.path) with \(data.count) bytes",
        context: FileSystemLogContext(
          operation: "createFile",
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to create file at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "createFile",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to write file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Updates an existing file with new data.
   
   - Parameters:
     - path: The path to the file to update
     - data: The new data to write to the file
   - Throws: FileSystemError if the file cannot be updated
   */
  public func updateFile(
    at path: FilePath,
    data: Data
  ) async throws {
    await logger.debug(
      "Updating file at \(path.path)",
      context: FileSystemLogContext(
        operation: "updateFile",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    // Make sure we can write to the file
    if !fileManager.isWritableFile(atPath: path.path) {
      throw FileSystemInterfaces.FileSystemError.permissionDenied(
        path: path.path,
        message: "File is not writable"
      )
    }
    
    do {
      // Write the data to the file
      try data.write(to: URL(fileURLWithPath: path.path), options: .atomic)
      
      await logger.debug(
        "Updated file at \(path.path) with \(data.count) bytes",
        context: FileSystemLogContext(
          operation: "updateFile",
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to update file at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "updateFile",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to update file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The path to check
   - Returns: True if the file exists, false otherwise
   - Throws: FileSystemError if the existence check fails
   */
  public func fileExists(at path: FilePath) async throws -> Bool {
    await logger.debug(
      "Checking if file exists",
      context: FileSystemLogContext(
        operation: "fileExists",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    let exists = fileManager.fileExists(atPath: path.path)
    
    await logger.debug(
      "File exists check completed",
      context: FileSystemLogContext(
        operation: "fileExists",
        source: "FileSystemService"
      )
    )
    
    return exists
  }

  /**
   Checks if a directory exists at the specified path.

   - Parameter path: The path to check
   - Returns: True if the directory exists, false otherwise
   - Throws: FileSystemError if the check fails
   */
  public func directoryExists(at path: FilePath) async throws -> Bool {
    await logger.debug(
      "Checking if directory exists",
      context: FileSystemLogContext(
        operation: "directoryExists",
        source: "FileSystemService"
      )
    )
    
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
          source: "FileSystemService"
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
   Lists the contents of a directory.
   
   - Parameters:
     - path: The directory path to list
     - includeHidden: Whether to include hidden files in the listing
   - Returns: Array of file paths in the directory
   - Throws: FileSystemError if the directory cannot be listed
   */
  public func listDirectory(
    at path: FilePath,
    includeHidden: Bool = false
  ) async throws -> [FilePath] {
    await logger.debug(
      "Listing directory",
      context: FileSystemLogContext(
        operation: "listDirectory",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if directory exists
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)
    
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
    
    do {
      let contents = try Foundation.FileManager.default.contentsOfDirectory(atPath: path.path)
      
      // Filter out hidden files if requested
      let filteredContents = includeHidden
        ? contents
        : contents.filter { !$0.hasPrefix(".") }
      
      // Convert to FilePath objects
      let filePaths = filteredContents.map { item -> FilePath in
        let fullPath = (path.path as NSString).appendingPathComponent(item)
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
        return FilePath(path: fullPath, isDirectory: isDir.boolValue)
      }
      
      await logger.debug(
        "Listed directory contents",
        context: FileSystemLogContext(
          operation: "listDirectory",
          source: "FileSystemService"
        )
      )
      
      return filePaths
    } catch {
      await logger.error(
        "Failed to list directory",
        context: FileSystemLogContext(
          operation: "listDirectory",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to list directory: \(error.localizedDescription)"
      )
    }
  }
  
  /**
   Lists the contents of a directory recursively.
   
   - Parameters:
     - path: The directory to list
     - includeHidden: Whether to include hidden files
   - Returns: An array of file paths
   - Throws: FileSystemError if the directory cannot be listed
   */
  public func listDirectoryRecursive(
    at path: FilePath,
    includeHidden: Bool = false
  ) async throws -> [FilePath] {
    await logger.debug(
      "Listing directory recursively at \(path.path)",
      context: FileSystemLogContext(
        operation: "listDirectoryRecursive",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the path exists and is a directory
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)
    
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
    
    do {
      var result: [FilePath] = []
      
      // Get the contents of the directory
      let contents = try Foundation.FileManager.default.contentsOfDirectory(atPath: path.path)
      
      // Filter out hidden files if requested
      let filteredContents = includeHidden
        ? contents
        : contents.filter { !$0.hasPrefix(".") }
      
      // Process each item
      for item in filteredContents {
        let itemPath = path.path + "/" + item
        let itemFilePath = FilePath(path: itemPath)
        
        // Add the current item to the result
        result.append(itemFilePath)
        
        // If it's a directory, recursively list its contents
        var isItemDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: itemPath, isDirectory: &isItemDirectory) && isItemDirectory.boolValue {
          let subItems = try await listDirectoryRecursive(at: itemFilePath, includeHidden: includeHidden)
          result.append(contentsOf: subItems)
        }
      }
      
      await logger.debug(
        "Listed \(result.count) items recursively in directory at \(path.path)",
        context: FileSystemLogContext(
          operation: "listDirectoryRecursive",
          source: "FileSystemService"
        )
      )
      
      return result
    } catch {
      await logger.error(
        "Failed to list directory recursively at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "listDirectoryRecursive",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to list directory recursively: \(error.localizedDescription)"
      )
    }
  }

  /**
   Reads the contents of a file.
   
   - Parameter path: The path to the file to read
   - Returns: The file contents as Data
   - Throws: FileSystemError if the file cannot be read
   */
  public func readFile(at path: FilePath) async throws -> Data {
    await logger.debug(
      "Reading file",
      context: FileSystemLogContext(
        operation: "readFile",
        source: "FileSystemService"
      )
    )
    
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: path.path))
      
      await logger.debug(
        "Read file",
        context: FileSystemLogContext(
          operation: "readFile",
          source: "FileSystemService"
        )
      )
      
      return data
    } catch {
      await logger.error(
        "Failed to read file",
        context: FileSystemLogContext(
          operation: "readFile",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to read file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Deletes a file at the specified path.
   
   - Parameters:
     - path: The path to the file to delete
     - secure: Whether to perform a secure delete (overwrite with zeros before deletion)
   - Throws: FileSystemError if the file cannot be deleted
   */
  public func deleteFile(
    at path: FilePath,
    secure: Bool = false
  ) async throws {
    await logger.debug(
      "Deleting file at \(path.path)",
      context: FileSystemLogContext(
        operation: "deleteFile",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the file exists
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)
    
    if !exists {
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
      if secure {
        // Perform secure delete by overwriting with zeros
        let fileSize = try fileManager.attributesOfItem(atPath: path.path)[.size] as? UInt64 ?? 0
        if fileSize > 0 {
          let zeros = Data(count: Int(fileSize))
          try zeros.write(to: URL(fileURLWithPath: path.path), options: .atomic)
        }
      }
      
      // Delete the file
      try Foundation.FileManager.default.removeItem(atPath: path.path)
      
      await logger.debug(
        "Deleted file at \(path.path)",
        context: FileSystemLogContext(
          operation: "deleteFile",
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to delete file at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "deleteFile",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: "Failed to delete file: \(error.localizedDescription)"
      )
    }
  }
  
  /**
   Deletes a directory at the specified path.
   
   - Parameters:
     - path: The path to the directory to delete
     - secure: Whether to perform a secure delete (overwrite files with zeros before deletion)
   - Throws: FileSystemError if the directory cannot be deleted
   */
  public func deleteDirectory(
    at path: FilePath,
    secure: Bool = false
  ) async throws {
    await logger.debug(
      "Deleting directory at \(path.path)",
      context: FileSystemLogContext(
        operation: "deleteDirectory",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the directory exists
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)
    
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
    
    do {
      if secure {
        // If secure delete is requested, we need to securely delete all files in the directory first
        let contents = try Foundation.FileManager.default.contentsOfDirectory(atPath: path.path)
        for item in contents {
          let itemPath = path.path + "/" + item
          var isItemDirectory: ObjCBool = false
          if fileManager.fileExists(atPath: itemPath, isDirectory: &isItemDirectory) {
            if isItemDirectory.boolValue {
              // Recursively delete subdirectories
              try await deleteDirectory(at: FilePath(path: itemPath), secure: true)
            } else {
              // Securely delete files
              try await deleteFile(at: FilePath(path: itemPath), secure: true)
            }
          }
        }
      }
      
      // Delete the directory
      try Foundation.FileManager.default.removeItem(atPath: path.path)
      
      await logger.debug(
        "Deleted directory at \(path.path)",
        context: FileSystemLogContext(
          operation: "deleteDirectory",
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to delete directory at \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "deleteDirectory",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: "Failed to delete directory: \(error.localizedDescription)"
      )
    }
  }

  /**
   Copies an item from one path to another.
   
   - Parameters:
     - sourcePath: The path to the item to copy
     - destinationPath: The path where the item should be copied to
     - overwrite: Whether to overwrite an existing item at the destination
   - Throws: FileSystemError if the copy operation fails
   */
  public func copyItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool = false
  ) async throws {
    await logger.debug(
      "Copying item from \(sourcePath.path) to \(destinationPath.path)",
      context: FileSystemLogContext(
        operation: "copyItem",
        source: "FileSystemService"
      )
    )
    
    guard !sourcePath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty source path provided"
      )
    }
    
    guard !destinationPath.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty destination path provided"
      )
    }
    
    // Check if the source exists
    guard fileManager.fileExists(atPath: sourcePath.path) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }
    
    // Check if the destination already exists
    if fileManager.fileExists(atPath: destinationPath.path) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }
      
      // If overwrite is true, remove the existing item
      do {
        try Foundation.FileManager.default.removeItem(atPath: destinationPath.path)
      } catch {
        await logger.error(
          "Failed to remove existing item at \(destinationPath.path): \(error.localizedDescription)",
          context: FileSystemLogContext(
            operation: "copyItem",
            source: "FileSystemService"
          )
        )
        
        throw FileSystemInterfaces.FileSystemError.deleteError(
          path: destinationPath.path,
          reason: "Failed to remove existing item before copy: \(error.localizedDescription)"
        )
      }
    }
    
    // Ensure the destination directory exists
    let destinationDirectory = (destinationPath.path as NSString).deletingLastPathComponent
    if !destinationDirectory.isEmpty && !fileManager.fileExists(atPath: destinationDirectory) {
      do {
        try Foundation.FileManager.default.createDirectory(
          atPath: destinationDirectory,
          withIntermediateDirectories: true,
          attributes: nil
        )
      } catch {
        await logger.error(
          "Failed to create parent directory for \(destinationPath.path): \(error.localizedDescription)",
          context: FileSystemLogContext(
            operation: "copyItem",
            source: "FileSystemService"
          )
        )
        
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: destinationDirectory,
          reason: "Failed to create parent directory: \(error.localizedDescription)"
        )
      }
    }
    
    do {
      // Perform the copy
      try Foundation.FileManager.default.copyItem(atPath: sourcePath.path, toPath: destinationPath.path)
      
      await logger.debug(
        "Copied item from \(sourcePath.path) to \(destinationPath.path)",
        context: FileSystemLogContext(
          operation: "copyItem",
          source: "FileSystemService"
        )
      )
    } catch {
      await logger.error(
        "Failed to copy item from \(sourcePath.path) to \(destinationPath.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "copyItem",
          source: "FileSystemService"
        )
      )
      
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
   - Returns: A URL representing the path
   - Throws: FileSystemError if the conversion fails
   */
  public func pathToURL(_ path: FilePath) async throws -> URL {
    await logger.debug(
      "Converting path to URL: \(path.path)",
      context: FileSystemLogContext(
        operation: "pathToURL",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Create a URL from the path
    let url = URL(fileURLWithPath: path.path)
    
    return url
  }

  /**
   Creates a security bookmark for a file or directory.
   
   - Parameters:
     - path: The path to create a bookmark for
     - readOnly: Whether the bookmark should be read-only
   - Returns: The bookmark data
   - Throws: FileSystemError if the bookmark cannot be created
   */
  public func createSecurityBookmark(
    for path: FilePath,
    readOnly: Bool = false
  ) async throws -> Data {
    await logger.debug(
      "Creating security bookmark for \(path.path)",
      context: FileSystemLogContext(
        operation: "createBookmark",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    do {
      // Create a URL from the path
      let url = URL(fileURLWithPath: path.path)
      
      // Create the bookmark
      let bookmarkData = try url.bookmarkData(
        options: readOnly ? [.securityScopeAllowOnlyReadAccess] : [],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      
      await logger.debug(
        "Created security bookmark for \(path.path)",
        context: FileSystemLogContext(
          operation: "createBookmark",
          source: "FileSystemService"
        )
      )
      
      return bookmarkData
    } catch {
      await logger.error(
        "Failed to create security bookmark for \(path.path): \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "createBookmark",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.securityViolation(
        path: path.path,
        constraint: "Failed to create security bookmark: \(error.localizedDescription)"
      )
    }
  }
  
  /**
   Resolves a security bookmark to a file path.
   
   - Parameter bookmark: The bookmark data to resolve
   - Returns: A tuple containing the resolved path and whether the bookmark is stale
   - Throws: FileSystemError if the bookmark cannot be resolved
   */
  public func resolveSecurityBookmark(
    _ bookmark: Data
  ) async throws -> (FilePath, Bool) {
    await logger.debug(
      "Resolving security bookmark",
      context: FileSystemLogContext(
        operation: "resolveBookmark",
        source: "FileSystemService"
      )
    )
    
    do {
      // Resolve the bookmark
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
      
      let path = FilePath(path: url.path)
      
      await logger.debug(
        "Resolved security bookmark to \(path.path)",
        context: FileSystemLogContext(
          operation: "resolveBookmark",
          source: "FileSystemService"
        )
      )
      
      return (path, isStale)
    } catch {
      await logger.error(
        "Failed to resolve security bookmark: \(error.localizedDescription)",
        context: FileSystemLogContext(
          operation: "resolveBookmark",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.securityViolation(
        path: "",
        constraint: "Failed to resolve security bookmark: \(error.localizedDescription)"
      )
    }
  }
  
  /**
   Starts accessing a security-scoped resource.
   
   - Parameter path: The path to the resource to access
   - Returns: Whether access was started successfully
   - Throws: FileSystemError if access cannot be started
   */
  public func startAccessingSecurityScopedResource(
    at path: FilePath
  ) async throws -> Bool {
    await logger.debug(
      "Starting access to security-scoped resource at \(path.path)",
      context: FileSystemLogContext(
        operation: "startAccess",
        source: "FileSystemService"
      )
    )
    
    guard !path.path.isEmpty else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: "",
        reason: "Empty path provided"
      )
    }
    
    // Check if the file exists
    guard fileManager.fileExists(atPath: path.path) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }
    
    // Create a URL from the path
    let url = URL(fileURLWithPath: path.path)
    
    // Start accessing the resource
    let result = url.startAccessingSecurityScopedResource()
    
    await logger.debug(
      "Started access to security-scoped resource at \(path.path): \(result)",
      context: FileSystemLogContext(
        operation: "startAccess",
        source: "FileSystemService"
      )
    )
    
    return result
  }
  
  /**
   Stops accessing a security-scoped resource.
   
   - Parameter path: The path to stop accessing
   */
  public func stopAccessingSecurityScopedResource(
    at path: FilePath
  ) async {
    await logger.debug(
      "Stopping access to security-scoped resource at \(path.path)",
      context: FileSystemLogContext(
        operation: "stopAccess",
        source: "FileSystemService"
      )
    )
    
    if path.path.isEmpty {
      return
    }
    
    // Create a URL from the path
    let url = URL(fileURLWithPath: path.path)
    
    // Stop accessing the resource
    url.stopAccessingSecurityScopedResource()
    
    await logger.debug(
      "Stopped access to security-scoped resource at \(path.path)",
      context: FileSystemLogContext(
        operation: "stopAccess",
        source: "FileSystemService"
      )
    )
  }

  /**
   Creates a temporary file with the specified prefix and suffix.
   
   - Parameters:
     - prefix: Optional prefix for the temporary file name
     - suffix: Optional suffix for the temporary file name
     - options: Optional options for the temporary file
   - Returns: The path to the created temporary file
   - Throws: FileSystemError if the temporary file cannot be created
   */
  public func createTemporaryFile(
    prefix: String? = nil,
    suffix: String? = nil,
    options: FileSystemInterfaces.TemporaryFileOptions? = nil
  ) async throws -> FilePath {
    await logger.debug(
      "Creating temporary file",
      context: FileSystemLogContext(
        operation: "createTempFile",
        source: "FileSystemService"
      )
    )
    
    // Determine the temporary directory
    let tempDir = NSTemporaryDirectory()
    
    // Create a unique filename
    let uuid = UUID().uuidString
    let filename = [prefix, uuid, suffix].compactMap { $0 }.joined()
    let tempPath = (tempDir as NSString).appendingPathComponent(filename)
    
    do {
      // Create an empty file
      if !(Foundation.FileManager.default.createFile(atPath: tempPath, contents: Data(), attributes: options?.attributes) as Bool) {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: tempPath,
          reason: "Failed to create temporary file"
        )
      }
      
      let filePath = FilePath(path: tempPath)
      
      await logger.debug(
        "Created temporary file",
        context: FileSystemLogContext(
          operation: "createTempFile",
          source: "FileSystemService"
        )
      )
      
      return filePath
    } catch {
      await logger.error(
        "Failed to create temporary file",
        context: FileSystemLogContext(
          operation: "createTempFile",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempPath,
        reason: "Failed to create temporary file: \(error.localizedDescription)"
      )
    }
  }
  
  /**
   Creates a temporary directory with the specified prefix.
   
   - Parameters:
     - prefix: Optional prefix for the temporary directory name
     - options: Optional options for the temporary directory
   - Returns: The path to the created temporary directory
   - Throws: FileSystemError if the temporary directory cannot be created
   */
  public func createTemporaryDirectory(
    prefix: String? = nil,
    options: FileSystemInterfaces.TemporaryFileOptions? = nil
  ) async throws -> FilePath {
    await logger.debug(
      "Creating temporary directory",
      context: FileSystemLogContext(
        operation: "createTempDir",
        source: "FileSystemService"
      )
    )
    
    // Determine the temporary directory
    let tempDir = NSTemporaryDirectory()
    
    // Create a unique directory name
    let uuid = UUID().uuidString
    let dirName = [prefix, uuid].compactMap { $0 }.joined()
    let tempPath = (tempDir as NSString).appendingPathComponent(dirName)
    
    do {
      // Create the directory
      try (Foundation.FileManager.default.createDirectory(
        atPath: tempPath,
        withIntermediateDirectories: true,
        attributes: options?.attributes
      ) as Void)
      
      let dirPath = FilePath(path: tempPath)
      
      await logger.debug(
        "Created temporary directory",
        context: FileSystemLogContext(
          operation: "createTempDir",
          source: "FileSystemService"
        )
      )
      
      return dirPath
    } catch {
      await logger.error(
        "Failed to create temporary directory",
        context: FileSystemLogContext(
          operation: "createTempDir",
          source: "FileSystemService"
        )
      )
      
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: tempPath,
        reason: "Failed to create temporary directory: \(error.localizedDescription)"
      )
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

}

extension FileSystemServiceImpl: FileReadOperationsProtocol {
  public func readFile(at path: String) async throws -> Data {
    try await readFile(at: FilePath(path))
  }

  public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> String {
    try await readFileAsString(at: FilePath(path), encoding: encoding)
  }

  public func fileExists(at path: String) async -> Bool {
    do {
      return try await fileExists(at: FilePath(path))
    } catch {
      return false
    }
  }

  public func listDirectory(at path: String) async throws -> [String] {
    let filePaths = try await listDirectory(at: FilePath(path))
    return filePaths.map { $0.path }
  }

  public func listDirectoryRecursively(at path: String) async throws -> [String] {
    let filePaths = try await listDirectoryRecursively(at: FilePath(path))
    return filePaths.map { $0.path }
  }
}

extension FileSystemServiceImpl: FileWriteOperationsProtocol {
  public func createFile(at path: String, options: FileCreationOptions?) async throws -> String {
    try await createFile(at: FilePath(path), options: options).path
  }

  public func writeString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws {
    try await writeString(string, to: FilePath(path), encoding: encoding, options: options)
  }

  public func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> String {
    try await createDirectory(at: FilePath(path), options: options).path
  }

  public func delete(at path: String) async throws {
    try await delete(at: FilePath(path))
  }

  public func move(from sourcePath: String, to destinationPath: String, options: FileMoveOptions?) async throws {
    try await move(from: FilePath(sourcePath), to: FilePath(destinationPath), options: options)
  }

  public func copy(from sourcePath: String, to destinationPath: String, options: FileCopyOptions?) async throws {
    try await copy(from: FilePath(sourcePath), to: FilePath(destinationPath), options: options)
  }
}

extension FileSystemServiceImpl: FileMetadataProtocol {
  public func getAttributes(at path: String) async throws -> FileAttributes {
    try await getAttributes(at: FilePath(path))
  }

  public func setAttributes(_ attributes: FileAttributes, at path: String) async throws {
    try await setAttributes(attributes, at: FilePath(path))
  }

  public func getFileSize(at path: String) async throws -> UInt64 {
    try await getFileSize(at: FilePath(path))
  }

  public func getCreationDate(at path: String) async throws -> Date {
    try await getCreationDate(at: FilePath(path))
  }

  public func getModificationDate(at path: String) async throws -> Date {
    try await getModificationDate(at: FilePath(path))
  }

  public func getExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> Data {
    try await getExtendedAttribute(withName: name, fromItemAtPath: FilePath(path))
  }

  public func setExtendedAttribute(_ data: Data, withName name: String, onItemAtPath path: String) async throws {
    try await setExtendedAttribute(data, withName: name, onItemAtPath: FilePath(path))
  }

  public func listExtendedAttributes(atPath path: String) async throws -> [String] {
    try await listExtendedAttributes(atPath: FilePath(path))
  }

  public func removeExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws {
    try await removeExtendedAttribute(withName: name, fromItemAtPath: FilePath(path))
  }
}

extension FileSystemServiceImpl: FileSecurityOperationsProtocol {
  public func createSecurityBookmark(for path: String, readOnly: Bool) async throws -> Data {
    try await createSecurityBookmark(for: FilePath(path), readOnly: readOnly)
  }

  public func resolveSecurityBookmark(_ bookmark: Data) async throws -> (String, Bool) {
    let (path, isStale) = try await resolveSecurityBookmark(bookmark)
    return (path.path, isStale)
  }

  public func startAccessingSecurityScopedResource(at path: String) async throws -> Bool {
    try await startAccessingSecurityScopedResource(at: FilePath(path))
  }

  public func stopAccessingSecurityScopedResource(at path: String) async {
    await stopAccessingSecurityScopedResource(at: FilePath(path))
  }
}

extension FileSystemServiceImpl: FileServiceProtocol {
  public func temporaryDirectoryPath() async -> String {
    fileManager.temporaryDirectory.path
  }

  public func createUniqueFilename(in directory: String, prefix: String?, extension: String?) async -> String {
    let prefixToUse = prefix ?? ""
    let extensionToUse = `extension` != nil ? ".\(`extension`!)" : ""
    let uuid = UUID().uuidString
    return "\(directory)/\(prefixToUse)\(uuid)\(extensionToUse)"
  }

  public func normalisePath(_ path: String) async -> String {
    (path as NSString).standardizingPath
  }

  public func createSandboxed(rootDirectory: String) -> Self {
    Self(secureOperations: SandboxedSecureFileOperations(rootDirectory: rootDirectory))
  }
}
