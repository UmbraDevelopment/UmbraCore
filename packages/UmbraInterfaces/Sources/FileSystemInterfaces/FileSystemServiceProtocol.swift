import FileSystemTypes

/**
 # File System Service Protocol

 Protocol defining a cross-platform file system service that provides access
 to files, directories, and their metadata in a secure, sandbox-compliant manner
 with proper type safety.

 The service handles operations such as:
 - Creating, reading, writing, and deleting files
 - Creating and managing directories
 - Retrieving and manipulating file metadata and attributes
 - Managing security-scoped bookmarks for sandbox compliance

 All operations are designed to be thread-safe and can be used from multiple actors
 without concern for data races. Methods are asynchronous where appropriate to
 prevent blocking the caller.

 ## Error Handling

 All methods can throw FileSystemError to indicate various failure scenarios
 such as permission issues, file not found, etc. Many operations also provide
 detailed error information in the thrown error.

 ## Security Considerations

 The implementation is designed to follow best practices for security and 
 sandbox compliance as per your requirements memory. It:

 - Properly handles security-scoped bookmarks
 - Uses appropriate permission levels
 - Manages access to files correctly
 - Securely disposes of temporary resources
 - Follows principle of least privilege
 */
public protocol FileSystemServiceProtocol: Sendable {

  // MARK: - Core File & Directory Operations

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The file path to check
   - Returns: Whether the file exists
   - Throws: FileSystemError if the existence check fails
   */
  func fileExists(at path: FilePath) async throws -> Bool

  /**
   Checks if a directory exists at the specified path.

   - Parameter path: The directory path to check
   - Returns: Whether the directory exists
   - Throws: FileSystemError if the existence check fails
   */
  func directoryExists(at path: FilePath) async throws -> Bool

  /**
   Lists the contents of a directory.

   - Parameter path: The directory to list
   - Parameter includeHidden: Whether to include hidden files
   - Returns: Array of file paths for directory contents
   - Throws: FileSystemError if the directory cannot be read
   */
  func listDirectory(
    at path: FilePath,
    includeHidden: Bool
  ) async throws -> [FilePath]

  /**
   Lists the contents of a directory recursively.

   - Parameter path: The directory to list
   - Parameter includeHidden: Whether to include hidden files
   - Returns: Array of file paths for all files and directories
   - Throws: FileSystemError if the directory cannot be read
   */
  func listDirectoryRecursive(
    at path: FilePath,
    includeHidden: Bool
  ) async throws -> [FilePath]

  /**
   Creates a file at the specified path.

   - Parameter path: The path where the file should be created
   - Parameter data: The data to write to the file
   - Parameter overwrite: Whether to overwrite an existing file
   - Throws: FileSystemError if the file cannot be created
   */
  func createFile(
    at path: FilePath,
    data: Data,
    overwrite: Bool
  ) async throws

  /**
   Reads the contents of a file.

   - Parameter path: The file to read
   - Returns: The file data
   - Throws: FileSystemError if the file cannot be read
   */
  func readFile(at path: FilePath) async throws -> Data

  /**
   Updates a file with new data.

   - Parameter path: The file to update
   - Parameter data: The new data to write
   - Throws: FileSystemError if the file cannot be updated
   */
  func updateFile(
    at path: FilePath,
    data: Data
  ) async throws

  /**
   Gets the metadata for a file.

   - Parameter path: The file path to check
   - Parameter options: Configuration options for metadata retrieval
   - Returns: A FileMetadata object containing the file's attributes
   - Throws: FileSystemError if the metadata cannot be retrieved
   */
  func getFileMetadata(
    at path: FilePath,
    options: FileMetadataOptions?
  ) async throws -> FileMetadata

  /**
   Creates a directory at the specified path.

   - Parameter path: Path where the directory should be created
   - Parameter createIntermediates: Whether to create intermediate directories
   - Parameter attributes: Optional file attributes for the created directory
   - Throws: FileSystemError if the directory cannot be created
   */
  func createDirectory(
    at path: FilePath,
    createIntermediates: Bool,
    attributes: FileAttributes?
  ) async throws

