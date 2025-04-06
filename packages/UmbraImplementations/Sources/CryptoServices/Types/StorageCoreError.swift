import Foundation

/**
 Error type for secure storage core operations
 */
public enum StorageCoreError: Error {
  /// The requested data was not found
  case dataNotFound
  /// The operation failed for a general reason
  case operationFailed(String)
  /// Access was denied
  case accessDenied
  /// The storage is full
  case storageFull
  /// The identifier is invalid
  case invalidIdentifier
  /// The data is corrupted
  case dataCorrupted
}
