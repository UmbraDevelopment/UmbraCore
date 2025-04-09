import Foundation

/**
 # Core File Operations Protocol
 
 A protocol defining the core file system operations for reading and writing files.
 
 This protocol focuses specifically on the fundamental file operations:
 - Reading file contents
 - Writing file contents
 - Checking file existence
 - Path normalisation
 
 ## Alpha Dot Five Architecture
 
 This protocol follows the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility
 - Uses async/await for thread safety
 - Provides clear operation contracts
 - Uses British spelling in documentation
 */
public protocol CoreFileOperationsProtocol: Sendable {
    /**
     Reads the contents of a file at the specified path.
     
     - Parameter path: The path to the file to read
     - Returns: The file contents as Data and operation result
     - Throws: If the read operation fails
     */
    func readFile(at path: String) async throws -> (Data, FileOperationResultDTO)
    
    /**
     Reads the contents of a file at the specified path as a string.
     
     - Parameters:
        - path: The path to the file to read
        - encoding: The string encoding to use
     - Returns: The file contents as a String and operation result
     - Throws: If the read operation fails
     */
    func readFileAsString(at path: String, encoding: String.Encoding) async throws -> (String, FileOperationResultDTO)
    
    /**
     Checks if a file exists at the specified path.
     
     - Parameter path: The path to check
     - Returns: True if the file exists, false otherwise, along with operation result
     */
    func fileExists(at path: String) async -> (Bool, FileOperationResultDTO)
    
    /**
     Checks if a path points to a file (not a directory).
     
     - Parameter path: The path to check
     - Returns: True if the path points to a file, false otherwise, along with operation result
     */
    func isFile(at path: String) async -> (Bool, FileOperationResultDTO)
    
    /**
     Checks if a path points to a directory.
     
     - Parameter path: The path to check
     - Returns: True if the path points to a directory, false otherwise, along with operation result
     */
    func isDirectory(at path: String) async -> (Bool, FileOperationResultDTO)
    
    /**
     Writes data to a file at the specified path.
     
     - Parameters:
        - data: The data to write
        - path: The path to write to
        - options: Optional write options
     - Returns: Operation result
     - Throws: If the write operation fails
     */
    func writeFile(data: Data, to path: String, options: FileWriteOptions?) async throws -> FileOperationResultDTO
    
    /**
     Writes a string to a file at the specified path.
     
     - Parameters:
        - string: The string to write
        - path: The path to write to
        - encoding: The string encoding to use
        - options: Optional write options
     - Returns: Operation result
     - Throws: If the write operation fails
     */
    func writeString(_ string: String, to path: String, encoding: String.Encoding, options: FileWriteOptions?) async throws -> FileOperationResultDTO
    
    /**
     Normalises a file path according to system rules.
     
     - Parameter path: The path to normalise
     - Returns: The normalised path string
     */
    func normalisePath(_ path: String) async -> String
    
    /**
     Gets the path to the temporary directory.
     
     - Returns: The path to the temporary directory
     */
    func temporaryDirectoryPath() async -> String
    
    /**
     Creates a unique filename in the specified directory.
     
     - Parameters:
        - directory: The directory to create the filename in
        - prefix: Optional prefix for the filename
        - extension: Optional file extension
     - Returns: The unique filename
     */
    func createUniqueFilename(in directory: String, prefix: String?, extension: String?) async -> String
}
