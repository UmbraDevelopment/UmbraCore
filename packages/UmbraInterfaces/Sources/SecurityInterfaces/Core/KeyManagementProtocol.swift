/**
 # Key Management Protocol

 Defines the interface for key management operations in the Alpha Dot Five architecture.
 This protocol provides thread-safe access to cryptographic key operations
 with proper error handling and privacy protections.
 */

import Foundation
import SecurityTypes

/**
 Protocol defining key management operations.
 */
public protocol KeyManagementProtocol: Sendable {
  /**
   Generates a new cryptographic key.

   - Parameters:
      - algorithm: The cryptographic algorithm
      - keySizeInBits: The key size in bits

   - Returns: The key identifier for the generated key
   - Throws: KeyManagementError if key generation fails
   */
  func generateKey(
    algorithm: String,
    keySizeInBits: Int
  ) async throws -> KeyIdentifier

  /**
   Imports a cryptographic key.

   - Parameters:
      - keyData: The key data to import
      - algorithm: The cryptographic algorithm

   - Returns: The key identifier for the imported key
   - Throws: KeyManagementError if key import fails
   */
  func importKey(
    keyData: Data,
    algorithm: String
  ) async throws -> KeyIdentifier

  /**
   Retrieves a cryptographic key.

   - Parameter identifier: The key identifier

   - Returns: The key data
   - Throws: KeyManagementError if key retrieval fails or key not found
   */
  func retrieveKey(
    withIdentifier identifier: KeyIdentifier
  ) async throws -> Data

  /**
   Deletes a cryptographic key.

   - Parameter identifier: The key identifier

   - Throws: KeyManagementError if key deletion fails
   */
  func deleteKey(
    withIdentifier identifier: KeyIdentifier
  ) async throws

  /**
   Lists all key identifiers managed by this service.

   - Returns: Array of key identifiers
   - Throws: KeyManagementError if listing keys fails
   */
  func listKeys() async throws -> [KeyIdentifier]

  /**
   Derives a key from a password or other input using PBKDF2 or similar.

   - Parameters:
      - password: The password to derive from
      - salt: Optional salt for derivation
      - iterations: Number of iterations
      - keySizeInBits: The desired key size in bits

   - Returns: The derived key data
   - Throws: KeyManagementError if key derivation fails
   */
  func deriveKey(
    fromPassword password: String,
    salt: Data?,
    iterations: Int,
    keySizeInBits: Int
  ) async throws -> Data
}
