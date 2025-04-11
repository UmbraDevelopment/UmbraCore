import Foundation

/**
 Errors that can occur during persistence operations.
 
 This enum defines a comprehensive set of errors that may arise
 during data persistence operations, with localised descriptions.
 */
public enum PersistenceError: Error, Equatable {
    /// The item could not be found
    case itemNotFound(String)
    
    /// The item already exists (e.g., when trying to create a duplicate)
    case itemAlreadyExists(String)
    
    /// The operation failed due to a validation error
    case validationFailed(String)
    
    /// The storage is unavailable or inaccessible
    case storageUnavailable(String)
    
    /// Permission was denied for the operation
    case permissionDenied(String)
    
    /// A transaction operation failed
    case transactionFailed(String)
    
    /// A concurrency conflict occurred (e.g., optimistic locking failure)
    case concurrencyConflict(String)
    
    /// A schema migration failed
    case migrationFailed(String)
    
    /// The storage is corrupt or in an inconsistent state
    case storageCorruption(String)
    
    /// The storage is full or quotas have been exceeded
    case storageFull(String)
    
    /// The operation timed out
    case operationTimeout(String)
    
    /// The query was invalid or malformed
    case invalidQuery(String)
    
    /// Backup or restore operation failed
    case backupFailed(String)
    
    /// The operation failed due to sandbox restrictions
    case sandboxViolation(String)
    
    /// A resource needed for the operation was locked
    case resourceLocked(String)
    
    /// Connection to a remote storage failed
    case connectionFailed(String)
    
    /// A general or unexpected error occurred
    case general(String)
}

// MARK: - CustomStringConvertible

extension PersistenceError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .itemNotFound(let message):
            return "Item not found: \(message)"
        case .itemAlreadyExists(let message):
            return "Item already exists: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .storageUnavailable(let message):
            return "Storage unavailable: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .concurrencyConflict(let message):
            return "Concurrency conflict: \(message)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .storageCorruption(let message):
            return "Storage corruption: \(message)"
        case .storageFull(let message):
            return "Storage full: \(message)"
        case .operationTimeout(let message):
            return "Operation timed out: \(message)"
        case .invalidQuery(let message):
            return "Invalid query: \(message)"
        case .backupFailed(let message):
            return "Backup failed: \(message)"
        case .sandboxViolation(let message):
            return "Sandbox violation: \(message)"
        case .resourceLocked(let message):
            return "Resource locked: \(message)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .general(let message):
            return "General error: \(message)"
        }
    }
}
