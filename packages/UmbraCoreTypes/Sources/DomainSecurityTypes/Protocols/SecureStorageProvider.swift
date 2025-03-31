import CoreSecurityTypes
import Foundation

/**
 Defines the functionality required for secure storage operations.

 This protocol follows the architecture pattern for actor-isolated interfaces
 with async methods for thread safety. All implementations must be actor-based
 to ensure proper state isolation.
 */
public protocol SecureStorageProvider: Sendable {
  /**
   Securely stores data with the specified identifier.

   - Parameters:
     - data: Data to store
     - identifier: Unique identifier for retrieval
     - options: Optional storage options

   - Throws: CoreSecurityError if storage fails
   */
  func securelyStore(
    data: Data,
    withIdentifier identifier: String,
    options: [String: Any]?
  ) async throws

  /**
   Retrieves securely stored data by identifier.

   - Parameters:
     - identifier: Unique identifier of the data

   - Returns: Retrieved data
   - Throws: CoreSecurityError if retrieval fails
   */
  func retrieveSecureData(
    withIdentifier identifier: String
  ) async throws -> Data

  /**
   Deletes securely stored data by identifier.

   - Parameters:
     - identifier: Unique identifier of the data to delete

   - Throws: CoreSecurityError if deletion fails
   */
  func deleteSecureData(
    withIdentifier identifier: String
  ) async throws

  /**
   Checks if data with the specified identifier exists.

   - Parameters:
     - identifier: Unique identifier to check

   - Returns: True if data exists, false otherwise
   */
  func hasSecureData(
    withIdentifier identifier: String
  ) async -> Bool

  /**
   Updates securely stored data with new data.

   - Parameters:
     - data: New data to store
     - identifier: Unique identifier of the data to update
     - options: Optional storage options

   - Throws: CoreSecurityError if update fails
   */
  func updateSecureData(
    data: Data,
    withIdentifier identifier: String,
    options: [String: Any]?
  ) async throws
}
