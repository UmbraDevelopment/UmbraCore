import Foundation
import FileSystemInterfaces
import LoggingInterfaces

/**
 # File Sandboxing Implementation
 
 The implementation of FileSandboxingProtocol that restricts file operations
 to a specific directory.
 
 This actor-based implementation ensures all operations are thread-safe through
 Swift concurrency. It provides sandbox restriction features to limit file
 operations to a specific directory for security.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 - Returns standardised operation results
 */
public actor FileSandboxingImpl: FileSandboxingProtocol {
    /// The underlying file manager isolated within this actor
    private let fileManager: FileManager
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /// The root directory of the sandbox
    private let rootDirectory: String
    
    /**
     Initialises a new file sandboxing implementation.
     
     - Parameters:
        - rootDirectory: The root directory to sandbox operations to
        - fileManager: Optional custom file manager to use
        - logger: Optional logger for recording operations
     */
    private init(rootDirectory: String, fileManager: FileManager = .default, logger: (any LoggingProtocol)? = nil) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
        self.logger = logger ?? NullLogger()
    }
    
    /**
     Creates a sandboxed file system service instance that restricts
     all operations to within the specified root directory.
     
     - Parameter rootDirectory: The directory to restrict operations to
     - Returns: A sandboxed service instance and operation result
     */
    public static func createSandboxed(rootDirectory: String) -> (Self, FileOperationResultDTO) {
        let normalizedRoot = (rootDirectory as NSString).standardizingPath
        let instance = FileSandboxingImpl(rootDirectory: normalizedRoot)
        
        let result = FileOperationResultDTO.success(
            path: normalizedRoot,
            context: [
                "operation": "createSandboxed",
                "sandbox": normalizedRoot
            ]
        )
        
        return (instance, result)
    }
    
    /**
     Validates whether a path is within the sandbox.
     
     - Parameter path: The path to validate
     - Returns: True if the path is within the sandbox, false otherwise, and operation result
     */
    public func isPathWithinSandbox(_ path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Checking if path is within sandbox", metadata: [
            "path": path,
            "sandbox": rootDirectory
        ])
        
        let normalizedPath = (path as NSString).standardizingPath
        let isWithin = normalizedPath.hasPrefix(rootDirectory) || normalizedPath == rootDirectory
        
        let result = FileOperationResultDTO.success(
            path: path,
            context: [
                "operation": "isPathWithinSandbox",
                "sandbox": rootDirectory,
                "isWithin": "\(isWithin)"
            ]
        )
        
        await logger.debug("Path within sandbox check result: \(isWithin)", metadata: [
            "path": path,
            "sandbox": rootDirectory,
            "isWithin": "\(isWithin)"
        ])
        
        return (isWithin, result)
    }
    
    /**
     Transforms an absolute path to a path relative to the sandbox root.
     
     - Parameter path: The absolute path to transform
     - Returns: The path relative to the sandbox root and operation result
     - Throws: If the path is outside the sandbox
     */
    public func pathRelativeToSandbox(_ path: String) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Converting path to be relative to sandbox", metadata: [
            "path": path,
            "sandbox": rootDirectory
        ])
        
        let normalizedPath = (path as NSString).standardizingPath
        
        // Check if the path is within the sandbox
        guard normalizedPath.hasPrefix(rootDirectory) || normalizedPath == rootDirectory else {
            let error = FileSystemError.sandboxViolation(path: normalizedPath, sandbox: rootDirectory)
            await logger.error("Path is outside sandbox: \(normalizedPath)", metadata: [
                "path": normalizedPath,
                "sandbox": rootDirectory
            ])
            throw error
        }
        
        // Get the relative path
        var relativePath = ""
        if normalizedPath == rootDirectory {
            relativePath = "."
        } else {
            let index = normalizedPath.index(normalizedPath.startIndex, offsetBy: rootDirectory.count)
            var subPath = String(normalizedPath[index...])
            
            // Remove leading slash if present
            if subPath.hasPrefix("/") {
                subPath.removeFirst()
            }
            
            relativePath = subPath.isEmpty ? "." : subPath
        }
        
        let result = FileOperationResultDTO.success(
            path: path,
            context: [
                "operation": "pathRelativeToSandbox",
                "sandbox": rootDirectory,
                "relativePath": relativePath
            ]
        )
        
        await logger.debug("Converted path to relative: \(relativePath)", metadata: [
            "path": path,
            "sandbox": rootDirectory,
            "relativePath": relativePath
        ])
        
        return (relativePath, result)
    }
    
    /**
     Gets the sandbox root directory.
     
     - Returns: The path to the sandbox root directory
     */
    public func sandboxRootDirectory() async -> String {
        await logger.debug("Getting sandbox root directory", metadata: ["sandbox": rootDirectory])
        return rootDirectory
    }
    
    /**
     Creates a directory within the sandbox.
     
     - Parameters:
        - path: The path where the directory should be created
        - options: Optional creation options
     - Returns: The path to the created directory and operation result
     - Throws: If the directory cannot be created or the path is outside the sandbox
     */
    public func createSandboxedDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Creating sandboxed directory", metadata: [
            "path": path,
            "sandbox": rootDirectory
        ])
        
        // Get the absolute path
        let normalizedPath = (path as NSString).standardizingPath
        let absolutePath: String
        
        // If the path is already absolute and within the sandbox, use it
        if normalizedPath.hasPrefix("/") {
            // Check if the path is within the sandbox
            guard normalizedPath.hasPrefix(rootDirectory) else {
                let error = FileSystemError.sandboxViolation(path: normalizedPath, sandbox: rootDirectory)
                await logger.error("Path is outside sandbox: \(normalizedPath)", metadata: [
                    "path": normalizedPath,
                    "sandbox": rootDirectory
                ])
                throw error
            }
            absolutePath = normalizedPath
        } else {
            // Relative path, so join with sandbox root
            absolutePath = (rootDirectory as NSString).appendingPathComponent(normalizedPath)
        }
        
        do {
            // Create the directory with the specified options
            let createIntermediates = options?.createIntermediates ?? false
            let attributes = options?.attributes
            
            try fileManager.createDirectory(
                atPath: absolutePath,
                withIntermediateDirectories: createIntermediates,
                attributes: attributes
            )
            
            // Get the directory attributes for the result metadata
            let dirAttributes = try fileManager.attributesOfItem(atPath: absolutePath)
            let metadata = FileMetadataDTO.from(attributes: dirAttributes)
            
            let result = FileOperationResultDTO.success(
                path: absolutePath,
                metadata: metadata,
                context: [
                    "operation": "createSandboxedDirectory",
                    "sandbox": rootDirectory
                ]
            )
            
            await logger.debug("Successfully created sandboxed directory", metadata: [
                "path": absolutePath,
                "sandbox": rootDirectory
            ])
            
            return (absolutePath, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let dirError = FileSystemError.createDirectoryError(
                path: absolutePath,
                reason: "Failed to create directory: \(error.localizedDescription)"
            )
            await logger.error("Failed to create directory: \(error.localizedDescription)", metadata: [
                "path": absolutePath,
                "error": "\(error)"
            ])
            throw dirError
        }
    }
    
    /**
     Creates a file within the sandbox.
     
     - Parameters:
        - path: The path where the file should be created
        - options: Optional creation options
     - Returns: The path to the created file and operation result
     - Throws: If the file cannot be created or the path is outside the sandbox
     */
    public func createSandboxedFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Creating sandboxed file", metadata: [
            "path": path,
            "sandbox": rootDirectory
        ])
        
        // Get the absolute path
        let normalizedPath = (path as NSString).standardizingPath
        let absolutePath: String
        
        // If the path is already absolute and within the sandbox, use it
        if normalizedPath.hasPrefix("/") {
            // Check if the path is within the sandbox
            guard normalizedPath.hasPrefix(rootDirectory) else {
                let error = FileSystemError.sandboxViolation(path: normalizedPath, sandbox: rootDirectory)
                await logger.error("Path is outside sandbox: \(normalizedPath)", metadata: [
                    "path": normalizedPath,
                    "sandbox": rootDirectory
                ])
                throw error
            }
            absolutePath = normalizedPath
        } else {
            // Relative path, so join with sandbox root
            absolutePath = (rootDirectory as NSString).appendingPathComponent(normalizedPath)
        }
        
        do {
            // Check if we need to create intermediate directories
            if options?.createIntermediateDirectories == true {
                let dirPath = (absolutePath as NSString).deletingLastPathComponent
                if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                    try fileManager.createDirectory(
                        atPath: dirPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            }
            
            // Check if the file already exists and if we should overwrite
            let overwrite = options?.overwrite ?? false
            if fileManager.fileExists(atPath: absolutePath) && !overwrite {
                throw FileSystemError.createError(
                    path: absolutePath,
                    reason: "File already exists and overwrite not allowed"
                )
            }
            
            // Create the file with the specified attributes
            let created = fileManager.createFile(
                atPath: absolutePath,
                contents: nil,
                attributes: options?.attributes
            )
            
            guard created else {
                throw FileSystemError.createError(
                    path: absolutePath,
                    reason: "Failed to create file"
                )
            }
            
            // Get the file attributes for the result metadata
            let fileAttributes = try fileManager.attributesOfItem(atPath: absolutePath)
            let metadata = FileMetadataDTO.from(attributes: fileAttributes)
            
            let result = FileOperationResultDTO.success(
                path: absolutePath,
                metadata: metadata,
                context: [
                    "operation": "createSandboxedFile",
                    "sandbox": rootDirectory
                ]
            )
            
            await logger.debug("Successfully created sandboxed file", metadata: [
                "path": absolutePath,
                "sandbox": rootDirectory
            ])
            
            return (absolutePath, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.createError(
                path: absolutePath,
                reason: "Failed to create file: \(error.localizedDescription)"
            )
            await logger.error("Failed to create file: \(error.localizedDescription)", metadata: [
                "path": absolutePath,
                "error": "\(error)"
            ])
            throw fileError
        }
    }
    
    /**
     Writes data to a file within the sandbox.
     
     - Parameters:
        - data: The data to write
        - path: The path to write to
        - options: Optional write options
     - Returns: Operation result
     - Throws: If the write operation fails or the path is outside the sandbox
     */
    public func writeSandboxedFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Writing to sandboxed file", metadata: [
            "path": path,
            "sandbox": rootDirectory,
            "size": "\(data.count)"
        ])
        
        // Get the absolute path
        let normalizedPath = (path as NSString).standardizingPath
        let absolutePath: String
        
        // If the path is already absolute and within the sandbox, use it
        if normalizedPath.hasPrefix("/") {
            // Check if the path is within the sandbox
            guard normalizedPath.hasPrefix(rootDirectory) else {
                let error = FileSystemError.sandboxViolation(path: normalizedPath, sandbox: rootDirectory)
                await logger.error("Path is outside sandbox: \(normalizedPath)", metadata: [
                    "path": normalizedPath,
                    "sandbox": rootDirectory
                ])
                throw error
            }
            absolutePath = normalizedPath
        } else {
            // Relative path, so join with sandbox root
            absolutePath = (rootDirectory as NSString).appendingPathComponent(normalizedPath)
        }
        
        do {
            // Create intermediate directories if needed
            if options?.createIntermediateDirectories == true {
                let dirPath = (absolutePath as NSString).deletingLastPathComponent
                if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                    try fileManager.createDirectory(
                        atPath: dirPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            }
            
            // Determine write options based on append flag
            let writeOptions: Data.WritingOptions = options?.append == true ? .atomic : .atomicWrite
            
            // Write the data
            try data.write(to: URL(fileURLWithPath: absolutePath), options: writeOptions)
            
            // Get the file attributes for the result metadata
            let fileAttributes = try fileManager.attributesOfItem(atPath: absolutePath)
            let metadata = FileMetadataDTO.from(attributes: fileAttributes)
            
            let result = FileOperationResultDTO.success(
                path: absolutePath,
                metadata: metadata,
                context: [
                    "operation": "writeSandboxedFile",
                    "sandbox": rootDirectory,
                    "fileSize": "\(data.count)"
                ]
            )
            
            await logger.debug("Successfully wrote to sandboxed file", metadata: [
                "path": absolutePath,
                "sandbox": rootDirectory,
                "size": "\(data.count)"
            ])
            
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.writeError(
                path: absolutePath,
                reason: "Failed to write file: \(error.localizedDescription)"
            )
            await logger.error("Failed to write file: \(error.localizedDescription)", metadata: [
                "path": absolutePath,
                "error": "\(error)"
            ])
            throw fileError
        }
    }
    
    /**
     Lists the contents of a directory within the sandbox.
     
     - Parameter path: The path to the directory to list
     - Returns: An array of file paths contained in the directory and operation result
     - Throws: If the directory cannot be read or the path is outside the sandbox
     */
    public func listSandboxedDirectory(at path: String) async throws -> ([String], FileOperationResultDTO) {
        await logger.debug("Listing sandboxed directory", metadata: [
            "path": path,
            "sandbox": rootDirectory
        ])
        
        // Get the absolute path
        let normalizedPath = (path as NSString).standardizingPath
        let absolutePath: String
        
        // If the path is already absolute and within the sandbox, use it
        if normalizedPath.hasPrefix("/") {
            // Check if the path is within the sandbox
            guard normalizedPath.hasPrefix(rootDirectory) else {
                let error = FileSystemError.sandboxViolation(path: normalizedPath, sandbox: rootDirectory)
                await logger.error("Path is outside sandbox: \(normalizedPath)", metadata: [
                    "path": normalizedPath,
                    "sandbox": rootDirectory
                ])
                throw error
            }
            absolutePath = normalizedPath
        } else {
            // Relative path, so join with sandbox root
            absolutePath = (rootDirectory as NSString).appendingPathComponent(normalizedPath)
        }
        
        do {
            // Check if directory exists
            var isDir: ObjCBool = false
            let exists = fileManager.fileExists(atPath: absolutePath, isDirectory: &isDir)
            
            guard exists else {
                throw FileSystemError.pathNotFound(path: absolutePath)
            }
            
            guard isDir.boolValue else {
                throw FileSystemError.genericError(reason: "Path is not a directory: \(absolutePath)")
            }
            
            // List directory contents
            let contents = try fileManager.contentsOfDirectory(atPath: absolutePath)
            
            // Convert to absolute paths within sandbox
            let absolutePaths = contents.map { (absolutePath as NSString).appendingPathComponent($0) }
            
            // Get the directory attributes for the result metadata
            let dirAttributes = try fileManager.attributesOfItem(atPath: absolutePath)
            let metadata = FileMetadataDTO.from(attributes: dirAttributes)
            
            let result = FileOperationResultDTO.success(
                path: absolutePath,
                metadata: metadata,
                context: [
                    "operation": "listSandboxedDirectory",
                    "sandbox": rootDirectory,
                    "itemCount": "\(contents.count)"
                ]
            )
            
            await logger.debug("Successfully listed sandboxed directory", metadata: [
                "path": absolutePath,
                "sandbox": rootDirectory,
                "itemCount": "\(contents.count)"
            ])
            
            return (absolutePaths, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let dirError = FileSystemError.genericError(
                reason: "Failed to list directory: \(error.localizedDescription)"
            )
            await logger.error("Failed to list directory: \(error.localizedDescription)", metadata: [
                "path": absolutePath,
                "error": "\(error)"
            ])
            throw dirError
        }
    }
}
