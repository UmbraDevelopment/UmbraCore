import FileSystemTypes

/**
 # File System Service Protocol

 A foundation-independent interface for file system operations that provides a
 clean abstraction layer for handling files and directories in a secure manner.

 ## Actor-Based Implementation

 Implementations of this protocol MUST use Swift actors to ensure proper
 state isolation and thread safety for file system operations:

 ```swift
 actor FileSystemServiceActor: FileSystemServiceProtocol {
     // Private state should be isolated within the actor
     private let fileManager: FileManagerProtocol
     private let logger: PrivacyAwareLoggingProtocol

     // All function implementations must use 'await' appropriately when
     // accessing actor-isolated state or calling other actor methods
 }
 ```

 ## Protocol Forwarding

 To support proper protocol conformance while maintaining actor isolation,
 implementations should consider using the protocol forwarding pattern:

 ```swift
 // Public non-actor class that conforms to protocol
 public final class FileSystemService: FileSystemServiceProtocol {
     private let actor: FileSystemServiceActor

     // Forward all protocol methods to the actor
     public func createDirectory(...) async throws {
         try await actor.createDirectory(...)
     }
 }
 ```

 ## Privacy Considerations

 File system operations often involve sensitive file paths. Implementations must:
 - Use privacy-aware logging for file paths
 - Apply proper redaction to sensitive path components in logs
 - Handle permissions and access errors without revealing sensitive information
 - Implement secure deletion where appropriate

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
   Reads the contents of a file as binary data.

   - Parameter path: Path to the file to read
   - Parameter options: Configuration options for file reading
   - Returns: The file's contents as an array of bytes
   - Throws: FileSystemError if the file cannot be read
   */
  func readFile(
    at path: FilePath,
    options: FileReadOptions?
  ) async throws -> [UInt8]

  /**
   Writes binary data to a file.

   - Parameters:
     - data: The bytes to write
     - path: The file path to write to
     - options: Configuration options for file writing
   - Throws: FileSystemError if the write operation fails
   */
  func writeFile(
    _ data: [UInt8],
    to path: FilePath,
    options: FileWriteOptions?
  ) async throws

  /**
   Appends binary data to an existing file.

   - Parameters:
     - data: The bytes to append
     - path: The file path to append to
     - options: Configuration options for file appending
   - Throws: FileSystemError if the append operation fails
   */
  func appendData(
    _ data: [UInt8],
    to path: FilePath,
    options: FileWriteOptions?
  ) async throws

  /**
   Deletes a file or directory.

   - Parameter path: Path to delete
   - Parameter options: Configuration options for deletion
   - Throws: FileSystemError if the deletion fails
   */
  func delete(
    at path: FilePath,
    options: DeleteOptions?
  ) async throws

  /**
   Copies an item from one location to another.

   - Parameters:
     - sourcePath: The path to copy from
     - destinationPath: The path to copy to
     - options: Configuration options for the copy operation
   - Throws: FileSystemError if the copy operation fails
   */
  func copy(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    options: CopyOptions?
  ) async throws

  /**
   Moves an item from one location to another.

   - Parameters:
     - sourcePath: The path to move from
     - destinationPath: The path to move to
     - options: Configuration options for the move operation
   - Throws: FileSystemError if the move operation fails
   */
  func move(
    from sourcePath: FilePath,
    to destinationPath: FilePath,
    options: MoveOptions?
  ) async throws

  // MARK: - Directory Contents

  /**
   Lists the contents of a directory.

   - Parameter directoryPath: The directory to list
   - Parameter options: Configuration options for directory listing
   - Returns: An array of file paths within the directory
   - Throws: FileSystemError if the directory cannot be read
   */
  func listDirectory(
    at directoryPath: FilePath,
    options: DirectoryListOptions?
  ) async throws -> [FilePath]

  /**
   Recursively lists the contents of a directory.

   - Parameter directoryPath: The directory to list
   - Parameter options: Configuration options for recursive directory listing
   - Returns: An array of file paths within the directory and its subdirectories
   - Throws: FileSystemError if the directory cannot be read
   */
  func listDirectoryRecursively(
    at directoryPath: FilePath,
    options: RecursiveDirectoryListOptions?
  ) async throws -> [FilePath]

  // MARK: - Extended Attributes

  /**
   Sets an extended attribute on a file.

   - Parameters:
     - attribute: The attribute name
     - value: The attribute value
     - path: The file path
     - options: Configuration options for setting extended attributes
   - Throws: FileSystemError if the attribute cannot be set
   */
  func setExtendedAttribute(
    named attribute: String,
    value: [UInt8],
    for path: FilePath,
    options: ExtendedAttributeOptions?
  ) async throws

  /**
   Retrieves an extended attribute from a file.

   - Parameters:
     - attribute: The attribute name
     - path: The file path
     - options: Configuration options for getting extended attributes
   - Returns: The attribute value as binary data
   - Throws: FileSystemError if the attribute cannot be retrieved
   */
  func getExtendedAttribute(
    named attribute: String,
    for path: FilePath,
    options: ExtendedAttributeOptions?
  ) async throws -> [UInt8]

  /**
   Lists all extended attributes for a file.

   - Parameter path: The file path
   - Parameter options: Configuration options for listing extended attributes
   - Returns: An array of attribute names
   - Throws: FileSystemError if the attributes cannot be listed
   */
  func listExtendedAttributes(
    for path: FilePath,
    options: ExtendedAttributeOptions?
  ) async throws -> [String]

  /**
   Removes an extended attribute from a file.

   - Parameters:
     - attribute: The attribute name
     - path: The file path
     - options: Configuration options for removing extended attributes
   - Throws: FileSystemError if the attribute cannot be removed
   */
  func removeExtendedAttribute(
    named attribute: String,
    for path: FilePath,
    options: ExtendedAttributeOptions?
  ) async throws

  // MARK: - Path Utilities

  /**
   Determines if a path is a subpath of another path.

   This method checks if one path is contained within another path
   in the directory hierarchy.

   - Parameters:
     - path: The path to check
     - possibleParent: The potential parent path
   - Returns: True if path is a subpath of possibleParent
   */
  func isSubpath(
    _ path: FilePath,
    of possibleParent: FilePath
  ) async -> Bool

  /**
   Creates a uniquely named temporary file.

   - Parameter directory: Optional directory where the temp file should be created
   - Parameter prefix: Optional prefix for the temp file name
   - Parameter suffix: Optional suffix (extension) for the temp file name
   - Parameter options: Configuration options for temporary file creation
   - Returns: Path to the created temporary file
   - Throws: FileSystemError if the temporary file cannot be created
   */
  func createTemporaryFile(
    inDirectory directory: FilePath?,
    prefix: String?,
    suffix: String?,
    options: TemporaryFileOptions?
  ) async throws -> FilePath
}

