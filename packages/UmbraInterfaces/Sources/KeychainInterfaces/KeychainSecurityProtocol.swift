import Foundation
import SecurityCoreInterfaces

/**
 # KeychainSecurityProtocol

 Protocol defining the interface for a service that integrates both keychain operations
 and key management for encrypted data storage.

 This protocol provides a unified interface for operations that require both the keychain
 for secure storage and key management for encryption/decryption, ensuring proper
 integration between these security domains.

 ## Usage Example

 ```swift
 // Create the security service
 let securityService = await KeychainServices.createSecurityService()

 // Store an encrypted secret
 try await securityService.storeEncryptedSecret(
     "mysecret",
     forAccount: "user@example.com"
 )

 // Retrieve the decrypted secret
 let secret = try await securityService.retrieveEncryptedSecret(
     forAccount: "user@example.com"
 )
 ```
 */
public protocol KeychainSecurityProtocol: Sendable {
  /**
   Stores a secret in the keychain, encrypted with a managed key.

   This method encrypts the provided secret using a key that is managed
   by the security service, then stores the encrypted data in the keychain.

   - Parameters:
      - secret: The secret to encrypt and store
      - account: The account identifier for retrieving the secret
      - keyIdentifier: Optional custom key identifier (default: derived from account)
      - accessOptions: Optional keychain access options
   */
  func storeEncryptedSecret(
    _ secret: String,
    forAccount account: String,
    keyIdentifier: String?,
    accessOptions: KeychainAccessOptions?
  ) async throws

  /**
   Stores a secret in the keychain, encrypted with a managed key.

   Convenience method that uses a key identifier derived from the account.

   - Parameters:
      - secret: The secret to encrypt and store
      - account: The account identifier for retrieving the secret
      - accessOptions: Optional keychain access options
   */
  func storeEncryptedSecret(
    _ secret: String,
    forAccount account: String,
    accessOptions: KeychainAccessOptions?
  ) async throws

  /**
   Retrieves a secret from the keychain, decrypting it with the managed key.

   This method retrieves the encrypted data from the keychain, then decrypts
   it using the appropriate key from the key management service.

   - Parameters:
      - account: The account identifier for the secret
      - keyIdentifier: Optional custom key identifier (default: derived from account)

   - Returns: The decrypted secret
   */
  func retrieveEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String?
  ) async throws -> String

  /**
   Retrieves a secret from the keychain, decrypting it with the managed key.

   Convenience method that uses a key identifier derived from the account.

   - Parameter account: The account identifier for the secret
   - Returns: The decrypted secret
   */
  func retrieveEncryptedSecret(
    forAccount account: String
  ) async throws -> String

  /**
   Deletes an encrypted secret from the keychain.

   This method removes both the encrypted data from the keychain and
   can optionally clean up the associated encryption key.

   - Parameters:
      - account: The account identifier for the secret
      - deleteKey: Whether to also delete the encryption key
      - keyIdentifier: Optional custom key identifier (default: derived from account)
   */
  func deleteEncryptedSecret(
    forAccount account: String,
    deleteKey: Bool,
    keyIdentifier: String?
  ) async throws

  /**
   Deletes an encrypted secret from the keychain.

   Convenience method that uses a key identifier derived from the account.

   - Parameters:
      - account: The account identifier for the secret
      - deleteKey: Whether to also delete the encryption key
   */
  func deleteEncryptedSecret(
    forAccount account: String,
    deleteKey: Bool
  ) async throws

  /**
   Updates an encrypted secret in the keychain.

   This method replaces an existing encrypted secret with a new value,
   using the same key for encryption.

   - Parameters:
      - newSecret: The new secret value to encrypt and store
      - account: The account identifier for the secret
      - keyIdentifier: Optional custom key identifier (default: derived from account)
      - accessOptions: Optional keychain access options
   */
  func updateEncryptedSecret(
    _ newSecret: String,
    forAccount account: String,
    keyIdentifier: String?,
    accessOptions: KeychainAccessOptions?
  ) async throws

  /**
   Updates an encrypted secret in the keychain.

   Convenience method that uses a key identifier derived from the account.

   - Parameters:
      - newSecret: The new secret value to encrypt and store
      - account: The account identifier for the secret
      - accessOptions: Optional keychain access options
   */
  func updateEncryptedSecret(
    _ newSecret: String,
    forAccount account: String,
    accessOptions: KeychainAccessOptions?
  ) async throws
}

// Default implementations for convenience methods
extension KeychainSecurityProtocol {
  public func storeEncryptedSecret(
    _ secret: String,
    forAccount account: String,
    accessOptions: KeychainAccessOptions?=nil
  ) async throws {
    try await storeEncryptedSecret(
      secret,
      forAccount: account,
      keyIdentifier: nil,
      accessOptions: accessOptions
    )
  }

  public func retrieveEncryptedSecret(
    forAccount account: String
  ) async throws -> String {
    try await retrieveEncryptedSecret(
      forAccount: account,
      keyIdentifier: nil
    )
  }

  public func deleteEncryptedSecret(
    forAccount account: String,
    deleteKey: Bool=false
  ) async throws {
    try await deleteEncryptedSecret(
      forAccount: account,
      deleteKey: deleteKey,
      keyIdentifier: nil
    )
  }

  public func updateEncryptedSecret(
    _ newSecret: String,
    forAccount account: String,
    accessOptions: KeychainAccessOptions?=nil
  ) async throws {
    try await updateEncryptedSecret(
      newSecret,
      forAccount: account,
      keyIdentifier: nil,
      accessOptions: accessOptions
    )
  }
}