  /**
   Deletes a file at the specified path.

   - Parameter path: The file to delete
   - Parameter secure: Whether to securely overwrite the file before deletion
   - Throws: FileSystemError if the file cannot be deleted
   */
  func deleteFile(
    at path: FilePath,
    secure: Bool
  ) async throws

  /**
   Deletes a directory and all its contents.

   - Parameter path: The directory to delete
   - Parameter secure: Whether to securely overwrite all files
   - Throws: FileSystemError if the directory cannot be deleted
   */
  func deleteDirectory(
    at path: FilePath,
    secure: Bool
  ) async throws

  /**
   Moves a file or directory.

   - Parameter sourcePath: The source path
   - Parameter destinationPath: The destination path
   - Parameter overwrite: Whether to overwrite the destination if it exists
   - Throws: FileSystemError if the move operation fails
   */
  func moveItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool
  ) async throws

  /**
   Copies a file or directory.

   - Parameter sourcePath: The source path
   - Parameter destinationPath: The destination path
   - Parameter overwrite: Whether to overwrite the destination if it exists
   - Throws: FileSystemError if the copy operation fails
   */
  func copyItem(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool
  ) async throws

  // MARK: - Extended Attributes

  /**
   Retrieves an extended attribute from a file.

   - Parameter path: The file to query
   - Parameter attributeName: The name of the extended attribute
   - Returns: The attribute value as a SafeAttributeValue
   - Throws: FileSystemError if the attribute cannot be retrieved
   */
  func getExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws -> SafeAttributeValue

  /**
   Sets an extended attribute on a file.

   - Parameter path: The file to modify
   - Parameter attributeName: The name of the extended attribute
   - Parameter attributeValue: The value to set
   - Throws: FileSystemError if the attribute cannot be set
   */
  func setExtendedAttribute(
    at path: FilePath,
    name attributeName: String,
    value attributeValue: SafeAttributeValue
  ) async throws

  /**
   Lists all extended attributes for a file.

   - Parameter path: The file to query
   - Returns: An array of attribute names
   - Throws: FileSystemError if the attributes cannot be retrieved
   */
  func listExtendedAttributes(
    at path: FilePath
  ) async throws -> [String]

  /**
   Removes an extended attribute from a file.

   - Parameter path: The file to modify
   - Parameter attributeName: The name of the attribute to remove
   - Throws: FileSystemError if the attribute cannot be removed
   */
  func removeExtendedAttribute(
    at path: FilePath,
    name attributeName: String
  ) async throws

  // MARK: - URL and Bookmark Operations

  /**
   Converts a file path to a URL.

   - Parameter path: The file path to convert
   - Returns: The equivalent URL
   - Throws: FileSystemError if the conversion fails
   */
  func pathToURL(_ path: FilePath) async throws -> URL

  /**
   Creates a security-scoped bookmark for a file.

   - Parameter path: The file path to bookmark
   - Parameter readOnly: Whether the bookmark should be read-only
   - Returns: The bookmark data
   - Throws: FileSystemError if the bookmark cannot be created
   */
  func createSecurityBookmark(
    for path: FilePath,
    readOnly: Bool
  ) async throws -> Data

  /**
   Resolves a security-scoped bookmark.

   - Parameter bookmark: The bookmark data
   - Returns: The resolved file path and whether the bookmark was stale
   - Throws: FileSystemError if the bookmark cannot be resolved
   */
  func resolveSecurityBookmark(
    _ bookmark: Data
  ) async throws -> (FilePath, Bool)

  /**
   Starts accessing a bookmarked resource.

   - Parameter path: The path to access
   - Returns: Whether access was granted
   - Throws: FileSystemError if access cannot be started
   */
  func startAccessingSecurityScopedResource(
    at path: FilePath
  ) async throws -> Bool

  /**
   Stops accessing a bookmarked resource.

   - Parameter path: The path to stop accessing
   */
  func stopAccessingSecurityScopedResource(
    at path: FilePath
  ) async

  // MARK: - Temporary Files

  /**
   Creates a temporary file in the system's temporary directory.

   - Parameter prefix: Optional prefix for the filename
   - Parameter suffix: Optional suffix for the filename
   - Parameter options: Configuration options for the temporary file
   - Returns: Path to the temporary file
   - Throws: FileSystemError if the temporary file cannot be created
   */
  func createTemporaryFile(
    prefix: String?,
    suffix: String?,
    options: TemporaryFileOptions?
  ) async throws -> FilePath

  /**
   Creates a temporary directory in the system's temporary directory.

   - Parameter prefix: Optional prefix for the directory name
   - Parameter options: Configuration options for the temporary directory
   - Returns: Path to the temporary directory
   - Throws: FileSystemError if the temporary directory cannot be created
   */
  func createTemporaryDirectory(
    prefix: String?,
    options: TemporaryFileOptions?
  ) async throws -> FilePath
}

