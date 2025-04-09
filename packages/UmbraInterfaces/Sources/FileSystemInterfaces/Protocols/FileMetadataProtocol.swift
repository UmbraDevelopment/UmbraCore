import Foundation

/**
 # File Metadata Protocol
 
 Defines operations for working with file metadata and attributes.
 
 This protocol centralises all file metadata operations to ensure consistency
 across different file system service implementations.
 
 ## Alpha Dot Five Architecture
 
 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (metadata operations)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 */
public protocol FileMetadataProtocol: Actor, Sendable {
    /**
     Gets attributes of a file or directory at the specified path.
     
     - Parameter path: The path to the file or directory.
     - Returns: The file attributes.
     - Throws: FileSystemError if the attributes cannot be retrieved.
     */
    func getAttributes(at path: String) async throws -> FileAttributes
    
    /**
     Sets attributes of a file or directory at the specified path.
     
     - Parameters:
        - attributes: The attributes to set.
        - path: The path to the file or directory.
     - Throws: FileSystemError if the attributes cannot be set.
     */
    func setAttributes(_ attributes: FileAttributes, at path: String) async throws
    
    /**
     Gets the size of a file at the specified path.
     
     - Parameter path: The path to the file.
     - Returns: The size of the file in bytes.
     - Throws: FileSystemError if the size cannot be determined.
     */
    func getFileSize(at path: String) async throws -> UInt64
    
    /**
     Gets the creation date of a file or directory at the specified path.
     
     - Parameter path: The path to the file or directory.
     - Returns: The creation date.
     - Throws: FileSystemError if the creation date cannot be determined.
     */
    func getCreationDate(at path: String) async throws -> Date
    
    /**
     Gets the modification date of a file or directory at the specified path.
     
     - Parameter path: The path to the file or directory.
     - Returns: The modification date.
     - Throws: FileSystemError if the modification date cannot be determined.
     */
    func getModificationDate(at path: String) async throws -> Date
    
    /**
     Gets an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute.
        - path: The path to the file or directory.
     - Returns: The extended attribute data.
     - Throws: FileSystemError if the extended attribute cannot be retrieved.
     */
    func getExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws -> Data
    
    /**
     Sets an extended attribute on a file or directory.
     
     - Parameters:
        - data: The data for the extended attribute.
        - name: The name of the extended attribute.
        - path: The path to the file or directory.
     - Throws: FileSystemError if the extended attribute cannot be set.
     */
    func setExtendedAttribute(_ data: Data, withName name: String, onItemAtPath path: String) async throws
    
    /**
     Lists all extended attributes on a file or directory.
     
     - Parameter path: The path to the file or directory.
     - Returns: An array of attribute names.
     - Throws: FileSystemError if the extended attributes cannot be listed.
     */
    func listExtendedAttributes(atPath path: String) async throws -> [String]
    
    /**
     Removes an extended attribute from a file or directory.
     
     - Parameters:
        - name: The name of the extended attribute to remove.
        - path: The path to the file or directory.
     - Throws: FileSystemError if the extended attribute cannot be removed.
     */
    func removeExtendedAttribute(withName name: String, fromItemAtPath path: String) async throws
}
