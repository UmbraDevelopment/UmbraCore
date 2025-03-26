import Foundation
import UmbraErrorsCore
// Use the shared declarations instead of local ones
import Interfaces

extension UmbraErrors {
  /// Storage-related error domains
  public enum Storage {
    /// Core storage errors spanning all storage operations
    public enum Core: Error, Sendable, Equatable {
      /// Failed to read data from storage
      case readFailed(reason: String)

      /// Failed to write data to storage
      case writeFailed(reason: String)

      /// Failed to delete data from storage
      case deleteFailed(reason: String)

      /// Requested item does not exist
      case itemNotFound(identifier: String)

      /// Storage location does not exist or is not accessible
      case locationUnavailable(path: String)

      /// Storage is full, cannot write additional data
      case outOfSpace(bytesRequired: UInt64, bytesAvailable: UInt64)

      /// Failed to create a new storage location
      case creationFailed(reason: String)

      /// Storage operation timed out
      case timeout(operation: String)

      /// Storage is corrupted and data cannot be retrieved
      case corrupted(reason: String)

      /// Required permissions are missing for the operation
      case accessDenied(reason: String)

      /// Storage item exists but has an unexpected format
      case invalidFormat(reason: String)

      /// Unexpected error during storage operation
      case internalError(String)
    }

    /// Database-specific storage errors
    public enum Database: Error, Sendable, Equatable {
      /// Database query execution failed
      case queryFailed(reason: String)

      /// Failed to connect to the database
      case connectionFailed(reason: String)

      /// Database schema is incompatible
      case schemaIncompatible(expected: String, found: String)

      /// Database migration failed
      case migrationFailed(reason: String)

      /// Database transaction failed
      case transactionFailed(reason: String)

      /// Data integrity constraint violation
      case constraintViolation(constraint: String, reason: String)

      /// Database is locked by another process
      case databaseLocked(reason: String)

      /// Internal error within database operations
      case internalError(String)
    }

    /// File system-specific storage errors
    public enum FileSystem: Error, Sendable, Equatable {
      /// File system permission error
      case permissionDenied(path: String)

      /// Path is invalid or malformed
      case invalidPath(path: String)

      /// Directory does not exist
      case directoryNotFound(path: String)

      /// File does not exist
      case fileNotFound(path: String)

      /// Failed to create directory
      case directoryCreationFailed(path: String, reason: String)

      /// Failed to rename file or directory
      case renameFailed(source: String, destination: String, reason: String)

      /// Failed to copy file or directory
      case copyFailed(source: String, destination: String, reason: String)

      /// File system is read-only
      case readOnlyFileSystem(path: String)

      /// File is currently in use by another process
      case fileInUse(path: String)

      /// File operations are not supported on this file system
      case unsupportedOperation(operation: String, filesystem: String)

      /// File system is full
      case filesystemFull(path: String)

      /// Internal error within file system operations
      case internalError(String)
    }
  }
}
