import Foundation

/**
 # File Metadata Operations Protocol
 
 Defines operations for working with file metadata, attributes,
 and extended attributes.
 
 This protocol centralises all metadata operations to ensure consistency
 across different file system service implementations.
 
 ## Alpha Dot Five Architecture
 
 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (metadata operations)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 - Uses British spelling in documentation
 */
public protocol FileMetadataOperationsProtocol: Actor, Sendable {
    /**
     Gets the attributes of a file or directory.
     
     - Parameter path: Path to the file or directory.
     - Returns: A tuple containing the file metadata and the operation result.
     - Throws: FileSystemError if the attributes cannot be retrieved.
     */
    func getAttributes(at path: String) async throws -> (FileMetadataDTO, FileOperationResultDTO)
    
    /**
     Sets the attributes of a file or directory.
     
     - Parameters:
        - attributes: The attributes to set.
        - path: Path to the file or directory.
     - Returns: The operation result.
     - Throws: FileSystemError if the attributes cannot be set.
     */
    func setAttributes(_ attributes: [FileAttributeKey: Any], at path: String) async throws -> FileOperationResultDTO
    
    /**
     Gets all the extended attributes for a file or directory.
     
     - Parameter path: Path to the file or directory.
     - Returns: A tuple containing a dictionary of attribute names to values and the operation result.
     - Throws: FileSystemError if the extended attributes cannot be retrieved.
     */
    func getExtendedAttributes(at path: String) async throws -> ([String: Data], FileOperationResultDTO)
    
    /**
     Gets a specific extended attribute for a file or directory.
     
     - Parameters:
        - name: Name of the attribute to retrieve.
        - path: Path to the file or directory.
     - Returns: A tuple containing the attribute value and the operation result.
     - Throws: FileSystemError if the extended attribute cannot be retrieved.
     */
    func getExtendedAttribute(name: String, at path: String) async throws -> (Data, FileOperationResultDTO)
    
    /**
     Sets an extended attribute for a file or directory.
     
     - Parameters:
        - data: The data to set.
        - name: Name of the attribute to set.
        - path: Path to the file or directory.
        - options: Optional flags for the attribute (e.g., create-only).
     - Returns: The operation result.
     - Throws: FileSystemError if the extended attribute cannot be set.
     */
    func setExtendedAttribute(data: Data, name: String, at path: String, options: Int32?) async throws -> FileOperationResultDTO
    
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - name: Name of the attribute to remove.
        - path: Path to the file or directory.
     - Returns: The operation result.
     - Throws: FileSystemError if the extended attribute cannot be removed.
     */
    func removeExtendedAttribute(name: String, at path: String) async throws -> FileOperationResultDTO
    
    /**
     Gets the creation date of a file or directory.
     
     - Parameter path: Path to the file or directory.
     - Returns: A tuple containing the creation date and the operation result.
     - Throws: FileSystemError if the creation date cannot be retrieved.
     */
    func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO)
    
    /**
     Sets the creation date of a file or directory.
     
     - Parameters:
        - date: The date to set.
        - path: Path to the file or directory.
     - Returns: The operation result.
     - Throws: FileSystemError if the creation date cannot be set.
     */
    func setCreationDate(_ date: Date, at path: String) async throws -> FileOperationResultDTO
    
    /**
     Gets the modification date of a file or directory.
     
     - Parameter path: Path to the file or directory.
     - Returns: A tuple containing the modification date and the operation result.
     - Throws: FileSystemError if the modification date cannot be retrieved.
     */
    func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO)
    
    /**
     Sets the modification date of a file or directory.
     
     - Parameters:
        - date: The date to set.
        - path: Path to the file or directory.
     - Returns: The operation result.
     - Throws: FileSystemError if the modification date cannot be set.
     */
    func setModificationDate(_ date: Date, at path: String) async throws -> FileOperationResultDTO
    
    /**
     Gets the resource values for a file or directory.
     
     - Parameters:
        - keys: The resource keys to retrieve.
        - path: Path to the file or directory.
     - Returns: A tuple containing the resource values and the operation result.
     - Throws: FileSystemError if the resource values cannot be retrieved.
     */
    func getResourceValues(forKeys keys: Set<URLResourceKey>, at path: String) async throws -> ([URLResourceKey: Any], FileOperationResultDTO)
}
