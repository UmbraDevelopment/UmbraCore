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
 
 1. **Core File Operations** - Reading, writing, copying, moving files
 2. **Directory Operations** - Creating, listing, and managing directories
 3. **Streaming Operations** - Memory-efficient handling of large files
 4. **Extended Attributes** - Storing custom metadata with files
 5. **Path Operations** - Manipulating and normalising file paths
 6. **Temporary File Management** - Working with ephemeral files and directories
 
 ## Usage Guidelines
 
 When using this interface:
 
 - Always check operation results before proceeding with dependent operations
 - Handle permissions and security contexts appropriately
 - Consider using relative paths when possible for better portability
 - Implement proper error handling for all file operations
 - Use streaming operations for large files to minimise memory usage
 - Properly clean up temporary resources when no longer needed
 
 ## Error Handling
 
 All operations that can fail return a `Result` type that
 encapsulates either a successful result or a detailed error with context.
 Error handling should be comprehensive, as file operations may fail for
 various reasons including permissions, disk space, locking, and more.
 */

import Foundation
import FileSystemTypes

/// Type for streaming file read callback
/// When implementing a handler, return `true` to continue receiving chunks, or `false` to stop streaming.
public typealias FileReadChunkHandler = (Result<[UInt8], FileSystemError>) async -> Bool

/// Type for streaming file write callback that provides chunks of data
/// Return `nil` to signal the end of data, or a non-nil byte array to continue writing.
public typealias FileWriteChunkProvider = () async -> Result<[UInt8]?, FileSystemError>

/// Protocol defining a Foundation-independent interface for file system operations
public protocol FileSystemServiceProtocol: Sendable {
    
    // MARK: - Core File & Directory Operations
    
    /**
     Checks if a file exists at the specified path.
     
     This method verifies the existence of a file or directory at the given path.
     It does not validate permissions or validate that the path is accessible,
     only that it exists in the file system.
     
     - Parameter path: The file path to check
     - Returns: Boolean indicating whether the file exists
     
     Example:
     ```swift
     let exists = await fileSystemService.fileExists(at: FilePath(path: "/path/to/check"))
     if exists {
         // File or directory exists
     }
     ```
     */
    func fileExists(at path: FilePath) async -> Bool

    /**
     Retrieves metadata about a file or directory.
     
     This method collects information about the specified file system item,
     including its size, creation date, modification date, and type.
     
     - Parameter path: The file path to check
     - Returns: Metadata if the file exists, nil otherwise
     
     Example:
     ```swift
     if let metadata = await fileSystemService.getMetadata(at: filePath) {
         print("File size: \(metadata.size)")
         print("Modified: \(metadata.modificationDate)")
     }
     ```
     */
    func getMetadata(at path: FilePath) async -> FileSystemMetadata?

    /**
     Lists the contents of a directory.
     
     This method returns all files and directories contained within the specified directory.
     The results can be filtered to exclude hidden files if desired.
     
     - Parameters:
        - directoryPath: The directory to list contents of
        - includeHidden: Whether to include hidden files (default: false)
     - Returns: A result containing either an array of file paths or an error
     
     Example:
     ```swift
     let result = await fileSystemService.listDirectory(at: directoryPath, includeHidden: false)
     switch result {
     case .success(let files):
         // Process list of files
     case .failure(let error):
         // Handle error
     }
     ```
     */
    func listDirectory(
        at directoryPath: FilePath,
        includeHidden: Bool
    ) async -> Result<[FilePath], FileSystemError>

    /**
     Creates a directory at the specified path.
     
     This method attempts to create a new directory. If intermediate directories
     don't exist, they can optionally be created as well.
     
     - Parameters:
        - path: The directory path to create
        - withIntermediates: Whether to create intermediate directories (default: false)
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     let result = await fileSystemService.createDirectory(
         at: directoryPath,
         withIntermediates: true
     )
     if case .failure(let error) = result {
         // Handle directory creation error
     }
     ```
     */
    func createDirectory(
        at path: FilePath,
        withIntermediates: Bool
    ) async -> Result<Void, FileSystemError>

