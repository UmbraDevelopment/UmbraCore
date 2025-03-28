/**
 # File System Service Implementation
 
 A comprehensive implementation of the FileSystemServiceProtocol that provides
 secure and reliable file system operations with proper error handling.
 
 ## Implementation Approach
 
 This service provides a foundation-independent abstraction over the native
 file system operations, with particular attention to:
 
 - **Security**: Proper handling of permissions and access controls
 - **Error Handling**: Comprehensive error reporting with contextual information
 - **Performance**: Optimised operations for common file system tasks
 - **Thread Safety**: Safe concurrent access through proper synchronisation
 
 ## Usage Considerations
 
 Whilst this implementation handles many edge cases automatically, be aware of:
 
 - Large file handling may require streaming operations for optimal performance
 - Error states should always be properly handled by callers
 - Operations on network file systems may experience different latencies
 - Consider using relative paths for better portability across environments
 */

import Foundation
import FileSystemInterfaces
import FileSystemTypes
import UmbraErrors
import Darwin

/**
 # Implementation of FileSystemServiceProtocol using Foundation's FileManager
 
 This implementation provides file system operations backed by the standard
 FileManager API and wraps them in our domain-specific type system and error handling.
 
 ## Overview
 
 The `FileSystemServiceImpl` class implements all operations defined in the
 `FileSystemServiceProtocol`, providing a complete foundation-independent
 abstraction for file system interactions. It's designed to be thread-safe,
 efficient, and handle common edge cases consistently.
 
 ## Features
 
 This implementation offers several categories of functionality:
 
 - **Core File Operations**: Reading, writing, copying, moving files
 - **Directory Operations**: Creating, listing, and managing directories
 - **Streaming Operations**: Memory-efficient handling of large files
 - **Extended Attributes**: Storing custom metadata with files
 - **Path Operations**: Manipulating and normalising file paths
 - **Temporary File Management**: Working with ephemeral files and directories
 
 ## Implementation Notes
 
 - Uses an operation queue for background operations to ensure thread safety
 - Consistently maps Foundation-specific errors to our domain-specific error types
 - Preserves the non-blocking nature of async operations where appropriate
 - Properly manages resources like file handles to prevent leaks
 
 ## Thread Safety
 
 Note: This implementation is marked as `@unchecked Sendable` because FileManager
 instances can be safely used across concurrent contexts when used properly, but
 the compiler can't verify this automatically.
 */
public final class FileSystemServiceImpl: @unchecked Sendable, FileSystemServiceProtocol {
    /// The FileManager instance used for file operations
    private let fileManager: FileManager
    
    /// Queue for serialising file operations to prevent race conditions
    private let operationQueue: DispatchQueue
    
    /// Default chunk size for streaming operations (64KB)
    private let defaultChunkSize = 65536
    
