/**
 # Secure Storage Protocol

 Defines the interface for secure storage operations in the Alpha Dot Five architecture.
 This protocol provides thread-safe access to secure storage operations
 with proper error handling and privacy protections.
 */

import Foundation

/**
 Protocol defining secure storage operations.
 */
public protocol SecureStorageProtocol: Sendable {
  /**
   Stores data securely.

   - Parameters:
      - data: The data to store
      - identifier: String identifier for the stored data
      - config: Configuration for the storage operation

   - Returns: Result of the storage operation
   - Throws: SecureStorageError if storage fails
   */
  func storeSecurely(
    data: Data,
    identifier: String,
    config: SecureStorageConfig
  ) async throws -> StorageResult

  /**
   Retrieves data securely.

   - Parameters:
      - identifier: String identifier for the data
      - config: Configuration for the retrieval operation

   - Returns: Result of the retrieval operation
   - Throws: SecureStorageError if retrieval fails
   */
  func retrieveSecurely(
    identifier: String,
    config: SecureStorageConfig
  ) async throws -> RetrievalResult

  /**
   Deletes data securely.

   - Parameters:
      - identifier: String identifier for the data
      - config: Configuration for the deletion operation

   - Returns: Result of the deletion operation
   - Throws: SecureStorageError if deletion fails
   */
  func deleteSecurely(
    identifier: String,
    config: SecureStorageConfig
  ) async throws -> DeletionResult

  /**
   Lists all identifiers for stored data.

   - Returns: Array of identifiers
   - Throws: SecureStorageError if listing fails
   */
  func listSecureIdentifiers() async throws -> [String]

  /**
   Checks if data exists for the given identifier.

   - Parameter identifier: String identifier to check

   - Returns: True if data exists, false otherwise
   - Throws: SecureStorageError if check fails
   */
  func hasSecureData(forIdentifier identifier: String) async throws -> Bool
}
