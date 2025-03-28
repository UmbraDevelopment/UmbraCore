import FileSystemTypes

/**
 # File System Service Protocol

 A foundation-independent interface for file system operations that provides a
 clean abstraction layer for handling files and directories in a secure manner.

 ## Purpose

 This protocol defines the essential operations needed for file manipulation
 without tying to specific implementation details or underlying frameworks.
 By using this protocol, applications can:

 - Perform common file system operations with a consistent interface
 - Swap implementations for testing or platform-specific optimisations
 - Handle errors in a structured and predictable manner
 - Maintain security boundaries through typed interfaces

 ## Key Feature Areas

 The protocol is organised into several functional areas:

 1. **Core Operations**: Reading, writing, and deleting files
 2. **Directory Management**: Creating, listing, and navigating directories
 3. **Path Manipulation**: Working with file paths and references
 4. **Extended Attributes**: Storing metadata alongside files
 5. **Temporary Files**: Creating and working with ephemeral file storage

 ## Error Handling

 This protocol uses Swift's throwing mechanism with the `FileSystemError` enum
 for consistent error handling. Each error provides specific information about
 what went wrong, enabling callers to handle failures appropriately.

 ## Thread Safety

 Implementations of this protocol should be thread-safe and handle
 concurrent access to the file system appropriately.
 */
import Foundation

public protocol FileSystemServiceProtocol: Sendable {

  // MARK: - Core File & Directory Operations

  /**
   Checks if a file exists at the specified path.

   - Parameter path: The file path to check
   - Returns: Boolean indicating whether the file exists
   */
  func fileExists(at path: FilePath) async -> Bool

  /**
   Retrieves metadata about a file or directory.

   This method collects information about size, dates, and other attributes
   of the specified file system item.

   - Parameter path: The file path to check
   - Returns: Metadata if the file exists, nil otherwise
   - Throws: `FileSystemError` if the operation fails for reasons other than non-existence
   */
  func getMetadata(at path: FilePath) async throws -> FileSystemMetadata?

  /**
   Lists the contents of a directory.

   This method returns all files and directories contained within the specified directory,
   with options to filter hidden files.

   - Parameters:
      - directoryPath: The directory to list contents of
      - includeHidden: Whether to include hidden files (default: false)
   - Returns: An array of file paths within the directory
   - Throws: `FileSystemError` if the operation fails
   */
  func listDirectory(
    at directoryPath: FilePath,
    includeHidden: Bool
  ) async throws -> [FilePath]

  /**
   Creates a directory at the specified path.

   This method attempts to create a new directory, with options to create
   any intermediate directories as needed.

   - Parameters:
      - path: The directory path to create
      - withIntermediates: Whether to create intermediate directories (default: false)
   - Throws: `FileSystemError` if the operation fails
   */
  func createDirectory(
    at path: FilePath,
    withIntermediates: Bool
  ) async throws

  /**
   Removes a file or directory at the specified path.

   This method deletes the item at the given path. For directories, the recursive
   parameter determines whether to delete contents or require an empty directory.

   - Parameters:
      - path: The path to delete
      - recursive: Whether to delete directories recursively (default: false)
   - Throws: `FileSystemError` if the operation fails
   */
  func remove(
    at path: FilePath,
    recursive: Bool
  ) async throws

  /**
   Copies an item from one path to another.

   This method copies a file or directory from the source path to the destination path,
   with options to control overwriting existing items and preserving attributes.

   - Parameters:
      - sourcePath: The source path to copy from
      - destinationPath: The destination path to copy to
      - overwrite: Whether to overwrite existing items at the destination (default: false)
      - preserveAttributes: Whether to preserve metadata and attributes (default: true)
   - Throws: `FileSystemError` if the operation fails
   */
  func copy(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool,
    preserveAttributes: Bool
  ) async throws