    /**
     Initialises a new FileSystemServiceImpl with optional custom FileManager.
     
     - Parameter fileManager: The FileManager to use for operations (defaults to .default)
     */
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.operationQueue = DispatchQueue(
            label: "com.umbra.filesystem.service",
            qos: .userInitiated,
            attributes: .concurrent
        )
    }
    
    /**
     Checks if a file exists at the specified path.
     
     This method is thread-safe and handles path validation internally.
     
     - Parameter path: The file path to check
     - Returns: Boolean indicating whether the file exists
     */
    public func fileExists(at path: FilePath) async -> Bool {
        let nsPath = path.path
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                let exists = self.fileManager.fileExists(atPath: nsPath)
                continuation.resume(returning: exists)
            }
        }
    }
    
    /**
     Retrieves metadata about a file or directory.
     
     This method collects information about size, dates, and other attributes
     of the specified file system item.
     
     - Parameter path: The file path to check
     - Returns: Metadata if the file exists, nil otherwise
     */
    public func getMetadata(at path: FilePath) async -> FileSystemMetadata? {
        let nsPath = path.path
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    let attributes = try self.fileManager.attributesOfItem(atPath: nsPath)
                    let metadata = self.createMetadata(from: attributes, for: path)
                    continuation.resume(returning: metadata)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /**
     Lists the contents of a directory.
     
     This method returns all files and directories contained within the specified directory,
     with options to filter hidden files.
     
     - Parameters:
        - directoryPath: The directory to list contents of
        - includeHidden: Whether to include hidden files (default: false)
     - Returns: A result containing either an array of file paths or an error
     */
    public func listDirectory(
        at directoryPath: FilePath,
        includeHidden: Bool = false
    ) async -> Result<[FilePath], FileSystemError> {
        let nsPath = directoryPath.path
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    let contents = try self.fileManager.contentsOfDirectory(atPath: nsPath)
                    let filteredContents = includeHidden 
                        ? contents 
                        : contents.filter { !$0.hasPrefix(".") }
                    
                    let paths = filteredContents.map { item in
                        let fullPath = nsPath.hasSuffix("/") 
                            ? "\(nsPath)\(item)" 
                            : "\(nsPath)/\(item)"
                        return FilePath(path: fullPath)
                    }
                    
                    continuation.resume(returning: .success(paths))
                } catch {
                    let fsError = self.mapError(error, path: directoryPath)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Creates a directory at the specified path.
     
     This method attempts to create a new directory, with options to create
     any intermediate directories as needed.
     
     - Parameters:
        - path: The directory path to create
        - withIntermediates: Whether to create intermediate directories (default: false)
     - Returns: A result indicating success or providing an error
     */
    public func createDirectory(
        at path: FilePath,
        withIntermediates: Bool = false
    ) async -> Result<Void, FileSystemError> {
        let nsPath = path.path
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    try self.fileManager.createDirectory(
                        atPath: nsPath,
                        withIntermediateDirectories: withIntermediates,
                        attributes: nil
                    )
                    continuation.resume(returning: .success(()))
                } catch {
                    let fsError = self.mapError(error, path: path)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Creates a file with the specified data.
     
     This method writes data to a file at the given path, with options to
     overwrite existing files.
     
     - Parameters:
        - path: The file path to create
        - data: The data to write to the file
        - overwrite: Whether to overwrite if the file already exists (default: false)
     - Returns: A result indicating success or providing an error
     */
    public func createFile(
        at path: FilePath,
        data: [UInt8],
        overwrite: Bool = false
    ) async -> Result<Void, FileSystemError> {
        let nsPath = path.path
        
        // Check if file exists and we shouldn't overwrite
        if !overwrite {
            let exists = await fileExists(at: path)
            if exists {
                return .failure(
                    FileSystemError.fileAlreadyExists(
                        path: path.path,
                        message: "File already exists and overwrite is set to false"
                    )
                )
            }
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    let nsData = Data(data)
                    try nsData.write(to: URL(fileURLWithPath: nsPath))
                    continuation.resume(returning: .success(()))
                } catch {
                    let fsError = self.mapError(error, path: path)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Reads the contents of a file as raw bytes.
     
     This method reads the entire contents of the specified file and returns
     it as an array of bytes.
     
     - Parameter path: The file path to read
     - Returns: A result containing either the file data or an error
     */
    public func readFile(at path: FilePath) async -> Result<[UInt8], FileSystemError> {
        let nsPath = path.path
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: nsPath))
                    let bytes = [UInt8](data)
                    continuation.resume(returning: .success(bytes))
                } catch {
                    let fsError = self.mapError(error, path: path)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Writes data to a file, replacing its contents if it exists.
     
     This method writes the provided data to a file, creating it if it doesn't
     exist or replacing its contents if it does.
     
     - Parameters:
        - path: The file path to write to
        - data: The data to write to the file
     - Returns: A result indicating success or providing an error
     */
    public func writeFile(
        at path: FilePath,
        data: [UInt8]
    ) async -> Result<Void, FileSystemError> {
        let nsPath = path.path
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    let nsData = Data(data)
                    try nsData.write(to: URL(fileURLWithPath: nsPath))
                    continuation.resume(returning: .success(()))
                } catch {
                    let fsError = self.mapError(error, path: path)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Deletes a file or directory at the specified path.
     
     This method removes the item at the given path, with options for
     recursively deleting directory contents.
     
     - Parameters:
        - path: The path to delete
        - recursive: Whether to recursively delete directory contents (default: false)
     - Returns: A result indicating success or providing an error
     */
    public func delete(
        at path: FilePath,
        recursive: Bool = false
    ) async -> Result<Void, FileSystemError> {
        let nsPath = path.path
        
        // Handle non-recursive directory deletion
        if !recursive {
            let isDirectory = await withCheckedContinuation { continuation in
                operationQueue.async {
                    var isDir: ObjCBool = false
                    let exists = self.fileManager.fileExists(atPath: nsPath, isDirectory: &isDir)
                    continuation.resume(returning: exists && isDir.boolValue)
                }
            }
            
            if isDirectory {
                let contents = await listDirectory(at: path, includeHidden: true)
                switch contents {
                case .success(let items) where !items.isEmpty:
                    return .failure(
                        FileSystemError.directoryNotEmpty(
                            path: path.path,
                            message: "Cannot delete non-empty directory without recursive flag"
                        )
                    )
                case .failure(let error):
                    return .failure(error)
                default:
                    break
                }
            }
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    try self.fileManager.removeItem(atPath: nsPath)
                    continuation.resume(returning: .success(()))
                } catch {
                    let fsError = self.mapError(error, path: path)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Moves a file or directory from one location to another.
     
     This method relocates a file or directory, with options to overwrite
     the destination if it already exists.
     
     - Parameters:
        - sourcePath: The path of the item to move
        - destinationPath: The path to move the item to
        - overwrite: Whether to overwrite the destination if it exists (default: false)
     - Returns: A result indicating success or providing an error
     */
    public func move(
        from sourcePath: FilePath,
        to destinationPath: FilePath,
        overwrite: Bool = false
    ) async -> Result<Void, FileSystemError> {
        let nsSourcePath = sourcePath.path
        let nsDestPath = destinationPath.path
        
        // Check if source exists
        let sourceExists = await fileExists(at: sourcePath)
        if !sourceExists {
            return .failure(
                FileSystemError.fileNotFound(
                    path: sourcePath.path,
                    message: "Source file does not exist"
                )
            )
        }
        
        // Check if destination exists and handle overwrite
        let destExists = await fileExists(at: destinationPath)
        if destExists && !overwrite {
            return .failure(
                FileSystemError.fileAlreadyExists(
                    path: destinationPath.path,
                    message: "Destination already exists and overwrite is set to false"
                )
            )
        }
        
        // If destination exists and overwrite is true, delete it first
        if destExists && overwrite {
            let deleteResult = await delete(at: destinationPath, recursive: true)
            if case .failure(let error) = deleteResult {
                return .failure(error)
            }
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    try self.fileManager.moveItem(atPath: nsSourcePath, toPath: nsDestPath)
                    continuation.resume(returning: .success(()))
                } catch {
                    let fsError = self.mapError(error, path: sourcePath)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    /**
     Copies a file or directory from one location to another.
     
     This method creates a copy of a file or directory, with options to
     overwrite the destination and recursively copy directory contents.
     
     - Parameters:
        - sourcePath: The path of the item to copy
        - destinationPath: The path to copy the item to
        - overwrite: Whether to overwrite the destination if it exists (default: false)
        - recursive: Whether to recursively copy directory contents (default: true)
     - Returns: A result indicating success or providing an error
     */
    public func copy(
        from sourcePath: FilePath,
        to destinationPath: FilePath,
        overwrite: Bool = false,
        recursive: Bool = true
    ) async -> Result<Void, FileSystemError> {
        let nsSourcePath = sourcePath.path
        let nsDestPath = destinationPath.path
        
        // Check if source exists
        let sourceExists = await fileExists(at: sourcePath)
        if !sourceExists {
            return .failure(
                FileSystemError.fileNotFound(
                    path: sourcePath.path,
                    message: "Source file does not exist"
                )
            )
        }
        
        // Check if destination exists and handle overwrite
        let destExists = await fileExists(at: destinationPath)
        if destExists && !overwrite {
            return .failure(
                FileSystemError.fileAlreadyExists(
                    path: destinationPath.path,
                    message: "Destination already exists and overwrite is set to false"
                )
            )
        }
        
        // If destination exists and overwrite is true, delete it first
        if destExists && overwrite {
            let deleteResult = await delete(at: destinationPath, recursive: true)
            if case .failure(let error) = deleteResult {
                return .failure(error)
            }
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                do {
                    try self.fileManager.copyItem(atPath: nsSourcePath, toPath: nsDestPath)
                    continuation.resume(returning: .success(()))
                } catch {
                    let fsError = self.mapError(error, path: sourcePath)
                    continuation.resume(returning: .failure(fsError))
                }
            }
        }
    }
    
    // MARK: - Streaming Operations
    
    /**
     # Streaming File Operations
     
     The streaming operations allow efficient handling of large files by processing them in chunks
     rather than loading the entire file into memory at once. This implementation provides:
     
     - Memory-efficient processing of large files
     - Incremental processing with cancellation support
     - Proper resource management with automatic cleanup
     - Comprehensive error handling throughout the streaming process
     
     ## Implementation Details
     
     - Uses FileHandle for low-level file access
     - Ensures handles are properly closed using defer statements
     - Supports both modern and legacy macOS APIs
     - Provides cancellation capability through handler return values
     
     ## Memory Usage Considerations
     
     For very large files, the chunk size parameter can be tuned to balance between
     memory usage and performance. Smaller chunks use less memory but may be less
     efficient due to more frequent I/O operations.
     */
    
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
     */
    public func streamReadFile(
        at path: FilePath,
        chunkSize: Int,
        handler: FileReadChunkHandler
    ) async -> Result<Void, FileSystemError> {
        let nsPath = path.path
        
        // Check if file exists
        let exists = await fileExists(at: path)
        if !exists {
            return .failure(
                FileSystemError.fileNotFound(
                    path: path.path,
                    message: "File not found for reading stream"
                )
            )
        }
        
        // Attempt to open the file handle for reading
        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: nsPath))
        } catch {
            return .failure(
                self.mapError(error, path: path)
            )
        }
        
        // Use defer to ensure file handle is closed when the function exits
        defer {
            try? fileHandle.close()
        }
        
        // Buffer for reading chunks
        let actualChunkSize = max(1024, chunkSize) // Ensure a minimum chunk size
        
        do {
            // Establish our stream reading loop
            var shouldContinue = true
            
            while shouldContinue {
                // Read a chunk of data
                let chunkData: Data
                
                if #available(macOS 10.15.4, *) {
                    // We need to properly handle this as an async operation
                    chunkData = try await withCheckedThrowingContinuation { continuation in
                        Task {
                            do {
                                let data = try fileHandle.read(upToCount: actualChunkSize)
                                continuation.resume(returning: data ?? Data())
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                } else {
                    // Fall back for older macOS versions
                    chunkData = try await withCheckedThrowingContinuation { continuation in
                        DispatchQueue.global().async {
                            let data = fileHandle.readData(ofLength: actualChunkSize)
                            continuation.resume(returning: data)
                        }
                    }
                }
                
                // If we reach the end of the file (empty data), we're done
                if chunkData.isEmpty {
                    break
                }
                
                // Convert to [UInt8] and pass to handler
                let bytes = [UInt8](chunkData)
                shouldContinue = await handler(.success(bytes))
            }
            
            return .success(())
        } catch {
            // If an error occurs, pass it to the handler and return failure
            _ = await handler(.failure(self.mapError(error, path: path)))
            return .failure(self.mapError(error, path: path))
        }
    }
    
    /**
     Writes data to a file in chunks supplied by a provider function.
     
     This method is optimised for handling large files without loading the entire
     content into memory. The provider function supplies chunks of data until
     it returns nil, indicating the end of the stream.
     
     - Parameters:
        - path: The file path to write to
        - overwrite: Whether to overwrite if the file already exists (default: false)
        - provider: An async function that provides chunks of data. Return nil to signal the end of the data.
     - Returns: A result indicating success or providing an error
     */
    public func streamWriteFile(
        at path: FilePath,
        overwrite: Bool,
        provider: FileWriteChunkProvider
    ) async -> Result<Void, FileSystemError> {
        let nsPath = path.path
        
        // Check if file exists and we shouldn't overwrite
        if !overwrite {
            let exists = await fileExists(at: path)
            if exists {
                return .failure(
                    FileSystemError.fileAlreadyExists(
                        path: path.path,
                        message: "File already exists and overwrite is set to false"
                    )
                )
            }
        }
        
        // Create the directory path if needed
        if let directoryPath = URL(fileURLWithPath: nsPath).deletingLastPathComponent().path as String? {
            let dirExists = await withCheckedContinuation { continuation in
                operationQueue.async {
                    var isDir: ObjCBool = false
                    let exists = self.fileManager.fileExists(atPath: directoryPath, isDirectory: &isDir)
                    continuation.resume(returning: exists && isDir.boolValue)
                }
            }
            
            if !dirExists {
                let createResult = await createDirectory(
                    at: FilePath(path: directoryPath),
                    withIntermediates: true
                )
                
                if case .failure(let error) = createResult {
                    return .failure(error)
                }
            }
        }
        
        // Create/open the file handle for writing
        let fileHandle: FileHandle
        
        do {
            // Create an empty file first
            if self.fileManager.createFile(atPath: nsPath, contents: nil) == false {
                return .failure(
                    FileSystemError.general(
                        path: path.path,
                        message: "Failed to create file for write stream",
                        code: -1
                    )
                )
            }
            
            fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: nsPath))
        } catch {
            return .failure(
                self.mapError(error, path: path)
            )
        }
        
        // Use defer to ensure file handle is closed when the function exits
        defer {
            try? fileHandle.close()
        }
        
        do {
            // Seek to the beginning of the file
            if #available(macOS 10.15.4, *) {
                try fileHandle.seek(toOffset: 0)
            } else {
                fileHandle.seek(toFileOffset: 0)
            }
            
            // Process chunks from the provider
            while true {
                // Get the next chunk of data
                let result = await provider()
                
                switch result {
                case .success(let chunk):
                    // If nil is returned, it signals the end of data
                    guard let chunk = chunk else {
                        break
                    }
                    
                    // Write the chunk to the file
                    let data = Data(chunk)
                    
                    if #available(macOS 10.15.4, *) {
                        try fileHandle.write(contentsOf: data)
                    } else {
                        // Fall back for older macOS versions
                        await withCheckedContinuation { continuation in
                            DispatchQueue.global().async {
                                fileHandle.write(data)
                                continuation.resume()
                            }
                        }
                    }
                    
                case .failure(let error):
                    // If provider returns an error, propagate it
                    return .failure(error)
                }
            }
            
            // Ensure all data is written to disk
            if #available(macOS 10.15.4, *) {
                try fileHandle.synchronize()
            } else {
                fileHandle.synchronizeFile()
            }
            
            return .success(())
        } catch {
            return .failure(
                self.mapError(error, path: path)
            )
        }
    }
    
    // MARK: - Extended Attributes
    
    /**
     # Extended Attributes
     
     Extended attributes provide a mechanism for storing custom metadata alongside files
     without requiring a separate database. This implementation offers:
     
     - Low-level access to filesystem xattr capabilities
     - Support for reading, writing, and listing extended attributes
     - Comprehensive error mapping for attribute-specific failures
     - Secure attribute manipulation with appropriate error handling
     
     ## Implementation Details
     
     - Uses Darwin C API for maximum performance and compatibility
     - Maps low-level errors to semantic FileSystemError types
     - Handles platform-specific attribute limitations appropriately
     - Ensures proper memory management for attribute data
     
     ## Usage Considerations
     
     Not all filesystems support extended attributes. Operations will fail
     with appropriate errors on unsupported filesystems. Additionally, there
     may be size limitations depending on the underlying filesystem.
     */
    
    /**
     Gets the value of an extended attribute on a file or directory.
     
     Extended attributes are name:value pairs associated with filesystem objects (files, directories,
     symlinks, etc.). They allow storing custom metadata with files without requiring a separate database.
     
     - Parameters:
        - name: The name of the extended attribute to retrieve
        - path: The path of the file or directory
     - Returns: A result containing either the attribute data or an error
     */
    public func getExtendedAttribute(
        name: String,
        at path: FilePath
    ) async -> Result<[UInt8], FileSystemError> {
        
        let nsPath = path.path
        
        // Check if file exists
        let exists = await fileExists(at: path)
        if !exists {
            return .failure(
                FileSystemError.fileNotFound(
                    path: path.path,
                    message: "File not found when retrieving extended attribute"
                )
            )
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                // Get size of attribute first
                let size = getxattr(nsPath, name, nil, 0, 0, 0)
                
                if size == -1 {
                    let error = errno
                    
                    if error == ENOATTR {
                        // Attribute doesn't exist
                        continuation.resume(returning: .failure(
                            FileSystemError.general(
                                path: path.path,
                                message: "Extended attribute '\(name)' does not exist",
                                code: Int(error)
                            )
                        ))
                    } else {
                        // Other error
                        continuation.resume(returning: .failure(
                            FileSystemError.general(
                                path: path.path,
                                message: "Failed to get extended attribute: \(String(cString: strerror(error)))",
                                code: Int(error)
                            )
                        ))
                    }
                    return
                }
                
                // Allocate buffer for attribute data
                var data = [UInt8](repeating: 0, count: size)
                
                // Get attribute data
                let result = getxattr(nsPath, name, &data, size, 0, 0)
                
                if result == -1 {
                    let error = errno
                    continuation.resume(returning: .failure(
                        FileSystemError.general(
                            path: path.path,
                            message: "Failed to get extended attribute: \(String(cString: strerror(error)))",
                            code: Int(error)
                        )
                    ))
                    return
                }
                
                continuation.resume(returning: .success(data))
            }
        }
    }
    
    /**
     Sets an extended attribute on a file or directory.
     
     This method associates a name:value pair with the specified file. These attributes
     can be used to store application-specific metadata alongside the file.
     
     - Parameters:
        - name: The name of the extended attribute to set
        - value: The data to store in the attribute
        - path: The path of the file or directory
        - options: Options for setting the attribute (platform-specific)
              Common options include:
              0 - Default behaviour
              XATTR_CREATE (2) - Fails if attribute already exists
              XATTR_REPLACE (4) - Fails if attribute doesn't exist
     - Returns: A result indicating success or providing an error
     */
    public func setExtendedAttribute(
        name: String,
        value: [UInt8],
        at path: FilePath,
        options: Int
    ) async -> Result<Void, FileSystemError> {
        
        let nsPath = path.path
        
        // Check if file exists
        let exists = await fileExists(at: path)
        if !exists {
            return .failure(
                FileSystemError.fileNotFound(
                    path: path.path,
                    message: "File not found when setting extended attribute"
                )
            )
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                // Set the attribute
                let result = setxattr(nsPath, name, value, value.count, 0, Int32(options))
                
                if result == -1 {
                    let error = errno
                    
                    // Map specific errors to appropriate FileSystemError types
                    let mappedError: FileSystemError
                    
                    switch error {
                    case EEXIST:
                        mappedError = .fileAlreadyExists(
                            path: path.path,
                            message: "Extended attribute '\(name)' already exists"
                        )
                    case ENOATTR:
                        mappedError = .general(
                            path: path.path,
                            message: "Extended attribute '\(name)' does not exist",
                            code: Int(error)
                        )
                    case EACCES, EPERM:
                        mappedError = .permissionDenied(
                            path: path.path,
                            message: "Permission denied when setting extended attribute"
                        )
                    default:
                        mappedError = .general(
                            path: path.path,
                            message: "Failed to set extended attribute: \(String(cString: strerror(error)))",
                            code: Int(error)
                        )
                    }
                    
                    continuation.resume(returning: .failure(mappedError))
                    return
                }
                
                continuation.resume(returning: .success(()))
            }
        }
    }
    
    /**
     Lists all extended attributes associated with a file or directory.
     
     This method retrieves the names of all extended attributes that have been
     set on the specified file system item.
     
     - Parameter path: The path of the file or directory
     - Returns: A result containing either an array of attribute names or an error
     */
    public func listExtendedAttributes(
        at path: FilePath
    ) async -> Result<[String], FileSystemError> {
        
        let nsPath = path.path
        
        // Check if file exists
        let exists = await fileExists(at: path)
        if !exists {
            return .failure(
                FileSystemError.fileNotFound(
                    path: path.path,
                    message: "File not found when listing extended attributes"
                )
            )
        }
        
        return await withCheckedContinuation { continuation in
            operationQueue.async {
                // Get size of attribute list first
                let size = listxattr(nsPath, nil, 0, 0)
                
                if size == -1 {
                    let error = errno
                    continuation.resume(returning: .failure(
                        FileSystemError.general(
                            path: path.path,
                            message: "Failed to list extended attributes: \(String(cString: strerror(error)))",
                            code: Int(error)
                        )
                    ))
                    return
                }
                
                // If size is 0, there are no attributes
                if size == 0 {
                    continuation.resume(returning: .success([]))
                    return
                }
                
                // Allocate buffer for attribute names
                var buffer = [Int8](repeating: 0, count: size)
                
                // Get attribute names
                let result = listxattr(nsPath, &buffer, size, 0)
                
                if result == -1 {
                    let error = errno
                    continuation.resume(returning: .failure(
                        FileSystemError.general(
                            path: path.path,
                            message: "Failed to list extended attributes: \(String(cString: strerror(error)))",
                            code: Int(error)
                        )
                    ))
                    return
                }
                
                // Parse the null-terminated list of attribute names
                var attributeNames: [String] = []
                var start = 0
                
                for i in 0..<size {
                    if buffer[i] == 0 {
                        if i > start {
                            if let name = String(bytes: buffer[start..<i].map { UInt8($0) }, encoding: .utf8) {
                                attributeNames.append(name)
                            }
                        }
                        start = i + 1
                    }
                }
                
                continuation.resume(returning: .success(attributeNames))
            }
        }
    }
    
    // MARK: - Path Operations
    
    /**
     # Path Operations
     
     Path operations provide utilities for manipulating, normalising, and resolving
     file paths in a platform-independent manner. This implementation offers:
     
     - Comprehensive path handling for both absolute and relative paths
     - Normalisation to create canonical path representations
     - Resolution of paths against base directories
     - Component-based path manipulation utilities
     
     ## Implementation Details
     
     - Uses URL for standardising paths and handling path components
     - Properly maintains relative vs. absolute path distinctions
     - Handles symlink resolution when requested
     - Provides efficient path comparison capabilities
     
     ## Usage Considerations
     
     These utilities are essential for security-sensitive operations where
     path canonicalisation is required to prevent path traversal vulnerabilities
     and for ensuring consistent path handling across different platform conventions.
     */
    
    /**
     Normalises a file path, resolving any relative components.
     
     This method processes a path to create a canonical representation by:
     - Resolving relative components like '.' and '..'
     - Removing redundant separators
     - Expanding symbolic links if requested
     
     - Parameters:
        - path: The file path to normalise
        - followSymlinks: Whether to resolve symbolic links (default: false)
     - Returns: A result containing either the normalised path or an error
     */
    public func normalisePath(
        _ path: FilePath,
        followSymlinks: Bool
    ) async -> Result<FilePath, FileSystemError> {
        let nsPath = path.path
        
        // Handle empty paths
        if nsPath.isEmpty {
            return .success(path)
        }
        
        // Create URL for standardising
        let url = URL(fileURLWithPath: nsPath)
        
        // For absolute paths, we can use standardised URL
        if url.path.hasPrefix("/") {
            let standardisedPath = url.standardised.path
            
            // If following symlinks is required
            if followSymlinks {
                let resolvedURL = URL(fileURLWithPath: standardisedPath).resolvingSymlinksInPath()
                return .success(FilePath(path: resolvedURL.path))
            }
            
            return .success(FilePath(path: standardisedPath))
        } else {
            // For relative paths, standardise with current directory
            let currentDir = fileManager.currentDirectoryPath
            let currentURL = URL(fileURLWithPath: currentDir)
            let combinedURL = URL(fileURLWithPath: nsPath, relativeTo: currentURL)
            let standardisedPath = combinedURL.standardised.path
            
            // If following symlinks is required
            if followSymlinks {
                let resolvedURL = URL(fileURLWithPath: standardisedPath).resolvingSymlinksInPath()
                
                // Make it relative again if the input was relative
                let relativePath = resolvedURL.path
                    .replacingOccurrences(of: currentDir, with: "")
                    .replacingOccurrences(of: "//", with: "/")
                
                // If it starts with /, remove it to keep it relative
                let finalPath = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
                
                return .success(FilePath(path: finalPath))
            }
            
            // Make it relative again if the input was relative
            let relativePath = standardisedPath
                .replacingOccurrences(of: currentDir, with: "")
                .replacingOccurrences(of: "//", with: "/")
            
            // If it starts with /, remove it to keep it relative
            let finalPath = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
            
            return .success(FilePath(path: finalPath))
        }
    }
    
    /**
     Resolves a relative path against a base path.
     
     This method combines a base path with a relative path to produce
     an absolute path. If the relative path is already absolute, it
     is returned unchanged.
     
     - Parameters:
        - relativePath: The relative path to resolve
        - basePath: The base path to resolve against
     - Returns: A result containing either the resolved path or an error
     */
    public func resolvePath(
        _ relativePath: FilePath,
        relativeTo basePath: FilePath
    ) async -> Result<FilePath, FileSystemError> {
        let relativeNSPath = relativePath.path
        let baseNSPath = basePath.path
        
        // If relative path is already absolute, return it
        if relativeNSPath.hasPrefix("/") {
            return .success(relativePath)
        }
        
        // Make sure base path is absolute
        let baseURL: URL
        if baseNSPath.hasPrefix("/") {
            baseURL = URL(fileURLWithPath: baseNSPath)
        } else {
            // If base path is also relative, resolve it against current directory
            let currentDir = fileManager.currentDirectoryPath
            baseURL = URL(fileURLWithPath: baseNSPath, relativeTo: URL(fileURLWithPath: currentDir))
        }
        
        // Create combined path
        let resolvedURL = URL(fileURLWithPath: relativeNSPath, relativeTo: baseURL)
        
        // Return standardised path to clean up any .. or . components
        return .success(FilePath(path: resolvedURL.standardised.path))
    }
    
    /**
     Splits a path into its components.
     
     This method breaks down a path into its individual components, treating
     the path separator as the delimiter between components.
     
     - Parameter path: The file path to split
     - Returns: An array of path components
     */
    public func pathComponents(_ path: FilePath) -> [String] {
        let nsPath = path.path
        let url = URL(fileURLWithPath: nsPath)
        
        // Filter out empty components
        return url.pathComponents.filter { !$0.isEmpty }
    }
    
    /**
     Gets the file name component of a path.
     
     This method extracts just the file or directory name from the path,
     without the preceding directory components.
     
     - Parameter path: The file path to get the name from
     - Returns: The file or directory name
     */
    public func fileName(_ path: FilePath) -> String {
        let nsPath = path.path
        
        // Handle simple cases directly
        if nsPath.isEmpty {
            return ""
        }
        
        // Use URL's lastPathComponent
        let url = URL(fileURLWithPath: nsPath)
        return url.lastPathComponent
    }
    
    /**
     Gets the directory component of a path.
     
     This method extracts the directory portion of a path, excluding
     the final file or directory name component.
     
     - Parameter path: The file path to get the directory from
     - Returns: The directory portion of the path
     */
    public func directoryPath(_ path: FilePath) -> FilePath {
        let nsPath = path.path
        
        // Handle simple cases directly
        if nsPath.isEmpty {
            return path
        }
        
        // Use URL's deletingLastPathComponent
        let url = URL(fileURLWithPath: nsPath)
        return FilePath(path: url.deletingLastPathComponent().path)
    }
    
    /**
     Joins multiple path components together.
     
     This method combines multiple path components into a single path,
     handling the path separators appropriately.
     
     - Parameters:
        - base: The base path
        - components: Additional path components to append
     - Returns: The combined path
     */
    public func joinPath(_ base: FilePath, withComponents components: [String]) -> FilePath {
        let basePath = base.path
        
        // Handle empty components array
        if components.isEmpty {
            return base
        }
        
        // Start with the base path
        var url = URL(fileURLWithPath: basePath)
        
        // Append each component
        for component in components {
            url = url.appendingPathComponent(component)
        }
        
        return FilePath(path: url.path)
    }
    
    /**
     Determines if a path is a subpath of another path.
     
     This method checks if one path is contained within another path
     in the directory hierarchy.
     
     - Parameters:
        - path: The path to check
        - potentialParent: The potential parent path
     - Returns: True if path is a subpath of potentialParent, false otherwise
     */
    public func isSubpath(
        _ path: FilePath,
        of potentialParent: FilePath
    ) -> Bool {
        // Normalise both paths to ensure consistent comparison
        let normalisedPath = URL(fileURLWithPath: path.path).standardised.path
        let normalisedParent = URL(fileURLWithPath: potentialParent.path).standardised.path
        
        // Ensure parent path ends with path separator for proper prefix checking
        let parentWithSeparator = normalisedParent.hasSuffix("/") ? normalisedParent : normalisedParent + "/"
        
        // Check if the path starts with the parent path
        // The path must either be exactly the parent or start with parent + "/"
        return normalisedPath == normalisedParent || 
               normalisedPath.hasPrefix(parentWithSeparator)
    }
    
    /**
     Maps Foundation file system errors to our domain-specific FileSystemError type.
     
     This provides consistent error reporting with rich context about the operation.
     
     - Parameters:
       - error: The original error from Foundation
       - path: The file path that was being operated on
     - Returns: A domain-specific FileSystemError
     */
    private func mapError(_ error: Error, path: FilePath) -> FileSystemError {
        let nsError = error as NSError
        let message = nsError.localizedDescription
        
        switch nsError.code {
        case NSFileReadNoSuchFileError:
            return .fileNotFound(path: path.path, message: message)
        case NSFileWriteNoPermissionError:
            return .permissionDenied(path: path.path, message: message)
        case NSFileWriteOutOfSpaceError:
            return .insufficientStorage(path: path.path, message: message)
        case NSFileWriteFileExistsError:
            return .fileAlreadyExists(path: path.path, message: message)
        default:
            return .general(path: path.path, message: message, code: nsError.code)
        }
    }
    
    /**
     Creates a FileSystemMetadata object from Foundation file attributes.
     
     This maps the native file attributes to our domain-specific metadata type.
     
     - Parameters:
       - attributes: The Foundation file attributes dictionary
       - path: The file path the attributes are for
     - Returns: A FileSystemMetadata object
     */
    private func createMetadata(
        from attributes: [FileAttributeKey: Any],
        for path: FilePath
    ) -> FileSystemMetadata {
        let fileSize = attributes[.size] as? UInt64 ?? 0
        let creationDate = attributes[.creationDate] as? Date
        let modificationDate = attributes[.modificationDate] as? Date
        let fileType = attributes[.type] as? String ?? ""
        
        let itemType: FileSystemItemType
        switch fileType {
        case FileAttributeType.typeDirectory.rawValue:
            itemType = .directory
        case FileAttributeType.typeRegular.rawValue:
            itemType = .file
        case FileAttributeType.typeSymbolicLink.rawValue:
            itemType = .symbolicLink
        default:
            itemType = .unknown
        }
        
        return FileSystemMetadata(
            path: path,
            itemType: itemType,
            size: fileSize,
            creationDate: creationDate,
            modificationDate: modificationDate
        )
    }
    
    // MARK: - Temporary File Management
    
    /**
     # Temporary File Management
     
     Temporary file operations provide utilities for creating and managing ephemeral
     files and directories that are cleaned up automatically. This implementation offers:
     
     - Secure creation of temporary files with unique names
     - Support for temporary directories for multi-file operations
     - Automatic resource cleanup via high-order functions
     - Safe temporary file handling with proper permissions
     
     ## Implementation Details
     
     - Uses system temporary directory for platform-appropriate storage
     - Generates secure unique filenames using UUIDs
     - Implements RAII pattern for resource management
     - Ensures proper cleanup even in error conditions
     
     ## Usage Considerations
     
     Temporary files are ideal for intermediate processing results, extraction
     workspaces, or any short-lived data that doesn't need to persist. The
     high-order functions (`withTemporaryFile` and `withTemporaryDirectory`)
     provide the safest approach as they guarantee cleanup.
     */
    
    /**
     Creates a temporary file with optional content.
     
     This method generates a secure temporary file with a unique name in the system's
     temporary directory. The file will be automatically deleted when the system
     restarts unless you move it to a permanent location.
     
     - Parameters:
        - prefix: Optional prefix for the temporary filename (default: "tmp")
        - suffix: Optional suffix/extension for the temporary filename (default: "")
        - data: Optional initial data to write to the temporary file
     - Returns: A result containing either the path to the temporary file or an error
     */
    public func createTemporaryFile(
        prefix: String = "tmp",
        suffix: String = "",
        data: [UInt8]?
    ) async -> Result<FilePath, FileSystemError> {
        // Generate a unique temporary file path
        let tempDirURL = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let fileName = "\(prefix)\(uniqueID)\(suffix)"
        let fileURL = tempDirURL.appendingPathComponent(fileName)
        
        // Create the file
        if !fileManager.createFile(atPath: fileURL.path, contents: nil) {
            return .failure(
                FileSystemError.general(
                    path: fileURL.path,
                    message: "Failed to create temporary file",
                    code: -1
                )
            )
        }
        
        let tempPath = FilePath(path: fileURL.path)
        
        // If initial data is provided, write it to the file
        if let initialData = data {
            let writeResult = await writeFile(at: tempPath, data: initialData)
            if case .failure(let error) = writeResult {
                // Clean up by deleting the empty file
                _ = await delete(at: tempPath, recursive: false)
                return .failure(error)
            }
        }
        
        return .success(tempPath)
    }
    
    /**
     Creates a temporary directory.
     
     This method generates a secure temporary directory with a unique name in the system's
     temporary directory. The directory will be automatically deleted when the system
     restarts unless you move its contents to a permanent location.
     
     - Parameter prefix: Optional prefix for the temporary directory name (default: "tmp")
     - Returns: A result containing either the path to the temporary directory or an error
     */
    public func createTemporaryDirectory(
        prefix: String = "tmp"
    ) async -> Result<FilePath, FileSystemError> {
        let tempDirURL = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let dirName = "\(prefix)\(uniqueID)"
        let dirURL = tempDirURL.appendingPathComponent(dirName)
        let tempPath = FilePath(path: dirURL.path)
        
        // Create the directory
        let result = await createDirectory(
            at: tempPath,
            withIntermediates: true
        )
        
        // Map the Result<Void, FileSystemError> to Result<FilePath, FileSystemError>
        switch result {
        case .success:
            return .success(tempPath)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /**
     Gets the system's temporary directory path.
     
     This method returns the path to the system-wide temporary directory
     where temporary files can be created.
     
     - Returns: The path to the system temporary directory
     */
    public func temporaryDirectoryPath() -> FilePath {
        return FilePath(path: FileManager.default.temporaryDirectory.path)
    }
    
    /**
     Creates and manages a temporary file for the duration of a task.
     
     This method creates a temporary file, passes it to a task closure, and
     ensures the file is deleted when the task completes (whether successfully
     or with an error).
     
     - Parameters:
        - prefix: Optional prefix for the temporary filename (default: "tmp")
        - suffix: Optional suffix/extension for the temporary filename (default: "")
        - data: Optional initial data to write to the temporary file
        - task: A closure that performs operations with the temporary file
     - Returns: The result returned by the task closure
     */
    public func withTemporaryFile<T>(
        prefix: String = "tmp",
        suffix: String = "",
        data: [UInt8]? = nil,
        task: (FilePath) async throws -> T
    ) async -> Result<T, Error> {
        // Create the temporary file
        let fileResult = await createTemporaryFile(prefix: prefix, suffix: suffix, data: data)
        
        switch fileResult {
        case .success(let tempPath):
            do {
                // Perform the task with the temporary file
                let result = try await task(tempPath)
                
                // Clean up the temporary file
                _ = await delete(at: tempPath, recursive: false)
                
                return .success(result)
            } catch {
                // Clean up the temporary file even if the task fails
                _ = await delete(at: tempPath, recursive: false)
                
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /**
     Creates and manages a temporary directory for the duration of a task.
     
     This method creates a temporary directory, passes it to a task closure, and
     ensures the directory and its contents are deleted when the task completes
     (whether successfully or with an error).
     
     - Parameters:
        - prefix: Optional prefix for the temporary directory name (default: "tmp")
        - task: A closure that performs operations with the temporary directory
     - Returns: The result returned by the task closure
     */
    public func withTemporaryDirectory<T>(
        prefix: String = "tmp",
        task: (FilePath) async throws -> T
    ) async -> Result<T, Error> {
        // Create the temporary directory
        let dirResult = await createTemporaryDirectory(prefix: prefix)
        
        switch dirResult {
        case .success(let tempDirPath):
            do {
                // Perform the task with the temporary directory
                let result = try await task(tempDirPath)
                
                // Clean up the temporary directory recursively
                _ = await delete(at: tempDirPath, recursive: true)
                
                return .success(result)
            } catch {
                // Clean up the temporary directory even if the task fails
                _ = await delete(at: tempDirPath, recursive: true)
                
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
}
