import Foundation

/**
 # File Metadata Operations Protocol
 
 A protocol defining operations for retrieving and manipulating file metadata.
 
 This protocol focuses specifically on handling file attributes:
 - Getting and setting standard file attributes
 - Managing extended attributes
 - Retrieving file sizes and timestamps
 
 ## Alpha Dot Five Architecture
 
 This protocol follows the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility
 - Uses async/await for thread safety
 - Provides clear operation contracts
 - Uses British spelling in documentation
 */
public protocol FileMetadataOperationsProtocol: Sendable {
    /**
     Gets attributes of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The file metadata DTO and operation result
     - Throws: If the attributes cannot be retrieved
     */
    func getAttributes(at path: String) async throws -> (FileMetadataDTO, FileOperationResultDTO)
    
    /**
     Sets attributes on a file or directory.
     
     - Parameters:
        - attributes: The attributes to set
        - path: The path to the file or directory
     - Returns: Operation result
     - Throws: If the attributes cannot be set
     */
    func setAttributes(_ attributes: [FileAttributeKey: Any], at path: String) async throws -> FileOperationResultDTO
    
    /**
     Gets the size of a file.
     
     - Parameter path: The path to the file
     - Returns: The file size in bytes and operation result
     - Throws: If the file size cannot be retrieved
     */
    func getFileSize(at path: String) async throws -> (UInt64, FileOperationResultDTO)
    
    /**
     Gets the creation date of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The creation date and operation result
     - Throws: If the creation date cannot be retrieved
     */
    func getCreationDate(at path: String) async throws -> (Date, FileOperationResultDTO)
    
    /**
     Gets the modification date of a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: The modification date and operation result
     - Throws: If the modification date cannot be retrieved
     */
    func getModificationDate(at path: String) async throws -> (Date, FileOperationResultDTO)
    
    /**
     Gets an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute
        - path: The path to the file or directory
     - Returns: The extended attribute DTO and operation result
     - Throws: If the extended attribute cannot be retrieved
     */
    func getExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> (ExtendedAttributeDTO, FileOperationResultDTO)
    
    /**
     Sets an extended attribute on a file or directory.
     
     - Parameters:
        - attribute: The extended attribute to set
        - path: The path to the file or directory
     - Returns: Operation result
     - Throws: If the extended attribute cannot be set
     */
    func setExtendedAttribute(_ attribute: ExtendedAttributeDTO, onItemAtPath path: String) async throws -> FileOperationResultDTO
    
    /**
     Lists all extended attributes on a file or directory.
     
     - Parameter path: The path to the file or directory
     - Returns: An array of extended attribute names and operation result
     - Throws: If the extended attributes cannot be listed
     */
    func listExtendedAttributes(atPath path: String) async throws -> ([String], FileOperationResultDTO)
    
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute
        - path: The path to the file or directory
     - Returns: Operation result
     - Throws: If the extended attribute cannot be removed
     */
    func removeExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> FileOperationResultDTO
}
