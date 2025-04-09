import Foundation

/**
 # File Sandboxing Protocol
 
 A protocol defining operations for sandboxed file system access.
 
 This protocol focuses specifically on restricting file operations to specific directories:
 - Creating sandboxed environments
 - Validating paths against sandboxed roots
 - Managing permissions within sandboxes
 
 ## Alpha Dot Five Architecture
 
 This protocol follows the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility
 - Uses async/await for thread safety
 - Provides clear operation contracts
 - Uses British spelling in documentation
 */
public protocol FileSandboxingProtocol: Sendable {
    /**
     Creates a sandboxed file system service instance that restricts
     all operations to within the specified root directory.
     
     - Parameter rootDirectory: The directory to restrict operations to
     - Returns: A sandboxed service instance and operation result
     */
    static func createSandboxed(rootDirectory: String) -> (Self, FileOperationResultDTO)
    
    /**
     Validates whether a path is within the sandbox.
     
     - Parameter path: The path to validate
     - Returns: True if the path is within the sandbox, false otherwise, and operation result
     */
    func isPathWithinSandbox(_ path: String) async -> (Bool, FileOperationResultDTO)
    
    /**
     Transforms an absolute path to a path relative to the sandbox root.
     
     - Parameter path: The absolute path to transform
     - Returns: The path relative to the sandbox root and operation result
     - Throws: If the path is outside the sandbox
     */
    func pathRelativeToSandbox(_ path: String) async throws -> (String, FileOperationResultDTO)
    
    /**
     Gets the sandbox root directory.
     
     - Returns: The path to the sandbox root directory
     */
    func sandboxRootDirectory() async -> String
    
    /**
     Creates a directory within the sandbox.
     
     - Parameters:
        - path: The path where the directory should be created
        - options: Optional creation options
     - Returns: The path to the created directory and operation result
     - Throws: If the directory cannot be created or the path is outside the sandbox
     */
    func createSandboxedDirectory(at path: String, options: DirectoryCreationOptions?) async throws -> (String, FileOperationResultDTO)
    
    /**
     Creates a file within the sandbox.
     
     - Parameters:
        - path: The path where the file should be created
        - options: Optional creation options
     - Returns: The path to the created file and operation result
     - Throws: If the file cannot be created or the path is outside the sandbox
     */
    func createSandboxedFile(at path: String, options: FileCreationOptions?) async throws -> (String, FileOperationResultDTO)
    
    /**
     Writes data to a file within the sandbox.
     
     - Parameters:
        - data: The data to write
        - path: The path to write to
        - options: Optional write options
     - Returns: Operation result
     - Throws: If the write operation fails or the path is outside the sandbox
     */
    func writeSandboxedFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO
    
    /**
     Lists the contents of a directory within the sandbox.
     
     - Parameter path: The path to the directory to list
     - Returns: An array of file paths contained in the directory and operation result
     - Throws: If the directory cannot be read or the path is outside the sandbox
     */
    func listSandboxedDirectory(at path: String) async throws -> ([String], FileOperationResultDTO)
}
