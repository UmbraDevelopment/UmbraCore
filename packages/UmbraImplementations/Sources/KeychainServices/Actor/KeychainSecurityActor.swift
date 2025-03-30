import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import UmbraErrors

/**
 # KeychainSecurityActor

 An actor that integrates both KeychainServiceProtocol and SecurityProviderProtocol,
 providing a unified interface for secure storage operations that might require
 both services.

 ## Responsibilities

 - Secure storage of sensitive data in the keychain
 - Proper encryption/decryption of data using the security provider
 - Thread-safe operations for all security-related activities
 - Proper error handling and logging

 ## Usage

 ```swift
 // Create the actor
 let securityActor = KeychainSecurityActor(
     keychainService: await KeychainServiceFactory.createService(),
     securityProvider: await SecurityProviderFactory.createSecurityProvider(),
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

  /// The security provider for encryption operations
  private let securityProvider: SecurityProviderProtocol

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
      - securityProvider: The provider for encryption and key management
      - logger: Logger for recording operations
   */
  public init(
    keychainService: KeychainServiceProtocol,
    securityProvider: SecurityProviderProtocol,
    logger: LoggingServiceProtocol
  ) {
    self.keychainService=keychainService
    self.securityProvider=securityProvider
    self.logger=logger
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
    keyIdentifier: String?=nil
  ) async throws {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation (without sensitive details)
    var metadata=LogMetadata()
    metadata["account"]=account
    metadata["keyIdentifier"]=keyID
    await logger.debug(
      "Storing encrypted secret for account",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    // Get the encryption key via the key manager
    let keyManager=await securityProvider.keyManager()
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    let key: SecureBytes

    switch keyResult {
      case let .success(existingKey):
        key=existingKey
        await logger.debug(
          "Retrieved existing encryption key",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )
      case .failure:
        // Generate a new key if one doesn't exist
        await logger.debug(
          "No existing key found, generating new key",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )

        // Generate a new AES-256 key using the crypto service
        key=try await generateAESKey()

        // Store the new key for future use
        let keyStoreResult=await keyManager.storeKey(key, withIdentifier: keyID)
        guard case .success=keyStoreResult else {
          await logger.error(
            "Failed to store encryption key",
            metadata: metadata,
            source: "KeychainSecurityActor"
          )
          throw KeychainSecurityError.keyStorageFailed
        }

        await logger.debug(
          "Stored new encryption key",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )
    }

    // Encrypt the secret
    guard let data=secret.data(using: .utf8) else {
      throw KeychainSecurityError.encodingFailed
    }

    let secureData=SecureBytes(data: data)

    // Create encryption config
    var options: [String: String]=[:]
    options["dataBase64"]=secureData.base64EncodedString()
    let keyBase64=key.base64EncodedString()
    options["keyBase64"]=keyBase64

    let config=SecurityConfigDTO.aesEncryption(
      keySize: 256,
      mode: "GCM",
      additionalOptions: options
    )

    // Perform encryption
    do {
      let encryptionResult=try await securityProvider.encrypt(config: config)

      // Store the encrypted data in the keychain
      if let resultData=encryptionResult.data {
        try await keychainService.storeData(
          resultData.extractUnderlyingData(),
          for: account,
          accessOptions: nil
        )
      } else {
        throw KeychainSecurityError.securityError(
          SecurityProtocolError.invalidInput("Invalid data format")
        )
      }

      await logger.info(
        "Successfully stored encrypted secret",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
    } catch let error as SecurityProtocolError {
      await logger.error(
        "Encryption failed",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.securityError(error)
    } catch {
      await logger.error(
        "Keychain storage failed",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.keychainError(error.localizedDescription)
    }
  }

  /**
   Retrieves and decrypts a secret from the keychain.

   - Parameters:
      - account: The account identifier for the secret
      - keyIdentifier: Optional identifier for the decryption key

   - Returns: The decrypted secret as a string
   - Throws: KeychainSecurityError if operations fail
   */
  public func retrieveEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String?=nil
  ) async throws -> String {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation (without sensitive details)
    var metadata=LogMetadata()
    metadata["account"]=account
    metadata["keyIdentifier"]=keyID
    await logger.debug(
      "Retrieving encrypted secret for account",
      metadata: metadata,
      source: "KeychainSecurityActor"
    )

    // Get the encryption key via the key manager
    let keyManager=await securityProvider.keyManager()
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    guard case .success(_)=keyResult else {
      await logger.error(
        "Encryption key not found for decryption",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.keyNotFound
    }

    // Get the encrypted data from the keychain
    do {
      let password = try await keychainService.retrievePassword(for: account)

      // Create decryption config
      let config = SecurityConfigDTO.aesEncryption(
        keySize: 256,
        mode: "GCM",
        additionalOptions: ["operation": "decrypt"]
      )

      // Set up the encrypted data
      let secureData = SecureBytes(data: Data(password.utf8))

      // Perform decryption
      do {
        let decryptionResult = try await securityProvider.decrypt(config: config)

        // Convert the decrypted data back to a string
        guard
          let secretString=String(
            data: decryptionResult.data?.extractUnderlyingData() ?? Data(),
            encoding: .utf8
          )
        else {
          await logger.error(
            "Failed to decode decrypted data to string",
            metadata: metadata,
            source: "KeychainSecurityActor"
          )
          throw KeychainSecurityError.encodingFailed
        }

        await logger.info(
          "Successfully retrieved and decrypted secret",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )
        return secretString
      } catch let error as SecurityProtocolError {
        await logger.error(
          "Decryption failed",
          metadata: metadata,
          source: "KeychainSecurityActor"
        )
        throw KeychainSecurityError.securityError(error)
      }
    } catch {
      await logger.error(
        "Failed to retrieve encrypted data from keychain: \(error.localizedDescription)",
        metadata: metadata,
        source: "KeychainSecurityActor"
      )
      throw KeychainSecurityError.keychainError(error.localizedDescription)
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
    keyIdentifier: String?=nil,
    deleteKey: Bool=true
  ) async throws {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation
    var metadata=LogMetadata()
    metadata["account"]=account
    metadata["keyIdentifier"]=keyID
    metadata["deleteKey"]=String(deleteKey)
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
      let keyManager=await securityProvider.keyManager()
      let keyResult=await keyManager.deleteKey(withIdentifier: keyID)
      if case let .failure(error)=keyResult {
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
   Derives a key identifier from an account name.

   - Parameter account: The account to derive from
   - Returns: A standardised key identifier
   */
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    "keychain_key_\(account)"
  }

  private func generateAESKey() async throws -> SecureBytes {
    // Generate a new secure random key for AES-256 (32 bytes)
    // We need to create a SecurityConfigDTO for AES-256 encryption
    let config = SecurityConfigDTO.aesEncryption(
        keySize: 256,
        mode: "GCM"
    )
    
    // Use the security provider to generate the key
    let keyResult = try await securityProvider.generateKey(config: config)
    
    if let key = keyResult.data {
        return key
    } else {
        throw KeychainSecurityError.keyGenerationFailed
    }
  }
}
