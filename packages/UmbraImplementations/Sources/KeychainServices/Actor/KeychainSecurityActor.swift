import Foundation
import KeychainInterfaces
import SecurityCoreInterfaces
import UmbraErrors
import LoggingInterfaces
import LoggingTypes
import SecurityCoreTypes

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
public actor KeychainSecurityActor: Sendable {
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
        let keyId = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
        
        // Log the operation (without sensitive details)
        var metadata = LogMetadata()
        metadata["account"] = .string(account)
        metadata["keyIdentifier"] = .string(keyId)
        await logger.debug("Storing encrypted secret for account", metadata: metadata)
        
        // Get the encryption key
        let keyResult = await securityProvider.retrieveKey(withIdentifier: keyId)
        
        let key: SecureBytes
        
        switch keyResult {
        case .success(let existingKey):
            key = existingKey
            await logger.debug("Retrieved existing encryption key", metadata: metadata)
        case .failure:
            // Generate a new key if one doesn't exist
            await logger.debug("No existing key found, generating new key", metadata: metadata)
            guard case .success(let newKey) = await securityProvider.generateEncryptionKey() else {
                throw KeychainSecurityError.securityError(.keyGenerationFailed(message: "Failed to generate encryption key"))
            }
            
            // Store the new key
            let storeResult = await securityProvider.storeKey(newKey, withIdentifier: keyId)
            if case .failure(let error) = storeResult {
                throw KeychainSecurityError.securityError(error)
            }
            
            key = newKey
        }
        
        // Encrypt the secret
        guard let data = secret.data(using: .utf8) else {
            throw KeychainSecurityError.encodingFailed
        }
        
        let secureData = SecureBytes(data: data)
        
        // Create encryption config
        let config = SecurityConfigDTO(
            operation: .encrypt,
            key: key,
            data: secureData,
            algorithm: "AES",
            mode: "GCM"
        )
        
        // Perform encryption
        do {
            let encryptionResult = try await securityProvider.encrypt(config: config)
            
            // Store the encrypted data in the keychain
            try await keychainService.storeSecureData(
                encryptionResult.processedData,
                for: account
            )
            
            await logger.info("Successfully stored encrypted secret", metadata: metadata)
        } catch let error as SecurityProtocolError {
            await logger.error("Encryption failed", metadata: metadata, error: error)
            throw KeychainSecurityError.securityError(error)
        } catch {
            await logger.error("Keychain storage failed", metadata: metadata, error: error)
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
        keyIdentifier: String? = nil
    ) async throws -> String {
        let keyId = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
        
        // Log the operation (without sensitive details)
        var metadata = LogMetadata()
        metadata["account"] = .string(account)
        metadata["keyIdentifier"] = .string(keyId)
        await logger.debug("Retrieving encrypted secret for account", metadata: metadata)
        
        // Get the encrypted data from the keychain
        let encryptedData: SecureBytes
        do {
            encryptedData = try await keychainService.retrieveSecureData(for: account)
        } catch {
            await logger.error("Failed to retrieve encrypted data from keychain", metadata: metadata, error: error)
            throw KeychainSecurityError.keychainError(error.localizedDescription)
        }
        
        // Get the decryption key
        let keyResult = await securityProvider.retrieveKey(withIdentifier: keyId)
        guard case .success(let key) = keyResult else {
            await logger.error("Decryption key not found", metadata: metadata)
            throw KeychainSecurityError.securityError(.keyRetrievalFailed(message: "Key not found for decryption"))
        }
        
        // Create decryption config
        let config = SecurityConfigDTO(
            operation: .decrypt,
            key: key,
            data: encryptedData,
            algorithm: "AES",
            mode: "GCM"
        )
        
        // Perform decryption
        do {
            let decryptionResult = try await securityProvider.decrypt(config: config)
            
            // Convert the decrypted data back to a string
            guard let secretString = String(data: decryptionResult.processedData.extractUnderlyingData(), encoding: .utf8) else {
                await logger.error("Failed to decode decrypted data to string", metadata: metadata)
                throw KeychainSecurityError.encodingFailed
            }
            
            await logger.info("Successfully retrieved and decrypted secret", metadata: metadata)
            return secretString
        } catch let error as SecurityProtocolError {
            await logger.error("Decryption failed", metadata: metadata, error: error)
            throw KeychainSecurityError.securityError(error)
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
        let keyId = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
        
        // Log the operation
        var metadata = LogMetadata()
        metadata["account"] = .string(account)
        metadata["keyIdentifier"] = .string(keyId)
        metadata["deleteKey"] = .bool(deleteKey)
        await logger.debug("Deleting encrypted secret", metadata: metadata)
        
        // Delete from keychain
        do {
            try await keychainService.deleteSecureData(for: account)
            await logger.info("Deleted encrypted data from keychain", metadata: metadata)
        } catch {
            await logger.error("Failed to delete from keychain", metadata: metadata, error: error)
            throw KeychainSecurityError.keychainError(error.localizedDescription)
        }
        
        // Delete the key if requested
        if deleteKey {
            let keyResult = await securityProvider.deleteKey(withIdentifier: keyId)
            if case .failure(let error) = keyResult {
                await logger.error("Failed to delete encryption key", metadata: metadata, error: error)
                throw KeychainSecurityError.securityError(error)
            }
            await logger.info("Successfully deleted encryption key", metadata: metadata)
        }
    }
    
    // MARK: - Private Helpers
    
    /**
     Derives a key identifier from an account name.
     
     - Parameter account: The account to derive from
     - Returns: A standardised key identifier
     */
    private func deriveKeyIdentifier(forAccount account: String) -> String {
        return "keychain_key_\(account)"
    }
}
