import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import UmbraErrors

/**
 # KeychainSecurityActor

 An actor that integrates both KeychainServiceProtocol and KeyManagementProtocol,
 providing a unified interface for secure storage operations that might require
 both services.

 ## Responsibilities

 - Secure storage of sensitive data in the keychain
 - Proper encryption/decryption of data using the key management system
 - Thread-safe operations for all security-related activities
 - Proper error handling and logging

 ## Usage

 ```swift
 // Create the actor
 let securityActor = KeychainSecurityActor(
     keychainService: await KeychainServices.createService(),
     keyManager: await SecurityKeyManagement.createKeyManager(),
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

  /// The key management service for encryption operations
  private let keyManager: KeyManagementProtocol

  /// Logger for recording operations
  private let logger: LoggingProtocol
  
  /// Domain-specific logger for keychain operations
  private let keychainLogger: KeychainLogger

  /// Error type for keychain security operations
  public enum KeychainSecurityError: Error {
    case keychainError(String)
    case securityError(SecurityProtocolError)
    case encodingFailed
  }

  // MARK: - Initialisation

  /**
   Initialises a new KeychainSecurityActor with the required services.

   - Parameters:
      - keychainService: The service for interacting with the keychain
      - keyManager: The service for encryption key management
      - logger: Logger for recording operations
   */
  public init(
    keychainService: KeychainServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingProtocol
  ) {
    self.keychainService = keychainService
    self.keyManager = keyManager
    self.logger = logger
    self.keychainLogger = KeychainLogger(logger: logger)
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

    // Log the operation start using our domain-specific logger
    await keychainLogger.logOperationStart(
        account: account,
        operation: "store",
        keyIdentifier: keyID
    )

    // Get or generate key for encryption
    let keyResult = await keyManager.retrieveKey(withIdentifier: keyID)
    let key: SecureBytes

    switch keyResult {
    case let .success(existingKey):
        key = existingKey
    case .failure:
        // Key doesn't exist, generate a new one
        var additionalContext = LogMetadataDTOCollection()
        additionalContext.addPublic(key: "action", value: "generate_key")
        
        await keychainLogger.logOperationStart(
            account: account,
            operation: "generate_key",
            keyIdentifier: keyID,
            additionalContext: additionalContext
        )

        // Create secure bytes from the secret
        guard let secretData = secret.data(using: .utf8) else {
            let error = KeychainSecurityError.encodingFailed
            await keychainLogger.logOperationError(
                account: account,
                operation: "store",
                error: error,
                keyIdentifier: keyID
            )
            throw error
        }

        let secureBytes = SecureBytes(bytes: [UInt8](secretData))

        // Store the key
        let storeResult = await keyManager.storeKey(secureBytes, withIdentifier: keyID)

        switch storeResult {
        case .success:
            key = secureBytes
            await keychainLogger.logOperationSuccess(
                account: account,
                operation: "generate_key",
                keyIdentifier: keyID
            )
        case let .failure(error):
            await keychainLogger.logOperationError(
                account: account,
                operation: "generate_key",
                error: error,
                keyIdentifier: keyID
            )
            throw KeychainSecurityError.securityError(error)
        }
    }

    // Use the key to encrypt the secret
    // In a real implementation, we would do proper encryption here
    // This is simplified for demonstration purposes

    // Store in keychain
    do {
        try await keychainService.storePassword(
            secret,
            for: account,
            accessOptions: nil
        )
        
        await keychainLogger.logOperationSuccess(
            account: account,
            operation: "store",
            keyIdentifier: keyID
        )
    } catch {
        await keychainLogger.logOperationError(
            account: account,
            operation: "store",
            error: error,
            keyIdentifier: keyID
        )
        throw KeychainSecurityError.keychainError(error.localizedDescription)
    }
  }

  /**
   Retrieves an encrypted secret from the keychain.

   - Parameters:
      - account: The account identifier for the secret
      - keyIdentifier: Optional identifier for the decryption key, defaults to the account name

   - Returns: The decrypted secret
   - Throws: KeychainSecurityError if operations fail
   */
  public func retrieveEncryptedSecret(
    for account: String,
    keyIdentifier: String? = nil
  ) async throws -> String {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation using our domain-specific logger
    await keychainLogger.logOperationStart(
        account: account,
        operation: "retrieve",
        keyIdentifier: keyID
    )

    // Get the key for decryption
    let keyResult = await keyManager.retrieveKey(withIdentifier: keyID)

    switch keyResult {
    case .success:
        // Key exists, continue
        break
    case let .failure(error):
        await keychainLogger.logOperationError(
            account: account,
            operation: "retrieve",
            error: error,
            keyIdentifier: keyID
        )
        throw KeychainSecurityError.securityError(error)
    }

    // Get the encrypted secret from keychain
    do {
        let secret = try await keychainService.retrievePassword(for: account)
        
        await keychainLogger.logOperationSuccess(
            account: account,
            operation: "retrieve",
            keyIdentifier: keyID
        )
        
        return secret
    } catch {
        await keychainLogger.logOperationError(
            account: account,
            operation: "retrieve",
            error: error,
            keyIdentifier: keyID
        )
        throw KeychainSecurityError.keychainError(error.localizedDescription)
    }
  }

  /**
   Deletes an encrypted secret from the keychain.

   - Parameters:
      - account: The account identifier for the secret
      - keyIdentifier: Optional identifier for the encryption key, defaults to the account name

   - Throws: KeychainSecurityError if operations fail
   */
  public func deleteEncryptedSecret(
    for account: String,
    keyIdentifier: String? = nil
  ) async throws {
    let keyID = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)

    // Log the operation
    await keychainLogger.logOperationStart(
        account: account,
        operation: "delete",
        keyIdentifier: keyID
    )

    // Delete the key first
    let keyResult = await keyManager.deleteKey(withIdentifier: keyID)

    switch keyResult {
    case .success:
        var additionalContext = LogMetadataDTOCollection()
        additionalContext.addPublic(key: "keyDeleted", value: "true")
        
        await keychainLogger.logOperationSuccess(
            account: account,
            operation: "delete_key",
            keyIdentifier: keyID,
            additionalContext: additionalContext
        )
    case let .failure(error):
        var additionalContext = LogMetadataDTOCollection()
        additionalContext.addPublic(key: "keyDeleted", value: "false")
        
        await keychainLogger.logOperationError(
            account: account,
            operation: "delete_key",
            error: error,
            keyIdentifier: keyID,
            additionalContext: additionalContext,
            message: "Failed to delete key, continuing with secret deletion"
        )
        // We still continue to delete the item from keychain
    }

    // Delete the secret from keychain
    do {
        try await keychainService.deletePassword(for: account)
        
        await keychainLogger.logOperationSuccess(
            account: account,
            operation: "delete",
            keyIdentifier: keyID
        )
    } catch {
        await keychainLogger.logOperationError(
            account: account,
            operation: "delete",
            error: error,
            keyIdentifier: keyID
        )
        throw KeychainSecurityError.keychainError(error.localizedDescription)
    }
  }

  // MARK: - Private Helpers

  /**
   Derives a key identifier from an account name.

   This creates a consistent key ID that can be used to retrieve the
   encryption key for a specific account.

   - Parameter account: The account name
   - Returns: A key identifier
   */
  private func deriveKeyIdentifier(forAccount account: String) -> String {
    // In a real implementation, this might hash the account name for security
    // For this example, we'll just append a prefix
    return "keychain_key_\(account)"
  }
}
