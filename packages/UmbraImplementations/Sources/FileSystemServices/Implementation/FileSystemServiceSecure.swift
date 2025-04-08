import FileSystemInterfaces
import FileSystemTypes
import LoggingInterfaces
import LoggingTypes

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
        logger: (any LoggingProtocol)? = nil
    ) {
        self.filePathService = filePathService
        self.logger = logger ?? NullLogger()
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        let exists = await filePathService.exists(securePath)
        let isFile = await filePathService.isFile(securePath)
        
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        let exists = await filePathService.exists(securePath)
        let isDirectory = await filePathService.isDirectory(securePath)
        
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
        withIntermediateDirectories: Bool = true
    ) async throws {
        await logDebug("Creating directory at \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
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
            throw FileSystemError.directoryCreationFailed(
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
        options: DirectoryEnumerationOptions = []
    ) async throws -> [FilePath] {
        await logDebug("Listing contents of directory at \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: securePath.toString())
            
            return contents.map { item in
                let itemPath = path.path.hasSuffix("/") ? path.path + item : path.path + "/" + item
                let isDirectory = (try? FileManager.default.attributesOfItem(
                    atPath: itemPath
                )[.type] as? FileAttributeType) == .typeDirectory
                
                return FilePath(path: itemPath, isDirectory: isDirectory)
            }
        } catch {
            throw FileSystemError.directoryEnumerationFailed(
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            return try Data(contentsOf: URL(fileURLWithPath: securePath.toString()))
        } catch {
            throw FileSystemError.fileReadFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Writes data to a file.
     
     - Parameters:
        - data: The data to write
        - path: The path where the file should be written
        - options: Options for writing the file
     - Throws: FileSystemError if file writing fails
     */
    public func writeFile(
        _ data: Data,
        to path: FilePath,
        options: FileWriteOptions = []
    ) async throws {
        await logDebug("Writing file to \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            try data.write(
                to: URL(fileURLWithPath: securePath.toString()),
                options: options.contains(.atomic) ? .atomic : []
            )
        } catch {
            throw FileSystemError.fileWriteFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Deletes a file at the specified path.
     
     - Parameter path: The path to the file to delete
     - Throws: FileSystemError if file deletion fails
     */
    public func deleteFile(at path: FilePath) async throws {
        await logDebug("Deleting file at \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            try FileManager.default.removeItem(atPath: securePath.toString())
        } catch {
            throw FileSystemError.fileDeletionFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Moves a file from one location to another.
     
     - Parameters:
        - sourcePath: The path to the file to move
        - destinationPath: The path where the file should be moved
        - options: Options for moving the file
     - Throws: FileSystemError if file moving fails
     */
    public func moveFile(
        from sourcePath: FilePath,
        to destinationPath: FilePath,
        options: FileMoveOptions = []
    ) async throws {
        await logDebug("Moving file from \(sourcePath.path) to \(destinationPath.path)")
        
        guard let secureSourcePath = SecurePathAdapter.toSecurePath(sourcePath) else {
            throw FileSystemError.invalidPath(
                path: sourcePath.path,
                reason: "Could not convert source path to secure path"
            )
        }
        
        guard let secureDestPath = SecurePathAdapter.toSecurePath(destinationPath) else {
            throw FileSystemError.invalidPath(
                path: destinationPath.path,
                reason: "Could not convert destination path to secure path"
            )
        }
        
        do {
            try FileManager.default.moveItem(
                atPath: secureSourcePath.toString(),
                toPath: secureDestPath.toString()
            )
        } catch {
            throw FileSystemError.fileMoveFailed(
                sourcePath: sourcePath.path,
                destinationPath: destinationPath.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Copies a file from one location to another.
     
     - Parameters:
        - sourcePath: The path to the file to copy
        - destinationPath: The path where the file should be copied
        - options: Options for copying the file
     - Throws: FileSystemError if file copying fails
     */
    public func copyFile(
        from sourcePath: FilePath,
        to destinationPath: FilePath,
        options: FileCopyOptions = []
    ) async throws {
        await logDebug("Copying file from \(sourcePath.path) to \(destinationPath.path)")
        
        guard let secureSourcePath = SecurePathAdapter.toSecurePath(sourcePath) else {
            throw FileSystemError.invalidPath(
                path: sourcePath.path,
                reason: "Could not convert source path to secure path"
            )
        }
        
        guard let secureDestPath = SecurePathAdapter.toSecurePath(destinationPath) else {
            throw FileSystemError.invalidPath(
                path: destinationPath.path,
                reason: "Could not convert destination path to secure path"
            )
        }
        
        do {
            try FileManager.default.copyItem(
                atPath: secureSourcePath.toString(),
                toPath: secureDestPath.toString()
            )
        } catch {
            throw FileSystemError.fileCopyFailed(
                sourcePath: sourcePath.path,
                destinationPath: destinationPath.path,
                reason: error.localizedDescription
            )
        }
    }
    
    // MARK: - Path Operations
    
    /**
     Returns the parent directory of a path.
     
     - Parameter path: The path to get the parent of
     - Returns: The parent directory path
     - Throws: FileSystemError if parent retrieval fails
     */
    public func parentDirectory(of path: FilePath) async throws -> FilePath {
        await logDebug("Getting parent directory of \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        guard let parentPath = await filePathService.parentDirectory(of: securePath) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not get parent directory"
            )
        }
        
        return SecurePathAdapter.toFilePath(parentPath)
    }
    
    /**
     Returns the last component of a path.
     
     - Parameter path: The path to get the last component of
     - Returns: The last path component
     - Throws: FileSystemError if component retrieval fails
     */
    public func lastPathComponent(of path: FilePath) async throws -> String {
        await logDebug("Getting last component of \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        return await filePathService.lastComponent(of: securePath)
    }
    
    /**
     Returns the file extension of a path.
     
     - Parameter path: The path to get the extension of
     - Returns: The file extension, or nil if there is none
     - Throws: FileSystemError if extension retrieval fails
     */
    public func fileExtension(of path: FilePath) async throws -> String? {
        await logDebug("Getting file extension of \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        return await filePathService.fileExtension(of: securePath)
    }
    
    // MARK: - Security-Scoped Resources
    
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            return
        }
        
        await filePathService.stopAccessingSecurityScopedResource(securePath)
    }
    
    // MARK: - Additional Protocol Methods
    
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: securePath.toString())
            
            return contents.compactMap { item in
                // Skip hidden files if not requested
                if !includeHidden && item.hasPrefix(".") {
                    return nil
                }
                
                let itemPath = path.path.hasSuffix("/") ? path.path + item : path.path + "/" + item
                let isDirectory = (try? FileManager.default.attributesOfItem(
                    atPath: itemPath
                )[.type] as? FileAttributeType) == .typeDirectory
                
                return FilePath(path: itemPath, isDirectory: isDirectory)
            }
        } catch {
            throw FileSystemError.directoryEnumerationFailed(
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        var result: [FilePath] = []
        
        // Helper function to recursively list directory contents
        func listRecursive(at currentPath: String, relativeTo basePath: String) throws {
            let contents = try FileManager.default.contentsOfDirectory(atPath: currentPath)
            
            for item in contents {
                // Skip hidden files if not requested
                if !includeHidden && item.hasPrefix(".") {
                    continue
                }
                
                let itemPath = currentPath.hasSuffix("/") ? currentPath + item : currentPath + "/" + item
                let relativePath = basePath.hasSuffix("/") ? basePath + item : basePath + "/" + item
                
                let attributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                let isDirectory = (attributes[.type] as? FileAttributeType) == .typeDirectory
                
                result.append(FilePath(path: relativePath, isDirectory: isDirectory))
                
                // Recursively process directories
                if isDirectory {
                    try listRecursive(at: itemPath, relativeTo: relativePath)
                }
            }
        }
        
        do {
            try listRecursive(at: securePath.toString(), relativeTo: path.path)
            return result
        } catch {
            throw FileSystemError.directoryEnumerationFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        // Check if file exists and handle overwrite policy
        if await filePathService.exists(securePath) {
            if !overwrite {
                throw FileSystemError.fileAlreadyExists(
                    path: path.path,
                    reason: "File already exists and overwrite is not allowed"
                )
            }
        }
        
        do {
            try data.write(
                to: URL(fileURLWithPath: securePath.toString()),
                options: .atomic
            )
        } catch {
            throw FileSystemError.fileCreationFailed(
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        // Check if file exists before updating
        if !await filePathService.exists(securePath) {
            throw FileSystemError.fileNotFound(
                path: path.path,
                reason: "File does not exist"
            )
        }
        
        do {
            try data.write(
                to: URL(fileURLWithPath: securePath.toString()),
                options: .atomic
            )
        } catch {
            throw FileSystemError.fileUpdateFailed(
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
        options: FileMetadataOptions?
    ) async throws -> FileMetadata {
        await logDebug("Getting file metadata at \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        let resolveSymlinks = options?.resolveSymlinks ?? true
        
        do {
            let fileURL = URL(fileURLWithPath: securePath.toString())
            let attributes = try FileManager.default.attributesOfItem(atPath: securePath.toString())
            
            // Create basic metadata
            var metadata = FileMetadata(
                path: path,
                size: attributes[.size] as? UInt64 ?? 0,
                creationDate: attributes[.creationDate] as? Date,
                modificationDate: attributes[.modificationDate] as? Date,
                isDirectory: (attributes[.type] as? FileAttributeType) == .typeDirectory,
                isSymbolicLink: (attributes[.type] as? FileAttributeType) == .typeSymbolicLink,
                isHidden: securePath.toString().lastPathComponent.hasPrefix("."),
                permissions: attributes[.posixPermissions] as? UInt16 ?? 0
            )
            
            // Resolve symbolic links if requested
            if resolveSymlinks && metadata.isSymbolicLink {
                let destination = try FileManager.default.destinationOfSymbolicLink(atPath: securePath.toString())
                metadata.symbolicLinkDestination = FilePath(path: destination, isDirectory: false)
            }
            
            return metadata
        } catch {
            throw FileSystemError.metadataRetrievalFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Creates a directory at the specified path with additional options.
     
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
        await logDebug("Creating directory at \(path.path), createIntermediates: \(createIntermediates)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            try FileManager.default.createDirectory(
                atPath: securePath.toString(),
                withIntermediateDirectories: createIntermediates,
                attributes: attributes
            )
        } catch {
            throw FileSystemError.directoryCreationFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Deletes a file at the specified path with secure option.
     
     - Parameter path: The file to delete
     - Parameter secure: Whether to securely overwrite the file before deletion
     - Throws: FileSystemError if the file cannot be deleted
     */
    public func deleteFile(
        at path: FilePath,
        secure: Bool
    ) async throws {
        await logDebug("Deleting file at \(path.path), secure: \(secure)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        // If secure deletion is requested, overwrite the file first
        if secure {
            do {
                // Get file size
                let attributes = try FileManager.default.attributesOfItem(atPath: securePath.toString())
                let fileSize = attributes[.size] as? UInt64 ?? 0
                
                if fileSize > 0 {
                    // Create secure random data
                    var secureData = Data(count: Int(min(fileSize, 1024 * 1024))) // Cap at 1MB for large files
                    for i in 0..<secureData.count {
                        secureData[i] = UInt8.random(in: 0...255)
                    }
                    
                    // Overwrite file multiple times
                    for _ in 0..<3 {
                        try secureData.write(to: URL(fileURLWithPath: securePath.toString()))
                    }
                    
                    // Final overwrite with zeros
                    for i in 0..<secureData.count {
                        secureData[i] = 0
                    }
                    try secureData.write(to: URL(fileURLWithPath: securePath.toString()))
                }
            } catch {
                // Log but continue with deletion
                await logger.warning(
                    "Secure overwrite failed: \(error.localizedDescription)",
                    context: FileSystemLogContext(
                        operation: "SecureDelete",
                        additionalContext: nil
                    )
                )
            }
        }
        
        // Now delete the file
        do {
            try FileManager.default.removeItem(atPath: securePath.toString())
        } catch {
            throw FileSystemError.fileDeletionFailed(
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
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        // If secure deletion is requested, we need to handle each file individually
        if secure {
            do {
                // Get all files in the directory
                let contents = try await listDirectoryRecursive(at: path, includeHidden: true)
                
                // Delete files first (not directories)
                for item in contents.filter({ !$0.isDirectory }) {
                    try await deleteFile(at: item, secure: true)
                }
                
                // Now delete the directory structure
                try FileManager.default.removeItem(atPath: securePath.toString())
            } catch {
                throw FileSystemError.directoryDeletionFailed(
                    path: path.path,
                    reason: error.localizedDescription
                )
            }
        } else {
            // Standard deletion
            do {
                try FileManager.default.removeItem(atPath: securePath.toString())
            } catch {
                throw FileSystemError.directoryDeletionFailed(
                    path: path.path,
                    reason: error.localizedDescription
                )
            }
        }
    }
    
    /**
     Moves a file or directory.
     
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
        await logDebug("Moving item from \(sourcePath.path) to \(destinationPath.path), overwrite: \(overwrite)")
        
        guard let secureSourcePath = SecurePathAdapter.toSecurePath(sourcePath) else {
            throw FileSystemError.invalidPath(
                path: sourcePath.path,
                reason: "Could not convert source path to secure path"
            )
        }
        
        guard let secureDestPath = SecurePathAdapter.toSecurePath(destinationPath) else {
            throw FileSystemError.invalidPath(
                path: destinationPath.path,
                reason: "Could not convert destination path to secure path"
            )
        }
        
        // Check if destination exists and handle overwrite policy
        if await filePathService.exists(secureDestPath) {
            if !overwrite {
                throw FileSystemError.fileAlreadyExists(
                    path: destinationPath.path,
                    reason: "Destination already exists and overwrite is not allowed"
                )
            }
            
            // Delete the destination if overwrite is allowed
            try FileManager.default.removeItem(atPath: secureDestPath.toString())
        }
        
        do {
            try FileManager.default.moveItem(
                atPath: secureSourcePath.toString(),
                toPath: secureDestPath.toString()
            )
        } catch {
            throw FileSystemError.fileMoveFailed(
                sourcePath: sourcePath.path,
                destinationPath: destinationPath.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Copies a file or directory.
     
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
        await logDebug("Copying item from \(sourcePath.path) to \(destinationPath.path), overwrite: \(overwrite)")
        
        guard let secureSourcePath = SecurePathAdapter.toSecurePath(sourcePath) else {
            throw FileSystemError.invalidPath(
                path: sourcePath.path,
                reason: "Could not convert source path to secure path"
            )
        }
        
        guard let secureDestPath = SecurePathAdapter.toSecurePath(destinationPath) else {
            throw FileSystemError.invalidPath(
                path: destinationPath.path,
                reason: "Could not convert destination path to secure path"
            )
        }
        
        // Check if destination exists and handle overwrite policy
        if await filePathService.exists(secureDestPath) {
            if !overwrite {
                throw FileSystemError.fileAlreadyExists(
                    path: destinationPath.path,
                    reason: "Destination already exists and overwrite is not allowed"
                )
            }
            
            // Delete the destination if overwrite is allowed
            try FileManager.default.removeItem(atPath: secureDestPath.toString())
        }
        
        do {
            try FileManager.default.copyItem(
                atPath: secureSourcePath.toString(),
                toPath: secureDestPath.toString()
            )
        } catch {
            throw FileSystemError.fileCopyFailed(
                sourcePath: sourcePath.path,
                destinationPath: destinationPath.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Converts a file path to a URL.
     
     - Parameter path: The file path to convert
     - Returns: The equivalent URL
     - Throws: FileSystemError if the conversion fails
     */
    public func pathToURL(_ path: FilePath) async throws -> URL {
        await logDebug("Converting path to URL: \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        return URL(fileURLWithPath: securePath.toString())
    }
    
    /**
     Creates a security-scoped bookmark for a file.
     
     - Parameter path: The file path to bookmark
     - Parameter readOnly: Whether the bookmark should be read-only
     - Returns: The bookmark data
     - Throws: FileSystemError if the bookmark cannot be created
     */
    public func createSecurityBookmark(
        for path: FilePath,
        readOnly: Bool
    ) async throws -> Data {
        await logDebug("Creating security bookmark for \(path.path), readOnly: \(readOnly)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let url = URL(fileURLWithPath: securePath.toString())
            let bookmarkData = try url.bookmarkData(
                options: readOnly ? [.securityScopeAllowOnlyReadAccess] : [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmarkData
        } catch {
            throw FileSystemError.bookmarkCreationFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Resolves a security-scoped bookmark.
     
     - Parameter bookmark: The bookmark data
     - Returns: The resolved file path and whether the bookmark was stale
     - Throws: FileSystemError if the bookmark cannot be resolved
     */
    public func resolveSecurityBookmark(
        _ bookmark: Data
    ) async throws -> (FilePath, Bool) {
        await logDebug("Resolving security bookmark")
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            let path = FilePath(
                path: url.path,
                isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            )
            
            return (path, isStale)
        } catch {
            throw FileSystemError.bookmarkResolutionFailed(
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Creates a temporary file in the system's temporary directory.
     
     - Parameter prefix: Optional prefix for the filename
     - Parameter suffix: Optional suffix for the filename
     - Parameter options: Configuration options for the temporary file
     - Returns: Path to the temporary file
     - Throws: FileSystemError if the temporary file cannot be created
     */
    public func createTemporaryFile(
        prefix: String?,
        suffix: String?,
        options: TemporaryFileOptions?
    ) async throws -> FilePath {
        await logDebug("Creating temporary file with prefix: \(prefix ?? "none"), suffix: \(suffix ?? "none")")
        
        let tempDir = FileManager.default.temporaryDirectory.path
        let uuid = UUID().uuidString
        let fileName = "\(prefix ?? "")\(uuid)\(suffix ?? "")"
        let tempPath = tempDir + "/" + fileName
        
        // Create an empty file
        do {
            FileManager.default.createFile(atPath: tempPath, contents: nil)
            
            // Set file attributes if provided
            if let attributes = options?.attributes {
                try FileManager.default.setAttributes(attributes, ofItemAtPath: tempPath)
            }
            
            return FilePath(path: tempPath, isDirectory: false)
        } catch {
            throw FileSystemError.temporaryFileCreationFailed(
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Creates a temporary directory in the system's temporary directory.
     
     - Parameter prefix: Optional prefix for the directory name
     - Parameter options: Configuration options for the temporary directory
     - Returns: Path to the temporary directory
     - Throws: FileSystemError if the temporary directory cannot be created
     */
    public func createTemporaryDirectory(
        prefix: String?,
        options: TemporaryFileOptions?
    ) async throws -> FilePath {
        await logDebug("Creating temporary directory with prefix: \(prefix ?? "none")")
        
        let tempDir = FileManager.default.temporaryDirectory.path
        let uuid = UUID().uuidString
        let dirName = "\(prefix ?? "")\(uuid)"
        let tempPath = tempDir + "/" + dirName
        
        do {
            try FileManager.default.createDirectory(
                atPath: tempPath,
                withIntermediateDirectories: true,
                attributes: options?.attributes
            )
            
            return FilePath(path: tempPath, isDirectory: true)
        } catch {
            throw FileSystemError.temporaryDirectoryCreationFailed(
                reason: error.localizedDescription
            )
        }
    }
    
    // MARK: - Extended Attributes
    
    /**
     Retrieves an extended attribute from a file.
     
     - Parameter path: The file to query
     - Parameter attributeName: The name of the extended attribute
     - Returns: The attribute value as a SafeAttributeValue
     - Throws: FileSystemError if the attribute cannot be retrieved
     */
    public func getExtendedAttribute(
        at path: FilePath,
        name attributeName: String
    ) async throws -> SafeAttributeValue {
        await logDebug("Getting extended attribute \(attributeName) for \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let url = URL(fileURLWithPath: securePath.toString())
            let data = try url.extendedAttribute(forName: attributeName)
            return SafeAttributeValue(data: data)
        } catch {
            throw FileSystemError.extendedAttributeReadFailed(
                path: path.path,
                attributeName: attributeName,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Sets an extended attribute on a file.
     
     - Parameter path: The file to modify
     - Parameter attributeName: The name of the extended attribute
     - Parameter attributeValue: The value to set
     - Throws: FileSystemError if the attribute cannot be set
     */
    public func setExtendedAttribute(
        at path: FilePath,
        name attributeName: String,
        value attributeValue: SafeAttributeValue
    ) async throws {
        await logDebug("Setting extended attribute \(attributeName) for \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let url = URL(fileURLWithPath: securePath.toString())
            try url.setExtendedAttribute(data: attributeValue.data, forName: attributeName)
        } catch {
            throw FileSystemError.extendedAttributeWriteFailed(
                path: path.path,
                attributeName: attributeName,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Lists all extended attributes for a file.
     
     - Parameter path: The file to query
     - Returns: An array of attribute names
     - Throws: FileSystemError if the attributes cannot be retrieved
     */
    public func listExtendedAttributes(
        at path: FilePath
    ) async throws -> [String] {
        await logDebug("Listing extended attributes for \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let url = URL(fileURLWithPath: securePath.toString())
            return try url.listExtendedAttributes()
        } catch {
            throw FileSystemError.extendedAttributeListFailed(
                path: path.path,
                reason: error.localizedDescription
            )
        }
    }
    
    /**
     Removes an extended attribute from a file.
     
     - Parameter path: The file to modify
     - Parameter attributeName: The name of the attribute to remove
     - Throws: FileSystemError if the attribute cannot be removed
     */
    public func removeExtendedAttribute(
        at path: FilePath,
        name attributeName: String
    ) async throws {
        await logDebug("Removing extended attribute \(attributeName) for \(path.path)")
        
        guard let securePath = SecurePathAdapter.toSecurePath(path) else {
            throw FileSystemError.invalidPath(
                path: path.path,
                reason: "Could not convert to secure path"
            )
        }
        
        do {
            let url = URL(fileURLWithPath: securePath.toString())
            try url.removeExtendedAttribute(forName: attributeName)
        } catch {
            throw FileSystemError.extendedAttributeRemoveFailed(
                path: path.path,
                attributeName: attributeName,
                reason: error.localizedDescription
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Logs a debug message with the file system context.
     
     - Parameter message: The message to log
     */
    private func logDebug(_ message: String) async {
        await logger.debug(
            message,
            context: FileSystemLogContext(
                operation: "FileSystemServiceSecure",
                additionalContext: nil
            )
        )
    }
}

/**
 A null logger that does nothing.
 */
private struct NullLogger: LoggingProtocol {
    func log(
        level: LogLevel,
        message: String,
        context: LogContextDTO?,
        file: String,
        function: String,
        line: Int
    ) async {}
    
    func isEnabled(for level: LogLevel) async -> Bool {
        return false
    }
}
