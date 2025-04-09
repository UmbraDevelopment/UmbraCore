import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # File Sandboxing Implementation
 
 This implementation provides file system sandboxing to restrict operations
 to a specific directory for security purposes.
 
 It uses Swift's actor system to ensure thread-safety and implements the
 FileSandboxingProtocol defined in the FileSystemInterfaces module.
 
 ## Security Features
 
 The sandboxing ensures:
 - All file operations are restricted to the sandbox directory
 - Paths are properly normalised to prevent path traversal attacks
 - Attempts to access outside the sandbox are detected and rejected
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 */
public actor FileSandboxingImpl: FileSandboxingProtocol {
    /// Root directory path for sandboxed operations
    private let rootDirectoryPath: String
    
    /// Logger used by this service
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new FileSandboxing implementation with the specified root directory.
     
     - Parameters:
        - rootDirectoryPath: The absolute path to the root directory for sandboxed operations
        - logger: Optional logger to use for recording operations
     */
    public init(rootDirectoryPath: String, logger: (any LoggingProtocol)? = nil) {
        self.rootDirectoryPath = rootDirectoryPath
        self.logger = logger ?? LoggingProtocol_NoOp()
    }
    
    /**
     Creates a sandboxed version of a file system service.
     
     - Parameter service: The CoreFileOperationsProtocol service to sandbox
     - Returns: A sandboxed version of the service and operation result
     */
    public func createSandboxed(service: any CoreFileOperationsProtocol) async -> (any CoreFileOperationsProtocol, FileOperationResultDTO) {
        let context = createLogContext([
            "rootDirectory": rootDirectoryPath
        ])
        await logger.debug("Creating sandboxed file service", context: context)
        
        // Create the result metadata
        let fileManager = FileManager.default
        let metadata: FileMetadataDTO?
        
        if fileManager.fileExists(atPath: rootDirectoryPath) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: rootDirectoryPath)
                metadata = FileMetadataDTO.from(attributes: attributes, path: rootDirectoryPath)
            } catch {
                let errorContext = createLogContext([
                    "rootDirectory": rootDirectoryPath,
                    "error": "\(error)"
                ])
                await logger.warning("Failed to get sandbox directory attributes", context: errorContext)
                metadata = nil
            }
        } else {
            metadata = nil
        }
        
        // Create sandboxed service
        let sandboxed = SandboxedFileOperations(
            fileService: service, 
            rootDirectoryPath: rootDirectoryPath,
            logger: logger
        )
        
        let result = FileOperationResultDTO.success(
            path: rootDirectoryPath,
            metadata: metadata
        )
        
        let successContext = createLogContext([
            "rootDirectory": rootDirectoryPath
        ])
        await logger.info("Successfully created sandboxed file service", context: successContext)
        
        return (sandboxed, result)
    }
    
    /**
     Creates a directory within the sandbox.
     
     - Parameters:
        - path: Relative path within the sandbox
        - options: Optional directory creation options
     - Returns: The absolute path to the created directory and operation result
     - Throws: FileSystemError if directory creation fails or path is outside sandbox
     */
    public func createSandboxedDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext([
            "path": path,
            "rootDirectory": rootDirectoryPath
        ])
        await logger.debug("Creating sandboxed directory", context: context)
        
        // Check if the path is trying to escape the sandbox
        guard isSafePath(path) else {
            let error = FileSystemError.securityViolation(
                path: path, 
                constraint: "Path attempts to escape sandbox"
            )
            let errorContext = createLogContext([
                "path": path,
                "rootDirectory": rootDirectoryPath
            ])
            await logger.error("Security violation: Path attempts to escape sandbox", context: errorContext)
            throw error
        }
        
        // Create the absolute path
        let absolutePath = resolvePath(path)
        
        // Create the directory
        do {
            try FileManager.default.createDirectory(
                atPath: absolutePath,
                withIntermediateDirectories: true,
                attributes: options?.attributes
            )
            
            // Get directory attributes for the result
            let attributes = try FileManager.default.attributesOfItem(atPath: absolutePath)
            let metadata = FileMetadataDTO.from(attributes: attributes, path: absolutePath)
            
            let result = FileOperationResultDTO.success(
                path: absolutePath,
                metadata: metadata
            )
            
            let successContext = createLogContext([
                "path": path,
                "absolutePath": absolutePath
            ])
            await logger.debug("Successfully created sandboxed directory", context: successContext)
            
            return (absolutePath, result)
        } catch {
            let dirError = FileSystemError.writeError(
                path: absolutePath,
                reason: "Failed to create directory: \(error.localizedDescription)"
            )
            let errorContext = createLogContext([
                "path": path,
                "absolutePath": absolutePath,
                "error": "\(error)"
            ])
            await logger.error("Failed to create sandboxed directory", context: errorContext)
            throw dirError
        }
    }
    
    /**
     Gets the absolute path for a relative path within the sandbox.
     
     - Parameter path: Relative path within the sandbox
     - Returns: The absolute path and operation result
     - Throws: FileSystemError if the path is outside the sandbox
     */
    public func getSandboxedPath(_ path: String) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext([
            "path": path,
            "rootDirectory": rootDirectoryPath
        ])
        await logger.debug("Getting sandboxed path", context: context)
        
        // Check if the path is trying to escape the sandbox
        guard isSafePath(path) else {
            let error = FileSystemError.securityViolation(
                path: path, 
                constraint: "Path attempts to escape sandbox"
            )
            let errorContext = createLogContext([
                "path": path,
                "rootDirectory": rootDirectoryPath
            ])
            await logger.error("Security violation: Path attempts to escape sandbox", context: errorContext)
            throw error
        }
        
        // Resolve to absolute path
        let absolutePath = resolvePath(path)
        
        // Check if path exists to get metadata
        let metadata: FileMetadataDTO?
        if FileManager.default.fileExists(atPath: absolutePath) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: absolutePath)
                metadata = FileMetadataDTO.from(attributes: attributes, path: absolutePath)
            } catch {
                let errorContext = createLogContext([
                    "path": path,
                    "absolutePath": absolutePath,
                    "error": "\(error)"
                ])
                await logger.warning("Failed to get item attributes", context: errorContext)
                metadata = nil
            }
        } else {
            metadata = nil
        }
        
        let result = FileOperationResultDTO.success(
            path: absolutePath,
            metadata: metadata
        )
        
        let successContext = createLogContext([
            "path": path,
            "absolutePath": absolutePath
        ])
        await logger.debug("Successfully resolved sandboxed path", context: successContext)
        
        return (absolutePath, result)
    }
    
    /**
     Gets a path relative to the sandbox from an absolute path.
     
     - Parameter absolutePath: Absolute path to convert to relative
     - Returns: The relative path and operation result
     - Throws: FileSystemError if the path is outside the sandbox
     */
    public func getRelativePath(from absolutePath: String) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext([
            "absolutePath": absolutePath,
            "rootDirectory": rootDirectoryPath
        ])
        await logger.debug("Getting relative path", context: context)
        
        // Normalise paths for comparison
        let normalisedRoot = (rootDirectoryPath as NSString).standardizingPath
        let normalisedPath = (absolutePath as NSString).standardizingPath
        
        // Check if path is within the sandbox
        guard normalisedPath.hasPrefix(normalisedRoot) else {
            let error = FileSystemError.securityViolation(
                path: absolutePath, 
                constraint: "Path is outside sandbox"
            )
            let errorContext = createLogContext([
                "absolutePath": absolutePath,
                "rootDirectory": rootDirectoryPath
            ])
            await logger.error("Security violation: Path is outside sandbox", context: errorContext)
            throw error
        }
        
        // Extract the relative path
        var relativePath = String(normalisedPath.dropFirst(normalisedRoot.count))
        
        // Remove leading slash if present
        if relativePath.hasPrefix("/") {
            relativePath = String(relativePath.dropFirst())
        }
        
        // Get metadata if path exists
        let metadata: FileMetadataDTO?
        if FileManager.default.fileExists(atPath: absolutePath) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: absolutePath)
                metadata = FileMetadataDTO.from(attributes: attributes, path: absolutePath)
            } catch {
                let errorContext = createLogContext([
                    "absolutePath": absolutePath,
                    "relativePath": relativePath,
                    "error": "\(error)"
                ])
                await logger.warning("Failed to get item attributes", context: errorContext)
                metadata = nil
            }
        } else {
            metadata = nil
        }
        
        let result = FileOperationResultDTO.success(
            path: relativePath,
            metadata: metadata
        )
        
        let successContext = createLogContext([
            "absolutePath": absolutePath,
            "relativePath": relativePath
        ])
        await logger.debug("Successfully resolved relative path", context: successContext)
        
        return (relativePath, result)
    }
    
    /**
     Validates the security of a path to ensure it doesn't escape the sandbox.
     
     - Parameter path: Path to validate
     - Returns: True if path is safe, false otherwise
     */
    private func isSafePath(_ path: String) -> Bool {
        // Normalise path for security checks
        let normalisedPath = (path as NSString).standardizingPath
        
        // Check for path traversal attempts
        let components = normalisedPath.components(separatedBy: "/")
        
        var depth = 0
        for component in components {
            if component == ".." {
                depth -= 1
                if depth < 0 {
                    // Path would escape the sandbox
                    return false
                }
            } else if component != "." && !component.isEmpty {
                depth += 1
            }
        }
        
        return true
    }
    
    /**
     Resolves a potentially relative path to an absolute path within the sandbox.
     
     - Parameter path: Path to resolve
     - Returns: Absolute path within the sandbox
     */
    private func resolvePath(_ path: String) -> String {
        // Handle empty path as root directory
        if path.isEmpty {
            return rootDirectoryPath
        }
        
        // Normalise path
        let normalisedPath = (path as NSString).standardizingPath
        
        // Check if already absolute and within sandbox
        if normalisedPath.hasPrefix(rootDirectoryPath) {
            return normalisedPath
        }
        
        // Create absolute path
        var absolutePath = rootDirectoryPath
        
        // Ensure there's a separator between root and path
        if !absolutePath.hasSuffix("/") && !normalisedPath.hasPrefix("/") {
            absolutePath += "/"
        }
        
        // Remove leading slash from path to avoid double slashes
        let pathToAppend = normalisedPath.hasPrefix("/") ? String(normalisedPath.dropFirst()) : normalisedPath
        
        absolutePath += pathToAppend
        return absolutePath
    }
    
    /**
     Creates a log context from a metadata dictionary.
     
     - Parameter metadata: The metadata dictionary
     - Returns: A BaseLogContextDTO
     */
    private func createLogContext(_ metadata: [String: String]) -> BaseLogContextDTO {
        var collection = LogMetadataDTOCollection()
        for (key, value) in metadata {
            collection = collection.withPublic(key: key, value: value)
        }
        
        return BaseLogContextDTO(
            domainName: "FileSandboxing",
            source: "FileSandboxingImpl",
            metadata: collection
        )
    }
}