/**
 Options for retrieving file metadata.
 */
public struct FileMetadataOptions: Sendable, Equatable {
  /// Whether to resolve symbolic links
  public let resolveSymlinks: Bool

  /// Resource keys to include in the metadata
  public let resourceKeys: Set<FileResourceKey>

  /// Creates new file metadata options
  public init(
    resolveSymlinks: Bool=true,
    resourceKeys: Set<FileResourceKey>=[]
  ) {
    self.resolveSymlinks=resolveSymlinks
    self.resourceKeys=resourceKeys
  }
}

/**
 Options for reading files.
 */
public struct FileReadOptions: Sendable, Equatable {
  /// Whether to use uncached I/O
  public let uncached: Bool

  /// Maximum buffer size for reading
  public let bufferSize: Int?

  /// Creates new file read options
  public init(
    uncached: Bool=false,
    bufferSize: Int?=nil
  ) {
    self.uncached=uncached
    self.bufferSize=bufferSize
  }
}

/**
 Options for writing to files.
 */
public struct FileWriteOptions: Sendable, Equatable {
  /// Whether to create the file if it doesn't exist
  public let createIfNeeded: Bool

  /// Whether to atomically write the file
  public let atomicWrite: Bool

  /// Whether to use uncached I/O
  public let uncached: Bool

