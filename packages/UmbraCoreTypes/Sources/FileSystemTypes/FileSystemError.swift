/**
 # FileSystemError
 
 Defines domain-specific errors for file system operations.
 
 ## Overview
 
 This enumeration provides a comprehensive set of error cases that can occur
 during file system operations, ensuring consistent error reporting and handling
 across the system.
 
 ## Error Cases
 
 FileSystemError provides specific error types for common failure scenarios:
 
 - `fileNotFound`: The specified file does not exist
 - `permissionDenied`: The operation was not allowed due to permissions
 - `fileAlreadyExists`: Attempted to create a file that already exists
 - `directoryNotEmpty`: Attempted to delete a non-empty directory without recursive flag
 - `insufficientStorage`: Not enough space to complete the operation
 - `invalidPath`: The provided path is invalid or malformed
 - `general`: A generic error with error code for other situations
 
 ## Error Handling Example
 
 ```swift
 let result = await fileSystem.readFile(at: path)
 switch result {
 case .success(let data):
     // Process the data
 case .failure(let error):
     switch error {
     case .fileNotFound(let path, let message):
         print("File not found at \(path): \(message)")
     case .permissionDenied(let path, let message):
         print("Permission denied for \(path): \(message)")
     default:
         print("Error: \(error)")
     }
 }
 ```
 */

import Foundation

/// Domain-specific error type for file system operations
public enum FileSystemError: Error, Sendable {
    /// The specified file or directory was not found
    case fileNotFound(path: String, message: String)
    
    /// The operation was not permitted due to insufficient permissions
    case permissionDenied(path: String, message: String)
    
    /// A file or directory already exists at the specified path
    case fileAlreadyExists(path: String, message: String)
    
    /// The directory is not empty and cannot be deleted without recursive flag
    case directoryNotEmpty(path: String, message: String)
    
    /// There is not enough storage space to complete the operation
    case insufficientStorage(path: String, message: String)
    
    /// The provided path is invalid or malformed
    case invalidPath(path: String, message: String)
    
    /// A general file system error with an associated error code
    case general(path: String, message: String, code: Int)
    
    /// User-friendly description of the error
    public var localizedDescription: String {
        switch self {
        case .fileNotFound(let path, let message):
            return "File not found at '\(path)': \(message)"
        case .permissionDenied(let path, let message):
            return "Permission denied for '\(path)': \(message)"
        case .fileAlreadyExists(let path, let message):
            return "File already exists at '\(path)': \(message)"
        case .directoryNotEmpty(let path, let message):
            return "Directory not empty at '\(path)': \(message)"
        case .insufficientStorage(let path, let message):
            return "Insufficient storage for operation on '\(path)': \(message)"
        case .invalidPath(let path, let message):
            return "Invalid path '\(path)': \(message)"
        case .general(let path, let message, let code):
            return "File system error (code: \(code)) for '\(path)': \(message)"
        }
    }
}
