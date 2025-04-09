import Foundation

/**
 # File System Error
 
 Comprehensive error type for file system operations.
 
 This enum provides detailed error categories and contextual information
 for all file system operation failures, enabling proper error handling
 and reporting throughout the application.
 
 ## Error Categories
 
 The errors are organised into categories that reflect the different types
 of failures that can occur during file system operations:
 
 - **Access Errors**: Permission and security-related issues
 - **Path Errors**: Problems with file paths or locations
 - **IO Errors**: Issues with reading or writing data
 - **Resource Errors**: Problems with system resources
 - **State Errors**: Unexpected file system states
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses enum with associated values for type safety
 - Provides rich context for debugging and error reporting
 - Conforms to standard error protocols
 - Uses British spelling in documentation
 */
public enum FileSystemError: Error, Equatable, Sendable {
    // MARK: - IO Errors
    
    /// Error when reading from a file
    case readError(path: String, reason: String)
    
    /// Error when writing to a file
    case writeError(path: String, reason: String)
    
    /// Error when a file operation is interrupted
    case operationInterrupted(path: String, reason: String)
    
    /// Error when data is corrupted or invalid
    case dataCorruption(path: String, reason: String)
    
    /// Error when a file format is not supported
    case unsupportedFormat(path: String, format: String)
    
    // MARK: - Path Errors
    
    /// Error when a file or directory does not exist
    case notFound(path: String)
    
    /// Error when a file or directory already exists
    case alreadyExists(path: String)
    
    /// Error when a path is invalid
    case invalidPath(path: String, reason: String)
    
    /// The path couldn't be accessed (e.g., network path unavailable)
    case pathUnavailable(path: String, reason: String)
    
    // MARK: - Access Errors
    
    /// Error when permission is denied
    case permissionDenied(path: String, reason: String)
    
    /// Error when access is denied due to security constraints
    case accessDenied(path: String, reason: String)
    
    /// The operation failed because the file is locked or in use
    case fileLocked(path: String)
    
    /// The operation failed because a security constraint was violated
    case securityViolation(path: String, constraint: String)
    
    /// Error when a secure operation fails
    case securityError(path: String, reason: String)
    
    // MARK: - Resource Errors
    
    /// Error when disk space is insufficient
    case diskSpaceFull(path: String, bytesRequired: UInt64?, bytesAvailable: UInt64?)
    
    /// Error when system resources are exhausted (file handles, memory, etc.)
    case resourceExhausted(resource: String, operation: String)
    
    /// Error when a timeout occurs during a file operation
    case timeout(path: String, operation: String, duration: TimeInterval)
    
    // MARK: - Metadata Errors
    
    /// Error when a file attribute operation fails
    case attributeError(path: String, attribute: String, reason: String)
    
    /// Error when a file metadata operation fails
    case metadataError(path: String, reason: String)
    
    /// Error when an extended attribute operation fails
    case extendedAttributeError(path: String, attribute: String, reason: String)
    
    // MARK: - State Errors
    
    /// Error when the file system is in an inconsistent state
    case inconsistentState(path: String, reason: String)
    
    /// Error when a file operation is not supported
    case operationNotSupported(path: String, operation: String)
    
    // MARK: - System Errors
    
    /// Error when a system call fails
    case systemError(path: String, code: Int, description: String)
    
    /// Wraps a standard Foundation error with additional context
    case wrappedError(Error, operation: String, path: String? = nil)
    
    /// A general error that doesn't fit into other categories
    case other(path: String?, reason: String)
    
    // MARK: - Error Factory Methods
    
    /**
     Wraps a standard Error into a FileSystemError with additional context.
     
     - Parameters:
        - error: The original error to wrap
        - operation: The operation that was being performed
        - path: Optional path related to the error
     - Returns: A FileSystemError that wraps the original error
     */
    public static func wrap(_ error: Error, operation: String, path: String? = nil) -> FileSystemError {
        // If it's already a FileSystemError, just return it
        if let fsError = error as? FileSystemError {
            return fsError
        }
        
        // For NSError, try to create a more specific error based on the error code
        if let nsError = error as? NSError {
            switch nsError.domain {
            case NSCocoaErrorDomain:
                return mapCocoaError(nsError, operation: operation, path: path)
            case NSPOSIXErrorDomain:
                return mapPOSIXError(nsError, operation: operation, path: path)
            default:
                break
            }
        }
        
        // Default case: just wrap the error
        return .wrappedError(error, operation: operation, path: path)
    }
    
