import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import CoreFileOperations
import FileMetadataOperations
import SecureFileOperations
import FileSandboxing

/**
 # Composite File System Service Implementation
 
 A composite implementation that combines all file system operation subdomains.
 
 This actor-based implementation delegates operations to the appropriate
 subdomain implementations, providing a unified interface for all file
 system operations while maintaining separation of concerns internally.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Leverages dependency injection for modularity
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 */
public actor CompositeFileSystemServiceImpl: CompositeFileSystemServiceProtocol {
    /// Core file operations implementation
    private let coreOperations: any CoreFileOperationsProtocol
    
    /// File metadata operations implementation
    private let metadataOperations: any FileMetadataOperationsProtocol
    
    /// Secure file operations implementation
    private let secureOperations: any SecureFileOperationsProtocol
    
    /// File sandboxing implementation
    private let sandboxing: any FileSandboxingProtocol
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new composite file system service implementation.
     
     - Parameters:
        - coreOperations: The core file operations implementation
        - metadataOperations: The file metadata operations implementation
        - secureOperations: The secure file operations implementation
        - sandboxing: The file sandboxing implementation
        - logger: Optional logger for recording operations
     */
    public init(
        coreOperations: any CoreFileOperationsProtocol,
        metadataOperations: any FileMetadataOperationsProtocol,
        secureOperations: any SecureFileOperationsProtocol,
        sandboxing: any FileSandboxingProtocol,
        logger: (any LoggingProtocol)? = nil
    ) {
        self.coreOperations = coreOperations
        self.metadataOperations = metadataOperations
        self.secureOperations = secureOperations
        self.sandboxing = sandboxing
        self.logger = logger ?? NullLogger()
    }
    
    // MARK: - CoreFileOperationsProtocol
    
    public func readFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
        await logger.debug("Delegating readFile operation", metadata: ["path": path])
        return try await coreOperations.readFile(at: path)
    }
    
    public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Delegating readFileAsString operation", metadata: ["path": path])
        return try await coreOperations.readFileAsString(at: path, encoding: encoding)
    }
    
    public func fileExists(at path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Delegating fileExists operation", metadata: ["path": path])
        return await coreOperations.fileExists(at: path)
    }
    
    public func isFile(at path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Delegating isFile operation", metadata: ["path": path])
        return await coreOperations.isFile(at: path)
    }
    
    public func isDirectory(at path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Delegating isDirectory operation", metadata: ["path": path])
        return await coreOperations.isDirectory(at: path)
    }
    
    public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating writeFile operation", metadata: ["path": path])
        return try await coreOperations.writeFile(data: data, to: path, options: options)
    }
    
    public func writeString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating writeString operation", metadata: ["path": path])
        return try await coreOperations.writeString(string, to: path, encoding: encoding, options: options)
    }
    
    public func normalisePath(_ path: String) async -> String {
        await logger.debug("Delegating normalisePath operation", metadata: ["path": path])
        return await coreOperations.normalisePath(path)
    }
    
    public func temporaryDirectoryPath() async -> String {
        await logger.debug("Delegating temporaryDirectoryPath operation")
        return await coreOperations.temporaryDirectoryPath()
    }
    
    public func createUniqueFilename(in directory: String, prefix: String?, extension: String?) async -> String {
        await logger.debug("Delegating createUniqueFilename operation", metadata: ["directory": directory])
        return await coreOperations.createUniqueFilename(in: directory, prefix: prefix, extension: `extension`)
    }
    
    // MARK: - FileMetadataOperationsProtocol
    
    public func getAttributes(at path: String) async throws -> (FileMetadataDTO, FileOperationResultDTO) {
        await logger.debug("Delegating getAttributes operation", metadata: ["path": path])
        return try await metadataOperations.getAttributes(at: path)
    }
    
    public func setAttributes(_ attributes: [FileAttributeKey: Any], at path: String) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating setAttributes operation", metadata: ["path": path])
        return try await metadataOperations.setAttributes(attributes, at: path)
    }
    
    public func getFileSize(at path: String) async throws -> (UInt64, FileOperationResultDTO) {
        await logger.debug("Delegating getFileSize operation", metadata: ["path": path])
        return try await metadataOperations.getFileSize(at: path)
    }
    
    public func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
        await logger.debug("Delegating getCreationDate operation", metadata: ["path": path])
        return try await metadataOperations.getCreationDate(at: path)
    }
    
    public func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
        await logger.debug("Delegating getModificationDate operation", metadata: ["path": path])
        return try await metadataOperations.getModificationDate(at: path)
    }
    
    public func getExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> (ExtendedAttributeDTO, FileOperationResultDTO) {
        await logger.debug("Delegating getExtendedAttribute operation", metadata: ["path": path, "attribute": name])
        return try await metadataOperations.getExtendedAttribute(withName: name, fromItemAtPath: path)
    }
    
    public func setExtendedAttribute(_ attribute: ExtendedAttributeDTO, onItemAtPath path: String) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating setExtendedAttribute operation", metadata: ["path": path, "attribute": attribute.name])
        return try await metadataOperations.setExtendedAttribute(attribute, onItemAtPath: path)
    }
    
    public func listExtendedAttributes(atPath path: String) async throws -> ([String], FileOperationResultDTO) {
        await logger.debug("Delegating listExtendedAttributes operation", metadata: ["path": path])
        return try await metadataOperations.listExtendedAttributes(atPath: path)
    }
    
    public func removeExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating removeExtendedAttribute operation", metadata: ["path": path, "attribute": name])
        return try await metadataOperations.removeExtendedAttribute(withName: name, fromItemAtPath: path)
    }
    
    // MARK: - SecureFileOperationsProtocol
    
    public func createSecurityBookmark(for path: String, readOnly: Bool) async throws -> (Data, FileOperationResultDTO) {
        await logger.debug("Delegating createSecurityBookmark operation", metadata: ["path": path])
        return try await secureOperations.createSecurityBookmark(for: path, readOnly: readOnly)
    }
    
    public func resolveSecurityBookmark(_ bookmark: Data) async throws -> (String, Bool, FileOperationResultDTO) {
        await logger.debug("Delegating resolveSecurityBookmark operation")
        return try await secureOperations.resolveSecurityBookmark(bookmark)
    }
    
    public func startAccessingSecurityScopedResource(at path: String) async throws -> (Bool, FileOperationResultDTO) {
        await logger.debug("Delegating startAccessingSecurityScopedResource operation", metadata: ["path": path])
        return try await secureOperations.startAccessingSecurityScopedResource(at: path)
    }
    
    public func stopAccessingSecurityScopedResource(at path: String) async -> FileOperationResultDTO {
        await logger.debug("Delegating stopAccessingSecurityScopedResource operation", metadata: ["path": path])
        return await secureOperations.stopAccessingSecurityScopedResource(at: path)
    }
    
    public func createSecureTemporaryFile(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Delegating createSecureTemporaryFile operation")
        return try await secureOperations.createSecureTemporaryFile(options: options)
    }
    
    public func createSecureTemporaryDirectory(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Delegating createSecureTemporaryDirectory operation")
        return try await secureOperations.createSecureTemporaryDirectory(options: options)
    }
    
    public func writeSecureFile(data: Data, to path: String, options: SecureFileOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating writeSecureFile operation", metadata: ["path": path])
        return try await secureOperations.writeSecureFile(data: data, to: path, options: options)
    }
    
    public func secureDelete(at path: String, passes: Int) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating secureDelete operation", metadata: ["path": path])
        return try await secureOperations.secureDelete(at: path, passes: passes)
    }
    
    public func verifyFileIntegrity(at path: String, expectedChecksum: Data, algorithm: ChecksumAlgorithm) async throws -> (Bool, FileOperationResultDTO) {
        await logger.debug("Delegating verifyFileIntegrity operation", metadata: ["path": path])
        return try await secureOperations.verifyFileIntegrity(at: path, expectedChecksum: expectedChecksum, algorithm: algorithm)
    }
    
    // MARK: - FileSandboxingProtocol
    
    public static func createSandboxed(rootDirectory: String) -> (Self, FileOperationResultDTO) {
        fatalError("Cannot be used to create a sandboxed instance. Use FileSystemServiceFactory instead.")
    }
    
    public func isPathWithinSandbox(_ path: String) async -> (Bool, FileOperationResultDTO) {
        await logger.debug("Delegating isPathWithinSandbox operation", metadata: ["path": path])
        return await sandboxing.isPathWithinSandbox(path)
    }
    
    public func pathRelativeToSandbox(_ path: String) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Delegating pathRelativeToSandbox operation", metadata: ["path": path])
        return try await sandboxing.pathRelativeToSandbox(path)
    }
    
    public func sandboxRootDirectory() async -> String {
        await logger.debug("Delegating sandboxRootDirectory operation")
        return await sandboxing.sandboxRootDirectory()
    }
    
    public func createSandboxedDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Delegating createSandboxedDirectory operation", metadata: ["path": path])
        return try await sandboxing.createSandboxedDirectory(at: path, options: options)
    }
    
    public func createSandboxedFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Delegating createSandboxedFile operation", metadata: ["path": path])
        return try await sandboxing.createSandboxedFile(at: path, options: options)
    }
    
    public func writeSandboxedFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Delegating writeSandboxedFile operation", metadata: ["path": path])
        return try await sandboxing.writeSandboxedFile(data: data, to: path, options: options)
    }
    
    public func listSandboxedDirectory(at path: String) async throws -> ([String], FileOperationResultDTO) {
        await logger.debug("Delegating listSandboxedDirectory operation", metadata: ["path": path])
        return try await sandboxing.listSandboxedDirectory(at: path)
    }
    
    // MARK: - CompositeFileSystemServiceProtocol Additional Operations
    
    public func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Handling createDirectory operation", metadata: ["path": path])
        
        // Check if the path is within the sandbox
        let (isWithinSandbox, _) = await sandboxing.isPathWithinSandbox(path)
        
        if isWithinSandbox {
            // Use sandboxed implementation if within sandbox
            return try await sandboxing.createSandboxedDirectory(at: path, options: options)
        } else {
            // If not in sandbox, create directly using FileManager
            let fileManager = FileManager.default
            
            do {
                // Create the directory
                try fileManager.createDirectory(
                    atPath: path,
                    withIntermediateDirectories: options?.createIntermediates ?? false,
                    attributes: options?.attributes
                )
                
                // Get the directory attributes for the result metadata
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let metadata = FileMetadataDTO.from(attributes: attributes)
                
                let result = FileOperationResultDTO.success(
                    path: path,
                    metadata: metadata,
                    context: ["operation": "createDirectory"]
                )
                
                return (path, result)
            } catch {
                let dirError = FileSystemError.createDirectoryError(
                    path: path,
                    reason: "Failed to create directory: \(error.localizedDescription)"
                )
                await logger.error("Failed to create directory: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
                throw dirError
            }
        }
    }
    
    public func createFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        await logger.debug("Handling createFile operation", metadata: ["path": path])
        
        // Check if the path is within the sandbox
        let (isWithinSandbox, _) = await sandboxing.isPathWithinSandbox(path)
        
        if isWithinSandbox {
            // Use sandboxed implementation if within sandbox
            return try await sandboxing.createSandboxedFile(at: path, options: options)
        } else {
            // If not in sandbox, create directly using FileManager
            let fileManager = FileManager.default
            
            do {
                // Check if we need to create intermediate directories
                if options?.createIntermediateDirectories == true {
                    let dirPath = (path as NSString).deletingLastPathComponent
                    if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                        try fileManager.createDirectory(
                            atPath: dirPath,
                            withIntermediateDirectories: true,
                            attributes: nil
                        )
                    }
                }
                
                // Check if the file exists and if we should overwrite
                let overwrite = options?.overwrite ?? false
                if fileManager.fileExists(atPath: path) && !overwrite {
                    throw FileSystemError.createError(
                        path: path,
                        reason: "File already exists and overwrite not allowed"
                    )
                }
                
                // Create the file with the specified attributes
                let created = fileManager.createFile(
                    atPath: path,
                    contents: nil,
                    attributes: options?.attributes
                )
                
                guard created else {
                    throw FileSystemError.createError(
                        path: path,
                        reason: "Failed to create file"
                    )
                }
                
                // Get the file attributes for the result metadata
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let metadata = FileMetadataDTO.from(attributes: attributes)
                
                let result = FileOperationResultDTO.success(
                    path: path,
                    metadata: metadata,
                    context: ["operation": "createFile"]
                )
                
                return (path, result)
            } catch let fsError as FileSystemError {
                throw fsError
            } catch {
                let fileError = FileSystemError.createError(
                    path: path,
                    reason: "Failed to create file: \(error.localizedDescription)"
                )
                await logger.error("Failed to create file: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
                throw fileError
            }
        }
    }
    
    public func delete(at path: String) async throws -> FileOperationResultDTO {
        await logger.debug("Handling delete operation", metadata: ["path": path])
        
        let fileManager = FileManager.default
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", metadata: ["path": path])
                throw error
            }
            
            // Get the file attributes for the result context before deletion
            let attributes = try fileManager.attributesOfItem(atPath: path)
            var context: [String: String] = ["operation": "delete"]
            
            if let fileType = attributes[.type] as? String {
                context["fileType"] = fileType
            }
            
            if let fileSize = attributes[.size] as? UInt64 {
                context["fileSize"] = "\(fileSize)"
            }
            
            // Delete the item
            try fileManager.removeItem(atPath: path)
            
            let result = FileOperationResultDTO.success(
                path: path,
                context: context
            )
            
            await logger.debug("Successfully deleted item at \(path)", metadata: ["path": path])
            return result
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let deleteError = FileSystemError.deleteError(
                path: path,
                reason: "Failed to delete item: \(error.localizedDescription)"
            )
            await logger.error("Failed to delete item: \(error.localizedDescription)", metadata: ["path": path, "error": "\(error)"])
            throw deleteError
        }
    }
    
    public func move(from sourcePath: String, to destinationPath: String, options: FileMoveOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Handling move operation", metadata: [
            "sourcePath": sourcePath,
            "destinationPath": destinationPath
        ])
        
        let fileManager = FileManager.default
        
        do {
            // Check if the source exists
            guard fileManager.fileExists(atPath: sourcePath) else {
                let error = FileSystemError.pathNotFound(path: sourcePath)
                await logger.error("Source file not found: \(sourcePath)", metadata: ["path": sourcePath])
                throw error
            }
            
            // Check if the destination exists and if we should overwrite
            let overwrite = options?.overwrite ?? false
            if fileManager.fileExists(atPath: destinationPath) && !overwrite {
                throw FileSystemError.moveError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Destination already exists and overwrite not allowed"
                )
            }
            
            // Create intermediate directories if needed
            if options?.createIntermediateDirectories == true {
                let dirPath = (destinationPath as NSString).deletingLastPathComponent
                if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                    try fileManager.createDirectory(
                        atPath: dirPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            }
            
            // Remove destination if it exists and overwrite is allowed
            if fileManager.fileExists(atPath: destinationPath) && overwrite {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Move the item
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: destinationPath)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: destinationPath,
                metadata: metadata,
                context: [
                    "operation": "move",
                    "source": sourcePath,
                    "destination": destinationPath
                ]
            )
            
            await logger.debug("Successfully moved item from \(sourcePath) to \(destinationPath)", metadata: [
                "sourcePath": sourcePath,
                "destinationPath": destinationPath
            ])
            
            return result
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let moveError = FileSystemError.moveError(
                source: sourcePath,
                destination: destinationPath,
                reason: "Failed to move item: \(error.localizedDescription)"
            )
            await logger.error("Failed to move item: \(error.localizedDescription)", metadata: [
                "sourcePath": sourcePath,
                "destinationPath": destinationPath,
                "error": "\(error)"
            ])
            throw moveError
        }
    }
    
    public func copy(from sourcePath: String, to destinationPath: String, options: FileCopyOptions?) async throws -> FileOperationResultDTO {
        await logger.debug("Handling copy operation", metadata: [
            "sourcePath": sourcePath,
            "destinationPath": destinationPath
        ])
        
        let fileManager = FileManager.default
        
        do {
            // Check if the source exists
            guard fileManager.fileExists(atPath: sourcePath) else {
                let error = FileSystemError.pathNotFound(path: sourcePath)
                await logger.error("Source file not found: \(sourcePath)", metadata: ["path": sourcePath])
                throw error
            }
            
            // Check if the destination exists and if we should overwrite
            let overwrite = options?.overwrite ?? false
            if fileManager.fileExists(atPath: destinationPath) && !overwrite {
                throw FileSystemError.copyError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Destination already exists and overwrite not allowed"
                )
            }
            
            // Create intermediate directories if needed
            if options?.createIntermediateDirectories == true {
                let dirPath = (destinationPath as NSString).deletingLastPathComponent
                if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                    try fileManager.createDirectory(
                        atPath: dirPath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            }
            
            // Remove destination if it exists and overwrite is allowed
            if fileManager.fileExists(atPath: destinationPath) && overwrite {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Copy the item
            try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: destinationPath)
            let metadata = FileMetadataDTO.from(attributes: attributes)
            
            let result = FileOperationResultDTO.success(
                path: destinationPath,
                metadata: metadata,
                context: [
                    "operation": "copy",
                    "source": sourcePath,
                    "destination": destinationPath
                ]
            )
            
            await logger.debug("Successfully copied item from \(sourcePath) to \(destinationPath)", metadata: [
                "sourcePath": sourcePath,
                "destinationPath": destinationPath
            ])
            
            return result
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let copyError = FileSystemError.copyError(
                source: sourcePath,
                destination: destinationPath,
                reason: "Failed to copy item: \(error.localizedDescription)"
            )
            await logger.error("Failed to copy item: \(error.localizedDescription)", metadata: [
                "sourcePath": sourcePath,
                "destinationPath": destinationPath,
                "error": "\(error)"
            ])
            throw copyError
        }
    }
    
    public func listDirectoryRecursively(at path: String) async throws -> ([String], FileOperationResultDTO) {
        await logger.debug("Handling listDirectoryRecursively operation", metadata: ["path": path])
        
        let fileManager = FileManager.default
        
        do {
            // Check if directory exists
            var isDir: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
            
            guard exists else {
                throw FileSystemError.pathNotFound(path: path)
            }
            
            guard isDir.boolValue else {
                throw FileSystemError.genericError(reason: "Path is not a directory: \(path)")
            }
            
            // Get directory enumerator
            guard let enumerator = fileManager.enumerator(atPath: path) else {
                throw FileSystemError.genericError(reason: "Failed to create directory enumerator")
            }
            
            // Build list of paths
            var paths = [String]()
            while let relativePath = enumerator.nextObject() as? String {
                let fullPath = (path as NSString).appendingPathComponent(relativePath)
                paths.append(fullPath)
            }
            
            // Get the directory attributes for the result metadata
            let dirAttributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(attributes: dirAttributes)
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata,
                context: [
                    "operation": "listDirectoryRecursively",
                    "itemCount": "\(paths.count)"
                ]
            )
            
            await logger.debug("Successfully listed directory recursively", metadata: [
                "path": path,
                "itemCount": "\(paths.count)"
            ])
            
            return (paths, result)
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let dirError = FileSystemError.genericError(
                reason: "Failed to list directory recursively: \(error.localizedDescription)"
            )
            await logger.error("Failed to list directory recursively: \(error.localizedDescription)", metadata: [
                "path": path,
                "error": "\(error)"
            ])
            throw dirError
        }
    }
}
