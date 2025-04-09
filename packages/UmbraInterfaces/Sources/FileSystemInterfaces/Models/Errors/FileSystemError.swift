import Foundation

/**
 # File System Error
 
 Errors that can occur during file system operations.
 
 This enumeration provides a standardised way to represent and handle
 errors that arise during file system operations, with clear context
 about the operation that failed.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Provides detailed error cases with context
 - Uses British spelling in documentation
 - Implements Sendable for thread safety
 */
public enum FileSystemError: Error, Sendable, Equatable {
    /// File or directory does not exist at specified path
    case pathNotFound(path: String)
    
    /// Error occurred while reading a file
    case readError(path: String, reason: String)
    
    /// Error occurred while writing to a file
    case writeError(path: String, reason: String)
    
    /// Error occurred while deleting a file or directory
    case deleteError(path: String, reason: String)
    
    /// Error occurred while creating a file
    case createError(path: String, reason: String)
    
    /// Error occurred while creating a directory
    case createDirectoryError(path: String, reason: String)
    
    /// Error occurred while moving a file or directory
    case moveError(source: String, destination: String, reason: String)
    
    /// Error occurred while copying a file or directory
    case copyError(source: String, destination: String, reason: String)
    
    /// Error occurred when a path is outside the permitted sandbox
    case sandboxViolation(path: String, sandbox: String)
    
    /// Error occurred with file permissions
    case permissionError(path: String, reason: String)
    
    /// Error occurred with extended attributes
    case extendedAttributeError(path: String, attribute: String, reason: String)
    
    /// Error occurred with security bookmarks
    case securityBookmarkError(reason: String)
    
    /// Error occurred with security-scoped resources
    case securityScopedResourceError(path: String, reason: String)
    
    /// Error occurred with file integrity verification
    case integrityError(path: String, reason: String)
    
    /// Generic error that doesn't fit other categories
    case genericError(reason: String)
}

// MARK: - CustomStringConvertible

extension FileSystemError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .pathNotFound(let path):
            return "Path not found: \(path)"
            
        case .readError(let path, let reason):
            return "Failed to read file at \(path): \(reason)"
            
        case .writeError(let path, let reason):
            return "Failed to write to file at \(path): \(reason)"
            
        case .deleteError(let path, let reason):
            return "Failed to delete item at \(path): \(reason)"
            
        case .createError(let path, let reason):
            return "Failed to create file at \(path): \(reason)"
            
        case .createDirectoryError(let path, let reason):
            return "Failed to create directory at \(path): \(reason)"
            
        case .moveError(let source, let destination, let reason):
            return "Failed to move item from \(source) to \(destination): \(reason)"
            
        case .copyError(let source, let destination, let reason):
            return "Failed to copy item from \(source) to \(destination): \(reason)"
            
        case .sandboxViolation(let path, let sandbox):
            return "Path \(path) is outside the permitted sandbox \(sandbox)"
            
        case .permissionError(let path, let reason):
            return "Permission error for \(path): \(reason)"
            
        case .extendedAttributeError(let path, let attribute, let reason):
            return "Extended attribute error for attribute '\(attribute)' on file \(path): \(reason)"
            
        case .securityBookmarkError(let reason):
            return "Security bookmark error: \(reason)"
            
        case .securityScopedResourceError(let path, let reason):
            return "Security-scoped resource error for \(path): \(reason)"
            
        case .integrityError(let path, let reason):
            return "File integrity error for \(path): \(reason)"
            
        case .genericError(let reason):
            return "File system error: \(reason)"
        }
    }
}

// MARK: - LocalizedError

extension FileSystemError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}
