import Foundation

/**
 # File System Service Protocol
 
 The primary protocol for interacting with the file system. This protocol
 combines read, write, metadata, and secure operations into a unified interface.
 
 This composite protocol provides a comprehensive API for applications to
 perform all necessary file system operations while maintaining separation
 of concerns in the implementation.
 
 The service handles operations such as:
 - Creating, reading, writing, and deleting files
 - Creating and managing directories
 - Retrieving and manipulating file metadata and attributes
 - Performing secure file operations
 - Managing file access in a sandbox-compliant manner
 
 ## Error Handling
 
 All methods can throw FileSystemError to indicate various failure scenarios
 such as permission issues, file not found, etc. Many operations also provide
 detailed error information in the thrown error.
 
 ## Security Considerations
 
 The implementation is designed to follow best practices for security and
 sandbox compliance. It:
 
 - Properly handles access restrictions and permissions
 - Uses appropriate permission levels
 - Manages access to files correctly
 - Securely disposes of temporary resources
 - Follows principle of least privilege
 
 ## Alpha Dot Five Architecture
 
 This protocol conforms to the Alpha Dot Five architecture principles:
 - Provides a unified interface through protocol composition
 - Maintains separation of concerns via specialized sub-protocols
 - Ensures all operations are asynchronous and thread-safe
 - Uses actor isolation for concurrency safety
 - Follows British spelling in documentation
 */
public protocol FileSystemServiceProtocol: FileReadOperationsProtocol, 
                                          FileWriteOperationsProtocol,
                                          FileMetadataProtocol {
    /**
     The secure operations component of this service.
     
     This provides access to secure file operations while maintaining
     the separation of regular and secure operations.
     */
    var secureOperations: SecureFileOperationsProtocol { get }
    
    /**
     Gets the temporary directory path appropriate for this file system service.
     
     - Returns: The path to the temporary directory.
     */
    func temporaryDirectoryPath() async -> String
    
    /**
     Creates a unique file name in the specified directory.
     
     - Parameters:
        - directory: The directory in which to create the unique name.
        - prefix: Optional prefix for the file name.
        - extension: Optional file extension.
     - Returns: A unique file path.
     */
    func createUniqueFilename(in directory: String, prefix: String?, extension: String?) async -> String
    
    /**
     Normalises a file path according to system rules.
     
     - Parameter path: The path to normalise.
     - Returns: The normalised path.
     */
    func normalisePath(_ path: String) async -> String
    
    /**
     Creates a sandboxed file system service instance that restricts
     all operations to within the specified root directory.
     
     - Parameter rootDirectory: The directory to restrict operations to.
     - Returns: A sandboxed file system service.
     */
    static func createSandboxed(rootDirectory: String) -> Self
}