    /**
     Maps a Cocoa error to a FileSystemError.
     
     - Parameters:
        - error: The NSError from Cocoa
        - operation: The operation that was being performed
        - path: Optional path related to the error
     - Returns: A FileSystemError that corresponds to the Cocoa error
     */
    private static func mapCocoaError(_ error: NSError, operation: String, path: String?) -> FileSystemError {
        let path = path ?? ""
        
        switch error.code {
        case NSFileNoSuchFileError:
            return .notFound(path: path)
        case NSFileWriteNoPermissionError:
            return .permissionDenied(path: path, reason: "No write permission")
        case NSFileReadNoPermissionError:
            return .permissionDenied(path: path, reason: "No read permission")
        case NSFileWriteOutOfSpaceError:
            return .diskSpaceFull(path: path, bytesRequired: nil, bytesAvailable: nil)
        case NSFileWriteVolumeReadOnlyError:
            return .permissionDenied(path: path, reason: "Volume is read-only")
        case NSFileWriteFileExistsError:
            return .alreadyExists(path: path)
        default:
            // Map POSIX errors
            let errorCode = error.code
            
            switch errorCode {
            case Int(ENOENT):
                return .notFound(path: path)
            case Int(EACCES):
                return .permissionDenied(path: path, reason: "Permission denied")
            case Int(EEXIST):
                return .alreadyExists(path: path)
            case Int(ENOSPC):
                return .diskSpaceFull(path: path, bytesRequired: nil, bytesAvailable: nil)
            case Int(EROFS):
                return .permissionDenied(path: path, reason: "File system is read-only")
            case Int(EBUSY):
                return .fileLocked(path: path)
            case Int(EINVAL):
                return .invalidPath(path: path, reason: "Invalid argument")
            case Int(EISDIR):
                return .invalidPath(path: path, reason: "Is a directory")
            case Int(ENOTDIR):
                return .invalidPath(path: path, reason: "Not a directory")
            case Int(ETIMEDOUT):
                return .timeout(path: path, operation: operation, duration: 0)
            case Int(EINTR):
                return .operationInterrupted(path: path, reason: "Operation interrupted")
            default:
                return .systemError(path: path, code: errorCode, description: String(cString: strerror(Int32(errorCode))))
            }
        }
    }
    
    /**
     Maps a POSIX error to a FileSystemError.
     
     - Parameters:
        - error: The NSError from POSIX
        - operation: The operation that was being performed
        - path: Optional path related to the error
     - Returns: A FileSystemError that corresponds to the POSIX error
     */
    private static func mapPOSIXError(_ error: NSError, operation: String, path: String?) -> FileSystemError {
        let path = path ?? ""
        let errorCode = error.code
        
        switch errorCode {
        case Int(ENOENT):
            return .notFound(path: path)
        case Int(EACCES):
            return .permissionDenied(path: path, reason: "Permission denied")
        case Int(EEXIST):
            return .alreadyExists(path: path)
        case Int(ENOSPC):
            return .diskSpaceFull(path: path, bytesRequired: nil, bytesAvailable: nil)
        case Int(EROFS):
            return .permissionDenied(path: path, reason: "File system is read-only")
        case Int(EBUSY):
            return .fileLocked(path: path)
        case Int(EINVAL):
            return .invalidPath(path: path, reason: "Invalid argument")
        case Int(EISDIR):
            return .invalidPath(path: path, reason: "Is a directory")
        case Int(ENOTDIR):
            return .invalidPath(path: path, reason: "Not a directory")
        case Int(ETIMEDOUT):
            return .timeout(path: path, operation: operation, duration: 0)
        case Int(EINTR):
            return .operationInterrupted(path: path, reason: "Operation interrupted")
        default:
            return .systemError(path: path, code: errorCode, description: String(cString: strerror(Int32(errorCode))))
        }
    }
}

// MARK: - Equatable Implementation

