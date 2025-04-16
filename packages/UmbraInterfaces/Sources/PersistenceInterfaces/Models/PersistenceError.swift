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
      case let .itemNotFound(message):
        "Item not found: \(message)"
      case let .itemAlreadyExists(message):
        "Item already exists: \(message)"
      case let .validationFailed(message):
        "Validation failed: \(message)"
      case let .storageUnavailable(message):
        "Storage unavailable: \(message)"
      case let .permissionDenied(message):
        "Permission denied: \(message)"
      case let .transactionFailed(message):
        "Transaction failed: \(message)"
      case let .concurrencyConflict(message):
        "Concurrency conflict: \(message)"
      case let .migrationFailed(message):
        "Migration failed: \(message)"
      case let .storageCorruption(message):
        "Storage corruption: \(message)"
      case let .storageFull(message):
        "Storage full: \(message)"
      case let .operationTimeout(message):
        "Operation timed out: \(message)"
      case let .invalidQuery(message):
        "Invalid query: \(message)"
      case let .backupFailed(message):
        "Backup failed: \(message)"
      case let .sandboxViolation(message):
        "Sandbox violation: \(message)"
      case let .resourceLocked(message):
        "Resource locked: \(message)"
      case let .connectionFailed(message):
        "Connection failed: \(message)"
      case let .general(message):
        "General error: \(message)"
    }
  }
}
