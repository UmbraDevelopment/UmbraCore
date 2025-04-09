import Foundation

/**
 # File Read Operations Protocol
 
 Defines the core read operations that can be performed on a file system.
 
 This protocol centralizes all file read operations to ensure consistency
 across different file system service implementations.
 
 ## Alpha Dot Five Architecture
 
 This protocol conforms to the Alpha Dot Five architecture principles:
 - Focuses on a single responsibility (reading operations)
 - Uses asynchronous APIs for thread safety
 - Provides comprehensive error handling
 */
public protocol FileReadOperationsProtocol: Actor, Sendable {
    /**
     Reads the contents of a file at the specified path.
     
     - Parameter path: The path to the file to read.
     - Returns: The file contents as Data.
     - Throws: FileSystemError if the read operation fails.
     */
    func readFile(at path: String) async throws -> Data
    
    /**
     Reads the contents of a file at the specified path as a string.
     
     - Parameters:
        - path: The path to the file to read.
        - encoding: The string encoding to use for reading the file.
     - Returns: The file contents as a String.
     - Throws: FileSystemError if the read operation fails.
     */
    func readFileAsString(at path: String, encoding: String.Encoding) async throws -> String
    
    /**
     Checks if a file exists at the specified path.
     
     - Parameter path: The path to check.
     - Returns: True if the file exists, false otherwise.
     */
    func fileExists(at path: String) async -> Bool
    
    /**
     Lists the contents of a directory at the specified path.
     
     - Parameter path: The path to the directory to list.
     - Returns: An array of file paths contained in the directory.
     - Throws: FileSystemError if the directory cannot be read.
     */
    func listDirectory(at path: String) async throws -> [String]
    
    /**
     Lists the contents of a directory recursively.
     
     - Parameter path: The path to the directory to recursively list.
     - Returns: An array of file paths contained in the directory and its subdirectories.
     - Throws: FileSystemError if the directory cannot be read.
     */
    func listDirectoryRecursively(at path: String) async throws -> [String]
}
