import Foundation

/**
 # Secure File Operations Protocol
 
 A protocol defining operations for secure file handling.
 
 This protocol focuses specifically on security-related operations:
 - Creating and resolving security bookmarks
 - Managing security-scoped resources
 - Secure file creation and deletion
 - Data verification
 
 ## Alpha Dot Five Architecture
 
 This protocol follows the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility
 - Uses async/await for thread safety
 - Provides clear operation contracts
 - Uses British spelling in documentation
 */
public protocol SecureFileOperationsProtocol: Sendable {
    /**
     Creates a security bookmark for a file or directory.
     
     - Parameters:
        - path: The path to the file or directory
        - readOnly: Whether the bookmark should be for read-only access
     - Returns: The bookmark data and operation result
     - Throws: If the bookmark cannot be created
     */
    func createSecurityBookmark(for path: String, readOnly: Bool) async throws -> (Data, FileOperationResultDTO)
    
    /**
     Resolves a security bookmark to a file path.
     
     - Parameter bookmark: The bookmark data to resolve
     - Returns: The file path, whether it's stale, and operation result
     - Throws: If the bookmark cannot be resolved
     */
    func resolveSecurityBookmark(_ bookmark: Data) async throws -> (String, Bool, FileOperationResultDTO)
    
    /**
     Starts accessing a security-scoped resource.
     
     - Parameter path: The path to start accessing
     - Returns: True if access was granted, false otherwise, and operation result
     - Throws: If access cannot be started
     */
    func startAccessingSecurityScopedResource(at path: String) async throws -> (Bool, FileOperationResultDTO)
    
    /**
     Stops accessing a security-scoped resource.
     
     - Parameter path: The path to stop accessing
     - Returns: Operation result
     */
    func stopAccessingSecurityScopedResource(at path: String) async -> FileOperationResultDTO
    
    /**
     Creates a temporary file with secure permissions.
     
     - Parameter options: Optional options for creating the temporary file
     - Returns: The path to the created file and operation result
     - Throws: If the file cannot be created
     */
    func createSecureTemporaryFile(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO)
    
    /**
     Creates a temporary directory with secure permissions.
     
     - Parameter options: Optional options for creating the temporary directory
     - Returns: The path to the created directory and operation result
     - Throws: If the directory cannot be created
     */
    func createSecureTemporaryDirectory(options: TemporaryFileOptions?) async throws -> (String, FileOperationResultDTO)
    
    /**
     Securely writes data to a file with encryption.
     
     - Parameters:
        - data: The data to write
        - path: The path to write to
        - options: Optional secure write options
     - Returns: Operation result
     - Throws: If the write operation fails
     */
    func writeSecureFile(data: Data, to path: String, options: SecureFileOptions?) async throws -> FileOperationResultDTO
    
    /**
     Securely deletes a file by overwriting its contents before removal.
     
     - Parameters:
        - path: The path to the file to delete
        - passes: Number of overwrite passes (default is 3)
     - Returns: Operation result
     - Throws: If the secure delete operation fails
     */
    func secureDelete(at path: String, passes: Int) async throws -> FileOperationResultDTO
    
    /**
     Verifies the integrity of a file using a checksum.
     
     - Parameters:
        - path: The path to the file to verify
        - expectedChecksum: The expected checksum
        - algorithm: The checksum algorithm to use
     - Returns: True if the file integrity is verified, false otherwise, and operation result
     - Throws: If the verification fails
     */
    func verifyFileIntegrity(at path: String, expectedChecksum: Data, algorithm: ChecksumAlgorithm) async throws -> (Bool, FileOperationResultDTO)
}