    /**
     Creates a file with the specified data.
     
     This method writes data to a file at the given path. If the file already
     exists, the overwrite parameter determines whether it will be replaced.
     
     - Parameters:
        - path: The file path to create
        - data: The data to write to the file
        - overwrite: Whether to overwrite if the file already exists (default: false)
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     let data: [UInt8] = Array("Hello, world!".utf8)
     let result = await fileSystemService.createFile(
         at: filePath,
         data: data,
         overwrite: false
     )
     ```
     */
    func createFile(
        at path: FilePath,
        data: [UInt8],
        overwrite: Bool
    ) async -> Result<Void, FileSystemError>

    /**
     Reads the contents of a file as raw bytes.
     
     This method reads the entire contents of the specified file and returns it as
     an array of bytes. For large files, consider using streaming methods instead.
     
     - Parameter path: The file path to read
     - Returns: A result containing either the file data or an error
     
     Example:
     ```swift
     let result = await fileSystemService.readFile(at: filePath)
     switch result {
     case .success(let data):
         // Process file data
     case .failure(let error):
         // Handle error
     }
     ```
     */
    func readFile(at path: FilePath) async -> Result<[UInt8], FileSystemError>

    /**
     Writes data to a file, replacing its contents if it exists.
     
     This method writes the provided data to a file. If the file already exists,
     its contents will be replaced entirely.
     
     - Parameters:
        - path: The file path to write to
        - data: The data to write to the file
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     let data: [UInt8] = Array("Updated content".utf8)
     let result = await fileSystemService.writeFile(at: filePath, data: data)
     ```
     */
    func writeFile(
        at path: FilePath,
        data: [UInt8]
    ) async -> Result<Void, FileSystemError>

    /**
     Deletes a file or directory at the specified path.
     
     This method removes the item at the given path. For directories, the recursive
     parameter determines whether its contents will also be deleted.
     
     - Parameters:
        - path: The path to delete
        - recursive: Whether to recursively delete directory contents (default: false)
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     // Delete directory and all its contents
     let result = await fileSystemService.delete(at: dirPath, recursive: true)
     ```
     */
    func delete(
        at path: FilePath,
        recursive: Bool
    ) async -> Result<Void, FileSystemError>

    /**
     Moves a file or directory from one location to another.
     
     This method relocates a file or directory. If the destination already exists,
     the operation will fail unless overwrite is true.
     
     - Parameters:
        - sourcePath: The path of the item to move
        - destinationPath: The path to move the item to
        - overwrite: Whether to overwrite the destination if it exists (default: false)
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     let result = await fileSystemService.move(
         from: sourcePath,
         to: destinationPath,
         overwrite: true
     )
     ```
     */
    func move(
        from sourcePath: FilePath,
        to destinationPath: FilePath,
        overwrite: Bool
    ) async -> Result<Void, FileSystemError>

    /**
     Copies a file or directory from one location to another.
     
     This method creates a copy of a file or directory. If the destination already exists,
     the operation will fail unless overwrite is true.
     
     - Parameters:
        - sourcePath: The path of the item to copy
        - destinationPath: The path to copy the item to
        - overwrite: Whether to overwrite the destination if it exists (default: false)
        - recursive: Whether to recursively copy directory contents (default: true)
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     let result = await fileSystemService.copy(
         from: sourceFile,
         to: destinationFile,
         overwrite: false,
         recursive: true
     )
     ```
     */
    func copy(
        from sourcePath: FilePath,
        to destinationPath: FilePath,
        overwrite: Bool,
        recursive: Bool
    ) async -> Result<Void, FileSystemError>
    
    // MARK: - Streaming Operations
    
    /**
     Reads a file in chunks and processes each chunk via a callback handler.
     
     This method is optimised for handling large files by streaming the content in
     small chunks rather than loading the entire file into memory at once.
     
     The handler should return true to continue receiving chunks, or false to stop
     the streaming process.
     
     - Parameters:
        - path: The file path to read
        - chunkSize: The size of each chunk in bytes
        - handler: An async callback that receives each chunk of data. Return true to continue streaming, false to stop.
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     // Process a large file in 64KB chunks
     let result = await fileSystemService.streamReadFile(
         at: largePath,
         chunkSize: 65536,
         handler: { chunkResult in
             switch chunkResult {
             case .success(let bytes):
                 // Process chunk of data
                 return true // Continue reading
             case .failure:
                 return false // Stop on error
             }
         }
     )
     ```
     
     This approach is ideal for large files or when performing incremental processing,
     such as parsing a file or streaming data to a network destination.
     */
    func streamReadFile(
        at path: FilePath,
        chunkSize: Int,
        handler: FileReadChunkHandler
    ) async -> Result<Void, FileSystemError>
    
