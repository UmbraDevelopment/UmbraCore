import Foundation
import FileSystemInterfaces
import LoggingInterfaces
import LoggingTypes

/**
 # File Metadata Operations Implementation
 
 The implementation of FileMetadataOperationsProtocol that handles file attributes
 and extended attributes.
 
 This actor-based implementation ensures all operations are thread-safe through
 Swift concurrency. It provides comprehensive metadata handling with proper
 error reporting and logging.
 
 ## Alpha Dot Five Architecture
 
 This implementation follows the Alpha Dot Five architecture principles:
 - Uses actor isolation for thread safety
 - Provides comprehensive privacy-aware logging
 - Follows British spelling in documentation
 - Returns standardised operation results
 */

/**
 Extended Attribute DTO for storing extended attribute information
 */
public struct ExtendedAttributeDTO: Sendable, Equatable {
    /// The name of the extended attribute
    public let name: String
    
    /// The data value of the extended attribute
    public let data: Data
    
    /// Initializes a new extended attribute DTO
    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
}

public actor FileMetadataOperationsImpl: FileMetadataOperationsProtocol {
    /// The underlying file manager isolated within this actor
    private let fileManager: FileManager
    
    /// Logger for this service
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new file metadata operations implementation.
     
     - Parameters:
        - fileManager: Optional custom file manager to use
        - logger: Optional logger for recording operations
     */
    public init(fileManager: FileManager = .default, logger: (any LoggingProtocol)? = nil) {
        self.fileManager = fileManager
        self.logger = logger ?? NullLogger()
    }
    
    /**
     Gets attributes of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The file metadata DTO and operation result
     - Throws: If the attributes cannot be retrieved
     */
    public func getAttributes(at path: String) async throws -> (FileMetadataDTO, FileOperationResultDTO) {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection().withPublic("path", path)
        )
        
        await logger.debug("Getting attributes for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: path)
            
            // Create metadata DTO
            let metadata = FileMetadataDTO.from(
                attributes: attributes,
                path: path
            )
            
            // Create extended attributes if possible
            var extendedAttributes: [String: ExtendedAttributeDTO]? = nil
            do {
                let attributeNames = try fileManager.extendedAttributeNames(atPath: path)
                if !attributeNames.isEmpty {
                    var attributesDict = [String: ExtendedAttributeDTO]()
                    for name in attributeNames {
                        if let data = try? fileManager.extendedAttribute(forName: name, atPath: path) {
                            attributesDict[name] = ExtendedAttributeDTO(name: name, data: data)
                        }
                    }
                    extendedAttributes = attributesDict
                }
            } catch {
                // Just log the error but don't fail the whole operation
                let warningContext = BaseLogContextDTO(
                    domainName: "FileSystem",
                    source: "FileMetadataOperationsImpl",
                    metadata: LogMetadataDTOCollection()
                        .withPublic("path", path)
                        .withPublic("error", error.localizedDescription)
                )
                await logger.warning("Could not retrieve extended attributes: \(error.localizedDescription)", context: warningContext)
            }
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            await logger.debug("Successfully retrieved attributes for \(path)", context: logContext)
            return (metadata, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(path: path, reason: "Failed to get attributes: \(error.localizedDescription)")
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to get attributes: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Sets attributes on a file or directory.
     
     - Parameters:
        - attributes: The attributes to set
        - path: The path to the file or directory
     - Returns: Operation result
     - Throws: If the attributes cannot be set
     */
    public func setAttributes(_ attributes: [FileAttributeKey: Any], at path: String) async throws -> FileOperationResultDTO {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection()
                .withPublic("path", path)
                .withPublic("attributes", "\(attributes)")
        )
        
        await logger.debug("Setting attributes for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Set the attributes
            try fileManager.setAttributes(attributes, ofItemAtPath: path)
            
            // Get the updated file attributes for the result metadata
            let updatedAttributes = try fileManager.attributesOfItem(atPath: path)
            let metadata = FileMetadataDTO.from(
                attributes: updatedAttributes,
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            await logger.debug("Successfully set attributes for \(path)", context: logContext)
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.permissionError(path: path, reason: "Failed to set attributes: \(error.localizedDescription)")
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to set attributes: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Gets the size of a file.
     
     - Parameter path: The path to the file
     - Returns: The file size in bytes and operation result
     - Throws: If the file size cannot be retrieved
     */
    public func getFileSize(at path: String) async throws -> (UInt64, FileOperationResultDTO) {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection().withPublic("path", path)
        )
        
        await logger.debug("Getting file size for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: path)
            
            // Extract the file size
            guard let fileSize = attributes[.size] as? UInt64 else {
                let error = FileSystemError.other(path: path, reason: "Failed to get file size from attributes")
                await logger.error("Failed to get file size from attributes", context: logContext)
                throw error
            }
            
            let metadata = FileMetadataDTO.from(
                attributes: attributes,
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = BaseLogContextDTO(
                domainName: "FileSystem",
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("size", "\(fileSize)")
            )
            
            await logger.debug("Successfully retrieved file size for \(path): \(fileSize) bytes", context: successContext)
            return (fileSize, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(path: path, reason: "Failed to get file size: \(error.localizedDescription)")
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to get file size: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Gets the creation date of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The creation date and operation result
     - Throws: If the creation date cannot be retrieved
     */
    public func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection().withPublic("path", path)
        )
        
        await logger.debug("Getting creation date for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: path)
            
            // Extract the creation date
            guard let creationDate = attributes[.creationDate] as? Date else {
                let error = FileSystemError.other(path: path, reason: "Failed to get creation date from attributes")
                await logger.error("Failed to get creation date from attributes", context: logContext)
                throw error
            }
            
            let metadata = FileMetadataDTO.from(
                attributes: attributes,
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = BaseLogContextDTO(
                domainName: "FileSystem",
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("creationDate", "\(creationDate)")
            )
            
            await logger.debug("Successfully retrieved creation date for \(path): \(creationDate)", context: successContext)
            return (creationDate, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(path: path, reason: "Failed to get creation date: \(error.localizedDescription)")
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to get creation date: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Gets the modification date of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The modification date and operation result
     - Throws: If the modification date cannot be retrieved
     */
    public func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO) {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection().withPublic("path", path)
        )
        
        await logger.debug("Getting modification date for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Get the file attributes
            let attributes = try fileManager.attributesOfItem(atPath: path)
            
            // Extract the modification date
            guard let modificationDate = attributes[.modificationDate] as? Date else {
                let error = FileSystemError.other(path: path, reason: "Failed to get modification date from attributes")
                await logger.error("Failed to get modification date from attributes", context: logContext)
                throw error
            }
            
            let metadata = FileMetadataDTO.from(
                attributes: attributes,
                path: path
            )
            
            let result = FileOperationResultDTO.success(
                path: path,
                metadata: metadata
            )
            
            let successContext = BaseLogContextDTO(
                domainName: "FileSystem",
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("modificationDate", "\(modificationDate)")
            )
            
            await logger.debug("Successfully retrieved modification date for \(path): \(modificationDate)", context: successContext)
            return (modificationDate, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(path: path, reason: "Failed to get modification date: \(error.localizedDescription)")
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to get modification date: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Gets an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute
        - path: The path to the file or directory
     - Returns: The extended attribute and operation result
     - Throws: If the extended attribute cannot be retrieved
     */
    public func getExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> (ExtendedAttributeDTO, FileOperationResultDTO) {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection()
                .withPublic("path", path)
                .withPublic("attribute", name)
        )
        
        await logger.debug("Getting extended attribute \(name) for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Get the extended attribute
            let data = try fileManager.extendedAttribute(forName: name, atPath: path)
            let attribute = ExtendedAttributeDTO(name: name, data: data)
            
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
            
            await logger.debug("Successfully retrieved extended attribute \(name) for \(path)", context: logContext)
            return (attribute, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(
                path: path,
                reason: "Failed to get extended attribute: \(error.localizedDescription)"
            )
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("attribute", name)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to get extended attribute: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Sets an extended attribute on a file or directory.
     
     - Parameters:
        - attribute: The extended attribute to set
        - path: The path to the file or directory
     - Returns: Operation result
     - Throws: If the extended attribute cannot be set
     */
    public func setExtendedAttribute(_ attribute: ExtendedAttributeDTO, onItemAtPath path: String) async throws -> FileOperationResultDTO {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection()
                .withPublic("path", path)
                .withPublic("attribute", attribute.name)
        )
        
        await logger.debug("Setting extended attribute \(attribute.name) for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Set the extended attribute
            try fileManager.setExtendedAttribute(attribute.data, forName: attribute.name, atPath: path)
            
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
            
            await logger.debug("Successfully set extended attribute \(attribute.name) for \(path)", context: logContext)
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(
                path: path,
                reason: "Failed to set extended attribute: \(error.localizedDescription)"
            )
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("attribute", attribute.name)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to set extended attribute: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Lists all extended attributes of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The list of extended attribute names and operation result
     - Throws: If the extended attributes cannot be listed
     */
    public func listExtendedAttributes(atPath path: String) async throws -> ([String], FileOperationResultDTO) {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection().withPublic("path", path)
        )
        
        await logger.debug("Listing extended attributes for \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Get the extended attribute names
            let attributeNames = try fileManager.extendedAttributeNames(atPath: path)
            
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
            
            let successContext = BaseLogContextDTO(
                domainName: "FileSystem",
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("count", "\(attributeNames.count)")
            )
            
            await logger.debug("Successfully listed \(attributeNames.count) extended attributes for \(path)", context: successContext)
            return (attributeNames, result)
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(
                path: path,
                reason: "Failed to list extended attributes: \(error.localizedDescription)"
            )
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to list extended attributes: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
    
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute to remove
        - path: The path to the file or directory
     - Returns: Operation result
     - Throws: If the extended attribute cannot be removed
     */
    public func removeExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> FileOperationResultDTO {
        let logContext = BaseLogContextDTO(
            domainName: "FileSystem",
            source: "FileMetadataOperationsImpl",
            metadata: LogMetadataDTOCollection()
                .withPublic("path", path)
                .withPublic("attribute", name)
        )
        
        await logger.debug("Removing extended attribute \(name) from \(path)", context: logContext)
        
        do {
            // Check if the file exists
            guard fileManager.fileExists(atPath: path) else {
                let error = FileSystemError.pathNotFound(path: path)
                await logger.error("File not found: \(path)", context: logContext)
                throw error
            }
            
            // Remove the extended attribute
            try fileManager.removeExtendedAttribute(forName: name, atPath: path)
            
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
            
            await logger.debug("Successfully removed extended attribute \(name) from \(path)", context: logContext)
            return result
        } catch let error as FileSystemError {
            throw error
        } catch {
            let fileError = FileSystemError.other(
                path: path,
                reason: "Failed to remove extended attribute: \(error.localizedDescription)"
            )
            
            let errorContext = BaseLogContextDTO(
                domainName: "FileSystem", 
                source: "FileMetadataOperationsImpl",
                metadata: LogMetadataDTOCollection()
                    .withPublic("path", path)
                    .withPublic("attribute", name)
                    .withPublic("error", error.localizedDescription)
            )
            
            await logger.error("Failed to remove extended attribute: \(error.localizedDescription)", context: errorContext)
            throw fileError
        }
    }
}

// MARK: - FileManager Extension for Extended Attributes

extension FileManager {
    /**
     Gets an extended attribute for a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute
        - path: The path to the file or directory
     - Returns: The extended attribute data
     - Throws: If the extended attribute cannot be retrieved
     */
    func extendedAttribute(forName name: String, atPath path: String) throws -> Data {
        let url = URL(fileURLWithPath: path)
        
        var length: Int = 0
        let status = url.withUnsafeFileSystemRepresentation { pathPtr in
            getxattr(pathPtr, name, nil, 0, 0, 0)
        }
        
        if status == -1 {
            throw FileSystemError.extendedAttributeError(
                path: path,
                attribute: name,
                reason: String(cString: strerror(errno))
            )
        }
        
        length = Int(status)
        var data = Data(count: length)
        
        let readStatus = data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) -> Int32 in
            let dataPtr = ptr.baseAddress
            return url.withUnsafeFileSystemRepresentation { pathPtr in
                getxattr(pathPtr, name, dataPtr, length, 0, 0)
            }
        }
        
        if readStatus == -1 {
            throw FileSystemError.extendedAttributeError(
                path: path,
                attribute: name,
                reason: String(cString: strerror(errno))
            )
        }
        
        return data
    }
    
    /**
     Sets an extended attribute on a file or directory.
     
     - Parameters:
        - data: The data to set
        - name: The name of the extended attribute
        - path: The path to the file or directory
     - Throws: If the extended attribute cannot be set
     */
    func setExtendedAttribute(_ data: Data, forName name: String, atPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        
        let status = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int32 in
            let dataPtr = ptr.baseAddress
            return url.withUnsafeFileSystemRepresentation { pathPtr in
                setxattr(pathPtr, name, dataPtr, data.count, 0, 0)
            }
        }
        
        if status == -1 {
            throw FileSystemError.extendedAttributeError(
                path: path,
                attribute: name,
                reason: String(cString: strerror(errno))
            )
        }
    }
    
    /**
     Lists all extended attributes on a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: An array of extended attribute names
     - Throws: If the extended attributes cannot be listed
     */
    func extendedAttributeNames(atPath path: String) throws -> [String] {
        let url = URL(fileURLWithPath: path)
        
        var length: Int = 0
        let status = url.withUnsafeFileSystemRepresentation { pathPtr in
            listxattr(pathPtr, nil, 0, 0)
        }
        
        if status == -1 {
            throw FileSystemError.extendedAttributeError(
                path: path,
                attribute: "all",
                reason: String(cString: strerror(errno))
            )
        }
        
        length = Int(status)
        if length == 0 {
            return []
        }
        
        var nameBuf = [CChar](repeating: 0, count: length)
        
        let readStatus = url.withUnsafeFileSystemRepresentation { pathPtr in
            listxattr(pathPtr, &nameBuf, length, 0)
        }
        
        if readStatus == -1 {
            throw FileSystemError.extendedAttributeError(
                path: path,
                attribute: "all",
                reason: String(cString: strerror(errno))
            )
        }
        
        var names = [String]()
        var start = 0
        for i in 0..<length {
            if nameBuf[i] == 0 {
                let nameBytes = nameBuf[start..<i]
                if let name = String(bytes: nameBytes, encoding: .utf8) {
                    names.append(name)
                }
                start = i + 1
            }
        }
        
        return names
    }
    
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute
        - path: The path to the file or directory
     - Throws: If the extended attribute cannot be removed
     */
    func removeExtendedAttribute(forName name: String, atPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        
        let status = url.withUnsafeFileSystemRepresentation { pathPtr in
            removexattr(pathPtr, name, 0)
        }
        
        if status == -1 {
            throw FileSystemError.extendedAttributeError(
                path: path,
                attribute: name,
                reason: String(cString: strerror(errno))
            )
        }
    }
}
