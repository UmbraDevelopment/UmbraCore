import FileSystemInterfaces
import FileSystemTypes
import Foundation
import LoggingInterfaces

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
  private let filePathService: any FilePathServiceProtocol

  /// Logger for this service
  private let logger: any LoggingProtocol

  /// Secure file operations implementation
  public let secureOperations: SecureFileOperationsProtocol

  /**
   Initialises a new secure file system service.

   - Parameters:
      - filePathService: The path service to use.
      - logger: Optional logger.
      - secureOperations: Optional secure operations service.
   */
  public init(
    filePathService: any FilePathServiceProtocol,
    logger: (any LoggingProtocol)?=nil,
    secureOperations: SecureFileOperationsProtocol?=nil
  ) {
    self.filePathService=filePathService
    self.logger=logger ?? NullLogger()
    self.secureOperations=secureOperations ?? SecureFileOperationsImpl()
  }

  // MARK: - Core File & Directory Operations

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The file path to check
   - Returns: Whether the file exists
   - Throws: FileSystemError if the existence check fails
   */
  public func fileExists(at path: FilePathDTO) async throws -> Bool {
    await logDebug("Checking if file exists at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    let exists=await fileExists(securePath)
    let isFile=await isPathFile(securePath)

    return exists && isFile
  }

  /**
   Checks if a directory exists at the specified path.

   - Parameter path: The directory path to check
   - Returns: Whether the directory exists
   - Throws: FileSystemError if the existence check fails
   */
  public func directoryExists(at path: FilePathDTO) async throws -> Bool {
    await logDebug("Checking if directory exists at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    let exists=await fileExists(securePath)
    let isDirectory=await isPathDirectory(securePath)

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
    at path: FilePathDTO,
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
      try Foundation.FileManager.default.createDirectory(
        atPath: securePath.path,
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
    at path: FilePathDTO,
    options _: DirectoryEnumerationOptions=[]
  ) async throws -> [FilePathDTO] {
    await logDebug("Listing contents of directory at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      let contents=try Foundation.FileManager.default.contentsOfDirectory(
        atPath: securePath.path
      )

      return contents.map { item in
        let itemPath=path.path.hasSuffix("/") ? path.path + item : path.path + "/" + item
        let isDirectory=(try? Foundation.FileManager.default.attributesOfItem(
          atPath: itemPath
        )[.type] as? FileAttributeType) == .typeDirectory

        return FilePathDTO(path: itemPath, isDirectory: isDirectory)
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
  public func readFile(at path: FilePathDTO) async throws -> Data {
    await logDebug("Reading file at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    do {
      return try Data(contentsOf: URL(fileURLWithPath: securePath.path))
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
    at path: FilePathDTO,
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
      try data.write(to: URL(fileURLWithPath: securePath.path))
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
  public func deleteFile(at path: FilePathDTO) async throws {
    await logDebug("Deleting file at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the file exists
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a file
    guard await isPathFile(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "file",
        actual: "directory"
      )
    }

    do {
      try Foundation.FileManager.default.removeItem(atPath: securePath.path)
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
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
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
      try Foundation.FileManager.default.moveItem(
        atPath: secureSourcePath.path,
        toPath: secureDestinationPath.path
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
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
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
      try Foundation.FileManager.default.copyItem(
        atPath: secureSourcePath.path,
        toPath: secureDestinationPath.path
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
  public func pathToURL(_ path: FilePathDTO) async throws -> URL {
    await logDebug("Converting path to URL: \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    return URL(fileURLWithPath: securePath.path, isDirectory: path.isDirectory)
  }

  /**
   Resolves a security bookmark.

   - Parameter bookmark: The bookmark data to resolve
   - Returns: A tuple containing the resolved path and whether the bookmark is stale
   - Throws: FileSystemError if the bookmark cannot be resolved
   */
  public func resolveSecurityBookmark(
    _ bookmark: Data
  ) async throws -> (FilePathDTO, Bool) {
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
      let path=FilePathDTO(path: url.path, isDirectory: isDirectory)

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
    at path: FilePathDTO
  ) async throws -> Bool {
    await logDebug("Starting access to security-scoped resource at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    let url=URL(fileURLWithPath: securePath.path)

    // Start accessing the security-scoped resource
    return url.startAccessingSecurityScopedResource()
  }

  /**
   Stops accessing a security-scoped resource.

   - Parameter path: The path to stop accessing
   */
  public func stopAccessingSecurityScopedResource(
    at path: FilePathDTO
  ) async {
    await logDebug("Stopping access to security-scoped resource at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      return
    }

    let url=URL(fileURLWithPath: securePath.path)

    // Stop accessing the security-scoped resource
    url.stopAccessingSecurityScopedResource()
  }

  /**
   Creates a temporary file.

   - Parameter options: Optional options for creating the temporary file
   - Returns: The path to the created temporary file
   - Throws: FileSystemError if the file cannot be created
   */
  public func createTemporaryFile(options: TemporaryFileOptions?) async throws -> FilePathDTO {
    await logDebug("Creating temporary file")

    // Get the temporary directory
    let tempDir=FileManager.default.temporaryDirectory

    // Generate a unique filename
    let uuid=UUID().uuidString
    let prefix=options?.prefix ?? ""
    let fileExtension=options?.fileExtension ?? ""

    let filename="\(prefix)\(uuid)\(fileExtension.isEmpty ? "" : ".\(fileExtension)")"
    let url=tempDir.appendingPathComponent(filename)

    // Create an empty file
    _=Foundation.FileManager.default.createFile(
      atPath: url.path,
      contents: nil,
      attributes: nil
    ) as Bool

    return FilePathDTO(path: url.path, isDirectory: false)
  }

  /**
   Creates a temporary directory.

   - Parameter options: Optional options for creating the temporary directory
   - Returns: The path to the created temporary directory
   - Throws: FileSystemError if the directory cannot be created
   */
  public func createTemporaryDirectory(options: TemporaryFileOptions?) async throws -> FilePathDTO {
    await logDebug("Creating temporary directory")

    // Get the temporary directory
    let tempDir=FileManager.default.temporaryDirectory

    // Generate a unique directory name
    let uuid=UUID().uuidString
    let prefix=options?.prefix ?? ""

    let dirName="\(prefix)\(uuid)"
    let url=tempDir.appendingPathComponent(dirName)

    do {
      try Foundation.FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true,
        attributes: nil
      ) as Void
    } catch {
      throw FileSystemInterfaces.FileSystemError.directoryCreationError(
        path: url.path,
        reason: error.localizedDescription
      )
    }

    return FilePathDTO(path: url.path, isDirectory: true)
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
    at path: FilePathDTO,
    includeHidden: Bool
  ) async throws -> [FilePathDTO] {
    await logDebug("Listing directory at \(path.path), includeHidden: \(includeHidden)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the directory exists
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a directory
    guard await isPathDirectory(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "directory",
        actual: "file"
      )
    }

    do {
      let contents=try Foundation.FileManager.default.contentsOfDirectory(
        atPath: securePath.path
      )

      return contents.compactMap { item in
        // Skip hidden files if not requested
        if !includeHidden && item.hasPrefix(".") {
          return nil
        }

        let itemPath=path.path.hasSuffix("/") ? path.path + item : path.path + "/" + item
        let isDirectory=(try? Foundation.FileManager.default.attributesOfItem(
          atPath: itemPath
        )[.type] as? FileAttributeType) == .typeDirectory

        return FilePathDTO(path: itemPath, isDirectory: isDirectory)
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
    at path: FilePathDTO,
    includeHidden: Bool
  ) async throws -> [FilePathDTO] {
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
    at path: FilePathDTO,
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
    if await fileExists(securePath) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path.path)
      }

      // If it's a directory, we can't overwrite it
      if await isPathDirectory(securePath) {
        throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
          path: path.path,
          expected: "file",
          actual: "directory"
        )
      }
    }

    // Create parent directories if needed
    try await ensureParentDirectoryExists(for: securePath)

    // Create an empty file
    _=Foundation.FileManager.default.createFile(
      atPath: securePath.path,
      contents: nil,
      attributes: nil
    ) as Bool

    // Write the data to the file
    do {
      try data.write(to: URL(fileURLWithPath: securePath.path), options: .atomic)
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a file
    guard await isPathFile(securePath) else {
      throw FileSystemInterfaces.FileSystemError.unexpectedItemType(
        path: path.path,
        expected: "file",
        actual: "directory"
      )
    }

    do {
      try data.write(to: URL(fileURLWithPath: securePath.path), options: .atomic)
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    do {
      let attributes=try Foundation.FileManager.default.attributesOfItem(
        atPath: securePath.path
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
    at path: FilePathDTO,
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
    if await fileExists(securePath) {
      if await isPathDirectory(securePath) {
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
        foundationAttributes=attrs.toDictionary()
      }

      try Foundation.FileManager.default.createDirectory(
        atPath: securePath.path,
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a file
    guard await isPathFile(securePath) else {
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
      try Foundation.FileManager.default.removeItem(atPath: securePath.path)
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Check if it's a directory
    guard await isPathDirectory(securePath) else {
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
      try Foundation.FileManager.default.removeItem(atPath: securePath.path)
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
      path: path.path,
      attribute: attributeName,
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
      path: path.path,
      attribute: attributeName,
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
    at path: FilePathDTO
  ) async throws -> [String] {
    await logDebug("Listing extended attributes at \(path.path)")

    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the path exists
    guard await fileExists(securePath) else {
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
    at path: FilePathDTO,
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
    guard await fileExists(securePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    // Implementation depends on platform-specific APIs
    // This is a simplified implementation
    throw FileSystemInterfaces.FileSystemError.extendedAttributeError(
      path: path.path,
      attribute: attributeName,
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
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
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
    guard await fileExists(secureSourcePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    // Check if destination exists and handle overwrite
    if await fileExists(secureDestinationPath) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Delete destination if overwrite is true
      try Foundation.FileManager.default.removeItem(atPath: secureDestinationPath.path)
    }

    do {
      try Foundation.FileManager.default.moveItem(
        atPath: secureSourcePath.path,
        toPath: secureDestinationPath.path
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
    from sourcePath: FilePathDTO,
    to destinationPath: FilePathDTO,
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
    guard await fileExists(secureSourcePath) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: sourcePath.path)
    }

    // Check if destination exists and handle overwrite
    if await fileExists(secureDestinationPath) {
      if !overwrite {
        throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: destinationPath.path)
      }

      // Delete destination if overwrite is true
      try Foundation.FileManager.default.removeItem(atPath: secureDestinationPath.path)
    }

    do {
      try Foundation.FileManager.default.copyItem(
        atPath: secureSourcePath.path,
        toPath: secureDestinationPath.path
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
    for path: FilePathDTO,
    readOnly: Bool
  ) async throws -> Data {
    await logDebug("Creating security bookmark for \(path.path), readOnly: \(readOnly)")

    guard let securePath=await filePathService.securePath(from: path) else {
      throw FileSystemInterfaces.FileSystemError.pathNotFound(path: path.path)
    }

    let url=URL(fileURLWithPath: securePath.path, isDirectory: path.isDirectory)

    do {
      let options: URL.BookmarkCreationOptions=readOnly ?
        [.securityScopeAllowOnlyReadAccess] : []

      return try url.bookmarkData(
        options: options,
        includingResourceValuesForKeys: nil as [URLResourceKey]?,
        relativeTo: nil as URL?
      )
    } catch {
      throw FileSystemInterfaces.FileSystemError.bookmarkCreationError(
        path: path.path,
        reason: error.localizedDescription
      )
    }
  }

  // MARK: - FileSystemServiceProtocol Conformance

  /**
   Gets the temporary directory path appropriate for this file system service.

   - Returns: The path to the temporary directory.
   */
  public func temporaryDirectoryPath() async -> String {
    FileManager.default.temporaryDirectory.path
  }

  /**
   Creates a unique file name in the specified directory.

   - Parameters:
      - directory: The directory in which to create the unique name.
      - prefix: Optional prefix for the file name.
      - extension: Optional file extension.
   - Returns: A unique file path.
   */
  public func createUniqueFilename(
    in directory: String,
    prefix: String?,
    extension: String?
  ) async -> String {
    let prefixToUse=prefix ?? ""
    let extensionToUse=`extension` != nil ? ".\(`extension`!)" : ""
    let uuid=UUID().uuidString
    return "\(directory)/\(prefixToUse)\(uuid)\(extensionToUse)"
  }

  /**
   Normalises a file path according to system rules.

   - Parameter path: The path to normalise.
   - Returns: The normalised path.
   */
  public func normalisePath(_ path: String) async -> String {
    (path as NSString).standardizingPath
  }

  /**
   Creates a sandboxed file system service instance that restricts
   all operations to within the specified root directory.

   - Parameter rootDirectory: The directory to restrict operations to.
   - Returns: A sandboxed file system service.
   */
  public static func createSandboxed(rootDirectory: String) -> Self {
    Self(
      filePathService: FilePathServiceFactory.shared.createSandboxed(rootDirectory: rootDirectory),
      secureOperations: SandboxedSecureFileOperations(rootDirectory: rootDirectory)
    )
  }

  // MARK: - FileReadOperationsProtocol Conformance

  /**
   Reads the contents of a file at the specified path.

   - Parameter path: The path to the file to read.
   - Returns: The file contents as Data.
   - Throws: FileSystemError if the read operation fails.
   */
  public func readFile(at path: String) async throws -> Data {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Call the FilePathDTO version of this method
    return try await readFile(at: filePath)
  }

  /**
   Reads the contents of a file at the specified path as a string.

   - Parameters:
      - path: The path to the file to read.
      - encoding: The string encoding to use for reading the file.
   - Returns: The file contents as a String.
   - Throws: FileSystemError if the read operation fails.
   */
  public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> String {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Read the file data
    let data=try await readFile(at: path)

    // Convert the data to a string
    guard let string=String(data: data, encoding: encoding) else {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Could not convert data to string with encoding \(encoding)"
      )
    }

    return string
  }

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The path to check.
   - Returns: True if the file exists, false otherwise.
   */
  public func fileExists(at path: String) async -> Bool {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Call the FilePathDTO version of this method
    do {
      return try await fileExists(at: filePath)
    } catch {
      return false
    }
  }

  /**
   Lists the contents of a directory at the specified path.

   - Parameter path: The path to the directory to list.
   - Returns: An array of file paths contained in the directory.
   - Throws: FileSystemError if the directory cannot be read.
   */
  public func listDirectory(at path: String) async throws -> [String] {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Call the core implementation that works with URLs
    let url=URL(fileURLWithPath: path, isDirectory: true)

    do {
      let contents=try FileManager.default.contentsOfDirectory(atPath: path)
      return contents.map { item in
        let itemPath=path.hasSuffix("/") ? "\(path)\(item)" : "\(path)/\(item)"
        return itemPath
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to list directory: \(error.localizedDescription)"
      )
    }
  }

  /**
   Lists the contents of a directory recursively.

   - Parameter path: The path to the directory to list.
   - Returns: An array of file paths contained in the directory and its subdirectories.
   - Throws: FileSystemError if the directory cannot be read.
   */
  public func listDirectoryRecursively(at path: String) async throws -> [String] {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Implement recursive directory listing
    var allPaths: [String]=[]

    // Get the direct contents first
    let directContents=try await listDirectory(at: path)
    allPaths.append(contentsOf: directContents)

    // Recursively process subdirectories
    for itemPath in directContents {
      var isDir: ObjCBool=false
      if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir) && isDir.boolValue {
        let subPaths=try await listDirectoryRecursively(at: itemPath)
        allPaths.append(contentsOf: subPaths)
      }
    }

    return allPaths
  }

  // MARK: - FileWriteOperationsProtocol Conformance

  /**
   Creates a new file at the specified path.

   - Parameters:
      - path: The path where the file should be created.
      - options: Optional creation options.
   - Returns: The path to the created file.
   - Throws: FileSystemError if file creation fails.
   */
  public func createFile(at path: String, options: FileCreationOptions?) async throws -> String {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Check if file exists and overwrite is not allowed
    if FileManager.default.fileExists(atPath: path) && options?.shouldOverwrite != true {
      throw FileSystemInterfaces.FileSystemError.pathAlreadyExists(path: path)
    }

    // Create parent directories if needed
    let directoryPath=(path as NSString).deletingLastPathComponent
    if !directoryPath.isEmpty && !FileManager.default.fileExists(atPath: directoryPath) {
      try FileManager.default.createDirectory(
        atPath: directoryPath,
        withIntermediateDirectories: true,
        attributes: options?.attributes?.toDictionary()
      )
    }

    // Create the file
    if
      !FileManager.default.createFile(
        atPath: path,
        contents: nil,
        attributes: options?.attributes?.toDictionary()
      )
    {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path,
        reason: "Failed to create file"
      )
    }

    return path
  }

  /**
   Writes a string to a file at the specified path.

   - Parameters:
      - string: The string content to write.
      - path: The path where the file should be written.
      - encoding: The string encoding to use.
      - options: Optional write options.
   - Throws: FileSystemError if the write operation fails.
   */
  public func writeString(
    _ string: String,
    to path: String,
    encoding: String.Encoding,
    options: FileWriteOptions?
  ) async throws {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Call the FilePathDTO version of this method
    try await writeString(string, to: filePath, encoding: encoding, options: options)
  }

  /**
   Creates a directory at the specified path.

   - Parameters:
      - path: The path where the directory should be created.
      - options: Optional creation options.
   - Returns: The path to the created directory.
   - Throws: FileSystemError if directory creation fails.
   */
  public func createDirectory(
    at path: String,
    options: DirectoryCreationOptions?
  ) async throws -> String {
    // Convert the path to a FilePathDTO
    let filePath=FilePathDTO(path: path)

    // Implement directory creation
    do {
      try FileManager.default.createDirectory(
        atPath: path,
        withIntermediateDirectories: true, // Always create intermediate directories
        attributes: options?.attributes?.toDictionary()
      )
      return path
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path,
        reason: "Failed to create directory: \(error.localizedDescription)"
      )
    }
  }

  /**
   Deletes the item at the specified path.

   - Parameter path: The path to the item to delete.
   - Throws: FileSystemError if the delete operation fails.
   */
  public func delete(at path: String) async throws {
    // Delete the item directly using FileManager
    do {
      try FileManager.default.removeItem(atPath: path)
    } catch {
      throw FileSystemInterfaces.FileSystemError.deleteError(
        path: path,
        reason: "Failed to delete item: \(error.localizedDescription)"
      )
    }
  }

  /**
   Moves an item from one path to another.

   - Parameters:
      - sourcePath: The path to the item to move.
      - destinationPath: The destination path.
      - options: Optional move options.
   - Throws: FileSystemError if the move operation fails.
   */
  public func move(
    from sourcePath: String,
    to destinationPath: String,
    options: FileMoveOptions?
  ) async throws {
    // Convert the paths to FilePathDTO
    let sourceFilePath=FilePathDTO(path: sourcePath)
    let destFilePath=FilePathDTO(path: destinationPath)

    // Call the FilePathDTO version of this method
    try await move(from: sourceFilePath, to: destFilePath, options: options)
  }

  /**
   Copies an item from one path to another.

   - Parameters:
      - sourcePath: The path to the item to copy.
      - destinationPath: The destination path.
      - options: Optional copy options.
   - Throws: FileSystemError if the copy operation fails.
   */
  public func copy(
    from sourcePath: String,
    to destinationPath: String,
    options: FileCopyOptions?
  ) async throws {
    // Convert the paths to FilePathDTO
    let sourceFilePath=FilePathDTO(path: sourcePath)
    let destFilePath=FilePathDTO(path: destinationPath)

    // Call the FilePathDTO version of this method
    try await copy(from: sourceFilePath, to: destFilePath, options: options)
  }

  /**
   Gets the attributes of a file or directory.

   - Parameter path: The path to the file or directory.
   - Returns: The file attributes.
   - Throws: FileSystemError if the attributes cannot be retrieved.
   */
  public func getAttributes(at path: String) async throws -> FileAttributes {
    // Get attributes directly from FileManager
    do {
      let attributes=try FileManager.default.attributesOfItem(atPath: path)
      return FileAttributes(attributes)
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to get attributes: \(error.localizedDescription)"
      )
    }
  }

  /**
   Sets attributes on a file or directory.

   - Parameters:
      - attributes: The attributes to set.
      - path: The path to the file or directory.
   - Throws: FileSystemError if the attributes cannot be set.
   */
  public func setAttributes(_ attributes: FileAttributes, at path: String) async throws {
    // Try to convert to Foundation attributes
    guard let foundationAttributes=attributes.toDictionary() else {
      throw FileSystemInterfaces.FileSystemError.invalidArgument(
        name: "attributes",
        value: "Could not convert to Foundation attributes"
      )
    }

    // Set attributes directly with FileManager
    do {
      try FileManager.default.setAttributes(foundationAttributes, ofItemAtPath: path)
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path,
        reason: "Failed to set attributes: \(error.localizedDescription)"
      )
    }
  }

  /**
   Gets the size of a file.

   - Parameter path: The path to the file.
   - Returns: The file size in bytes.
   - Throws: FileSystemError if the file size cannot be retrieved.
   */
  public func getFileSize(at path: String) async throws -> UInt64 {
    do {
      let attributes=try FileManager.default.attributesOfItem(atPath: path)
      if let size=attributes[.size] as? UInt64 {
        return size
      } else {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Could not determine file size"
        )
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to get file size: \(error.localizedDescription)"
      )
    }
  }

  /**
   Gets the creation date of a file or directory.

   - Parameter path: The path to the file or directory.
   - Returns: The creation date.
   - Throws: FileSystemError if the creation date cannot be retrieved.
   */
  public func getCreationDate(at path: String) async throws -> Date {
    do {
      let attributes=try FileManager.default.attributesOfItem(atPath: path)
      if let date=attributes[.creationDate] as? Date {
        return date
      } else {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Could not determine creation date"
        )
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to get creation date: \(error.localizedDescription)"
      )
    }
  }

  /**
   Gets the modification date of a file or directory.

   - Parameter path: The path to the file or directory.
   - Returns: The modification date.
   - Throws: FileSystemError if the modification date cannot be retrieved.
   */
  public func getModificationDate(at path: String) async throws -> Date {
    do {
      let attributes=try FileManager.default.attributesOfItem(atPath: path)
      if let date=attributes[.modificationDate] as? Date {
        return date
      } else {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Could not determine modification date"
        )
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to get modification date: \(error.localizedDescription)"
      )
    }
  }

  /**
   Gets an extended attribute from a file or directory.

   - Parameters:
      - name: The name of the extended attribute.
      - path: The path to the file or directory.
   - Returns: The extended attribute data.
   - Throws: FileSystemError if the extended attribute cannot be retrieved.
   */
  public func getExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws -> Data {
    // On macOS, use the dedicated xattr functions
    do {
      // Get the attribute size first
      let size=try path.withCString { pathPtr in
        name.withCString { namePtr in
          Darwin.getxattr(pathPtr, namePtr, nil, 0, 0, 0)
        }
      }

      if size < 0 {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Failed to get extended attribute size"
        )
      }

      // Now get the actual data
      var data=Data(count: size)
      let result=try data.withUnsafeMutableBytes { buffer in
        path.withCString { pathPtr in
          name.withCString { namePtr in
            Darwin.getxattr(pathPtr, namePtr, buffer.baseAddress, size, 0, 0)
          }
        }
      }

      if result < 0 {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Failed to get extended attribute data"
        )
      }

      return data
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to get extended attribute: \(error.localizedDescription)"
      )
    }
  }

  /**
   Sets an extended attribute on a file or directory.

   - Parameters:
      - data: The data to set.
      - name: The name of the extended attribute.
      - path: The path to the file or directory.
   - Throws: FileSystemError if the extended attribute cannot be set.
   */
  public func setExtendedAttribute(
    _ data: Data,
    withName name: String,
    onItemAtPath path: String
  ) async throws {
    // On macOS, use the dedicated xattr functions
    do {
      let result=try data.withUnsafeBytes { buffer in
        path.withCString { pathPtr in
          name.withCString { namePtr in
            Darwin.setxattr(pathPtr, namePtr, buffer.baseAddress, buffer.count, 0, 0)
          }
        }
      }

      if result < 0 {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: path,
          reason: "Failed to set extended attribute"
        )
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path,
        reason: "Failed to set extended attribute: \(error.localizedDescription)"
      )
    }
  }

  /**
   Lists all extended attributes on a file or directory.

   - Parameter path: The path to the file or directory.
   - Returns: An array of extended attribute names.
   - Throws: FileSystemError if the extended attributes cannot be listed.
   */
  public func listExtendedAttributes(atPath path: String) async throws -> [String] {
    // On macOS, use the dedicated xattr functions
    do {
      // Get the buffer size first
      let size=try path.withCString { pathPtr in
        Darwin.listxattr(pathPtr, nil, 0, 0)
      }

      if size < 0 {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Failed to get extended attributes list size"
        )
      }

      // Now get the actual list
      var buffer=[CChar](repeating: 0, count: size)
      let result=try path.withCString { pathPtr in
        Darwin.listxattr(pathPtr, &buffer, size, 0)
      }

      if result < 0 {
        throw FileSystemInterfaces.FileSystemError.readError(
          path: path,
          reason: "Failed to get extended attributes list"
        )
      }

      // Parse the null-terminated strings
      var attributeNames: [String]=[]
      var start=0
      for i in 0..<size {
        if buffer[i] == 0 {
          if let name=String(cString: buffer + start, encoding: .utf8) {
            attributeNames.append(name)
          }
          start=i + 1
        }
      }

      return attributeNames
    } catch {
      throw FileSystemInterfaces.FileSystemError.readError(
        path: path,
        reason: "Failed to list extended attributes: \(error.localizedDescription)"
      )
    }
  }

  /**
   Removes an extended attribute from a file or directory.

   - Parameters:
      - name: The name of the extended attribute.
      - path: The path to the file or directory.
   - Throws: FileSystemError if the extended attribute cannot be removed.
   */
  public func removeExtendedAttribute(
    withName name: String,
    fromItemAtPath path: String
  ) async throws {
    // On macOS, use the dedicated xattr functions
    do {
      let result=try path.withCString { pathPtr in
        name.withCString { namePtr in
          Darwin.removexattr(pathPtr, namePtr, 0)
        }
      }

      if result < 0 {
        throw FileSystemInterfaces.FileSystemError.writeError(
          path: path,
          reason: "Failed to remove extended attribute"
        )
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path,
        reason: "Failed to remove extended attribute: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - Private Utility Methods

  /**
   Check if a path exists in the filesystem.

   - Parameter path: The path to check
   - Returns: true if the path exists, false otherwise
   */
  private func fileExists(_ path: SecurePath) async -> Bool {
    // Use FileManager directly since the protocol method might not be available
    FileManager.default.fileExists(atPath: path.path)
  }

  /**
   Check if a path is a directory.

   - Parameter path: The path to check
   - Returns: true if the path is a directory, false otherwise
   */
  private func isPathDirectory(_ path: SecurePath) async -> Bool {
    let filePath=path.path
    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
    return exists && isDir.boolValue
  }

  /**
   Check if a path is a file.

   - Parameter path: The path to check
   - Returns: true if the path is a file, false otherwise
   */
  private func isPathFile(_ path: SecurePath) async -> Bool {
    let filePath=path.path
    var isDir: ObjCBool=false
    let exists=FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir)
    return exists && !isDir.boolValue
  }

  /**
   Securely overwrites a file with random data before deletion.

   - Parameter path: The file to overwrite
   - Throws: FileSystemError if the secure deletion fails
   */
  private func securelyOverwriteFile(at path: FilePathDTO) async throws {
    guard let securePath=SecurePathAdapter.toSecurePath(path) else {
      throw FileSystemInterfaces.FileSystemError.invalidPath(
        path: path.path,
        reason: "Could not convert to secure path"
      )
    }

    // Check if the file exists and is a file
    let exists=await fileExists(securePath)
    let isFile=await isPathFile(securePath)

    guard exists && isFile else {
      return
    }

    do {
      // Get the file size
      let attributes=try Foundation.FileManager.default.attributesOfItem(
        atPath: securePath.path
      )

      let fileSize=attributes[.size] as? UInt64 ?? 0

      if fileSize > 0 {
        // Create random data of the same size
        var randomData=Data(count: Int(fileSize))
        _=randomData.withUnsafeMutableBytes {
          SecRandomCopyBytes(kSecRandomDefault, Int(fileSize), $0.baseAddress!)
        }

        // Overwrite the file with random data
        try randomData.write(to: URL(fileURLWithPath: securePath.path))
      }
    } catch {
      throw FileSystemInterfaces.FileSystemError.writeError(
        path: path.path,
        reason: "Failed to securely overwrite file: \(error.localizedDescription)"
      )
    }
  }

  /**
   Ensures the parent directory exists for a given path.

   - Parameter securePath: The secure path to check
   - Throws: FileSystemError if the parent directory cannot be created
   */
  private func ensureParentDirectoryExists(for securePath: FilePathDTO) async throws {
    // Get the parent directory path
    let pathComponents=securePath.path.split(separator: "/")
    guard pathComponents.count > 1 else {
      // No parent directory (likely at root level)
      return
    }

    let parentPath=pathComponents.dropLast().joined(separator: "/")
    if parentPath.isEmpty {
      return
    }

    let parentFilePath=FilePathDTO(path: "/\(parentPath)", isDirectory: true)

    // Create parent directories if needed
    let exists=await fileExists(at: parentFilePath)
    if !exists {
      try await createDirectory(
        at: parentFilePath,
        createIntermediates: true,
        attributes: nil
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

  // Implement the required privacy-aware log method
  func log(
    _: LoggingInterfaces.LogLevel,
    _: PrivacyString,
    context _: LoggingTypes.LogContextDTO
  ) async {
    // Empty implementation for no-op logger
  }

  // Implement the required log sensitive method
  func logSensitive(
    _: LoggingInterfaces.LogLevel,
    _: String,
    sensitiveValues _: LoggingTypes.LogMetadata,
    context _: LoggingTypes.LogContextDTO
  ) async {
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
  func logError(
    _: Error,
    privacyLevel _: LoggingInterfaces.LogPrivacyLevel,
    context _: LoggingTypes.LogContextDTO
  ) async {
    // Empty implementation for no-op logger
  }
}