    /**
     Writes data to a file in chunks supplied by a provider function.
     
     This method is optimised for handling large files without loading the entire
     content into memory. The provider function supplies chunks of data until
     it returns nil, indicating the end of the stream.
     
     - Parameters:
        - path: The file path to write to
        - overwrite: Whether to overwrite if the file already exists
        - provider: An async function that provides chunks of data. Return nil to signal the end of the data.
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     // Stream write a large file
     let result = await fileSystemService.streamWriteFile(
         at: outputPath,
         overwrite: true,
         provider: {
             if hasMoreData {
                 return .success(nextChunk) // Provide next chunk
             } else {
                 return .success(nil) // Signal end of data
             }
         }
     )
     ```
     
     This approach is ideal for generating large files incrementally or streaming
     data from a network source directly to disk.
     */
    func streamWriteFile(
        at path: FilePath,
        overwrite: Bool,
        provider: FileWriteChunkProvider
    ) async -> Result<Void, FileSystemError>
    
    // MARK: - Extended Attributes
    
    /**
     Gets the value of an extended attribute on a file or directory.
     
     Extended attributes are name:value pairs associated with filesystem objects (files, directories, 
     symlinks, etc.). They allow storing custom metadata with files without requiring a separate database.
     
     Common use cases include storing file origin information, content type, security classifications,
     or application-specific metadata.
     
     - Parameters:
        - name: The name of the extended attribute to retrieve
        - path: The path of the file or directory
     - Returns: A result containing either the attribute data or an error
     
     Example:
     ```swift
     // Get a custom attribute
     let result = await fileSystemService.getExtendedAttribute(
         name: "com.app.metadata",
         at: filePath
     )
     ```
     
     Note: Not all filesystems support extended attributes. The operation will
     fail with an appropriate error on unsupported filesystems.
     */
    func getExtendedAttribute(
        name: String,
        at path: FilePath
    ) async -> Result<[UInt8], FileSystemError>
    
    /**
     Sets an extended attribute on a file or directory.
     
     This method associates a name:value pair with the specified file. These attributes
     can be used to store application-specific metadata alongside the file.
     
     - Parameters:
        - name: The name of the extended attribute to set
        - value: The data to store in the attribute
        - path: The path of the file or directory
        - options: Options for setting the attribute (platform-specific)
     - Returns: A result indicating success or providing an error
     
     Example:
     ```swift
     // Store metadata in an extended attribute
     let metadataValue: [UInt8] = Array("Custom file metadata".utf8)
     let result = await fileSystemService.setExtendedAttribute(
         name: "com.app.metadata",
         value: metadataValue,
         at: filePath,
         options: 0
     )
     ```
     
     Common option values:
     - 0: Default behaviour
     - 2 (XATTR_CREATE): Fail if attribute already exists
     - 4 (XATTR_REPLACE): Fail if attribute doesn't exist
     */
    func setExtendedAttribute(
        name: String,
        value: [UInt8],
        at path: FilePath,
        options: Int
    ) async -> Result<Void, FileSystemError>
    
    /**
     Lists all extended attributes associated with a file or directory.
     
     This method retrieves the names of all extended attributes that have been
     set on the specified file system item.
     
     - Parameter path: The path of the file or directory
     - Returns: A result containing either an array of attribute names or an error
     
     Example:
     ```swift
     // Get all attributes on a file
     let result = await fileSystemService.listExtendedAttributes(at: filePath)
     switch result {
     case .success(let attributeNames):
         for name in attributeNames {
             // Process each attribute
         }
     case .failure(let error):
         // Handle error
     }
     ```
     */
    func listExtendedAttributes(
        at path: FilePath
    ) async -> Result<[String], FileSystemError>
    
    // MARK: - Path Operations
    
