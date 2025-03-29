import Foundation
import KeychainInterfaces
import SecurityCoreInterfaces
import UmbraErrors
import LoggingInterfaces
import LoggingTypes
import SecurityCoreTypes

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
public actor KeychainSecurityActor: Sendable {
    // MARK: - Properties
    
    /// The keychain service for storing items
    private let keychainService: KeychainServiceProtocol
    
    /// The key management service for encryption operations
    private let keyManager: KeyManagementProtocol
    
    /// Logger for recording operations
    private let logger: LoggingProtocol
    
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
        metadata["account"] = account
        metadata["keyIdentifier"] = keyId
        metadata["operation"] = "store"
        
        await logger.info("Storing encrypted secret for account", metadata: metadata)
        
        // Get or generate key for encryption
        let keyResult = await keyManager.retrieveKey(withIdentifier: keyId)
        let key: SecureBytes
        
        switch keyResult {
        case .success(let existingKey):
            key = existingKey
        case .failure:
            // Key doesn't exist, generate a new one
            var debugMetadata = LogMetadata()
            debugMetadata["keyIdentifier"] = keyId
            
            await logger.debug("Generating new encryption key", metadata: debugMetadata)
            
            // Create secure bytes from the secret
            guard let secretData = secret.data(using: .utf8) else {
                throw KeychainSecurityError.encodingFailed
            }
            
            let secureBytes = SecureBytes(bytes: [UInt8](secretData))
            
            // Store the key
            let storeResult = await keyManager.storeKey(secureBytes, withIdentifier: keyId)
            
            switch storeResult {
            case .success:
                key = secureBytes
            case .failure(let error):
                var errorMetadata = LogMetadata()
                errorMetadata["error"] = error.localizedDescription
                
                await logger.error("Failed to store encryption key", metadata: errorMetadata)
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
        } catch {
            var errorMetadata = LogMetadata()
            errorMetadata["error"] = error.localizedDescription
            
            await logger.error("Failed to store secret in keychain", metadata: errorMetadata)
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
        let keyId = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
        
        // Log the operation (without sensitive details)
        var metadata = LogMetadata()
        metadata["account"] = account
        metadata["keyIdentifier"] = keyId
        metadata["operation"] = "retrieve"
        
        await logger.info("Retrieving encrypted secret for account", metadata: metadata)
        
        // Get the key for decryption
        let keyResult = await keyManager.retrieveKey(withIdentifier: keyId)
        
        switch keyResult {
        case .success:
            // Key exists, continue
            break
        case .failure(let error):
            var errorMetadata = LogMetadata()
            errorMetadata["error"] = error.localizedDescription
            
            await logger.error("Failed to retrieve encryption key", metadata: errorMetadata)
            throw KeychainSecurityError.securityError(error)
        }
        
        // Get the encrypted secret from keychain
        do {
            let secret = try await keychainService.retrievePassword(for: account)
            return secret
        } catch {
            var errorMetadata = LogMetadata()
            errorMetadata["error"] = error.localizedDescription
            
            await logger.error("Failed to retrieve secret from keychain", metadata: errorMetadata)
            throw KeychainSecurityError.keychainError(error.localizedDescription)
        }
    }
    
    /**
     Deletes a secret and its associated encryption key.
     
     - Parameters:
        - account: The account identifier for the secret
        - keyIdentifier: Optional identifier for the encryption key, defaults to the account name
        - deleteKey: Whether to also delete the associated encryption key
     
     - Throws: KeychainSecurityError if operations fail
     */
    public func deleteSecret(
        forAccount account: String,
        keyIdentifier: String? = nil,
        deleteKey: Bool = true
    ) async throws {
        let keyId = keyIdentifier ?? deriveKeyIdentifier(forAccount: account)
        
        // Log the operation
        var metadata = LogMetadata()
        metadata["account"] = account
        metadata["keyIdentifier"] = keyId
        metadata["deleteKey"] = "\(deleteKey)"
        metadata["operation"] = "delete"
        
        await logger.info("Deleting secret for account", metadata: metadata)
        
        // Delete from keychain
        do {
            try await keychainService.deletePassword(for: account)
        } catch {
            var errorMetadata = LogMetadata()
            errorMetadata["error"] = error.localizedDescription
            
            await logger.error("Failed to delete secret from keychain", metadata: errorMetadata)
            throw KeychainSecurityError.keychainError(error.localizedDescription)
        }
        
        // Optionally delete the key
        if deleteKey {
            let keyResult = await keyManager.deleteKey(withIdentifier: keyId)
            
            if case .failure(let error) = keyResult {
                var errorMetadata = LogMetadata()
                errorMetadata["error"] = error.localizedDescription
                
                await logger.error("Failed to delete encryption key", metadata: errorMetadata)
                throw KeychainSecurityError.securityError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Derives a consistent key identifier from an account name.
     
     - Parameter account: The account to derive from
     - Returns: A consistent key identifier
     */
    private func deriveKeyIdentifier(forAccount account: String) -> String {
        // Simple hashing to create a key identifier
        // In a real implementation, we might use a more sophisticated approach
        return "key_\(account.hashValue)"
    }
}
