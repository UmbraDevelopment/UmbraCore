import Foundation
import KeychainInterfaces
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Error types for KeychainSecurityService
 */
public enum SecurityServiceError: Error {
  case keyManagementError(String)
  case invalidInputData(String)
  case operationFailed(String)
  case securityProviderError(String)
}

/**
 # KeychainSecurityImpl

 This implementation provides enhanced keychain operations with encryption
 support using a key management service. It combines normal keychain operations
 with encryption to provide a more secure storage option.

 The implementation follows British spelling conventions for identifiers and documentation.
 */
public actor KeychainSecurityImpl: KeychainSecurityProtocol {
  /// The underlying keychain service
  private let keychainService: KeychainServiceProtocol

  /// The key manager for encryption operations
  private let keyManager: KeyManagementProtocol

  /// Logger for operations
  private let logger: LoggingProtocol

  /**
   Default key identifier suffix for encryption keys
   */
  private let defaultKeySuffix="_umbra_encryption_key"

  /**
   Initialise a new keychain security service.

   - Parameters:
     - keychainService: The underlying keychain service
     - keyManager: The key manager for encryption operations
     - logger: Logger for recording operations
   */
  public init(
    keychainService: KeychainServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingProtocol
  ) {
    self.keychainService=keychainService
    self.keyManager=keyManager
    self.logger=logger
  }

  /**
   Store an encrypted secret in the keychain.

   - Parameters:
     - secret: The secret to store
     - account: The account identifier
     - accessOptions: Options for keychain access
   */
  public func storeEncryptedSecret(
    _ secret: String,
    forAccount account: String,
    accessOptions: KeychainInterfaces.KeychainAccessOptions?=nil
  ) async throws {
    await logger.debug(
      "Storing encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // Get or generate a key for this account
    let keyID=keyIdentifierForAccount(account)
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    let key: [UInt8]

    switch keyResult {
      case let .success(existingKey):
        key=existingKey
        await logger.debug(
          "Using existing encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
      case .failure:
        // Generate a new key
        key=try await generateEncryptionKey()
        let storeResult=await keyManager.storeKey(key, withIdentifier: keyID)

        if case let .failure(error)=storeResult {
          await logger.error(
            "Failed to store encryption key: \(error)",
            metadata: nil,
            source: "KeychainSecurityService"
          )
          throw SecurityServiceError.keyManagementError("Failed to store encryption key: \(error)")
        }

        await logger.debug(
          "Generated new encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
    }

    // Encrypt the secret
    let secretData=Data(secret.utf8)
    let encryptedData=try encryptData(secretData, withKey: key)

    // Store in keychain
    try await keychainService.storeData(
      encryptedData,
      for: account,
      keychainOptions: accessOptionsToKeychainOptions(accessOptions)
    )

    await logger.info(
      "Successfully stored encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )
  }

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
  public func storeEncryptedSecret(
    _ secret: String,
    forAccount account: String,
    keyIdentifier: String?,
    accessOptions: KeychainInterfaces.KeychainAccessOptions?
  ) async throws {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    await logger.debug(
      "Storing encrypted secret for account: \(account) with key ID: \(keyID)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // Get or generate the encryption key
    let key: [UInt8]
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    switch keyResult {
      case let .success(existingKey):
        key=existingKey
        await logger.debug(
          "Using existing encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
      case .failure:
        // Generate a new key
        key=try await generateEncryptionKey()
        let storeResult=await keyManager.storeKey(key, withIdentifier: keyID)

        if case let .failure(error)=storeResult {
          await logger.error(
            "Failed to store encryption key: \(error)",
            metadata: nil,
            source: "KeychainSecurityService"
          )
          throw SecurityServiceError.keyManagementError("Failed to store encryption key: \(error)")
        }

        await logger.debug(
          "Generated new encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
    }

    // Encrypt the secret
    let secretData=Data(secret.utf8)
    let encryptedData=try encryptData(secretData, withKey: key)

    // Store in keychain
    try await keychainService.storeData(
      encryptedData,
      for: account,
      keychainOptions: accessOptionsToKeychainOptions(accessOptions)
    )

    await logger.info(
      "Stored encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )
  }

  /**
   Retrieve and decrypt a secret from the keychain.

   - Parameter account: The account identifier
   - Returns: The decrypted secret
   */
  public func retrieveEncryptedSecret(forAccount account: String) async throws -> String {
    await logger.debug(
      "Retrieving encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // Get the key for this account
    let keyID=keyIdentifierForAccount(account)
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    guard case let .success(key)=keyResult else {
      throw SecurityServiceError
        .keyManagementError("Encryption key not found for account: \(account)")
    }

    // Get encrypted data from keychain
    let encryptedData=try await keychainService.retrieveData(
      for: account,
      keychainOptions: nil
    )

    // Decrypt the data
    let decryptedData=try decryptData(encryptedData, withKey: key)

    guard let decryptedString=String(data: decryptedData, encoding: .utf8) else {
      throw SecurityServiceError.invalidInputData("Failed to decode decrypted data as UTF-8 string")
    }

    await logger.info(
      "Successfully retrieved encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )
    return decryptedString
  }

  /**
   Retrieve and decrypt a secret from the keychain.

   - Parameters:
     - account: The account identifier to retrieve the secret for
     - keyIdentifier: Optional custom key identifier (default: derived from account)
   - Returns: The decrypted secret string
   - Throws: SecurityServiceError if retrieval or decryption fails
   */
  public func retrieveEncryptedSecret(
    forAccount account: String,
    keyIdentifier: String?
  ) async throws -> String {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    await logger.debug(
      "Retrieving encrypted secret for account: \(account) with key ID: \(keyID)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // Get the encryption key
    let key: [UInt8]
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    switch keyResult {
      case let .success(existingKey):
        key=existingKey
      case let .failure(error):
        await logger.error(
          "Failed to retrieve encryption key: \(error)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
        throw SecurityServiceError.keyManagementError("Failed to retrieve encryption key: \(error)")
    }

    // Get the encrypted data from the keychain
    let encryptedData: Data
    do {
      encryptedData=try await keychainService.retrieveData(
        for: account,
        keychainOptions: nil
      )
    } catch {
      await logger.error(
        "Failed to retrieve encrypted data from keychain: \(error)",
        metadata: nil,
        source: "KeychainSecurityService"
      )
      throw SecurityServiceError.operationFailed("Failed to retrieve encrypted data: \(error)")
    }

    // Decrypt the data
    let decryptedData=try decryptData(encryptedData, withKey: key)

    // Convert to string
    guard let secret=String(data: decryptedData, encoding: .utf8) else {
      await logger.error(
        "Failed to decode decrypted data to string",
        metadata: nil,
        source: "KeychainSecurityService"
      )
      throw SecurityServiceError.invalidInputData("Failed to decode decrypted data to string")
    }

    await logger.info(
      "Successfully retrieved and decrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    return secret
  }

  /**
   Update an encrypted secret in the keychain.

   This method replaces an existing secret with a new one, using the same
   encryption key if available. If the secret doesn't exist, it will be created.

   - Parameters:
     - newSecret: The new secret to encrypt and store
     - account: The account identifier
     - accessOptions: Optional keychain access options
   */
  public func updateEncryptedSecret(
    _ newSecret: String,
    forAccount account: String,
    accessOptions: KeychainInterfaces.KeychainAccessOptions?
  ) async throws {
    await logger.debug(
      "Updating encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // First check if we can get the existing key
    let keyID=keyIdentifierForAccount(account)
    let key: [UInt8]
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    switch keyResult {
      case let .success(existingKey):
        key=existingKey
        await logger.debug(
          "Using existing encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
      case .failure:
        // Generate a new key if it doesn't exist
        key=try await generateEncryptionKey()
        let storeResult=await keyManager.storeKey(key, withIdentifier: keyID)

        if case let .failure(error)=storeResult {
          await logger.error(
            "Failed to store encryption key: \(error)",
            metadata: nil,
            source: "KeychainSecurityService"
          )
          throw SecurityServiceError.keyManagementError("Failed to store encryption key: \(error)")
        }

        await logger.debug(
          "Generated new encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
    }

    // Encrypt the new secret
    let secretData=Data(newSecret.utf8)
    let encryptedData=try encryptData(secretData, withKey: key)

    // Store in keychain (will overwrite existing data)
    try await keychainService.storeData(
      encryptedData,
      for: account,
      keychainOptions: accessOptionsToKeychainOptions(accessOptions)
    )

    await logger.info(
      "Updated encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )
  }

  /**
   Update an encrypted secret in the keychain.

   This method replaces an existing secret with a new one, using the same
   encryption key if available. If the secret doesn't exist, it will be created.

   - Parameters:
     - newSecret: The new secret to encrypt and store
     - account: The account identifier
     - keyIdentifier: Optional custom key identifier (default: derived from account)
     - accessOptions: Optional keychain access options
   */
  public func updateEncryptedSecret(
    _ newSecret: String,
    forAccount account: String,
    keyIdentifier: String?,
    accessOptions: KeychainInterfaces.KeychainAccessOptions?
  ) async throws {
    let keyID=keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    await logger.debug(
      "Updating encrypted secret for account: \(account) with key ID: \(keyID)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // First check if we can get the existing key
    let key: [UInt8]
    let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

    switch keyResult {
      case let .success(existingKey):
        key=existingKey
        await logger.debug(
          "Using existing encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
      case .failure:
        // Generate a new key if it doesn't exist
        key=try await generateEncryptionKey()
        let storeResult=await keyManager.storeKey(key, withIdentifier: keyID)

        if case let .failure(error)=storeResult {
          await logger.error(
            "Failed to store encryption key: \(error)",
            metadata: nil,
            source: "KeychainSecurityService"
          )
          throw SecurityServiceError.keyManagementError("Failed to store encryption key: \(error)")
        }

        await logger.debug(
          "Generated new encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
    }

    // Encrypt the new secret
    let secretData=Data(newSecret.utf8)
    let encryptedData=try encryptData(secretData, withKey: key)

    // Store in keychain (will overwrite existing data)
    try await keychainService.storeData(
      encryptedData,
      for: account,
      keychainOptions: accessOptionsToKeychainOptions(accessOptions)
    )

    await logger.info(
      "Updated encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )
  }

  /**
   Delete an encrypted secret from the keychain.

   - Parameters:
     - account: The account identifier
     - deleteKey: Whether to also delete the encryption key
     - keyIdentifier: Custom key identifier (optional)
   */
  public func deleteEncryptedSecret(
    forAccount account: String,
    deleteKey: Bool=false,
    keyIdentifier: String?=nil
  ) async throws {
    await logger.debug(
      "Deleting encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )

    // Delete from keychain
    try await keychainService.deletePassword(
      for: account,
      keychainOptions: nil
    )

    // Delete the encryption key if requested
    if deleteKey {
      let keyID=keyIdentifier ?? keyIdentifierForAccount(account)
      let result=await keyManager.deleteKey(withIdentifier: keyID)

      if case let .failure(error)=result {
        await logger.warning(
          "Failed to delete encryption key: \(error)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
      } else {
        await logger.debug(
          "Deleted encryption key for account: \(account)",
          metadata: nil,
          source: "KeychainSecurityService"
        )
      }
    }

    await logger.info(
      "Successfully deleted encrypted secret for account: \(account)",
      metadata: nil,
      source: "KeychainSecurityService"
    )
  }

  // MARK: - Private helpers

  /**
   Helper to encrypt a string using a key.
   */
  private func encryptString(_ string: String, withKey key: [UInt8]) throws -> Data {
    guard let stringData=string.data(using: .utf8) else {
      throw SecurityServiceError.invalidInputData("Cannot convert string to data")
    }

    // In a real implementation, this would use the key to perform encryption
    // For simplicity, this is using a basic XOR encryption (NOT secure for production)
    var encryptedData=Data(count: stringData.count)
    let keyData=key

    for i in 0..<stringData.count {
      let keyByte=keyData[i % keyData.count]
      let stringByte=stringData[i]
      encryptedData[i]=stringByte ^ keyByte
    }

    return encryptedData
  }

  /**
   Helper to decrypt data to a string using a key.
   */
  private func decryptToString(_ data: Data, withKey key: [UInt8]) throws -> String {
    // In a real implementation, this would use the key to perform decryption
    // For simplicity, this is using a basic XOR decryption (NOT secure for production)
    var decryptedData=Data(count: data.count)
    let keyData=key

    for i in 0..<data.count {
      let keyByte=keyData[i % keyData.count]
      let dataByte=data[i]
      decryptedData[i]=dataByte ^ keyByte
    }

    guard let string=String(data: decryptedData, encoding: .utf8) else {
      throw SecurityServiceError.invalidInputData("Cannot convert decrypted data to string")
    }

    return string
  }

  /**
   Generate a new encryption key.
   */
  private func generateEncryptionKey() async throws -> [UInt8] {
    // In a real implementation, this would use a secure key generation method
    // For simplicity, generating a random key
    var keyData=Data(count: 32) // 256-bit key
    let result=SecRandomCopyBytes(kSecRandomDefault, keyData.count, &keyData)

    if result != errSecSuccess {
      throw SecurityServiceError.operationFailed("Failed to generate secure random bytes")
    }

    return Array(keyData)
  }

  /**
   Derive a key identifier from an account name.
   */
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    "\(account)\(defaultKeySuffix)"
  }

  /**
   Derive a key identifier from an account name.
   */
  private func keyIdentifierForAccount(_ account: String) -> String {
    deriveKeyIdentifier(forAccount: account)
  }

  /**
   Encrypt the given data with a specific key.

   - Parameters:
     - data: The data to encrypt
     - key: The encryption key to use
   - Returns: The encrypted data
   - Throws: SecurityServiceError if encryption fails
   */
  private func encryptData(_ data: Data, withKey key: [UInt8]) throws -> Data {
    let keyData=key
    var encryptedData=Data(count: data.count)

    // In a real implementation, this would use proper AES encryption
    // For testing purposes, using a simple XOR operation (NOT secure for production)
    for i in 0..<data.count {
      let keyByte=keyData[i % keyData.count]
      let dataByte=data[i]
      encryptedData[i]=dataByte ^ keyByte
    }

    return encryptedData
  }

  /**
   Decrypt the given data with a specific key.

   - Parameters:
     - data: The data to decrypt
     - key: The decryption key to use
   - Returns: The decrypted data
   - Throws: SecurityServiceError if decryption fails
   */
  private func decryptData(_ data: Data, withKey key: [UInt8]) throws -> Data {
    // Since our placeholder encryption is XOR, decryption is the same operation
    try encryptData(data, withKey: key)
  }

  /**
   Converts KeychainAccessOptions to KeychainOptions

   This helper function bridges the gap between the legacy KeychainAccessOptions type
   and the newer KeychainOptions type used in the updated protocol.

   - Parameter options: The legacy KeychainAccessOptions to convert
   - Returns: Equivalent KeychainOptions or nil if input is nil
   */
  private func accessOptionsToKeychainOptions(
    _ options: KeychainInterfaces
      .KeychainAccessOptions?
  ) -> KeychainInterfaces.KeychainOptions? {
    guard let options else {
      return nil
    }

    // Map access options to the new KeychainOptions structure
    // Default to the most common access level if nothing specific matches
    var accessLevel: KeychainInterfaces.KeychainOptions.AccessLevel = .whenUnlockedThisDeviceOnly
    let authenticationType: KeychainInterfaces.KeychainOptions.AuthenticationType = .none
    let synchronisable = !options.contains(.thisDeviceOnly)

    // Map access control options based on the actual available options
    if options.contains(.whenUnlocked) && !options.contains(.thisDeviceOnly) {
      accessLevel = .whenUnlocked
    } else if options.contains(.whenUnlocked) && options.contains(.thisDeviceOnly) {
      accessLevel = .whenUnlockedThisDeviceOnly
    } else if options.contains(.whenPasscodeSetThisDeviceOnly) {
      accessLevel = .whenPasscodeSetThisDeviceOnly
    } else if options.contains(.accessibleWhenUnlockedThisDeviceOnly) {
      accessLevel = .whenUnlockedThisDeviceOnly
    }

    return KeychainInterfaces.KeychainOptions(
      accessLevel: accessLevel,
      authenticationType: authenticationType,
      synchronisable: synchronisable
    )
  }
}