    /**
     Normalises a file path, resolving any relative components.
     
     This method processes a path to create a canonical representation by:
     - Resolving relative components like '.' and '..'
     - Removing redundant separators
     - Expanding symbolic links if requested
     
     - Parameters:
        - path: The file path to normalise
        - followSymlinks: Whether to resolve symbolic links
     - Returns: A result containing either the normalised path or an error
     
     Example:
     ```swift
     // Get canonical path with symlinks resolved
     let messyPath = FilePath(path: "project/../config/./settings/../config.json")
     let result = await fileSystemService.normalisePath(messyPath, followSymlinks: true)
     ```
     
     Normalising paths is important for comparing paths, checking permissions,
     or storing canonical references to file system items.
     */
    func normalisePath(
        _ path: FilePath,
        followSymlinks: Bool
    ) async -> Result<FilePath, FileSystemError>
    
    /**
     Resolves a relative path against a base path.
     
     This method combines a base path with a relative path to produce
     an absolute path. If the relative path is already absolute, it
     is returned unchanged.
     
     - Parameters:
        - relativePath: The relative path to resolve
        - basePath: The base path to resolve against
     - Returns: A result containing either the resolved path or an error
     
     Example:
     ```swift
     // Resolve a configuration file path relative to the app directory
     let configPath = FilePath(path: "config/settings.json")
     let appPath = FilePath(path: "/Applications/MyApp")
     let result = await fileSystemService.resolvePath(configPath, relativeTo: appPath)
     // Result would be "/Applications/MyApp/config/settings.json"
     */
    func resolvePath(
        _ relativePath: FilePath,
        relativeTo basePath: FilePath
    ) async -> Result<FilePath, FileSystemError>
    
    /**
     Splits a path into its components.
     
     This method breaks down a path into its individual components, treating
     the path separator as the delimiter between components.
     
     - Parameter path: The file path to split
     - Returns: An array of path components
     
     Example:
     ```swift
     let path = FilePath(path: "/Users/name/Documents/file.txt")
     let components = fileSystemService.pathComponents(path)
     // Results in ["", "Users", "name", "Documents", "file.txt"]
     ```
     */
    func pathComponents(_ path: FilePath) -> [String]
    
    /**
     Gets the file name component of a path.
     
     This method extracts just the file or directory name from the path,
     without the preceding directory components.
     
     - Parameter path: The file path to get the name from
     - Returns: The file or directory name
     
     Example:
     ```swift
     let path = FilePath(path: "/path/to/document.pdf")
     let name = fileSystemService.fileName(path)
     // Results in "document.pdf"
     ```
     */
    func fileName(_ path: FilePath) -> String
    
    /**
     Gets the directory component of a path.
     
     This method extracts the directory portion of a path, excluding
     the final file or directory name component.
     
     - Parameter path: The file path to get the directory from
     - Returns: The directory portion of the path
     
     Example:
     ```swift
     let path = FilePath(path: "/path/to/document.pdf")
     let directory = fileSystemService.directoryPath(path)
     // Results in FilePath(path: "/path/to")
     ```
     */
    func directoryPath(_ path: FilePath) -> FilePath
    
    /**
     Joins multiple path components together.
     
     This method combines multiple path components into a single path,
     handling the path separators appropriately.
     
     - Parameters:
        - base: The base path
        - components: Additional path components to append
     - Returns: The combined path
     
     Example:
     ```swift
     let base = FilePath(path: "/Users/name")
     let result = fileSystemService.joinPath(base, withComponents: ["Documents", "Projects", "notes.txt"])
     // Results in FilePath(path: "/Users/name/Documents/Projects/notes.txt")
     ```
     */
    func joinPath(_ base: FilePath, withComponents components: [String]) -> FilePath
    
    /**
     Determines if a path is a subpath of another path.
     
     This method checks if one path is contained within another path
     in the directory hierarchy.
     
     - Parameters:
        - path: The path to check
        - potentialParent: The potential parent path
     - Returns: True if path is a subpath of potentialParent, false otherwise
     
     Example:
     ```swift
     let subPath = FilePath(path: "/Users/name/Documents/file.txt")
     let parentPath = FilePath(path: "/Users/name")
     let isSubpath = fileSystemService.isSubpath(subPath, of: parentPath)
     // Results in true
     ```
     
     This is useful for security checks, determining if a file is within an
     allowed directory, or validating user input.
     */
    func isSubpath(
        _ path: FilePath,
        of potentialParent: FilePath
    ) -> Bool
    
    // MARK: - Temporary File Management
    
