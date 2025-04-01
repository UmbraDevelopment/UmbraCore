/**
 # EnhancedSecureCryptoServiceImpl
 
 A fully secure implementation of CryptoServiceProtocol that follows the Alpha Dot Five
 architecture principles, integrating native actor-based SecureStorage for all
 cryptographic materials.
 
 This implementation ensures all sensitive data is properly stored, retrieved, and
 managed through secure channels with appropriate privacy protections.
 */

import Foundation
import CryptoInterfaces
import CryptoTypes
import SecurityCoreInterfaces
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 A secure implementation of CryptoServiceProtocol using actor-based SecureStorage
 for all cryptographic operations.
 */
public actor EnhancedSecureCryptoServiceImpl: CryptoServiceProtocol {
    /// The wrapped crypto service implementation
    private let wrapped: CryptoServiceProtocol
    
    /// Secure storage specifically for cryptographic materials
    private let secureStorage: SecureCryptoStorage
    
    /// Logger for recording operations with proper privacy controls
    private let logger: any LoggingProtocol
    
    /**
     Initialises a new secure crypto service.
     
     - Parameters:
        - wrapped: The base crypto service implementation
        - secureStorage: Secure storage for cryptographic materials
        - logger: Logger for recording operations
     */
    public init(
        wrapped: CryptoServiceProtocol,
        secureStorage: SecureCryptoStorage,
        logger: any LoggingProtocol
    ) {
        self.wrapped = wrapped
        self.secureStorage = secureStorage
        self.logger = logger
    }
    
    /**
     Encrypts data using the provided key and initialisation vector.
     
     - Parameters:
        - data: Data to encrypt
        - key: Encryption key
        - iv: Initialisation vector
        - cryptoOptions: Optional configuration
     
     - Returns: Encrypted data
     - Throws: CryptoError if encryption fails
     */
    public func encrypt(
        _ data: Data,
        using key: Data,
        iv: Data,
        cryptoOptions: CryptoOptions?
    ) async throws -> Data {
        // For small payloads, first try to get the key from secure storage
        var keyToUse = key
        if key.count < 64 && key.count > 16 {
            // This might be a key identifier rather than the actual key
            do {
                let keyString = String(data: key, encoding: .utf8) ?? ""
                keyToUse = try await secureStorage.retrieveKey(identifier: keyString)
                
                var metadata = PrivacyMetadata()
                metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
                metadata["keyId"] = PrivacyMetadataValue(value: keyString, privacy: .private)
                
                await logger.debug("Retrieved encryption key from secure storage", 
                                 metadata: metadata,
                                 source: "SecureCryptoService")
            } catch {
                // Not a key identifier, use the key directly
                keyToUse = key
            }
        }
        
        // Use the wrapped implementation for encryption
        let encryptedData = try await wrapped.encrypt(
            data,
            using: keyToUse,
            iv: iv,
            cryptoOptions: cryptoOptions
        )
        
        var metadata = PrivacyMetadata()
        metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
        metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
        
        await logger.debug("Successfully encrypted data", 
                         metadata: metadata,
                         source: "SecureCryptoService")
        
        return encryptedData
    }
    
    /**
     Decrypts data using the provided key and initialisation vector.
     
     - Parameters:
        - data: Data to decrypt
        - key: Decryption key
        - iv: Initialisation vector
        - cryptoOptions: Optional configuration
     
     - Returns: Decrypted data
     - Throws: CryptoError if decryption fails
     */
    public func decrypt(
        _ data: Data,
        using key: Data,
        iv: Data,
        cryptoOptions: CryptoOptions?
    ) async throws -> Data {
        // For small payloads, first try to get the key from secure storage
        var keyToUse = key
        if key.count < 64 && key.count > 16 {
            // This might be a key identifier rather than the actual key
            do {
                let keyString = String(data: key, encoding: .utf8) ?? ""
                keyToUse = try await secureStorage.retrieveKey(identifier: keyString)
                
                var metadata = PrivacyMetadata()
                metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
                metadata["keyId"] = PrivacyMetadataValue(value: keyString, privacy: .private)
                
                await logger.debug("Retrieved decryption key from secure storage", 
                                 metadata: metadata,
                                 source: "SecureCryptoService")
            } catch {
                // Not a key identifier, use the key directly
                keyToUse = key
            }
        }
        
        // Use the wrapped implementation for decryption
        let decryptedData = try await wrapped.decrypt(
            data,
            using: keyToUse,
            iv: iv,
            cryptoOptions: cryptoOptions
        )
        
        var metadata = PrivacyMetadata()
        metadata["algorithm"] = PrivacyMetadataValue(value: cryptoOptions?.algorithm.rawValue ?? "default", privacy: .public)
        metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
        
        await logger.debug("Successfully decrypted data", 
                         metadata: metadata,
                         source: "SecureCryptoService")
        
        return decryptedData
    }
    
    /**
     Derives a key from a password, salt, and iterations.
     
     - Parameters:
        - password: Password to derive key from
        - salt: Salt data to use in derivation
        - iterations: Number of iterations
        - derivationOptions: Optional configuration
     
     - Returns: Derived key or its identifier
     - Throws: CryptoError if derivation fails
     */
    public func deriveKey(
        from password: String,
        salt: Data,
        iterations: Int,
        derivationOptions: KeyDerivationOptions?
    ) async throws -> Data {
        // Generate the key using the wrapped implementation
        let derivedKey = try await wrapped.deriveKey(
            from: password,
            salt: salt,
            iterations: iterations,
            derivationOptions: derivationOptions
        )
        
        // Store the key securely without storing the password
        let passwordReference = String(password.hashValue)
        let identifier = try await secureStorage.storeDerivedKey(
            derivedKey,
            fromPasswordReference: passwordReference,
            salt: salt,
            iterations: iterations,
            options: derivationOptions
        )
        
        var metadata = PrivacyMetadata()
        metadata["iterations"] = PrivacyMetadataValue(value: "\(iterations)", privacy: .public)
        metadata["algorithm"] = PrivacyMetadataValue(value: derivationOptions?.function.rawValue ?? "pbkdf2", privacy: .public)
        metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)
        
        await logger.info("Successfully derived and stored key", 
                        metadata: metadata,
                        source: "SecureCryptoService")
        
        // Return the identifier instead of the key
        return identifier.data(using: .utf8) ?? derivedKey
    }
    
    /**
     Generates a cryptographic key of the specified length.
     
     - Parameters:
        - length: Length of the key in bytes
        - keyOptions: Optional configuration
     
     - Returns: Generated key or its identifier
     - Throws: CryptoError if key generation fails
     */
    public func generateKey(
        length: Int,
        keyOptions: KeyGenerationOptions?
    ) async throws -> Data {
        // Generate the key using the wrapped implementation
        let generatedKey = try await wrapped.generateKey(
            length: length,
            keyOptions: keyOptions
        )
        
        // Store the key securely
        let identifier = "generated_key_\(UUID().uuidString)"
        try await secureStorage.storeKey(
            generatedKey,
            identifier: identifier,
            purpose: keyOptions?.purpose ?? .encryption
        )
        
        var metadata = PrivacyMetadata()
        metadata["length"] = PrivacyMetadataValue(value: "\(length)", privacy: .public)
        metadata["purpose"] = PrivacyMetadataValue(value: keyOptions?.purpose.rawValue ?? "encryption", privacy: .public)
        metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)
        
        await logger.info("Successfully generated and stored key", 
                        metadata: metadata,
                        source: "SecureCryptoService")
        
        // Return the identifier instead of the key
        return identifier.data(using: .utf8) ?? generatedKey
    }
    
    /**
     Generates an HMAC for the provided data using the specified key.
     
     - Parameters:
        - data: Data to authenticate
        - key: Key to use for HMAC
        - hmacOptions: Optional configuration
     
     - Returns: Generated HMAC
     - Throws: CryptoError if HMAC generation fails
     */
    public func generateHMAC(
        for data: Data,
        using key: Data,
        hmacOptions: HMACOptions?
    ) async throws -> Data {
        // For small payloads, first try to get the key from secure storage
        var keyToUse = key
        if key.count < 64 && key.count > 16 {
            // This might be a key identifier rather than the actual key
            do {
                let keyString = String(data: key, encoding: .utf8) ?? ""
                keyToUse = try await secureStorage.retrieveKey(identifier: keyString)
                
                var metadata = PrivacyMetadata()
                metadata["algorithm"] = PrivacyMetadataValue(value: hmacOptions?.algorithm.rawValue ?? "sha256", privacy: .public)
                metadata["keyId"] = PrivacyMetadataValue(value: keyString, privacy: .private)
                
                await logger.debug("Retrieved HMAC key from secure storage", 
                                 metadata: metadata,
                                 source: "SecureCryptoService")
            } catch {
                // Not a key identifier, use the key directly
                keyToUse = key
            }
        }
        
        // Generate the HMAC using the wrapped implementation
        let hmac = try await wrapped.generateHMAC(
            for: data,
            using: keyToUse,
            hmacOptions: hmacOptions
        )
        
        // Store the HMAC securely
        let keyIdentifier = String(data: key, encoding: .utf8) ?? "direct_key"
        let hmacIdentifier = try await secureStorage.storeHMAC(
            hmac,
            forDataHash: data.hashValue,
            keyIdentifier: keyIdentifier,
            algorithm: hmacOptions?.algorithm ?? .sha256
        )
        
        var metadata = PrivacyMetadata()
        metadata["algorithm"] = PrivacyMetadataValue(value: hmacOptions?.algorithm.rawValue ?? "sha256", privacy: .public)
        metadata["hmacId"] = PrivacyMetadataValue(value: hmacIdentifier, privacy: .private)
        metadata["dataSize"] = PrivacyMetadataValue(value: "\(data.count)", privacy: .public)
        
        await logger.debug("Successfully generated and stored HMAC", 
                         metadata: metadata,
                         source: "SecureCryptoService")
        
        return hmac
    }
}