/**
 Options for retrieving file metadata.
 */
public struct FileMetadataOptions: Sendable, Equatable {
  /// Whether to resolve symbolic links
  public let resolveSymlinks: Bool

  /// Resource keys to fetch
  public let resourceKeys: [FileResourceKey]

  /// Creates new file metadata options
  public init(
    resolveSymlinks: Bool = true,
    resourceKeys: [FileResourceKey] = []
  ) {
    self.resolveSymlinks = resolveSymlinks
    self.resourceKeys = resourceKeys
  }
}

/**
 Result of file system operation that returns file content.
 */
public struct FileContent: Sendable, Equatable {
  /// The file data
  public let data: Data

  /// File path
  public let path: FilePath

  /// File attributes
  public let attributes: FileAttributes?

  /// Creates a new file content result
  public init(
    data: Data,
    path: FilePath,
    attributes: FileAttributes?=nil
  ) {
    self.data = data
    self.path = path
    self.attributes = attributes
  }
}

/**
 Result of batch file read operations.
 */
public struct BatchFileReadResult: Sendable {
  /// Files that were successfully read
  public let successfulReads: [FileContent]

  /// Files that failed to read with associated errors
  public let failedReads: [FilePath: Error]

  /// Creates a new batch read result
  public init(
    successfulReads: [FileContent] = [],
    failedReads: [FilePath: Error] = [:]
  ) {
    self.successfulReads = successfulReads
    self.failedReads = failedReads
  }
}

extension BatchFileReadResult: Equatable {
  public static func == (lhs: BatchFileReadResult, rhs: BatchFileReadResult) -> Bool {
    // We can compare the successful reads directly
    guard lhs.successfulReads == rhs.successfulReads else {
      return false
    }
    
    // For error dictionaries, we compare the keys but not the Error values
    // (since Error doesn't conform to Equatable)
    guard lhs.failedReads.keys.count == rhs.failedReads.keys.count else {
      return false
    }
    
    // Check that all keys in lhs are present in rhs
    for key in lhs.failedReads.keys {
      guard rhs.failedReads[key] != nil else {
        return false
      }
    }
    
    return true
  }
}

/**
 Type of file system item.
 */
public enum FileSystemItemType: String, Sendable, Equatable, CaseIterable {
  /// Regular file
  case file

  /// Directory
  case directory

  /// Symbolic link
  case symlink

  /// Socket
  case socket

  /// Character special device
  case characterSpecial

  /// Block special device
  case blockSpecial

  /// Named pipe (FIFO)
  case fifo

  /// Unknown type
  case unknown
}

/**
 File system item entry.
 */
public struct FileSystemItem: Sendable, Equatable {
  /// Path to the item
  public let path: FilePath

  /// Type of file system item
  public let type: FileSystemItemType

  /// Attributes of the item
  public let attributes: FileAttributes?

  /// Initialize a new file system item
  public init(
    path: FilePath,
    type: FileSystemItemType,
    attributes: FileAttributes?=nil
  ) {
    self.path = path
    self.type = type
    self.attributes = attributes
  }
}

/**
 Options for creating temporary files.
 */
public struct TemporaryFileOptions: Sendable, Equatable {
  /// Whether to securely delete the file upon process exit
  public let deleteOnExit: Bool

  /// File attributes to set when creating the file
  public let attributes: FileAttributes?

  /// Initialize temporary file options
  public init(
    deleteOnExit: Bool = true,
    attributes: FileAttributes? = nil
  ) {
    self.deleteOnExit = deleteOnExit
    self.attributes = attributes
  }
}
