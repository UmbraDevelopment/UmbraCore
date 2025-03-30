import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import KeychainTypes
import UmbraErrors

/**
 # KeychainSecurityActor

 An actor that integrates both KeychainServiceProtocol and ApplicationSecurityProviderProtocol,
 providing a unified interface for secure storage operations that might require
 both services.

 ## Responsibilities

 - Secure storage of sensitive data in the keychain
 - Proper encryption/decryption of data using the application security provider
 - Thread-safe operations for all security-related activities
 - Proper error handling and logging

 ## Usage

 ```swift
 // Create the actor
 let securityActor = KeychainSecurityActor(
     keychainService: await KeychainServiceFactory.createService(),
     securityProvider: await SecurityProviderFactory.createApplicationSecurityProvider(),
     logger: myLogger
 )

 // Store a secret with encryption
 try await securityActor.storeEncryptedSecret(
     "mysecret",
     forAccount: "user@example.com"
 )

 // Retrieve the secret
 let secret = try await securityActor.retrieveEncryptedSecret(
     forAccount: "user@example.com"
 )
 ```
 */
public actor KeychainSecurityActor {
  // MARK: - Properties

  /// The keychain service for storing items
  private let keychainService: KeychainServiceProtocol

  /// The application security provider for encryption operations
  private let securityProvider: ApplicationSecurityProviderProtocol

  /// Logger for recording operations
  private let logger: LoggingServiceProtocol

  /// Error type for keychain security operations
  public enum KeychainSecurityError: Error {
    case keychainError(String)
    case securityError(SecurityProtocolError)
    case encodingFailed
    case keyGenerationFailed
    case keyStorageFailed
    case keyNotFound
  }

  // MARK: - Initialisation

  /**
   Initialises a new KeychainSecurityActor with the required services.

   - Parameters:
      - keychainService: The service for interacting with the keychain
      - securityProvider: The application-level provider for encryption and key management
      - logger: Logger for recording operations
   */
  public init(
    keychainService: KeychainServiceProtocol,
    securityProvider: ApplicationSecurityProviderProtocol,
    logger: LoggingServiceProtocol
  ) {
    self.keychainService = keychainService
    self.securityProvider = securityProvider
    self.logger = logger
  }

  // MARK: - Public Methods

  /**
   Stores an encrypted secret in the keychain.

   - Parameters:
      - secret: The secret to store
      - account: The account identifier to associate with the secret
      - keyIdentifier: Optional identifier for the encryption key, defaults to the account name

   - Throws: KeychainSecurityError if operations fail
   */
  public func storeEncryptedSecret(
    _ secret: String,
    forAccount account: String,
    keyIdentifier: String? = nil
  ) async throws {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation (without sensitive details)
    var metadata = LogMetadata()
    metadata["account"] = account
    metadata["keyID"] = keyID
    metadata["operation"] = "storeEncryptedSecret"

    await logger.info(
      "Starting encrypted secret storage operation",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    do {
      // Convert the secret to data
      guard let secretData = secret.data(using: .utf8) else {
        throw KeychainSecurityError.encodingFailed
      }

      // Encrypt the data
      let encryptionOptions = SecurityConfigOptions(
        algorithm: EncryptionAlgorithm.aes256Gcm.rawValue,
        keyIdentifier: keyID
      )
      
      let encryptionConfig = SecurityConfigDTO(options: encryptionOptions)

      let encryptionResult = try await securityProvider.encrypt(
        data: secretData,
        with: encryptionConfig
      )

      // Store in keychain
      try await keychainService.storeItem(
        encryptionResult.encryptedData,
        forAccount: account,
        withLabel: "Encrypted Secret"
      )

      await logger.info(
        "Successfully stored encrypted secret",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
    } catch let error as KeychainError {
      // Handle keychain-specific errors
      await logger.error(
        "Failed to store encrypted secret: Keychain error",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.keychainError(error.localizedDescription)
    } catch let error as SecurityProtocolError {
      // Handle security provider errors
      await logger.error(
        "Failed to store encrypted secret: Security error",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.securityError(error)
    } catch {
      // Handle unexpected errors
      await logger.error(
        "Failed to store encrypted secret: Unknown error",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw error
    }
  }

  /**
   Retrieves an encrypted secret from the keychain.

   - Parameters:
      - account: The account identifier for the secret
      - keyIdentifier: Optional identifier for the encryption key, defaults to the account name

   - Returns: The decrypted secret string
   - Throws: KeychainSecurityError if operations fail
   */
  public func retrieveEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String? = nil
  ) async throws -> String {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation (without sensitive details)
    var metadata = LogMetadata()
    metadata["account"] = account
    metadata["keyID"] = keyID
    metadata["operation"] = "retrieveEncryptedSecret"

    await logger.info(
      "Starting encrypted secret retrieval operation",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    do {
      // Retrieve from keychain
      let encryptedData = try await keychainService.retrieveItem(
        forAccount: account
      )

      // Decrypt the data
      let decryptionOptions = SecurityConfigOptions(
        algorithm: EncryptionAlgorithm.aes256Gcm.rawValue,
        keyIdentifier: keyID
      )
      
      let decryptionConfig = SecurityConfigDTO(options: decryptionOptions)

      let decryptionResult = try await securityProvider.decrypt(
        data: encryptedData,
        with: decryptionConfig
      )

      // Convert to string
      guard let secretString = String(data: decryptionResult.decryptedData, encoding: String.Encoding.utf8) else {
        throw KeychainSecurityError.encodingFailed
      }

      await logger.info(
        "Successfully retrieved and decrypted secret",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )

      return secretString
    } catch let error as KeychainError {
      // Handle keychain-specific errors
      await logger.error(
        "Failed to retrieve encrypted secret: Keychain error",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.keychainError(error.localizedDescription)
    } catch let error as SecurityProtocolError {
      // Handle security provider errors
      await logger.error(
        "Failed to retrieve encrypted secret: Security error",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.securityError(error)
    } catch {
      // Handle unexpected errors
      await logger.error(
        "Failed to retrieve encrypted secret: Unknown error",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw error
    }
  }

  /**
   Deletes an encrypted secret and its associated encryption key.

   - Parameters:
      - account: The account identifier for the secret
      - keyIdentifier: Optional identifier for the encryption key

   - Throws: KeychainSecurityError if operations fail
   */
  public func deleteEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String? = nil,
    deleteKey: Bool = true
  ) async throws {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation
    var metadata = LogMetadata()
    metadata["account"] = account
    metadata["keyID"] = keyID
    metadata["deleteKey"] = String(deleteKey)
    await logger.debug(
      "Deleting encrypted secret",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    // Delete from keychain
    do {
      try await keychainService.deletePassword(for: account)
      await logger.info(
        "Deleted encrypted data from keychain",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
    } catch {
      await logger.error(
        "Failed to delete from keychain: \(error.localizedDescription)",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.keychainError(error.localizedDescription)
    }

    // Delete the key if requested
    if deleteKey {
      let keyManager = await securityProvider.keyManager()
      let keyResult = await keyManager.deleteKey(withIdentifier: keyID)
      if case let .failure(error) = keyResult {
        await logger.error(
          "Failed to delete encryption key: \(error.localizedDescription)",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )
        throw KeychainSecurityError.securityError(error)
      }
      await logger.info(
        "Successfully deleted encryption key",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
    }
  }

  // MARK: - Private Helpers

  /**
   Derives a consistent key identifier from an account name.

   - Parameter account: The account to derive the key identifier from
   - Returns: A key identifier suitable for use with the security provider
   */
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    return "keychain.secret.\(account)"
  }

  /**
   Generates a new AES encryption key.

   - Returns: A secure bytes representation of the key
   - Throws: KeychainSecurityError if key generation fails
   */
  private func generateAESKey() async throws -> SecureBytes {
    // Generate a new secure random key for AES-256 (32 bytes)
    // We need to create a SecurityConfigDTO for AES-256 encryption
    let configOptions = SecurityConfigOptions(
        algorithm: "AES",
        keySize: 256,
        mode: "GCM"
    )
    
    let config = SecurityConfigDTO(options: configOptions)

    let result = try await securityProvider.generateKey(
        with: config
    )

    // Return the key or throw if we didn't get one
    guard let keyData = result.keyID.data(using: String.Encoding.utf8) else {
        throw KeychainSecurityError.keyGenerationFailed
    }

    return SecureBytes(data: keyData)
  }
}
