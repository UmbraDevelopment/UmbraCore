import Foundation
import SecurityCoreInterfaces
import LoggingInterfaces
import UmbraErrors

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
    private let defaultKeySuffix = "_umbra_encryption_key"
    
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
        self.keychainService = keychainService
        self.keyManager = keyManager
        self.logger = logger
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
        accessOptions: KeychainAccessOptions? = nil
    ) async throws {
        await logger.debug("Storing encrypted secret for account: \(account)")
        
        // Get or generate a key for this account
        let keyId = keyIdentifierForAccount(account)
        let keyResult = await keyManager.retrieveKey(withIdentifier: keyId)
        
        let key: SecureBytes
        
        switch keyResult {
        case .success(let existingKey):
            key = existingKey
            await logger.debug("Using existing encryption key for account: \(account)")
        case .failure:
            // Generate a new key
            key = try await keyManager.generateKey(ofType: .aes256)
            let storeResult = await keyManager.storeKey(key, withIdentifier: keyId)
            
            if case .failure(let error) = storeResult {
                throw SecurityServiceError.keyManagementError("Failed to store encryption key: \(error)")
            }
            
            await logger.debug("Generated new encryption key for account: \(account)")
        }
        
        // Encrypt the secret
        let secretData = Data(secret.utf8)
        let encryptedData = try encryptData(secretData, withKey: key)
        
        // Store in keychain
        try await keychainService.storeData(
            encryptedData,
            forKey: account,
            accessOptions: accessOptions
        )
        
        await logger.info("Successfully stored encrypted secret for account: \(account)")
    }
    
    /**
     Retrieve and decrypt a secret from the keychain.
     
     - Parameter account: The account identifier
     - Returns: The decrypted secret
     */
    public func retrieveEncryptedSecret(forAccount account: String) async throws -> String {
        await logger.debug("Retrieving encrypted secret for account: \(account)")
        
        // Get the key for this account
        let keyId = keyIdentifierForAccount(account)
        let keyResult = await keyManager.retrieveKey(withIdentifier: keyId)
        
        guard case .success(let key) = keyResult else {
            throw SecurityServiceError.keyManagementError("Encryption key not found for account: \(account)")
        }
        
        // Get encrypted data from keychain
        let encryptedData = try await keychainService.retrieveData(forKey: account)
        
        // Decrypt the data
        let decryptedData = try decryptData(encryptedData, withKey: key)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityServiceError.invalidInputData("Failed to decode decrypted data as UTF-8 string")
        }
        
        await logger.info("Successfully retrieved encrypted secret for account: \(account)")
        return decryptedString
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
        deleteKey: Bool = false,
        keyIdentifier: String? = nil
    ) async throws {
        await logger.debug("Deleting encrypted secret for account: \(account)")
        
        // Delete from keychain
        try await keychainService.deleteItem(forKey: account)
        
        // Delete the encryption key if requested
        if deleteKey {
            let keyId = keyIdentifier ?? keyIdentifierForAccount(account)
            let result = await keyManager.deleteKey(withIdentifier: keyId)
            
            if case .failure(let error) = result {
                await logger.warning("Failed to delete encryption key: \(error)")
            } else {
                await logger.debug("Deleted encryption key for account: \(account)")
            }
        }
        
        await logger.info("Successfully deleted encrypted secret for account: \(account)")
    }
    
    // MARK: - Private helpers
    
    /**
     Generate a key identifier for an account.
     
     - Parameter account: The account identifier
     - Returns: A key identifier for the encryption key
     */
    private func keyIdentifierForAccount(_ account: String) -> String {
        return account + defaultKeySuffix
    }
    
    /**
     Encrypt data with a key.
     
     This is a simplified implementation. In a real implementation,
     this would use a proper encryption algorithm.
     
     - Parameters:
       - data: The data to encrypt
       - key: The encryption key
     - Returns: The encrypted data
     */
    private func encryptData(_ data: Data, withKey key: SecureBytes) throws -> Data {
        // This is a placeholder for actual encryption
        // In a real implementation, this would use AES or another algorithm
        
        // For now, just simulate encryption with XOR (NOT secure!)
        var encryptedBytes = [UInt8](repeating: 0, count: data.count)
        let keyBytes = [UInt8](key.data)
        
        for i in 0..<data.count {
            let keyIndex = i % keyBytes.count
            encryptedBytes[i] = data[i] ^ keyBytes[keyIndex]
        }
        
        return Data(encryptedBytes)
    }
    
    /**
     Decrypt data with a key.
     
     This is a simplified implementation. In a real implementation,
     this would use a proper decryption algorithm.
     
     - Parameters:
       - data: The data to decrypt
       - key: The decryption key
     - Returns: The decrypted data
     */
    private func decryptData(_ data: Data, withKey key: SecureBytes) throws -> Data {
        // Since our placeholder encryption is XOR, decryption is the same operation
        return try encryptData(data, withKey: key)
    }
}