/**
 # Sandboxed File Operations
 
 A wrapper around a CoreFileOperationsProtocol implementation that restricts
 all operations to a specific directory.
 
 This actor ensures all file operations performed through it are contained
 within the specified sandbox root directory.
 */
private actor SandboxedFileOperations: CoreFileOperationsProtocol {
    /// The underlying file operations service
    private let fileService: any CoreFileOperationsProtocol
    
    /// Root directory for the sandbox
    private let rootDirectoryPath: String
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new sandboxed file operations wrapper.
     
     - Parameters:
        - fileService: The file service to wrap
        - rootDirectoryPath: The root directory for the sandbox
        - logger: Logger for recording operations
     */
    init(
        fileService: any CoreFileOperationsProtocol,
        rootDirectoryPath: String,
        logger: any LoggingProtocol
    ) {
        self.fileService = fileService
        self.rootDirectoryPath = rootDirectoryPath
        self.logger = logger
    }
    
    /**
     Creates a log context from a metadata dictionary.
     
     - Parameter metadata: The metadata dictionary
     - Returns: A BaseLogContextDTO
     */
    private func createLogContext(_ metadata: [String: String]) -> BaseLogContextDTO {
        var collection = LogMetadataDTOCollection()
        for (key, value) in metadata {
            collection = collection.withPublic(key: key, value: value)
        }
        
        return BaseLogContextDTO(
            domainName: "FileSandboxing",
            source: "SandboxedFileOperations",
            metadata: collection
        )
    }
    
    /**
     Validates the security of a path to ensure it doesn't escape the sandbox.
     
     - Parameter path: Path to validate
     - Returns: True if path is safe, false otherwise
     */
    private func isSafePath(_ path: String) -> Bool {
        // Normalise path for security checks
        let normalisedPath = (path as NSString).standardizingPath
        
        // Check for path traversal attempts
        let components = normalisedPath.components(separatedBy: "/")
        
        var depth = 0
        for component in components {
            if component == ".." {
                depth -= 1
                if depth < 0 {
                    // Path would escape the sandbox
                    return false
                }
            } else if component != "." && !component.isEmpty {
                depth += 1
            }
        }
        
        return true
    }
    
    /**
     Resolves a potentially relative path to an absolute path within the sandbox.
     
     - Parameter path: Path to resolve
     - Returns: Absolute path within the sandbox
     - Throws: FileSystemError if path would escape the sandbox
     */
    private func resolvePath(_ path: String) throws -> String {
        // Handle empty path as root directory
        if path.isEmpty {
            return rootDirectoryPath
        }
        
        // Normalise path
        let normalisedPath = (path as NSString).standardizingPath
        
        // Check if already absolute and within sandbox
        if normalisedPath.hasPrefix(rootDirectoryPath) {
            return normalisedPath
        }
        
        // Verify the path is safe
        guard isSafePath(path) else {
            throw FileSystemError.securityViolation(
                path: path, 
                constraint: "Path attempts to escape sandbox"
            )
        }
        
        // Create absolute path
        var absolutePath = rootDirectoryPath
        
        // Ensure there's a separator between root and path
        if !absolutePath.hasSuffix("/") && !normalisedPath.hasPrefix("/") {
            absolutePath += "/"
        }
        
        // Remove leading slash from path to avoid double slashes
        let pathToAppend = normalisedPath.hasPrefix("/") ? String(normalisedPath.dropFirst()) : normalisedPath
        
        absolutePath += pathToAppend
        return (absolutePath as NSString).standardizingPath
    }
    
    // MARK: - CoreFileOperationsProtocol Implementation
    
    public func readFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Reading file in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.readFile(at: resolvedPath)
    }
    
    public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext(["path": path, "encoding": "\(encoding)"])
        await logger.debug("Reading file as string in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.readFileAsString(at: resolvedPath, encoding: encoding)
    }
    
    public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path, "size": "\(data.count)"])
        await logger.debug("Writing file in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.writeFile(data: data, to: resolvedPath, options: options)
    }
    
    public func writeFileFromString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path, "encoding": "\(encoding)", "length": "\(string.count)"])
        await logger.debug("Writing string to file in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.writeFileFromString(string, to: resolvedPath, encoding: encoding, options: options)
    }
    
    public func fileExists(at path: String) async -> (Bool, FileOperationResultDTO) {
        do {
            let context = createLogContext(["path": path])
            await logger.debug("Checking if file exists in sandbox", context: context)
            
            let resolvedPath = try resolvePath(path)
            return await fileService.fileExists(at: resolvedPath)
        } catch {
            // If path resolution fails, the file definitely doesn't exist (safely)
            let result = FileOperationResultDTO.failure(
                path: path,
                errorMessage: "Invalid path: \(error.localizedDescription)"
            )
            return (false, result)
        }
    }
    
    public func isFile(at path: String) async -> (Bool, FileOperationResultDTO) {
        do {
            let context = createLogContext(["path": path])
            await logger.debug("Checking if path is file in sandbox", context: context)
            
            let resolvedPath = try resolvePath(path)
            return await fileService.isFile(at: resolvedPath)
        } catch {
            // If path resolution fails, it's not a file (safely)
            let result = FileOperationResultDTO.failure(
                path: path,
                errorMessage: "Invalid path: \(error.localizedDescription)"
            )
            return (false, result)
        }
    }
    
    public func isDirectory(at path: String) async -> (Bool, FileOperationResultDTO) {
        do {
            let context = createLogContext(["path": path])
            await logger.debug("Checking if path is directory in sandbox", context: context)
            
            let resolvedPath = try resolvePath(path)
            return await fileService.isDirectory(at: resolvedPath)
        } catch {
            // If path resolution fails, it's not a directory (safely)
            let result = FileOperationResultDTO.failure(
                path: path,
                errorMessage: "Invalid path: \(error.localizedDescription)"
            )
            return (false, result)
        }
    }
    
    public func getFileURLs(in path: String) async throws -> ([URL], FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Getting file URLs in sandbox directory", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.getFileURLs(in: resolvedPath)
    }
    
    public func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Creating directory in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.createDirectory(at: resolvedPath, options: options)
    }
    
    public func createFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Creating file in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.createFile(at: resolvedPath, options: options)
    }
    
    public func delete(at path: String) async throws -> FileOperationResultDTO {
        let context = createLogContext(["path": path])
        await logger.debug("Deleting item in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        return try await fileService.delete(at: resolvedPath)
    }
    
    public func move(from sourcePath: String, to destinationPath: String, options: FileMoveOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext([
            "sourcePath": sourcePath,
            "destinationPath": destinationPath
        ])
        await logger.debug("Moving item in sandbox", context: context)
        
        let resolvedSourcePath = try resolvePath(sourcePath)
        let resolvedDestinationPath = try resolvePath(destinationPath)
        
        return try await fileService.move(from: resolvedSourcePath, to: resolvedDestinationPath, options: options)
    }
    
    public func copy(from sourcePath: String, to destinationPath: String, options: FileCopyOptions?) async throws -> FileOperationResultDTO {
        let context = createLogContext([
            "sourcePath": sourcePath,
            "destinationPath": destinationPath
        ])
        await logger.debug("Copying item in sandbox", context: context)
        
        let resolvedSourcePath = try resolvePath(sourcePath)
        let resolvedDestinationPath = try resolvePath(destinationPath)
        
        return try await fileService.copy(from: resolvedSourcePath, to: resolvedDestinationPath, options: options)
    }
    
    public func listDirectoryRecursively(at path: String) async throws -> ([String], FileOperationResultDTO) {
        let context = createLogContext(["path": path])
        await logger.debug("Listing directory recursively in sandbox", context: context)
        
        let resolvedPath = try resolvePath(path)
        
        // Get paths from underlying service
        let (paths, result) = try await fileService.listDirectoryRecursively(at: resolvedPath)
        
        // Paths returned are absolute, convert them to sandbox-relative for consistency
        var sandboxPaths: [String] = []
        for absolutePath in paths {
            if absolutePath.hasPrefix(rootDirectoryPath) {
                var relativePath = String(absolutePath.dropFirst(rootDirectoryPath.count))
                if relativePath.hasPrefix("/") {
                    relativePath = String(relativePath.dropFirst())
                }
                sandboxPaths.append(relativePath)
            } else {
                // If a path somehow escaped the sandbox (shouldn't happen), log and skip it
                let errorContext = createLogContext([
                    "path": path,
                    "absolutePath": absolutePath
                ])
                await logger.warning("Path outside sandbox encountered, skipping", context: errorContext)
            }
        }
        
        return (sandboxPaths, result)
    }
}

/// A simple no-op implementation of LoggingProtocol for default initialization
private actor LoggingProtocol_NoOp: LoggingProtocol {
    private let _loggingActor = LoggingActor(destinations: [])
    
    nonisolated var loggingActor: LoggingActor {
        return _loggingActor
    }
    
    func log(_ level: LogLevel, _ message: String, context: LogContextDTO) async {}
    func debug(_ message: String, context: LogContextDTO) async {}
    func info(_ message: String, context: LogContextDTO) async {}
    func notice(_ message: String, context: LogContextDTO) async {}
    func warning(_ message: String, context: LogContextDTO) async {}
    func error(_ message: String, context: LogContextDTO) async {}
    func critical(_ message: String, context: LogContextDTO) async {}
}