    /**
     Creates a temporary file with optional content.
     
     This method generates a secure temporary file with a unique name in the system's
     temporary directory. The file will be automatically deleted when the system
     restarts unless you move it to a permanent location.
     
     - Parameters:
        - prefix: Optional prefix for the temporary filename
        - suffix: Optional suffix/extension for the temporary filename
        - data: Optional initial data to write to the temporary file
     - Returns: A result containing either the path to the temporary file or an error
     
     Example:
     ```swift
     // Create a temporary JSON file with initial content
     let jsonData: [UInt8] = Array("{\"temp\":true}".utf8)
     let result = await fileSystemService.createTemporaryFile(
         prefix: "config-",
         suffix: ".json",
         data: jsonData
     )
     ```
     
     Temporary files are useful for:
     - Storing intermediate processing results
     - Staging content before finalising it in a permanent location
     - Sharing data between processes
     - Caching data that doesn't need to persist between application runs
     */
    func createTemporaryFile(
        prefix: String,
        suffix: String,
        data: [UInt8]?
    ) async -> Result<FilePath, FileSystemError>
    
    /**
     Creates a temporary directory.
     
     This method generates a secure temporary directory with a unique name in the system's
     temporary directory. The directory will be automatically deleted when the system
     restarts unless you move its contents to a permanent location.
     
     - Parameter prefix: Optional prefix for the temporary directory name
     - Returns: A result containing either the path to the temporary directory or an error
     
     Example:
     ```swift
     // Create a temporary directory for export operations
     let result = await fileSystemService.createTemporaryDirectory(prefix: "export-")
     ```
     
     Temporary directories are useful for:
     - Workspace for complex multi-file operations
     - Extracting archives
     - Grouping related temporary files
     - Building directory structures before finalising them
     */
    func createTemporaryDirectory(
        prefix: String
    ) async -> Result<FilePath, FileSystemError>
    
    /**
     Gets the system's temporary directory path.
     
     This method returns the path to the system-wide temporary directory
     where temporary files can be created.
     
     - Returns: The path to the system temporary directory
     
     Example:
     ```swift
     let tempDir = fileSystemService.temporaryDirectoryPath()
     ```
     */
    func temporaryDirectoryPath() -> FilePath
    
    /**
     Creates and manages a temporary file for the duration of a task.
     
     This method creates a temporary file, passes it to a task closure, and
     ensures the file is deleted when the task completes (whether successfully
     or with an error).
     
     - Parameters:
        - prefix: Optional prefix for the temporary filename
        - suffix: Optional suffix/extension for the temporary filename
        - data: Optional initial data to write to the temporary file
        - task: A closure that performs operations with the temporary file
     - Returns: The result returned by the task closure
     
     Example:
     ```swift
     // Process data in a temporary file and return a result
     let result = await fileSystemService.withTemporaryFile(
         prefix: "import-",
         suffix: ".dat",
         data: initialBytes
     ) { tempPath in
         // Process the temporary file
         return processedResult
     }
     ```
     
     This pattern ensures proper resource cleanup even in the presence of errors
     or exceptions, following the "Resource Acquisition Is Initialisation" (RAII)
     pattern common in resource management.
     */
    func withTemporaryFile<T>(
        prefix: String,
        suffix: String,
        data: [UInt8]?,
        task: (FilePath) async throws -> T
    ) async -> Result<T, Error>
    
    /**
     Creates and manages a temporary directory for the duration of a task.
     
     This method creates a temporary directory, passes it to a task closure, and
     ensures the directory and its contents are deleted when the task completes
     (whether successfully or with an error).
     
     - Parameters:
        - prefix: Optional prefix for the temporary directory name
        - task: A closure that performs operations with the temporary directory
     - Returns: The result returned by the task closure
     
     Example:
     ```swift
     // Extract and process an archive in a temporary directory
     let result = await fileSystemService.withTemporaryDirectory(prefix: "archive-") { tempDirPath in
         // Extract archive to tempDirPath
         // Process the extracted files
         return processingResult
     }
     ```
     
     Like withTemporaryFile, this ensures proper cleanup of the temporary directory
     and all its contents regardless of how the task completes.
     */
    func withTemporaryDirectory<T>(
        prefix: String,
        task: (FilePath) async throws -> T
    ) async -> Result<T, Error>
}
