import FileSystemInterfaces
import FileSystemTypes
import LoggingInterfaces
import LoggingTypes
import Security

/**
 # File System Service Secure Implementation

 This implementation of the FileSystemServiceProtocol uses the SecurePath abstraction
 and FilePathService to reduce direct dependencies on Foundation types like URL.

 The implementation follows the Alpha Dot Five architecture principles by:
 1. Using actor-based isolation for thread safety
 2. Providing comprehensive error handling
 3. Using Sendable types for cross-actor communication
 4. Reducing direct Foundation dependencies

 ## Thread Safety

 This implementation is an actor, ensuring all operations are thread-safe
 and can be safely called from multiple concurrent contexts.

 ## British Spelling

 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public actor FileSystemServiceSecure: FileSystemServiceProtocol {
  /// The file path service for path operations
  private let filePathService: FilePathServiceProtocol

  /// Logger for recording operations and errors
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure file system service.

   - Parameters:
      - filePathService: The file path service to use
      - logger: Optional logger for recording operations
   */
  public init(
    filePathService: FilePathServiceProtocol,
    logger: (any LoggingProtocol)?=nil
  ) {
    self.filePathService=filePathService
    self.logger=logger ?? NullLogger()
  }

  // MARK: - Core File & Directory Operations

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The file path to check
   - Returns: Whether the file exists
   - Throws: FileSystemError if the existence check fails
   */
  public func fileExists(at path: FilePath) async throws -> Bool {
    await logDebug("Checking if file exists at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    let exists=await filePathService.exists(securePath)
    let isFile=await filePathService.isFile(securePath)

    return exists && isFile
  }

  /**
   Checks if a directory exists at the specified path.

   - Parameter path: The directory path to check
   - Returns: Whether the directory exists
   - Throws: FileSystemError if the existence check fails
   */
  public func directoryExists(at path: FilePath) async throws -> Bool {
    await logDebug("Checking if directory exists at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    let exists=await filePathService.exists(securePath)
    let isDirectory=await filePathService.isDirectory(securePath)

    return exists && isDirectory
  }

  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The path where the directory should be created
      - withIntermediateDirectories: Whether to create intermediate directories
   - Throws: FileSystemError if directory creation fails
   */
  public func createDirectory(
    at path: FilePath,
    withIntermediateDirectories: Bool=true
  ) async throws {
    await logDebug("Creating directory at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      try FileManager.default.createDirectory(
        atPath: securePath.toString(),
        withIntermediateDirectories: withIntermediateDirectories,
        attributes: nil
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Returns the contents of a directory.

   - Parameters:
      - path: The directory path
      - options: Options for listing directory contents
   - Returns: An array of file paths
   - Throws: FileSystemError if directory listing fails
   */
  public func contentsOfDirectory(
    at path: FilePath,
    options _: DirectoryEnumerationOptions=[]
  ) async throws -> [FilePath] {
    await logDebug("Listing contents of directory at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      let contents=try FileManager.default.contentsOfDirectory(
        atPath: securePath.toString()
      )

      return contents.map { item in
        let itemPath=path.path.hasSuffix("/") ? path.path + item : path.path + "/" + item
        let isDirectory=(try? FileManager.default.attributesOfItem(
          atPath: itemPath
        )[.type] as? FileAttributeType) == .typeDirectory

        return FilePath(path: itemPath, isDirectory: isDirectory)
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  // MARK: - File Operations

  /**
   Reads a file and returns its contents.

   - Parameter path: The path to the file
   - Returns: The file contents as Data
   - Throws: FileSystemError if file reading fails
   */
  public func readFile(at path: FilePath) async throws -> Data {
    await logDebug("Reading file at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      return try Data(contentsOf: URL(fileURLWithPath: securePath.toString()))
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Writes data to a file.

   - Parameters:
      - path: The path to the file
      - data: The data to write
      - options: Options for writing the file
   - Throws: FileSystemError if file writing fails
   */
  public func writeFile(
    at path: FilePath,
    data: Data,
    options _: FileWriteOptions=[]
  ) async throws {
    await logDebug("Writing file at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      try data.write(to: URL(fileURLWithPath: securePath.toString()))
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Deletes a file at the specified path.

   - Parameter path: The file to delete
   - Throws: FileSystemError if file deletion fails
   */
  public func deleteFile(at path: FilePath) async throws {
    await logDebug("Deleting file at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      try FileManager.default.removeItem(atPath: securePath.toString())
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Moves a file or directory from one location to another.

   - Parameters:
      - sourcePath: The source path
      - destinationPath: The destination path
      - options: Options for the move operation
   - Throws: FileSystemError if the move fails
   */
  public func moveItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    options _: FileMoveOptions=[]
  ) async throws {
    await logDebug("Moving file from \(sourcePath.path) to \(destinationPath.path)")

    guard let secureSourcePath=SecurePathAdapter.toSecurePath(sourcePath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path,
        reason: "Could not convert source path to secure path"
      )
    }

    guard let secureDestinationPath=SecurePathAdapter.toSecurePath(destinationPath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: destinationPath.path,
        reason: "Could not convert destination path to secure path"
      )
    }

    do {
      try FileManager.default.moveItem(
        atPath: secureSourcePath.toString(),
        toPath: secureDestinationPath.toString()
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.moveError(
        source: sourcePath.path,
        destination: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Copies a file or directory from one location to another.

   - Parameters:
      - sourcePath: The source path
      - destinationPath: The destination path
      - options: Options for the copy operation
   - Throws: FileSystemError if the copy fails
   */
  public func copyItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    options _: FileCopyOptions=[]
  ) async throws {
    await logDebug("Copying file from \(sourcePath.path) to \(destinationPath.path)")

    guard let secureSourcePath=SecurePathAdapter.toSecurePath(sourcePath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path,
        reason: "Could not convert source path to secure path"
      )
    }

    guard let secureDestinationPath=SecurePathAdapter.toSecurePath(destinationPath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: destinationPath.path,
        reason: "Could not convert destination path to secure path"
      )
    }

    do {
      try FileManager.default.copyItem(
        atPath: secureSourcePath.toString(),
        toPath: secureDestinationPath.toString()
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.copyError(
        source: sourcePath.path,
        destination: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Converts a FilePath to a URL.

   - Parameter path: The path to convert
   - Returns: A URL representation of the path
   - Throws: FileSystemError if the conversion fails
   */
  public func pathToURL(_ path: FilePath) async throws -> URL {
    await logDebug("Converting path to URL: \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    return URL(fileURLWithPath: securePath.toString(), isDirectory: path.isDirectory)
  }

  /**
   Resolves a security bookmark.

   - Parameter bookmark: The bookmark data to resolve
   - Returns: A tuple containing the resolved path and whether the bookmark is stale
   - Throws: FileSystemError if the bookmark cannot be resolved
   */
  public func resolveSecurityBookmark(
    _ bookmark: Data
  ) async throws -> (FilePath, Bool) {
    await logDebug("Resolving security bookmark")

    do {
      var isStale=false
      let url=try URL(
        resolvingBookmarkData: bookmark,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      let isDirectory=(try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
      let path=FilePath(path: url.path, isDirectory: isDirectory)

      return (path, isStale)
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: "Unknown path",
        reason: "Failed to resolve bookmark: \(error.localizedDescription)"
      )
    }
  }

  /**
   Starts accessing a security-scoped resource.

   - Parameter path: The path to access
   - Returns: Whether access was successfully started
   - Throws: FileSystemError if access cannot be started
   */
  public func startAccessingSecurityScopedResource(
    at path: FilePath
  ) async throws -> Bool {
    await logDebug("Starting access to security-scoped resource at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    return await filePathService.startAccessingSecurityScopedResource(securePath)
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  public func stopAccessingSecurityScopedResource(
    at path: FilePath
  ) async {
    await logDebug("Stopping access to security-scoped resource at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      return
    }

    await filePathService.stopAccessingSecurityScopedResource(securePath)
  }

  /**
   Creates a temporary file.

   - Parameter prefix: Optional prefix for the filename
   - Parameter suffix: Optional suffix for the filename
   - Parameter options: Optional configuration options
   - Returns: Path to the created temporary file
   - Throws: FileSystemError if the temporary file cannot be created
   */
  public func createTemporaryFile(
    prefix: String?,
    suffix: String?,
    options _: TemporaryFileOptions?
  ) async throws -> FilePath {
    await logDebug(
      "Creating temporary file with prefix: \(prefix ?? "none"), suffix: \(suffix ?? "none")"
    )

    let tempDir=FileManager.default.temporaryDirectory
    let uuid=UUID().uuidString
    let filename=[prefix, uuid, suffix]
      .compactMap { $0 }
      .joined()

    let url=tempDir.appendingPathComponent(filename)

    // Create an empty file
    FileManager.default.createFile(atPath: url.path, contents: nil)

    return FilePath(path: url.path, isDirectory: false)
  }

  /**
   Creates a temporary directory.

   - Parameter prefix: Optional prefix for the directory name
   - Parameter options: Optional configuration options
   - Returns: Path to the created temporary directory
   - Throws: FileSystemError if the temporary directory cannot be created
   */
  public func createTemporaryDirectory(
    prefix: String?,
    options _: TemporaryFileOptions?
  ) async throws -> FilePath {
    await logDebug("Creating temporary directory with prefix: \(prefix ?? "none")")

    let tempDir=FileManager.default.temporaryDirectory
    let uuid=UUID().uuidString
    let dirname=prefix != nil ? "\(prefix!)\(uuid)" : uuid

    let url=tempDir.appendingPathComponent(dirname)

    do {
      try FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true,
        attributes: nil
      )

      return FilePath(path: url.path, isDirectory: true)
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: url.path,
        reason: "Failed to create temporary directory: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - Helper Methods

  /**
   Logs a debug message with appropriate context.

   - Parameter message: The message to log
   */
  private func logDebug(_ message: String) async {
    await logger.debug(message, context: FileSystemLogContextDTO(
      operation: "FileSystemSecure",
      path: nil,
      source: "FileSystemServiceSecure",
      correlationID: nil
    ))
  }

  /**
   Lists the contents of a directory.

   - Parameter path: The directory to list
   - Parameter includeHidden: Whether to include hidden files
   - Returns: Array of file paths for directory contents
   - Throws: FileSystemError if the directory cannot be read
   */
  public func listDirectory(
    at path: FilePath,
    includeHidden: Bool
  ) async throws -> [FilePath] {
    await logDebug("Listing directory at \(path.path), includeHidden: \(includeHidden)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the directory exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a directory
    guard await filePathService.isDirectory(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "directory",
        actual: "file"
      )
    }

    do {
      let contents=try FileManager.default.contentsOfDirectory(
        atPath: securePath.toString()
      )

      return contents.compactMap { item in
        // Skip hidden files if not requested
        if !includeHidden && item.hasPrefix(".") {
          return nil
        }

        let itemPath=path.path.hasSuffix("/") ? path.path + item : path.path + "/" + item
        let isDirectory=(try? FileManager.default.attributesOfItem(
          atPath: itemPath
        )[.type] as? FileAttributeType) == .typeDirectory

        return FilePath(path: itemPath, isDirectory: isDirectory)
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Lists the contents of a directory recursively.

   - Parameter path: The directory to list
   - Parameter includeHidden: Whether to include hidden files
   - Returns: Array of file paths for all files and directories
   - Throws: FileSystemError if the directory cannot be read
   */
  public func listDirectoryRecursive(
    at path: FilePath,
    includeHidden: Bool
  ) async throws -> [FilePath] {
    await logDebug("Listing directory recursively at \(path.path), includeHidden: \(includeHidden)")

    // Get the top-level contents
    let contents=try await listDirectory(at: path, includeHidden: includeHidden)
    var result=contents

    // Recursively process subdirectories
    for item in contents {
      if item.isDirectory {
        let subItems=try await listDirectoryRecursive(at: item, includeHidden: includeHidden)
        result.append(contentsOf: subItems)
      }
    }

    return result
  }

  /**
   Creates a file at the specified path.

   - Parameter path: The path where the file should be created
   - Parameter data: The data to write to the file
   - Parameter overwrite: Whether to overwrite an existing file
   - Throws: FileSystemError if the file cannot be created
   */
  public func createFile(
    at path: FilePath,
    data: Data,
    overwrite: Bool
  ) async throws {
    await logDebug("Creating file at \(path.path), overwrite: \(overwrite)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the file already exists
    if await filePathService.exists(securePath) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
      }

      // If it's a directory, we can't overwrite it
      if await filePathService.isDirectory(securePath) {
        throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
          path: path.path,
          expected: "file",
          actual: "directory"
        )
      }
    }

    // Create parent directories if needed
    if let parentPath=await filePathService.parentDirectory(of: securePath) {
      if await !(filePathService.exists(parentPath)) {
        try await createDirectory(
          at: FilePath(path: parentPath.toString(), isDirectory: true),
          createIntermediates: true,
          attributes: nil
        )
      }
    }

    do {
      try data.write(to: URL(fileURLWithPath: securePath.toString()), options: .atomic)
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Updates a file with new data.

   - Parameter path: The file to update
   - Parameter data: The new data to write
   - Throws: FileSystemError if the file cannot be updated
   */
  public func updateFile(
    at path: FilePath,
    data: Data
  ) async throws {
    await logDebug("Updating file at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the file exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a file
    guard await filePathService.isFile(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "file",
        actual: "directory"
      )
    }

    do {
      try data.write(to: URL(fileURLWithPath: securePath.toString()), options: .atomic)
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Gets the metadata for a file.

   - Parameter path: The file path to check
   - Parameter options: Configuration options for metadata retrieval
   - Returns: A FileMetadata object containing the file's attributes
   - Throws: FileSystemError if the metadata cannot be retrieved
   */
  public func getFileMetadata(
    at path: FilePath,
    options _: FileMetadataOptions?
  ) async throws -> FileMetadata {
    await logDebug("Getting file metadata at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    do {
      let attributes=try FileManager.default.attributesOfItem(
        atPath: securePath.toString()
      )

      // Check if it's a directory to ensure we're getting the right type of metadata
      let isDirectory=(attributes[.type] as? FileAttributeType) == .typeDirectory
      if isDirectory != path.isDirectory {
        await logDebug("Warning: Path directory flag doesn't match actual file type")
      }

      let size=attributes[.size] as? UInt64 ?? 0
      let creationDate=attributes[.creationDate] as? Date ?? Date()
      let modificationDate=attributes[.modificationDate] as? Date ?? Date()
      let accessDate=attributes[.modificationDate] as? Date
      let ownerID=(attributes[.ownerAccountID] as? NSNumber)?.uintValue ?? 0
      let groupID=(attributes[.groupOwnerAccountID] as? NSNumber)?.uintValue ?? 0
      let permissions=(attributes[.posixPermissions] as? NSNumber)?.uint16Value ?? 0

      // Convert to FileAttributes
      let fileAttributes=FileAttributes(
        size: size,
        creationDate: creationDate,
        modificationDate: modificationDate,
        accessDate: accessDate,
        ownerID: ownerID,
        groupID: groupID,
        permissions: permissions
      )

      return FileMetadata(
        path: path,
        attributes: fileAttributes,
        resourceValues: [:],
        exists: true
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path.path,
        reason: "Failed to get metadata: \(error.localizedDescription)"
      )
    }
  }

  /**
   Creates a directory at the specified path.

   - Parameter path: Path where the directory should be created
   - Parameter createIntermediates: Whether to create intermediate directories
   - Parameter attributes: Optional file attributes for the created directory
   - Throws: FileSystemError if the directory cannot be created
   */
  public func createDirectory(
    at path: FilePath,
    createIntermediates: Bool,
    attributes: FileAttributes?
  ) async throws {
    await logDebug(
      "Creating directory at \(path.path), createIntermediates: \(createIntermediates)"
    )

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the directory already exists
    if await filePathService.exists(securePath) {
      if await filePathService.isDirectory(securePath) {
        // Directory already exists, nothing to do
        return
      } else {
        // Path exists but is a file
        throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
          path: path.path,
          expected: "directory",
          actual: "file"
        )
      }
    }

    do {
      // Convert FileAttributes to Foundation attributes if needed
      var foundationAttributes: [FileAttributeKey: Any]?
      if let attrs=attributes {
        foundationAttributes=[:]
        foundationAttributes?[.creationDate]=attrs.creationDate
        foundationAttributes?[.modificationDate]=attrs.modificationDate
        if let accessDate=attrs.accessDate {
          foundationAttributes?[.modificationDate]=accessDate
        }
        if attrs.ownerID > 0 {
          foundationAttributes?[.ownerAccountID]=NSNumber(value: attrs.ownerID)
        }
        if attrs.groupID > 0 {
          foundationAttributes?[.groupOwnerAccountID]=NSNumber(value: attrs.groupID)
        }
        if attrs.permissions > 0 {
          foundationAttributes?[.posixPermissions]=NSNumber(value: attrs.permissions)
        }
      }

      try FileManager.default.createDirectory(
        atPath: securePath.toString(),
        withIntermediateDirectories: createIntermediates,
        attributes: foundationAttributes
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to create directory: \(error.localizedDescription)"
      )
    }
  }

  /**
   Deletes a file at the specified path.

   - Parameter path: The file to delete
   - Parameter secure: Whether to securely overwrite the file before deletion
   - Throws: FileSystemError if the file cannot be deleted
   */
  public func deleteFile(
    at path: FilePath,
    secure: Bool
  ) async throws {
    await logDebug("Deleting file at \(path.path), secure: \(secure)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the file exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a file
    guard await filePathService.isFile(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "file",
        actual: "directory"
      )
    }

    if secure {
      // Securely overwrite the file before deletion
      try await securelyOverwriteFile(at: path)
    }

    do {
      try FileManager.default.removeItem(atPath: securePath.toString())
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Deletes a directory and all its contents.

   - Parameter path: The directory to delete
   - Parameter secure: Whether to securely overwrite all files
   - Throws: FileSystemError if the directory cannot be deleted
   */
  public func deleteDirectory(
    at path: FilePath,
    secure: Bool
  ) async throws {
    await logDebug("Deleting directory at \(path.path), secure: \(secure)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the directory exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a directory
    guard await filePathService.isDirectory(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "directory",
        actual: "file"
      )
    }

    if secure {
      // Securely delete all files in the directory
      let contents=try await listDirectoryRecursive(
        at: path,
        includeHidden: true
      )

      for item in contents {
        if !item.isDirectory {
          try await securelyOverwriteFile(at: item)
        }
      }
    }

    do {
      try FileManager.default.removeItem(atPath: securePath.toString())
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Gets an extended attribute from a file.

   - Parameter path: The file path
   - Parameter attributeName: The name of the attribute to retrieve
   - Returns: The attribute value
   - Throws: FileSystemError if the attribute cannot be retrieved
   */
  public func getExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws -> SafeAttributeValue {
    await logDebug("Getting extended attribute \(attributeName) at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
      path: path.path,
      attribute: attributeName,
      operation: "get",
      reason: "Extended attributes not implemented in this version"
    )
  }

  /**
   Sets an extended attribute on a file.

   - Parameter path: The file path
   - Parameter attributeName: The name of the attribute to set
   - Parameter value: The attribute value to set
   - Throws: FileSystemError if the attribute cannot be set
   */
  public func setExtendedAttribute(
    at path: FilePath,
    name attributeName: String,
    value _: SafeAttributeValue
  ) async throws {
    await logDebug("Setting extended attribute \(attributeName) at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
      path: path.path,
      attribute: attributeName,
      operation: "set",
      reason: "Extended attributes not implemented in this version"
    )
  }

  /**
   Lists all extended attributes on a file.

   - Parameter path: The file path
   - Returns: Array of attribute names
   - Throws: FileSystemError if the attributes cannot be retrieved
   */
  public func listExtendedAttributes(
    at path: FilePath
  ) async throws -> [String] {
    await logDebug("Listing extended attributes at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    return []
  }

  /**
   Removes an extended attribute from a file.

   - Parameter path: The file path
   - Parameter attributeName: The name of the attribute to remove
   - Throws: FileSystemError if the attribute cannot be removed
   */
  public func removeExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws {
    await logDebug("Removing extended attribute \(attributeName) at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
      path: path.path,
      attribute: attributeName,
      operation: "remove",
      reason: "Extended attributes not implemented in this version"
    )
  }

  /**
   Moves a file or directory from one location to another.

   - Parameter sourcePath: The source path
   - Parameter destinationPath: The destination path
   - Parameter overwrite: Whether to overwrite the destination if it exists
   - Throws: FileSystemError if the move operation fails
   */
  public func moveItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool
  ) async throws {
    await logDebug(
      "Moving item from \(sourcePath.path) to \(destinationPath.path), overwrite: \(overwrite)"
    )

    guard let secureSourcePath=SecurePathAdapter.toSecurePath(sourcePath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path,
        reason: "Could not convert source path to secure path"
      )
    }

    guard let secureDestinationPath=SecurePathAdapter.toSecurePath(destinationPath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: destinationPath.path,
        reason: "Could not convert destination path to secure path"
      )
    }

    // Check if source exists
    guard await filePathService.exists(secureSourcePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    // Check if destination exists and handle overwrite
    if await filePathService.exists(secureDestinationPath) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Delete destination if overwrite is true
      try FileManager.default.removeItem(atPath: secureDestinationPath.toString())
    }

    do {
      try FileManager.default.moveItem(
        atPath: secureSourcePath.toString(),
        toPath: secureDestinationPath.toString()
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.moveError(
        source: sourcePath.path,
        destination: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Copies a file or directory from one location to another.

   - Parameter sourcePath: The source path
   - Parameter destinationPath: The destination path
   - Parameter overwrite: Whether to overwrite the destination if it exists
   - Throws: FileSystemError if the copy operation fails
   */
  public func copyItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool
  ) async throws {
    await logDebug(
      "Copying item from \(sourcePath.path) to \(destinationPath.path), overwrite: \(overwrite)"
    )

    guard let secureSourcePath=SecurePathAdapter.toSecurePath(sourcePath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: sourcePath.path,
        reason: "Could not convert source path to secure path"
      )
    }

    guard let secureDestinationPath=SecurePathAdapter.toSecurePath(destinationPath) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: destinationPath.path,
        reason: "Could not convert destination path to secure path"
      )
    }

    // Check if source exists
    guard await filePathService.exists(secureSourcePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    // Check if destination exists and handle overwrite
    if await filePathService.exists(secureDestinationPath) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Delete destination if overwrite is true
      try FileManager.default.removeItem(atPath: secureDestinationPath.toString())
    }

    do {
      try FileManager.default.copyItem(
        atPath: secureSourcePath.toString(),
        toPath: secureDestinationPath.toString()
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.copyError(
        source: sourcePath.path,
        destination: destinationPath.path,
        reason: error.localizedDescription
      )
    }
  }

  /**
   Creates a security bookmark for a file.

   - Parameter path: The file path
   - Parameter readOnly: Whether the bookmark should be read-only
   - Returns: Bookmark data
   - Throws: FileSystemError if the bookmark cannot be created
   */
  public func createSecurityBookmark(
    for path: FilePath,
    readOnly: Bool
  ) async throws -> Data {
    await logDebug("Creating security bookmark for \(path.path), readOnly: \(readOnly)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await filePathService.exists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    let url=URL(fileURLWithPath: securePath.toString(), isDirectory: path.isDirectory)

    do {
      let options: URL.BookmarkCreationOptions=readOnly ?
        [.withSecurityScope, .securityScopeAllowOnlyReadAccess] :
        [.withSecurityScope]

      return try url.bookmarkData(
        options: options,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to create bookmark: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - Helper Methods

  /**
   Securely overwrites a file with random data before deletion.

   - Parameter path: The file to overwrite
   - Throws: FileSystemError if the secure deletion fails
   */
  private func securelyOverwriteFile(at path: FilePath) async throws {
    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the file exists and is a file
    let exists=await filePathService.exists(securePath)
    let isFile=await filePathService.isFile(securePath)

    guard exists && isFile else {
      return
    }

    do {
      // Get the file size
      let attributes=try FileManager.default.attributesOfItem(atPath: securePath.toString())
      let fileSize=attributes[.size] as? UInt64 ?? 0

      if fileSize > 0 {
        // Create random data of the same size
        var randomData=Data(count: Int(fileSize))
        _=randomData.withUnsafeMutableBytes {
          SecRandomCopyBytes(kSecRandomDefault, Int(fileSize), $0.baseAddress!)
        }

        // Overwrite the file with random data
        try randomData.write(to: URL(fileURLWithPath: securePath.toString()))
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to securely overwrite file: \(error.localizedDescription)"
      )
    }
  }
}

/**
 A null logger implementation used as a default when no logger is provided.
 This avoids the need for nil checks throughout the file system services code.
 
 This implementation follows the Alpha Dot Five architecture principles by:
 1. Using actor isolation for thread safety
 2. Providing a complete implementation of the required protocol
 3. Using proper British spelling in documentation
 4. Supporting privacy-aware logging with appropriate data classification
 */
@preconcurrency
private actor NullLogger: PrivacyAwareLoggingProtocol {
  // Add loggingActor property required by LoggingProtocol
  nonisolated let loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  // Implement the required log method from CoreLoggingProtocol
  func log(_: LoggingInterfaces.LogLevel, _: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation for no-op logger
  }

  // Convenience methods with empty implementations
  func trace(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func debug(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func info(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func warning(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func error(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }

  func critical(_: String, context _: LoggingTypes.LogContextDTO) async {
    // Empty implementation
  }
  
  // Privacy-aware logging methods
  func trace(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {
    // Empty implementation
  }
  
  func debug(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {
    // Empty implementation
  }
  
  func info(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {
    // Empty implementation
  }
  
  func warning(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {
    // Empty implementation
  }
  
  func error(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {
    // Empty implementation
  }
  
  func critical(_: String, metadata _: LogMetadataDTOCollection?, source _: String) async {
    // Empty implementation
  }
  
  // Error logging with privacy controls
  func logError(_: Error, context _: LogContextDTO) async {
    // Empty implementation
  }
}