  /// File attributes to set when creating the file
  public let attributes: FileAttributes?

  /// Creates new file write options
  public init(
    createIfNeeded: Bool=true,
    atomicWrite: Bool=false,
    uncached: Bool=false,
    attributes: FileAttributes?=nil
  ) {
    self.createIfNeeded=createIfNeeded
    self.atomicWrite=atomicWrite
    self.uncached=uncached
    self.attributes=attributes
  }
}

/**
 Options for deleting files or directories.
 */
public struct DeleteOptions: Sendable, Equatable {
  /// Whether to recursively delete directory contents
  public let recursive: Bool

  /// Whether to securely erase file contents before deletion
  public let secureErase: Bool

  /// Creates new delete options
  public init(
    recursive: Bool=false,
    secureErase: Bool=false
  ) {
    self.recursive=recursive
    self.secureErase=secureErase
  }
}

/**
 Options for copying files or directories.
 */
public struct CopyOptions: Sendable, Equatable {
  /// Whether to replace existing items at the destination
  public let replaceExisting: Bool

  /// Whether to recursively copy directory contents
  public let recursive: Bool

  /// Whether to preserve file attributes during copy
  public let preserveAttributes: Bool

  /// Creates new copy options
  public init(
    replaceExisting: Bool=false,
    recursive: Bool=false,
    preserveAttributes: Bool=true
  ) {
    self.replaceExisting=replaceExisting
    self.recursive=recursive
    self.preserveAttributes=preserveAttributes
  }
}

/**
 Options for moving files or directories.
 */
public struct MoveOptions: Sendable, Equatable {
  /// Whether to replace existing items at the destination
  public let replaceExisting: Bool

  /// Creates new move options
  public init(replaceExisting: Bool=false) {
    self.replaceExisting=replaceExisting
  }
}

/**
 Options for listing directory contents.
 */
public struct DirectoryListOptions: Sendable, Equatable {
  /// Whether to include hidden files in the listing
  public let includeHidden: Bool

  /// File types to include in the listing
  public let fileTypes: Set<FileType>?

  /// Creates new directory list options
  public init(
    includeHidden: Bool=false,
    fileTypes: Set<FileType>?=nil
  ) {
    self.includeHidden=includeHidden
    self.fileTypes=fileTypes
  }
}

/**
 Options for recursive directory listing.
 */
public struct RecursiveDirectoryListOptions: Sendable, Equatable {
  /// Whether to include hidden files in the listing
  public let includeHidden: Bool

  /// File types to include in the listing
  public let fileTypes: Set<FileType>?

  /// Maximum depth to recurse (nil for unlimited)
  public let maxDepth: Int?

  /// Creates new recursive directory list options
  public init(
    includeHidden: Bool=false,
    fileTypes: Set<FileType>?=nil,
    maxDepth: Int?=nil
  ) {
    self.includeHidden=includeHidden
    self.fileTypes=fileTypes
    self.maxDepth=maxDepth
  }
}

/**
 Options for working with extended attributes.
 */
public struct ExtendedAttributeOptions: Sendable, Equatable {
  /// Whether to follow symbolic links
  public let followSymlinks: Bool

  /// Creates new extended attribute options
  public init(followSymlinks: Bool=true) {
    self.followSymlinks=followSymlinks
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

  /// Creates new temporary file options
  public init(
    deleteOnExit: Bool=true,
    attributes: FileAttributes?=nil
  ) {
    self.deleteOnExit=deleteOnExit
    self.attributes=attributes
  }
}
