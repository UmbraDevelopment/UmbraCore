import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 # File Metadata Actor
 
 Implements file metadata operations as an actor to ensure thread safety.
 This actor provides implementations for all methods defined in the
 FileMetadataProtocol, with comprehensive error handling and logging.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 1. Using proper British spelling in documentation
 2. Implementing actor-based concurrency for thread safety
 3. Providing comprehensive privacy-aware logging
 4. Using functional programming patterns where appropriate
 5. Supporting sandboxed operation for enhanced security
 */
public actor FileMetadataActor: FileMetadataProtocol {
    /// Logger for operation tracking
    private let logger: LoggingProtocol
    
    /// File manager instance for performing file operations
    private let fileManager: FileManager
    
    /// Optional root directory for sandboxed operation
    private let rootDirectory: String?
    
    /**
     Initialises a new FileMetadataActor.
     
     - Parameters:
        - logger: The logger to use for operation tracking
        - rootDirectory: Optional root directory to restrict operations to
     */
    public init(logger: LoggingProtocol, rootDirectory: String? = nil) {
        self.logger = logger
        self.fileManager = FileManager.default
        self.rootDirectory = rootDirectory
    }
    
    /**
     Validates that a path is within the root directory if one is specified.
     
     - Parameter path: The path to validate
     - Returns: The canonicalised path if valid
     - Throws: FileSystemError.accessDenied if the path is outside the root directory
     */
    private func validatePath(_ path: FilePathDTO) throws -> String {
        guard let rootDir = rootDirectory else {
            // No sandboxing, path is valid as-is
            return path.path
        }
        
        // Canonicalise paths to resolve any ../ or symlinks
        let canonicalPath = URL(fileURLWithPath: path.path).standardized.path
        let canonicalRootDir = URL(fileURLWithPath: rootDir).standardized.path
        
        // Check if the path is within the root directory
        if !canonicalPath.hasPrefix(canonicalRootDir) {
            let context = FileSystemLogContext(
                operation: "validatePath",
                path: path.path,
                source: "FileMetadataActor",
                isSecureOperation: true
            )
            
            await logger.warning(
                "Access attempt to path outside root directory", 
                context: context
            )
            
            throw FileSystemError.accessDenied(
                path: path.path,
                reason: "Path is outside the permitted root directory"
            )
        }
        
        return canonicalPath
    }
    
    // MARK: - Standard File Attributes
    
    /**
     Gets attributes of a file or directory at the specified path.
     
     - Parameter path: The path to the file or directory.
     - Returns: The file attributes.
     - Throws: FileSystemError if the attributes cannot be retrieved.
     */
    public func getAttributes(at path: FilePathDTO) async throws -> FileAttributes {
        let context = FileSystemLogContext(
            operation: "getAttributes",
            path: path.path
        )
        
        await logger.debug("Getting file attributes", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: validatedPath)
            
            // Convert to FileAttributes
            let fileAttributes = FileAttributes(attributes: attributes)
            
            // Log successful retrieval
            let successContext = context
                .withStatus("success")
                .withUpdatedMetadata(context.metadata.withPublic(key: "attributeCount", value: String(fileAttributes.count)))
            await logger.debug("Successfully retrieved file attributes", context: successContext)
            
            return fileAttributes
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to get file attributes: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "getAttributes", path: path.path)
            await logger.error("Failed to get file attributes: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Sets attributes of a file or directory at the specified path.
     
     - Parameters:
        - attributes: The attributes to set.
        - path: The path to the file or directory.
     - Throws: FileSystemError if the attributes cannot be set.
     */
    public func setAttributes(_ attributes: FileAttributes, at path: FilePathDTO) async throws {
        let context = FileSystemLogContext(
            operation: "setAttributes",
            path: path.path
        )
        
        let metadata = context.metadata.withPublic(key: "attributeCount", value: String(attributes.count))
        let enhancedContext = context.withUpdatedMetadata(metadata)
        
        await logger.debug("Setting file attributes", context: enhancedContext)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Convert to Dictionary and set the file attributes
            try fileManager.setAttributes(attributes.asDictionary, ofItemAtPath: validatedPath)
            
            // Log successful setting
            let successContext = enhancedContext
                .withStatus("success")
            await logger.debug("Successfully set file attributes", context: successContext)
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to set file attributes: \(error.localizedDescription)", context: enhancedContext)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "setAttributes", path: path.path)
            await logger.error("Failed to set file attributes: \(wrappedError.localizedDescription)", context: enhancedContext)
            throw wrappedError
        }
    }
    
    /**
     Gets the size of a file at the specified path.
     
     - Parameter path: The path to the file.
     - Returns: The file size in bytes.
     - Throws: FileSystemError if the file size cannot be retrieved.
     */
    public func getFileSize(at path: FilePathDTO) async throws -> UInt64 {
        let context = FileSystemLogContext(
            operation: "getFileSize",
            path: path.path
        )
        
        await logger.debug("Getting file size", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: validatedPath)
            
            // Extract the file size
            guard let fileSize = attributes[.size] as? UInt64 else {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not retrieve file size"
                )
            }
            
            // Log successful retrieval
            let successContext = context
                .withStatus("success")
                .withUpdatedMetadata(context.metadata.withPublic(key: "fileSize", value: String(fileSize)))
            await logger.debug("Successfully retrieved file size", context: successContext)
            
            return fileSize
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to get file size: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "getFileSize", path: path.path)
            await logger.error("Failed to get file size: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Gets the creation date of a file at the specified path.
     
     - Parameter path: The path to the file.
     - Returns: The file creation date.
     - Throws: FileSystemError if the creation date cannot be retrieved.
     */
    public func getCreationDate(at path: FilePathDTO) async throws -> Date {
        let context = FileSystemLogContext(
            operation: "getCreationDate",
            path: path.path
        )
        
        await logger.debug("Getting file creation date", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: validatedPath)
            
            // Extract the creation date
            guard let creationDate = attributes[.creationDate] as? Date else {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not retrieve creation date"
                )
            }
            
            // Log successful retrieval
            let successContext = context
                .withStatus("success")
                .withUpdatedMetadata(context.metadata.withPublic(key: "creationDate", value: String(describing: creationDate)))
            await logger.debug("Successfully retrieved file creation date", context: successContext)
            
            return creationDate
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to get file creation date: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "getCreationDate", path: path.path)
            await logger.error("Failed to get file creation date: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Gets the modification date of a file at the specified path.
     
     - Parameter path: The path to the file.
     - Returns: The file modification date.
     - Throws: FileSystemError if the modification date cannot be retrieved.
     */
    public func getModificationDate(at path: FilePathDTO) async throws -> Date {
        let context = FileSystemLogContext(
            operation: "getModificationDate",
            path: path.path
        )
        
        await logger.debug("Getting file modification date", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: validatedPath)
            
            // Extract the modification date
            guard let modificationDate = attributes[.modificationDate] as? Date else {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not retrieve modification date"
                )
            }
            
            // Log successful retrieval
            let successContext = context
                .withStatus("success")
                .withUpdatedMetadata(context.metadata.withPublic(key: "modificationDate", value: String(describing: modificationDate)))
            await logger.debug("Successfully retrieved file modification date", context: successContext)
            
            return modificationDate
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to get file modification date: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "getModificationDate", path: path.path)
            await logger.error("Failed to get file modification date: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    // MARK: - Extended Attributes

    /**
     Gets an extended attribute from a file.
     
     - Parameters:
        - name: The name of the extended attribute.
        - path: The path to the file.
     - Returns: The extended attribute data.
     - Throws: FileSystemError if the extended attribute cannot be retrieved.
     */
    public func getExtendedAttribute(withName name: String, fromItemAtPath path: FilePathDTO) async throws -> Data {
        let context = FileSystemLogContext(
            operation: "getExtendedAttribute",
            path: path.path
        )
        
        let metadata = context.metadata.withPublic(key: "attributeName", value: name)
        let enhancedContext = context.withUpdatedMetadata(metadata)
        
        await logger.debug("Getting extended attribute", context: enhancedContext)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Use the validated path directly with FileManager extended attribute methods
            do {
                // Get the extended attribute
                let attributeData = try FileManager.default.extendedAttribute(forName: name, atPath: validatedPath)
                
                // Log successful retrieval
                let successContext = enhancedContext
                    .withStatus("success")
                    .withUpdatedMetadata(enhancedContext.metadata.withPublic(key: "dataSize", value: String(attributeData.count)))
                await logger.debug("Successfully retrieved extended attribute", context: successContext)
                
                return attributeData
            } catch {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not retrieve extended attribute '\(name)': \(error.localizedDescription)"
                )
            }
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to get extended attribute: \(error.localizedDescription)", context: enhancedContext)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "getExtendedAttribute", path: path.path)
            await logger.error("Failed to get extended attribute: \(wrappedError.localizedDescription)", context: enhancedContext)
            throw wrappedError
        }
    }
    
    /**
     Sets an extended attribute on a file.
     
     - Parameters:
        - data: The extended attribute data.
        - name: The name of the extended attribute.
        - path: The path to the file.
     - Throws: FileSystemError if the extended attribute cannot be set.
     */
    public func setExtendedAttribute(_ data: Data, withName name: String, onItemAtPath path: FilePathDTO) async throws {
        let context = FileSystemLogContext(
            operation: "setExtendedAttribute",
            path: path.path
        )
        
        let metadata = context.metadata
            .withPublic(key: "attributeName", value: name)
            .withPublic(key: "dataSize", value: String(data.count))
        let enhancedContext = context.withUpdatedMetadata(metadata)
        
        await logger.debug("Setting extended attribute", context: enhancedContext)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Use the validated path directly with FileManager extended attribute methods
            do {
                // Set the extended attribute
                try FileManager.default.setExtendedAttribute(data, forName: name, atPath: validatedPath)
                
                // Log successful setting
                let successContext = enhancedContext
                    .withStatus("success")
                await logger.debug("Successfully set extended attribute", context: successContext)
            } catch {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not set extended attribute '\(name)': \(error.localizedDescription)"
                )
            }
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to set extended attribute: \(error.localizedDescription)", context: enhancedContext)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "setExtendedAttribute", path: path.path)
            await logger.error("Failed to set extended attribute: \(wrappedError.localizedDescription)", context: enhancedContext)
            throw wrappedError
        }
    }
    
    /**
     Lists all extended attributes on a file.
     
     - Parameter path: The path to the file.
     - Returns: An array of extended attribute names.
     - Throws: FileSystemError if the extended attributes cannot be listed.
     */
    public func listExtendedAttributes(atPath path: FilePathDTO) async throws -> [String] {
        let context = FileSystemLogContext(
            operation: "listExtendedAttributes",
            path: path.path
        )
        
        await logger.debug("Listing extended attributes", context: context)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Use the validated path directly to list extended attributes
            do {
                let attributeNames = try FileManager.default.listExtendedAttributes(atPath: validatedPath)
                
                // Log successful listing
                let successContext = context
                    .withStatus("success")
                    .withUpdatedMetadata(context.metadata.withPublic(key: "attributeCount", value: String(attributeNames.count)))
                await logger.debug("Successfully listed extended attributes", context: successContext)
                
                return attributeNames
            } catch {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not list extended attributes: \(error.localizedDescription)"
                )
            }
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to list extended attributes: \(error.localizedDescription)", context: context)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "listExtendedAttributes", path: path.path)
            await logger.error("Failed to list extended attributes: \(wrappedError.localizedDescription)", context: context)
            throw wrappedError
        }
    }
    
    /**
     Removes an extended attribute from a file.
     
     - Parameters:
        - name: The name of the extended attribute.
        - path: The path to the file.
     - Throws: FileSystemError if the extended attribute cannot be removed.
     */
    public func removeExtendedAttribute(withName name: String, fromItemAtPath path: FilePathDTO) async throws {
        let context = FileSystemLogContext(
            operation: "removeExtendedAttribute",
            path: path.path
        )
        
        let metadata = context.metadata.withPublic(key: "attributeName", value: name)
        let enhancedContext = context.withUpdatedMetadata(metadata)
        
        await logger.debug("Removing extended attribute", context: enhancedContext)
        
        do {
            // Validate path is within root directory if specified
            let validatedPath = try validatePath(path)
            
            // Check if the file exists
            if !fileManager.fileExists(atPath: validatedPath) {
                throw FileSystemError.notFound(path: validatedPath)
            }
            
            // Use the validated path directly to remove the extended attribute
            do {
                try FileManager.default.removeExtendedAttribute(forName: name, atPath: validatedPath)
                
                // Log successful removal
                let successContext = enhancedContext
                    .withStatus("success")
                await logger.debug("Successfully removed extended attribute", context: successContext)
            } catch {
                throw FileSystemError.metadataError(
                    path: validatedPath,
                    reason: "Could not remove extended attribute '\(name)': \(error.localizedDescription)"
                )
            }
        } catch let error as FileSystemError {
            // Re-throw already wrapped errors
            await logger.error("Failed to remove extended attribute: \(error.localizedDescription)", context: enhancedContext)
            throw error
        } catch {
            // Wrap and log other errors
            let wrappedError = FileSystemError.wrap(error, operation: "removeExtendedAttribute", path: path.path)
            await logger.error("Failed to remove extended attribute: \(wrappedError.localizedDescription)", context: enhancedContext)
            throw wrappedError
        }
    }
}