  /**
   Moves an item from one path to another.

   This method moves a file or directory from the source path to the destination path,
   with an option to control overwriting existing items.

   - Parameters:
      - sourcePath: The source path to move from
      - destinationPath: The destination path to move to
      - overwrite: Whether to overwrite existing items at the destination (default: false)
   - Throws: `FileSystemError` if the operation fails
   */
  func move(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    overwrite: Bool
  ) async throws

  // MARK: - File Reading & Writing

  /**
   Reads the entire contents of a file as binary data.

   This method reads all data from a file into memory. For large files,
   consider using streaming methods instead.

   - Parameter path: The file path to read from
   - Returns: The binary data from the file
   - Throws: `FileSystemError` if the operation fails
   */
  func readData(at path: FilePath) async throws -> [UInt8]

  /**
   Writes data to a file, replacing its contents if it exists.

   This method writes the provided data to a file. If the file already exists,
   its contents will be replaced entirely.

   - Parameters:
      - data: The binary data to write
      - path: The file path to write to
      - overwrite: Whether to overwrite if the file exists (default: false)
   - Throws: `FileSystemError` if the operation fails
   */
  func writeData(
    _ data: [UInt8],
    to path: FilePath,
    overwrite: Bool
  ) async throws

  /**
   Appends data to the end of a file.

   This method adds data to an existing file without replacing its current contents.
   If the file doesn't exist, it will be created.

   - Parameters:
      - data: The binary data to append
      - path: The file path to append to
   - Throws: `FileSystemError` if the operation fails
   */
  func appendData(
    _ data: [UInt8],
    to path: FilePath
  ) async throws

  /**
   Reads a file in chunks using a handler function.

   This method is optimised for large files, reading the file in chunks of the specified size
   and passing each chunk to the handler function.

   - Parameters:
      - path: The file path to read from
      - chunkSize: The size of each chunk to read (in bytes)
      - handler: A closure that receives each chunk of data
   - Throws: `FileSystemError` if the operation fails
   */
  func readDataInChunks(
    at path: FilePath,
    chunkSize: Int,
    handler: @Sendable ([UInt8]) async throws -> Void
  ) async throws

  /**
   Writes data to a file in chunks supplied by a provider function.

   This method is optimised for handling large files without loading the entire
   content into memory. The provider function supplies chunks of data until
   it returns nil, signaling the end of data.

   - Parameters:
      - path: The file path to write to
      - overwrite: Whether to overwrite if the file exists (default: false)
      - chunkProvider: A closure that provides chunks of data, returning nil when done
   - Throws: `FileSystemError` if the operation fails
   */
  func writeDataInChunks(
    to path: FilePath,
    overwrite: Bool,
    chunkProvider: @Sendable () async throws -> [UInt8]?
  ) async throws

  // MARK: - Extended Attributes

  /**
   Sets an extended attribute on a file or directory.

   This method associates a name:value pair with the specified file. These attributes
   can be used to store application-specific metadata alongside the file.

   - Parameters:
      - name: The attribute name
      - value: The attribute value as binary data
      - path: The path of the file or directory
   - Throws: `FileSystemError` if the operation fails
   */
  func setExtendedAttribute(
    name: String,
    value: [UInt8],
    at path: FilePath
  ) async throws

  /**
   Gets an extended attribute from a file or directory.

   This method retrieves the value of a named attribute associated with the file.

   - Parameters:
      - name: The attribute name
      - path: The path of the file or directory
   - Returns: The attribute value as binary data
   - Throws: `FileSystemError` if the operation fails or attribute doesn't exist
   */
  func getExtendedAttribute(
    name: String,
    at path: FilePath
  ) async throws -> [UInt8]

  /**
   Removes an extended attribute from a file or directory.

   This method deletes a named attribute from the specified file.

   - Parameters:
      - name: The attribute name to remove
      - path: The path of the file or directory
   - Throws: `FileSystemError` if the operation fails
   */
  func removeExtendedAttribute(
    name: String,
    at path: FilePath
  ) async throws