// Manual implementation of Equatable because Error protocol doesn't conform to Equatable
extension FileSystemError {
    public static func == (lhs: FileSystemError, rhs: FileSystemError) -> Bool {
        switch (lhs, rhs) {
        case (.readError(let lhsPath, let lhsReason), .readError(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.writeError(let lhsPath, let lhsReason), .writeError(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.operationInterrupted(let lhsPath, let lhsReason), .operationInterrupted(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.dataCorruption(let lhsPath, let lhsReason), .dataCorruption(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.unsupportedFormat(let lhsPath, let lhsFormat), .unsupportedFormat(let rhsPath, let rhsFormat)):
            return lhsPath == rhsPath && lhsFormat == rhsFormat
            
        case (.notFound(let lhsPath), .notFound(let rhsPath)):
            return lhsPath == rhsPath
            
        case (.alreadyExists(let lhsPath), .alreadyExists(let rhsPath)):
            return lhsPath == rhsPath
            
        case (.invalidPath(let lhsPath, let lhsReason), .invalidPath(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.pathUnavailable(let lhsPath, let lhsReason), .pathUnavailable(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.permissionDenied(let lhsPath, let lhsReason), .permissionDenied(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.accessDenied(let lhsPath, let lhsReason), .accessDenied(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.fileLocked(let lhsPath), .fileLocked(let rhsPath)):
            return lhsPath == rhsPath
            
        case (.securityViolation(let lhsPath, let lhsConstraint), .securityViolation(let rhsPath, let rhsConstraint)):
            return lhsPath == rhsPath && lhsConstraint == rhsConstraint
            
        case (.securityError(let lhsPath, let lhsReason), .securityError(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.diskSpaceFull(let lhsPath, let lhsRequired, let lhsAvailable), 
              .diskSpaceFull(let rhsPath, let rhsRequired, let rhsAvailable)):
            return lhsPath == rhsPath && lhsRequired == rhsRequired && lhsAvailable == rhsAvailable
            
        case (.resourceExhausted(let lhsResource, let lhsOperation), 
              .resourceExhausted(let rhsResource, let rhsOperation)):
            return lhsResource == rhsResource && lhsOperation == rhsOperation
            
        case (.timeout(let lhsPath, let lhsOperation, let lhsDuration), 
              .timeout(let rhsPath, let rhsOperation, let rhsDuration)):
            return lhsPath == rhsPath && lhsOperation == rhsOperation && lhsDuration == rhsDuration
            
        case (.attributeError(let lhsPath, let lhsAttribute, let lhsReason), 
              .attributeError(let rhsPath, let rhsAttribute, let rhsReason)):
            return lhsPath == rhsPath && lhsAttribute == rhsAttribute && lhsReason == rhsReason
            
        case (.metadataError(let lhsPath, let lhsReason), .metadataError(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.extendedAttributeError(let lhsPath, let lhsAttribute, let lhsReason), 
              .extendedAttributeError(let rhsPath, let rhsAttribute, let rhsReason)):
            return lhsPath == rhsPath && lhsAttribute == rhsAttribute && lhsReason == rhsReason
            
        case (.inconsistentState(let lhsPath, let lhsReason), .inconsistentState(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        case (.operationNotSupported(let lhsPath, let lhsOperation), 
              .operationNotSupported(let rhsPath, let rhsOperation)):
            return lhsPath == rhsPath && lhsOperation == rhsOperation
            
        case (.systemError(let lhsPath, let lhsCode, let lhsDescription), 
              .systemError(let rhsPath, let rhsCode, let rhsDescription)):
            return lhsPath == rhsPath && lhsCode == rhsCode && lhsDescription == rhsDescription
        
        // For wrapped errors, we compare the path and operation but not the underlying error
        // since Error is not Equatable
        case (.wrappedError(_, let lhsOperation, let lhsPath), .wrappedError(_, let rhsOperation, let rhsPath)):
            return lhsOperation == rhsOperation && lhsPath == rhsPath
            
        case (.other(let lhsPath, let lhsReason), .other(let rhsPath, let rhsReason)):
            return lhsPath == rhsPath && lhsReason == rhsReason
            
        // If case patterns don't match, the errors are not equal
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible Extension

extension FileSystemError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .readError(let path, let reason):
            return "Cannot read from '\(path)': \(reason)"
        case .writeError(let path, let reason):
            return "Cannot write to '\(path)': \(reason)"
        case .notFound(let path):
            return "Item not found at path: '\(path)'"
        case .alreadyExists(let path):
            return "Item already exists at path: '\(path)'"
        case .invalidPath(let path, let reason):
            return "Invalid path '\(path)': \(reason)"
        case .permissionDenied(let path, let reason):
            return "Permission denied for path: '\(path)'. \(reason)"
        case .diskSpaceFull(let path, let bytesRequired, let bytesAvailable):
            var message = "Disk space full for operation on '\(path)'"
            if let required = bytesRequired {
                message += ", \(required) bytes required"
            }
            if let available = bytesAvailable {
                message += ", \(available) bytes available"
            }
            return message
        case .operationInterrupted(let path, let reason):
            return "Operation interrupted for '\(path)': \(reason)"
        case .securityError(let path, let reason):
            return "Security error for '\(path)': \(reason)"
        case .attributeError(let path, let attribute, let reason):
            return "Attribute error for '\(path)', attribute '\(attribute)': \(reason)"
        case .extendedAttributeError(let path, let attribute, let reason):
            return "Extended attribute error for '\(path)', attribute '\(attribute)': \(reason)"
        case .metadataError(let path, let reason):
            return "Metadata error for '\(path)': \(reason)"
        case .accessDenied(let path, let reason):
            return "Access denied for path: '\(path)'. \(reason)"
        case .fileLocked(let path):
            return "File is locked or in use: '\(path)'"
        case .securityViolation(let path, let constraint):
            return "Security constraint violated for '\(path)': \(constraint)"
        case .pathUnavailable(let path, let reason):
            return "Path unavailable: '\(path)'. \(reason)"
        case .dataCorruption(let path, let reason):
            return "Data corruption detected in '\(path)': \(reason)"
        case .unsupportedFormat(let path, let format):
            return "Unsupported format '\(format)' for file: '\(path)'"
        case .resourceExhausted(let resource, let operation):
            return "System resource '\(resource)' exhausted during operation: \(operation)"
        case .timeout(let path, let operation, let duration):
            return "Operation '\(operation)' on '\(path)' timed out after \(duration) seconds"
        case .inconsistentState(let path, let reason):
            return "File system in inconsistent state for '\(path)': \(reason)"
        case .operationNotSupported(let path, let operation):
            return "Operation '\(operation)' not supported for '\(path)'"
        case .systemError(let path, let code, let description):
            return "System error (code \(code)) for '\(path)': \(description)"
        case .wrappedError(let error, let operation, let path):
            let pathDesc = path.map { " on '\($0)'" } ?? ""
            return "Error during \(operation)\(pathDesc): \(error.localizedDescription)"
        case .other(let path, let reason):
            let pathDesc = path.map { " for '\($0)'" } ?? ""
            return "File system error\(pathDesc): \(reason)"
        }
    }
}

// MARK: - LocalizedError Extension

extension FileSystemError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
    
    public var failureReason: String? {
        switch self {
        case .readError(_, let reason):
            return reason
        case .writeError(_, let reason):
            return reason
        case .notFound:
            return "The specified item could not be found."
        case .alreadyExists:
            return "An item already exists at the specified path."
        case .invalidPath(_, let reason):
            return reason
        case .permissionDenied(_, let reason):
            return reason
        case .accessDenied(_, let reason):
            return reason
        case .diskSpaceFull:
            return "There is not enough disk space to complete the operation."
        case .operationInterrupted(_, let reason):
            return reason
        case .securityError(_, let reason):
            return reason
        case .attributeError(_, _, let reason):
            return reason
        case .extendedAttributeError(_, _, let reason):
            return reason
        case .metadataError(_, let reason):
            return reason
        case .fileLocked:
            return "The file is locked or in use by another process."
        case .securityViolation(_, let constraint):
            return "Security constraint violation: \(constraint)"
        case .pathUnavailable(_, let reason):
            return reason
        case .dataCorruption(_, let reason):
            return reason
        case .unsupportedFormat(_, let format):
            return "The format '\(format)' is not supported."
        case .resourceExhausted(let resource, _):
            return "The system resource '\(resource)' has been exhausted."
        case .timeout:
            return "The operation timed out."
        case .inconsistentState(_, let reason):
            return reason
        case .operationNotSupported(_, let operation):
            return "The operation '\(operation)' is not supported."
        case .systemError(_, _, let description):
            return description
        case .wrappedError(let error, _, _):
            return error.localizedDescription
        case .other(_, let reason):
            return reason
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notFound:
            return "Check that the path exists and is spelled correctly."
        case .alreadyExists:
            return "Choose a different path or remove the existing item first."
        case .permissionDenied:
            return "Check file permissions or run the application with elevated privileges."
        case .accessDenied:
            return "Check sandbox permissions and file access entitlements."
        case .diskSpaceFull:
            return "Free up disk space or use a different volume."
        case .fileLocked:
            return "Close any applications that might be using this file and try again."
        case .operationInterrupted:
            return "Try the operation again."
        case .invalidPath:
            return "Check that the path is correctly formatted and within allowed bounds."
        default:
            return nil
        }
    }
}
