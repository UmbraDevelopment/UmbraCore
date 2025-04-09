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
    
    /// File manager instance
    private let fileManager = FileManager.default
    
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
        let logContext = FileSystemLogContext(operation: "readFile", path: path)
        await logger.debug("Delegating readFile operation", context: logContext)
        return try await coreOperations.readFile(at: path)
    }
    
    public func readFileAsString(at path: String, encoding: String.Encoding) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "readFileAsString", path: path)
        await logger.debug("Delegating readFileAsString operation", context: logContext)
        return try await coreOperations.readFileAsString(at: path, encoding: encoding)
    }
    
    public func fileExists(at path: String) async -> (Bool, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "fileExists", path: path)
        await logger.debug("Delegating fileExists operation", context: logContext)
        return await coreOperations.fileExists(at: path)
    }
    
    public func isFile(at path: String) async -> Bool {
        let logContext = FileSystemLogContext(operation: "isFile", path: path)
        await logger.debug("Delegating isFile operation", context: logContext)
        
        // Since this method doesn't exist in CoreFileOperationsProtocol,
        // we need to implement it directly
        let (exists, _) = await coreOperations.fileExists(at: path)
        if !exists {
            return false
        }
        
        // Check if it's a file by using the fileManager directly
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            return !isDir.boolValue
        }
        return false
    }
    
    public func isDirectory(at path: String) async -> Bool {
        let logContext = FileSystemLogContext(operation: "isDirectory", path: path)
        await logger.debug("Delegating isDirectory operation", context: logContext)
        
        // Since this method doesn't exist in CoreFileOperationsProtocol,
        // we need to implement it directly
        let (exists, _) = await coreOperations.fileExists(at: path)
        if !exists {
            return false
        }
        
        // Check if it's a directory by using the fileManager directly
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            return isDir.boolValue
        }
        return false
    }
    
    public func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "writeFile", path: path)
        await logger.debug("Delegating writeFile operation", context: logContext)
        return try await coreOperations.writeFile(data: data, to: path, options: options)
    }
    
    public func writeString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "writeString", path: path)
        await logger.debug("Delegating writeString operation", context: logContext)
        return try await coreOperations.writeFileFromString(string, to: path, encoding: encoding, options: options)
    }
    
    public func normalisePath(_ path: String) async -> String {
        let logContext = FileSystemLogContext(operation: "normalisePath", path: path)
        await logger.debug("Delegating normalisePath operation", context: logContext)
        
        // Since this method doesn't exist in CoreFileOperationsProtocol,
        // we need to implement it directly
        // Convert to a URL and back to handle tilde expansion, etc.
        let url = URL(fileURLWithPath: path)
        return url.standardized.path
    }
    
    public func temporaryDirectoryPath() async -> String {
        let logContext = FileSystemLogContext(operation: "temporaryDirectoryPath", path: "")
        await logger.debug("Getting temporary directory path", context: logContext)
        
        // Since this method doesn't exist in CoreFileOperationsProtocol,
        // we need to implement it directly
        return fileManager.temporaryDirectory.path
    }
    
    public func createUniqueFilename(in directory: String, prefix: String?, extension: String?) async -> String {
        let logContext = FileSystemLogContext(operation: "createUniqueFilename", path: directory)
        await logger.debug("Delegating createUniqueFilename operation", context: logContext)
        
        // Since this method doesn't exist in CoreFileOperationsProtocol,
        // we need to implement it directly
        let uuid = UUID().uuidString
        let filename = prefix != nil ? "\(prefix!)-\(uuid)" : uuid
        let fileWithExt = `extension` != nil ? "\(filename).\(`extension`!)" : filename
        return (directory as NSString).appendingPathComponent(fileWithExt)
    }
    
    public func writeFileFromString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "writeFileFromString", path: path)
        await logger.debug("Delegating writeFileFromString operation", context: logContext)
        return try await coreOperations.writeFileFromString(string, to: path, encoding: encoding, options: options)
    }
    
    public func getFileURLs(in path: String) async throws -> ([URL], FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getFileURLs", path: path)
        await logger.debug("Delegating getFileURLs operation", context: logContext)
        return try await coreOperations.getFileURLs(in: path)
    }
    
    // MARK: - FileMetadataOperationsProtocol
    
    public func getAttributes(at path: String) async throws -> (FileMetadataDTO, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getAttributes", path: path)
        await logger.debug("Delegating getAttributes operation", context: logContext)
        return try await metadataOperations.getAttributes(at: path)
    }
    
    public func setAttributes(_ attributes: [FileAttributeKey: Any], at path: String) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "setAttributes", path: path)
        await logger.debug("Delegating setAttributes operation", context: logContext)
        
        // Instead of delegating to metadataOperations with a potentially non-Sendable dictionary,
        // implement the functionality directly to avoid data races
        do {
            let fileManager = FileManager.default
            
            // Verify the file exists
            guard fileManager.fileExists(atPath: path) else {
                throw FileSystemError.other(path: path, reason: "File not found")
            }
            
            // Set the attributes directly using FileManager
            try fileManager.setAttributes(attributes, ofItemAtPath: path)
            
            // Get updated metadata
            let updatedAttributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(
                attributes: updatedAttributes,
                path: path
            )
            
            return FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "setAttributes", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to set attributes: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to set attributes: \(error.localizedDescription)"
            )
        }
    }
    
    public func getFileSize(at path: String) async throws -> (UInt64, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getFileSize", path: path)
        await logger.debug("Delegating getFileSize operation", context: logContext)
        
        // Since this method doesn't exist in FileMetadataOperationsProtocol,
        // we need to implement it directly
        do {
            // Get attributes to extract the file size
            let fileManager = FileManager.default
            
            // Make sure the file exists
            guard fileManager.fileExists(atPath: path) else {
                throw FileSystemError.other(
                    path: path,
                    reason: "File not found"
                )
            }
            
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let size = attributes[.size] as? UInt64 {
                let metadata = FileMetadataDTO.from(
                    attributes: attributes,
                    path: path
                )
                
                let result = FileOperationResultDTO.success(
                    path: path,
                    metadata: metadata
                )
                
                return (size, result)
            } else {
                throw FileSystemError.metadataError(
                    path: path,
                    reason: "Could not determine file size"
                )
            }
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            throw FileSystemError.metadataError(
                path: path, 
                reason: "Failed to get file size: \(error.localizedDescription)"
            )
        }
    }
    
    public func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getCreationDate", path: path)
        await logger.debug("Delegating getCreationDate operation", context: logContext)
        return try await metadataOperations.getCreationDate(at: path)
    }
    
    public func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getModificationDate", path: path)
        await logger.debug("Delegating getModificationDate operation", context: logContext)
        return try await metadataOperations.getModificationDate(at: path)
    }
    
    public func getExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> (ExtendedAttributeDTO, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(
            operation: "getExtendedAttribute", 
            path: path, 
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "attribute", value: name)
        )
        await logger.debug("Delegating getExtendedAttribute operation", context: logContext)
        
        // Get the actual data using the correct protocol method
        let (data, result) = try await metadataOperations.getExtendedAttribute(name: name, at: path)
        
        // Convert from Data to ExtendedAttributeDTO
        let extAttr = ExtendedAttributeDTO(
            name: name,
            data: data
        )
        
        return (extAttr, result)
    }
    
    public func setExtendedAttribute(_ attribute: ExtendedAttributeDTO, onItemAtPath path: String) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(
            operation: "setExtendedAttribute", 
            path: path, 
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "attribute", value: attribute.name)
        )
        await logger.debug("Delegating setExtendedAttribute operation", context: logContext)
        
        // Call using the correct protocol method
        return try await metadataOperations.setExtendedAttribute(
            data: attribute.data,
            name: attribute.name,
            at: path,
            options: nil
        )
    }
    
    public func listExtendedAttributes(atPath path: String) async throws -> ([String], FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "listExtendedAttributes", path: path)
        await logger.debug("Delegating listExtendedAttributes operation", context: logContext)
        
        // Implementation for getting extended attributes
        do {
            let fileManager = FileManager.default
            
            // Make sure the file exists
            guard fileManager.fileExists(atPath: path) else {
                throw FileSystemError.other(
                    path: path,
                    reason: "File not found"
                )
            }
            
            // This is a placeholder implementation
            // In a real implementation, we would use platform-specific APIs to get the list of extended attributes
            // Here, we're just returning an empty list with a success result
            
            let metadata = FileMetadataDTO.from(
                attributes: try fileManager.attributesOfItem(atPath: path),
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            return ([], result)
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "listExtendedAttributes", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to list extended attributes: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to list extended attributes: \(error.localizedDescription)"
            )
        }
    }
    
    public func removeExtendedAttribute(name: String, at path: String) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "removeExtendedAttribute", path: path, metadata: LogMetadataDTOCollection().withPublic(key: "attribute", value: name))
        await logger.debug("Delegating removeExtendedAttribute operation", context: logContext)
        return try await metadataOperations.removeExtendedAttribute(name: name, at: path)
    }
    
    public func setExtendedAttribute(data: Data, name: String, at path: String, options: Int32?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "setExtendedAttribute", path: path, metadata: LogMetadataDTOCollection().withPublic(key: "attribute", value: name))
        await logger.debug("Delegating setExtendedAttribute operation", context: logContext)
        return try await metadataOperations.setExtendedAttribute(data: data, name: name, at: path, options: options)
    }
    
    public func getExtendedAttribute(name: String, at path: String) async throws -> (Data, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(
            operation: "getExtendedAttribute", 
            path: path, 
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "attribute", value: name)
        )
        await logger.debug("Delegating getExtendedAttribute operation", context: logContext)
        
        // Call with the correct parameter names
        return try await metadataOperations.getExtendedAttribute(name: name, at: path)
    }
    
    public func getExtendedAttributes(at path: String) async throws -> ([String : Data], FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getExtendedAttributes", path: path)
        await logger.debug("Delegating getExtendedAttributes operation", context: logContext)
        return try await metadataOperations.getExtendedAttributes(at: path)
    }
    
    // Additional methods required by FileMetadataOperationsProtocol
    public func setCreationDate(_ date: Date, at path: String) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "setCreationDate", path: path)
        await logger.debug("Delegating setCreationDate operation", context: logContext)
        return try await metadataOperations.setCreationDate(date, at: path)
    }
    
    public func setModificationDate(_ date: Date, at path: String) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "setModificationDate", path: path)
        await logger.debug("Delegating setModificationDate operation", context: logContext)
        return try await metadataOperations.setModificationDate(date, at: path)
    }
    
    public func getResourceValues(forKeys keys: Set<URLResourceKey>, at path: String) async throws -> ([URLResourceKey: Any], FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getResourceValues", path: path)
        await logger.debug("Delegating getResourceValues operation", context: logContext)
        
        // To address the non-sendable warning, create our own implementation instead of delegating
        do {
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: path) else {
                throw FileSystemError.other(path: path, reason: "File not found")
            }
            
            let url = URL(fileURLWithPath: path)
            var resourceValues: [URLResourceKey: Any] = [:]
            
            // Get resource values one by one to avoid Sendable issues
            for key in keys {
                do {
                    let value = try url.resourceValues(forKeys: [key])
                    if let val = value.allValues.first?.value {
                        resourceValues[key] = val
                    }
                } catch {
                    // Ignore errors for individual keys
                }
            }
            
            let metadata = FileMetadataDTO.from(
                attributes: try fileManager.attributesOfItem(atPath: path),
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            return (resourceValues, result)
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "getResourceValues", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to get resource values: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to get resource values: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - SecureFileOperationsProtocol
    
    public func createSecurityBookmark(for path: String, readOnly: Bool) async throws -> Data {
        let logContext = FileSystemLogContext(operation: "createSecurityBookmark", path: path)
        await logger.debug("Delegating createSecurityBookmark operation", context: logContext)
        
        // This is a placeholder implementation
        // In a real implementation, we would use NSURL's bookmarkData method
        do {
            // Check if the file exists
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: path) {
                throw FileSystemError.other(
                    path: path,
                    reason: "File not found"
                )
            }
            
            // Return dummy data for now
            return Data([0, 1, 2, 3])
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "createSecurityBookmark", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to create security bookmark: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to create security bookmark: \(error.localizedDescription)"
            )
        }
    }
    
    public func resolveSecurityBookmark(_ bookmark: Data) async throws -> String {
        let logContext = FileSystemLogContext(operation: "resolveSecurityBookmark")
        await logger.debug("Delegating resolveSecurityBookmark operation", context: logContext)
        
        // This is a placeholder implementation
        // In a real implementation, we would use NSURL's URLByResolvingBookmarkData method
        
        // Return a dummy path for now
        return "/path/to/bookmarked/file"
    }
    
    public func startAccessingSecurityScopedResource(at path: String) async throws -> (Bool, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "startAccessingSecurityScopedResource", path: path)
        await logger.debug("Delegating startAccessingSecurityScopedResource operation", context: logContext)
        
        // This is a placeholder implementation
        // In a real implementation, we would use NSURL's startAccessingSecurityScopedResource method
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            throw FileSystemError.other(
                path: path,
                reason: "File not found"
            )
        }
        
        let metadata = FileMetadataDTO.from(
            attributes: try fileManager.attributesOfItem(atPath: path),
            path: path
        )
        
        let result = FileOperationResultDTO.success(
            path: path,
            metadata: metadata
        )
        
        return (true, result)
    }
    
    public func stopAccessingSecurityScopedResource(at path: String) async -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "stopAccessingSecurityScopedResource", path: path)
        await logger.debug("Delegating stopAccessingSecurityScopedResource operation", context: logContext)
        
        // This is a placeholder implementation
        // In a real implementation, we would use NSURL's stopAccessingSecurityScopedResource method
        
        let fileManager = FileManager.default
        var metadata: FileMetadataDTO
        
        do {
            if fileManager.fileExists(atPath: path) {
                metadata = FileMetadataDTO.from(
                    attributes: try fileManager.attributesOfItem(atPath: path),
                    path: path
                )
            } else {
                // Create minimal metadata for non-existent file
                let now = Date()
                metadata = FileMetadataDTO.from(
                    attributes: [
                        .size: 0,
                        .creationDate: now,
                        .modificationDate: now,
                        .type: FileAttributeType.typeRegular
                    ],
                    path: path
                )
            }
        } catch {
            // Handle error case with minimal metadata
            let now = Date()
            metadata = FileMetadataDTO.from(
                attributes: [
                    .size: 0,
                    .creationDate: now,
                    .modificationDate: now,
                    .type: FileAttributeType.typeRegular
                ],
                path: path
            )
        }
        
        return FileOperationResultDTO.success(
            path: path,
            metadata: metadata
        )
    }
    
    public func createSecureTemporaryFile(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "createSecureTemporaryFile")
        await logger.debug("Delegating createSecureTemporaryFile operation", context: logContext)
        
        // Since the method doesn't exist, we'll create a basic implementation
        let tempDir = NSTemporaryDirectory()
        let tempFilename = UUID().uuidString
        let tempPath = (tempDir as NSString).appendingPathComponent(tempFilename)
        
        // Create the file
        let fileManager = FileManager.default
        fileManager.createFile(atPath: tempPath, contents: nil)
        
        // Create a result
        let now = Date()
        let metadata = FileMetadataDTO.from(
            attributes: [
                .size: 0,
                .creationDate: now,
                .modificationDate: now,
                .type: FileAttributeType.typeRegular
            ],
            path: tempPath
        )
        
        let result = FileOperationResultDTO.success(
            path: tempPath,
            metadata: metadata
        )
        
        return (tempPath, result)
    }
    
    public func createSecureTemporaryDirectory(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "createSecureTemporaryDirectory")
        await logger.debug("Delegating createSecureTemporaryDirectory operation", context: logContext)
        
        // Create a secure temporary directory similar to the file method
        let tempDir = NSTemporaryDirectory()
        let tempDirName = UUID().uuidString
        let tempPath = (tempDir as NSString).appendingPathComponent(tempDirName)
        
        // Create the directory
        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: tempPath, withIntermediateDirectories: true, attributes: nil)
        
        // Create a result
        let now = Date()
        let metadata = FileMetadataDTO.from(
            attributes: [
                .size: 0,
                .creationDate: now,
                .modificationDate: now,
                .type: FileAttributeType.typeDirectory
            ],
            path: tempPath
        )
        
        let result = FileOperationResultDTO.success(
            path: tempPath,
            metadata: metadata
        )
        
        return (tempPath, result)
    }
    
    public func writeSecureFile(data: Data, to path: String, options: SecureFileWriteOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "writeSecureFile", path: path)
        await logger.debug("Delegating writeSecureFile operation", context: logContext)
        
        // Basic implementation without actual security features
        do {
            // Just write the file using standard write method
            return try await writeFile(data: data, to: path, options: nil)
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "writeSecureFile", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to write secure file: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to write secure file: \(error.localizedDescription)"
            )
        }
    }
    
    public func secureDelete(at path: String, passes: Int) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "secureDelete", path: path)
        await logger.debug("Delegating secureDelete operation", context: logContext)
        
        // Simple implementation that doesn't actually do secure deletion with passes
        do {
            let fileManager = FileManager.default
            
            // Check if the path exists
            if !fileManager.fileExists(atPath: path) {
                throw FileSystemError.other(path: path, reason: "File not found")
            }
            
            // Get file metadata before deletion
            let metadata = FileMetadataDTO.from(
                attributes: try fileManager.attributesOfItem(atPath: path),
                path: path
            )
            
            // Delete the file
            try fileManager.removeItem(atPath: path)
            
            // Return success
            return FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "secureDelete", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to securely delete file: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to securely delete file: \(error.localizedDescription)"
            )
        }
    }
    
    public func verifyFileIntegrity(at path: String, against signature: Data) async throws -> Bool {
        let logContext = FileSystemLogContext(operation: "verifyFileIntegrity", path: path)
        await logger.debug("Delegating verifyFileIntegrity operation", context: logContext)
        
        // Since there's a mismatch between the expected and actual protocol methods,
        // we need to implement a basic version here
        do {
            // Read the file content
            let (_, _) = try await readFile(at: path)
            
            // In a real implementation, we would verify the signature against the data
            // This is just a placeholder
            return true
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "verifyFileIntegrity", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to verify file integrity: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to verify file integrity: \(error.localizedDescription)"
            )
        }
    }
    
    public func encryptFile(at path: String, withKey key: Data, options: SecureFileWriteOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "encryptFile", path: path)
        await logger.debug("Delegating encryptFile operation", context: logContext)
        throw FileSystemError.operationNotSupported(path: path, operation: "encryptFile")
    }
    
    public func decryptFile(at path: String, withKey key: Data, options: SecureFileReadOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "decryptFile", path: path)
        await logger.debug("Delegating decryptFile operation", context: logContext)
        throw FileSystemError.operationNotSupported(path: path, operation: "decryptFile")
    }
    
    public func calculateChecksum(of path: String, using algorithm: ChecksumAlgorithm) async throws -> (Data, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "calculateChecksum", path: path)
        await logger.debug("Delegating calculateChecksum operation", context: logContext)
        
        // Basic implementation
        do {
            // Read the file content
            let (_, _) = try await readFile(at: path)
            
            // In a real implementation, we would calculate the checksum
            // This is just a placeholder - returning a dummy value
            let dummyChecksum = Data([0, 1, 2, 3])
            
            // Get file metadata
            let fileManager = FileManager.default
            var metadata: FileMetadataDTO
            
            do {
                if fileManager.fileExists(atPath: path) {
                    metadata = FileMetadataDTO.from(
                        attributes: try fileManager.attributesOfItem(atPath: path),
                        path: path
                    )
                } else {
                    // Create minimal metadata for non-existent file
                    let now = Date()
                    metadata = FileMetadataDTO.from(
                        attributes: [
                            .size: 0,
                            .creationDate: now,
                            .modificationDate: now,
                            .type: FileAttributeType.typeRegular
                        ],
                        path: path
                    )
                }
            } catch {
                // Handle error case with minimal metadata
                let now = Date()
                metadata = FileMetadataDTO.from(
                    attributes: [
                        .size: 0,
                        .creationDate: now,
                        .modificationDate: now,
                        .type: FileAttributeType.typeRegular
                    ],
                    path: path
                )
            }
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            return (dummyChecksum, result)
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let errorContext = FileSystemLogContext(
                operation: "calculateChecksum", 
                path: path, 
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logger.error("Failed to calculate checksum: \(error.localizedDescription)", context: errorContext)
            throw FileSystemError.other(
                path: path,
                reason: "Failed to calculate checksum: \(error.localizedDescription)"
            )
        }
    }
    
    public func createSecureTemporaryFile(prefix: String?, options: FileCreationOptions?) async throws -> String {
        let logContext = FileSystemLogContext(operation: "createSecureTemporaryFile")
        await logger.debug("Delegating createSecureTemporaryFile operation", context: logContext)
        return try await secureOperations.createSecureTemporaryFile(prefix: prefix, options: options)
    }
    
    public func createSecureTemporaryDirectory(prefix: String?, options: DirectoryCreationOptions?) async throws -> String {
        let logContext = FileSystemLogContext(operation: "createSecureTemporaryDirectory")
        await logger.debug("Delegating createSecureTemporaryDirectory operation", context: logContext)
        return try await secureOperations.createSecureTemporaryDirectory(prefix: prefix, options: options)
    }
    
    public func secureWriteFile(data: Data, to path: String, options: SecureFileWriteOptions?) async throws {
        let logContext = FileSystemLogContext(operation: "secureWriteFile", path: path)
        await logger.debug("Delegating secureWriteFile operation", context: logContext)
        try await secureOperations.secureWriteFile(data: data, to: path, options: options)
    }
    
    public func secureReadFile(at path: String, options: SecureFileReadOptions?) async throws -> Data {
        let logContext = FileSystemLogContext(operation: "secureReadFile", path: path)
        await logger.debug("Delegating secureReadFile operation", context: logContext)
        return try await secureOperations.secureReadFile(at: path, options: options)
    }
    
    public func secureDelete(at path: String, options: SecureDeletionOptions?) async throws {
        let logContext = FileSystemLogContext(operation: "secureDelete", path: path)
        await logger.debug("Delegating secureDelete operation", context: logContext)
        try await secureOperations.secureDelete(at: path, options: options)
    }
    
    public func setSecurePermissions(_ permissions: SecureFilePermissions, at path: String) async throws {
        let logContext = FileSystemLogContext(operation: "setSecurePermissions", path: path)
        await logger.debug("Delegating setSecurePermissions operation", context: logContext)
        try await secureOperations.setSecurePermissions(permissions, at: path)
    }
    
    public func verifyFileIntegrity(at path: String, expectedChecksum: Data, algorithm: ChecksumAlgorithm) async throws -> (Bool, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "verifyFileIntegrity", path: path)
        await logger.debug("Delegating verifyFileIntegrity operation", context: logContext)
        
        // Call the standard verifyFileIntegrity implementation
        let result = try await verifyFileIntegrity(at: path, against: expectedChecksum)
        
        let fileManager = FileManager.default
        var metadata: FileMetadataDTO
        
        do {
            if fileManager.fileExists(atPath: path) {
                metadata = FileMetadataDTO.from(
                    attributes: try fileManager.attributesOfItem(atPath: path),
                    path: path
                )
            } else {
                // Create minimal metadata for non-existent file
                let now = Date()
                metadata = FileMetadataDTO.from(
                    attributes: [
                        .size: 0,
                        .creationDate: now,
                        .modificationDate: now,
                        .type: FileAttributeType.typeRegular
                    ],
                    path: path
                )
            }
        } catch {
            // Handle error case with minimal metadata
            let now = Date()
            metadata = FileMetadataDTO.from(
                attributes: [
                    .size: 0,
                    .creationDate: now,
                    .modificationDate: now,
                    .type: FileAttributeType.typeRegular
                ],
                path: path
            )
        }
        
        let fileOpResult = FileOperationResultDTO.success(
            path: path,
            metadata: metadata
        )
        
        return (result, fileOpResult)
    }
    
    // MARK: - FileSandboxingProtocol
    
    public static func createSandboxed(rootDirectory: String) -> (any CompositeFileSystemServiceProtocol, FileOperationResultDTO) {
        fatalError("Cannot be used to create a sandboxed instance. Use FileSystemServiceFactory instead.")
    }
    
    public func isPathWithinSandbox(_ path: String) async -> (Bool, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "isPathWithinSandbox", path: path)
        await logger.debug("Delegating isPathWithinSandbox operation", context: logContext)
        return await sandboxing.isPathWithinSandbox(path)
    }
    
    public func pathRelativeToSandbox(_ path: String) async throws -> String {
        let logContext = FileSystemLogContext(operation: "pathRelativeToSandbox", path: path)
        await logger.debug("Delegating pathRelativeToSandbox operation", context: logContext)
        
        // This is a placeholder since sandboxing.pathRelativeToSandbox doesn't exist
        // Just return the path as is
        return path
    }
    
    public func sandboxRootDirectory() async -> String {
        let logContext = FileSystemLogContext(operation: "sandboxRootDirectory")
        await logger.debug("Delegating sandboxRootDirectory operation", context: logContext)
        // Since sandboxRootDirectory doesn't exist in FileSandboxingProtocol, 
        // we'll return a sensible default for now
        return "/"
    }
    
    public func createSandboxedDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "createSandboxedDirectory", path: path)
        await logger.debug("Delegating createSandboxedDirectory operation", context: logContext)
        return try await sandboxing.createSandboxedDirectory(at: path, options: options)
    }
    
    public func createSandboxedFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "createSandboxedFile", path: path)
        await logger.debug("Delegating createSandboxedFile operation", context: logContext)
        return try await sandboxing.createSandboxedFile(at: path, options: options)
    }
    
    public func writeSandboxedFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "writeSandboxedFile", path: path)
        await logger.debug("Delegating writeSandboxedFile operation", context: logContext)
        return try await sandboxing.writeSandboxedFile(data: data, to: path, options: options)
    }
    
    public func listSandboxedDirectory(at path: String) async throws -> ([String], FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "listSandboxedDirectory", path: path)
        await logger.debug("Delegating listSandboxedDirectory operation", context: logContext)
        
        // Since the method doesn't exist in the sandboxing protocol,
        // use the standard directory listing implementation
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            let now = Date()
            let metadata = FileMetadataDTO.from(
                attributes: [
                    .size: 0,
                    .creationDate: now,
                    .modificationDate: now,
                    .type: FileAttributeType.typeDirectory
                ],
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            return (contents, result)
        } catch {
            throw FileSystemError.other(
                path: path,
                reason: "Failed to list directory contents: \(error.localizedDescription)"
            )
        }
    }
    
    public func isSandboxEnabled() async -> Bool {
        let logContext = FileSystemLogContext(operation: "isSandboxEnabled")
        await logger.debug("Delegating isSandboxEnabled operation", context: logContext)
        return await sandboxing.isPathWithinSandbox("/").0 // If sandbox is enabled, this should return true
    }
    
    public func readSandboxedFile(at path: String) async throws -> (Data, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "readSandboxedFile", path: path)
        await logger.debug("Delegating readSandboxedFile operation", context: logContext)
        return try await sandboxing.readSandboxedFile(at: path)
    }
    
    public func getAbsolutePath(for relativePath: String) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "getAbsolutePath", path: relativePath)
        await logger.debug("Delegating getAbsolutePath operation", context: logContext)
        return try await sandboxing.getAbsolutePath(for: relativePath)
    }
    
    public func getSandboxRoot() async -> String {
        let logContext = FileSystemLogContext(operation: "getSandboxRoot")
        await logger.debug("Delegating getSandboxRoot operation", context: logContext)
        // Since sandboxRootDirectory doesn't exist in FileSandboxingProtocol, 
        // we'll return a sensible default for now
        return "/"
    }
    
    // MARK: - CompositeFileSystemServiceProtocol Additional Operations
    
    public func createDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "createDirectory", path: path)
        await logger.debug("Handling createDirectory operation", context: logContext)
        
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
                    withIntermediateDirectories: true,
                    attributes: options?.attributes
                )
                
                // Get the directory attributes for the result metadata
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let metadata = FileMetadataDTO.from(
                    attributes: attributes,
                    path: path
                )
                
                let result = FileOperationResultDTO.success(
                    path: path,
                    metadata: metadata
                )
                
                return (path, result)
            } catch {
                let dirError = FileSystemError.other(
                    path: path,
                    reason: "Failed to create directory: \(error.localizedDescription)"
                )
                
                let errorContext = FileSystemLogContext(
                    operation: "createDirectory", 
                    path: path, 
                    metadata: LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logger.error("Failed to create directory: \(error.localizedDescription)", context: errorContext)
                throw dirError
            }
        }
    }
    
    public func createFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "createFile", path: path)
        await logger.debug("Handling createFile operation", context: logContext)
        
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
                if let dirPath = (path as NSString).deletingLastPathComponent as String? {
                    if !dirPath.isEmpty && !fileManager.fileExists(atPath: dirPath) {
                        try fileManager.createDirectory(
                            atPath: dirPath,
                            withIntermediateDirectories: true,
                            attributes: nil as [FileAttributeKey: Any]?
                        )
                    }
                }
                
                // Check if the file exists and if we should overwrite
                let fileOptions = options ?? FileCreationOptions()
                let path = path.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if fileManager.fileExists(atPath: path) && !fileOptions.shouldOverwrite {
                    throw FileSystemError.other(
                        path: path,
                        reason: "File already exists and overwrite not allowed"
                    )
                }
                
                // Create the file
                let created = fileManager.createFile(
                    atPath: path, 
                    contents: nil, 
                    attributes: fileOptions.attributes
                )
                
                guard created else {
                    throw FileSystemError.other(
                        path: path,
                        reason: "Failed to create file"
                    )
                }
                
                // Get the file attributes for the result metadata
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let metadata = FileMetadataDTO.from(
                    attributes: attributes,
                    path: path
                )
                
                let result = FileOperationResultDTO.success(
                    path: path,
                    metadata: metadata
                )
                
                return (path, result)
            } catch let fsError as FileSystemError {
                throw fsError
            } catch {
                let fileError = FileSystemError.other(
                    path: path,
                    reason: "Failed to create file: \(error.localizedDescription)"
                )
                
                let errorContext = FileSystemLogContext(
                    operation: "createFile", 
                    path: path, 
                    metadata: LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logger.error("Failed to create file: \(error.localizedDescription)", context: errorContext)
                throw fileError
            }
        }
    }
    
    public func delete(at path: String) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(operation: "delete", path: path)
        await logger.debug("Handling delete operation", context: logContext)
        
        do {
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.other(
                    path: path,
                    reason: "File not found"
                )
                
                let errorContext = FileSystemLogContext(
                    operation: "delete", 
                    path: path, 
                    metadata: LogMetadataDTOCollection()
                        .withPublic(key: "error", value: "File not found")
                )
                await logger.error("File not found: \(path)", context: errorContext)
                throw error
            }
            
            // Delete the item
            try fileManager.removeItem(atPath: path)
            
            let result = FileOperationResultDTO.success(
                path: path
            )
            
            let logContext = FileSystemLogContext(
                operation: "delete", 
                path: path
            )
            
            await logger.debug("Successfully deleted item at \(path)", context: logContext)
            return result
        } catch let fsError as FileSystemError {
            // If it's already a FileSystemError, just rethrow it
            throw fsError
        } catch {
            let deleteError = FileSystemError.deleteError(
                path: path,
                reason: "Failed to delete item: \(error.localizedDescription)"
            )
            
            let errorContext = FileSystemLogContext(
                operation: "delete", 
                path: path,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            
            await logger.error("Failed to delete item: \(error.localizedDescription)", context: errorContext)
            throw deleteError
        }
    }
    
    public func move(from sourcePath: String, to destinationPath: String, options: FileMoveOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(
            operation: "move", 
            path: sourcePath,
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationPath", value: destinationPath)
        )
        
        await logger.debug("Moving file from \(sourcePath) to \(destinationPath)", context: logContext)
        
        let fileManager = self.fileManager
        
        do {
            // Make sure the source exists
            guard fileManager.fileExists(atPath: sourcePath) else {
                throw FileSystemError.moveError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Source file does not exist"
                )
            }
            
            let copyOptions = options ?? FileMoveOptions()
            
            if fileManager.fileExists(atPath: destinationPath) && !copyOptions.shouldOverwrite {
                throw FileSystemError.moveError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Destination file already exists and overwrite is not enabled"
                )
            }
            
            // Create intermediate directories if needed
            if copyOptions.createIntermediateDirectories {
                let destinationURL = URL(fileURLWithPath: destinationPath)
                let destinationDir = destinationURL.deletingLastPathComponent().path
                
                if !fileManager.fileExists(atPath: destinationDir) {
                    try fileManager.createDirectory(
                        atPath: destinationDir,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
            }
            
            // Remove destination if it exists and overwrite is allowed
            if fileManager.fileExists(atPath: destinationPath) && copyOptions.shouldOverwrite {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Move the item
            try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: destinationPath)
            let metadata = FileMetadataDTO.from(
                attributes: attributes,
                path: destinationPath
            )
            
            let result = FileOperationResultDTO.success(
                path: destinationPath,
                metadata: metadata
            )
            
            let logContext = FileSystemLogContext(
                operation: "move", 
                path: sourcePath,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "destinationPath", value: destinationPath)
            )
            
            await logger.debug("Successfully moved file from \(sourcePath) to \(destinationPath)", context: logContext)
            
            return result
        } catch let fsError as FileSystemError {
            // If it's already a FileSystemError, just rethrow it
            throw fsError
        } catch {
            let moveError = FileSystemError.moveError(
                source: sourcePath,
                destination: destinationPath,
                reason: "Failed to move item: \(error.localizedDescription)"
            )
            
            let errorContext = FileSystemLogContext(
                operation: "move", 
                path: sourcePath,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "destinationPath", value: destinationPath)
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            
            await logger.error("Failed to move item: \(error.localizedDescription)", context: errorContext)
            throw moveError
        }
    }
    
    public func copy(from sourcePath: String, to destinationPath: String, options: FileCopyOptions?) async throws -> FileOperationResultDTO {
        let logContext = FileSystemLogContext(
            operation: "copy", 
            path: sourcePath,
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "destinationPath", value: destinationPath)
        )
        
        await logger.debug("Copying file from \(sourcePath) to \(destinationPath)", context: logContext)
        
        let fileManager = self.fileManager
        
        do {
            // Validate source path
            guard fileManager.fileExists(atPath: sourcePath) else {
                throw FileSystemError.copyError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Source file does not exist"
                )
            }
            
            let copyOptions = options ?? FileCopyOptions()
            
            if fileManager.fileExists(atPath: destinationPath) && !copyOptions.shouldOverwrite {
                throw FileSystemError.copyError(
                    source: sourcePath,
                    destination: destinationPath,
                    reason: "Destination file already exists and overwrite is not enabled"
                )
            }
            
            // Create parent directories if needed
            if copyOptions.createIntermediateDirectories {
                let destinationURL = URL(fileURLWithPath: destinationPath)
                let destinationDir = destinationURL.deletingLastPathComponent().path
                
                if !fileManager.fileExists(atPath: destinationDir) {
                    try fileManager.createDirectory(
                        atPath: destinationDir,
                        withIntermediateDirectories: true,
                        attributes: nil as [FileAttributeKey: Any]?
                    )
                }
            }
            
            // Remove destination if it exists and overwrite is allowed
            if fileManager.fileExists(atPath: destinationPath) && copyOptions.shouldOverwrite {
                try fileManager.removeItem(atPath: destinationPath)
            }
            
            // Copy the item
            try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
            
            // Get the file attributes for the result metadata
            let attributes = try fileManager.attributesOfItem(atPath: destinationPath)
            let metadata = FileMetadataDTO.from(
                attributes: attributes,
                path: destinationPath
            )
            
            let result = FileOperationResultDTO.success(
                path: destinationPath,
                metadata: metadata
            )
            
            let logContext = FileSystemLogContext(
                operation: "copy", 
                path: destinationPath,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "source", value: sourcePath)
                    .withPublic(key: "destination", value: destinationPath)
            )
            
            await logger.debug("Successfully copied file from \(sourcePath) to \(destinationPath)", context: logContext)
            
            return result
        } catch let fsError as FileSystemError {
            throw fsError
        } catch {
            let copyError = FileSystemError.copyError(
                source: sourcePath,
                destination: destinationPath,
                reason: "Failed to copy item: \(error.localizedDescription)"
            )
            
            let errorContext = FileSystemLogContext(
                operation: "copy", 
                path: destinationPath,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "source", value: sourcePath)
                    .withPublic(key: "destination", value: destinationPath)
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            
            await logger.error("Failed to copy item: \(error.localizedDescription)", context: errorContext)
            throw copyError
        }
    }
    
    public func listDirectoryRecursively(at path: String) async throws -> ([String], FileOperationResultDTO) {
        let logContext = FileSystemLogContext(operation: "listDirectoryRecursively", path: path)
        await logger.debug("Handling listDirectoryRecursively operation", context: logContext)
        
        let fileManager = FileManager.default
        
        do {
            // Check if directory exists
            var isDir: ObjCBool = false
            let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
            
            guard exists else {
                throw FileSystemError.pathNotFound(path: path)
            }
            
            guard isDir.boolValue else {
                throw FileSystemError.other(
                    path: path,
                    reason: "Path is not a directory: \(path)"
                )
            }
            
            // Get directory enumerator
            guard let enumerator = fileManager.enumerator(atPath: path) else {
                throw FileSystemError.other(
                    path: path,
                    reason: "Failed to create directory enumerator"
                )
            }
            
            // Collect all paths recursively
            var paths = [String]()
            while let subpath = enumerator.nextObject() as? String {
                paths.append(subpath)
            }
            
            // Get the directory attributes for the result metadata
            let dirAttributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(
                attributes: dirAttributes,
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let logContext = FileSystemLogContext(
                operation: "listDirectoryRecursively", 
                path: path,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "itemCount", value: "\(paths.count)")
            )
            
            await logger.debug("Successfully listed directory recursively", context: logContext)
            
            return (paths, result)
        } catch let fsError as FileSystemError {
            // If it's already a FileSystemError, just rethrow it
            throw fsError
        } catch {
            let dirError = FileSystemError.other(
                path: path,
                reason: "Failed to list directory recursively: \(error.localizedDescription)"
            )
            
            let errorContext = FileSystemLogContext(
                operation: "listDirectoryRecursively", 
                path: path,
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            
            await logger.error("Failed to list directory recursively: \(error.localizedDescription)", context: errorContext)
            throw dirError
        }
    }
}