  /**
   Lists all extended attributes on a file or directory.

   This method returns the names of all attributes associated with the specified file.

   - Parameter path: The path of the file or directory
   - Returns: An array of attribute names
   - Throws: `FileSystemError` if the operation fails
   */
  func listExtendedAttributes(
    at path: FilePath
  ) async throws -> [String]

  // MARK: - Path Manipulation

  /**
   Normalises a file path, resolving any relative components.

   This method processes a path to create a canonical representation by:
   - Resolving relative components like '.' and '..'
   - Removing duplicate separators
   - Handling other platform-specific normalisations

   - Parameter path: The path to normalise
   - Returns: A normalised path
   - Throws: `FileSystemError` if the path is invalid or cannot be normalised
   */
  func normalisePath(_ path: FilePath) async throws -> FilePath

  /**
   Extracts the file name component from a path.

   This method returns just the final component of a path, without any directory information.

   - Parameter path: The path to extract from
   - Returns: The file name component
   */
  func fileName(_ path: FilePath) -> String

  /**
   Extracts the directory component from a path.

   This method returns the directory portion of a path, removing the final file name component.

   - Parameter path: The path to extract from
   - Returns: The directory component
   */
  func directoryPath(_ path: FilePath) -> FilePath

  /**
   Joins path components together.

   This method combines multiple path components into a single path,
   handling separator insertion appropriately.

   - Parameters:
      - base: The base path to start with
      - components: Additional path components to append
   - Returns: The combined path
   */
  func joinPath(_ base: FilePath, withComponents components: [String]) -> FilePath

  /**
   Determines if a path is a subpath of another path.

   This method checks if one path is contained within another path
   in the directory hierarchy.

   - Parameters:
      - path: The path to check
      - directory: The potential parent directory
   - Returns: True if path is a subpath of directory
   */
  func isSubpath(
    _ path: FilePath,
    of directory: FilePath
  ) -> Bool

  // MARK: - Temporary Files

  /**
   Creates a temporary directory.

   This method creates a directory in the system's temporary location
   that will be automatically cleaned up when the app terminates.

   - Parameters:
      - prefix: A prefix for the directory name
   - Returns: The path to the created temporary directory
   - Throws: `FileSystemError` if the operation fails
   */
  func createTemporaryDirectory(
    prefix: String
  ) async throws -> FilePath

  /**
   Creates a temporary file.

   This method creates a file in the system's temporary location
   that will be automatically cleaned up when the app terminates.

   - Parameters:
      - prefix: A prefix for the file name
      - suffix: A suffix for the file name (e.g., file extension)
      - data: Optional data to write to the file
   - Returns: The path to the created temporary file
   - Throws: `FileSystemError` if the operation fails
   */
  func createTemporaryFile(
    prefix: String,
    suffix: String,
    data: [UInt8]?
  ) async throws -> FilePath

  /**
   Executes an operation with a temporary file and cleans up afterward.

   This method creates a temporary file, passes it to the provided task,
   and ensures the file is deleted when the task completes.

   - Parameters:
      - prefix: A prefix for the file name
      - suffix: A suffix for the file name (e.g., file extension)
      - data: Optional data to write to the file
      - task: A closure that performs operations on the temporary file
   - Returns: The result of the task closure
   - Throws: `FileSystemError` if file operations fail, or rethrows errors from the task
   */
  func withTemporaryFile<T>(
    prefix: String,
    suffix: String,
    data: [UInt8]?,
    task: (FilePath) async throws -> T
  ) async throws -> T

  /**
   Executes an operation with a temporary directory and cleans up afterward.

   This method creates a temporary directory, passes it to the provided task,
   and ensures the directory is deleted when the task completes.

   - Parameters:
      - prefix: A prefix for the directory name
      - task: A closure that performs operations with the temporary directory
   - Returns: The result of the task closure
   - Throws: `FileSystemError` if directory operations fail, or rethrows errors from the task
   */
  func withTemporaryDirectory<T>(
    prefix: String,
    task: (FilePath) async throws -> T
  ) async throws -> T
}
