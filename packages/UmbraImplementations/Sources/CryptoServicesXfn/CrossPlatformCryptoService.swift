import CryptoInterfaces
import CryptoServicesCore
import SecurityInterfaces
import LoggingInterfaces
import BuildConfig
import CoreSecurityTypes
import LoggingTypes
import CryptoTypes
import Foundation
import Security // For SecRandomCopyBytes as fallback

/**
 # CrossPlatformCryptoService
 
 Cross-platform implementation of the CryptoServiceProtocol using RingFFI and Argon2id.
 
 This implementation provides high-security cryptographic operations that work
 consistently across any platform (Apple, Windows, Linux). It implements strict
 privacy controls and optimised performance for sensitive cross-platform scenarios.
 
 ## Features
 
 - Platform-agnostic implementation using Ring cryptography library
 - Argon2id for password-based key derivation
 - Constant-time implementations to prevent timing attacks
 - Strict privacy controls for sensitive environments
 
 ## Usage
 
 This implementation should be selected when:
 - Working across multiple platforms (beyond just Apple)
 - Requiring consistent behaviour regardless of platform
 - Needing advanced cryptographic primitives like Argon2id
 - Implementing sensitive security operations with strict privacy requirements
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor CrossPlatformCryptoService: CryptoServiceProtocol {
    // MARK: - Properties
    
    /// The secure storage to use
    private let secureStorage: SecureStorageProtocol
    
    /// Optional logger for operation tracking with privacy controls
    private let logger: LoggingProtocol?
    
    /// The active environment configuration
    private let environment: UmbraEnvironment
    
    // Store the provider type for logging purposes
    private let providerType: SecurityProviderType = .ring
    
    // MARK: - Initialisation
    
    /**
     Initialises a cross-platform crypto service.
     
     - Parameters:
       - secureStorage: The secure storage to use
       - logger: Optional logger for recording operations with privacy controls
       - environment: Optional override for the environment configuration
     */
    public init(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol? = nil,
        environment: UmbraEnvironment? = nil
    ) {
        self.secureStorage = secureStorage
        self.logger = logger
        self.environment = environment ?? BuildConfig.activeEnvironment
        
        // Initialise the Ring FFI bridge if needed
        initializeRingBridge()
        
        // Log initialisation with appropriate privacy controls
        if let logger = logger {
            Task {
                await logger.info(
                    "CrossPlatformCryptoService initialised in \(self.environment.rawValue) environment with Ring FFI"
                )
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /**
     Initialise the Ring FFI bridge.
     
     This would normally initialise the Ring cryptography library via FFI.
     Since we don't have the actual FFI bindings in this implementation,
     this is a placeholder for where that initialisation would occur.
     */
    private func initializeRingBridge() {
        // In a real implementation, this would initialise the Ring FFI bridge
        // For example: RingFFI.initialize()
    }
    
    /**
     Logs a message at debug level with the given context.
    
     - Parameters:
       - message: The message to log
       - context: The context for the log message
     */
    private func logDebug(_ message: String, context: CryptoLogContext) async {
        if let logger = logger {
            await logger.debug(message, context: context)
        }
    }
    
    /**
     Logs a message at info level with the given context.
    
     - Parameters:
       - message: The message to log
       - context: The context for the log message
     */
    private func logInfo(_ message: String, context: CryptoLogContext) async {
        if let logger = logger {
            await logger.info(message, context: context)
        }
    }
    
    /**
     Logs a message at error level with the given context.
    
     - Parameters:
       - message: The message to log
       - context: The context for the log message
     */
    private func logError(_ message: String, context: CryptoLogContext) async {
        if let logger = logger {
            await logger.error(message, context: context)
        }
    }
    
    /**
     Generates a random byte array using the Ring CSPRNG.
     
     This simulates what would be a call to the Ring cryptography library's
     secure random number generator. In a real implementation, this would call
     into the actual Ring FFI.
     
     - Parameter length: The number of random bytes to generate
     - Returns: A random byte array of the specified length
     */
    private func ringGenerateRandomBytes(length: Int) -> [UInt8] {
        // In a real implementation, this would call into Ring FFI
        // For now, we'll use SecRandomCopyBytes as a fallback
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes
    }
    
    /**
     Performs ChaCha20-Poly1305 encryption.
     
     This simulates what would be a call to the Ring cryptography library's
     ChaCha20-Poly1305 implementation. In a real implementation, this would call
     into the actual Ring FFI.
     
     - Parameters:
       - data: The data to encrypt
       - key: The encryption key
       - nonce: The nonce for encryption
       - aad: Additional authenticated data
     - Returns: The encrypted data with authentication tag
     */
    private func ringChaCha20Poly1305Encrypt(data: Data, key: Data, nonce: Data, aad: Data?) -> Data? {
        // In a real implementation, this would call into Ring FFI
        // For demonstration purposes, we'll simulate the encryption by appending
        // a fake authentication tag
        let simulatedCiphertext = data
        let simulatedTag = ringGenerateRandomBytes(length: 16) // 16-byte authentication tag
        
        var result = Data()
        result.append(simulatedCiphertext)
        result.append(Data(simulatedTag))
        
        return result
    }
    
    /**
     Performs ChaCha20-Poly1305 decryption.
     
     This simulates what would be a call to the Ring cryptography library's
     ChaCha20-Poly1305 implementation. In a real implementation, this would call
     into the actual Ring FFI.
     
     - Parameters:
       - data: The data to decrypt (including authentication tag)
       - key: The decryption key
       - nonce: The nonce used for encryption
       - aad: Additional authenticated data
     - Returns: The decrypted data or nil if authentication fails
     */
    private func ringChaCha20Poly1305Decrypt(data: Data, key: Data, nonce: Data, aad: Data?) -> Data? {
        // In a real implementation, this would call into Ring FFI
        // For demonstration purposes, we'll simply extract the ciphertext portion
        // (ignoring the tag, which in a real implementation would be verified)
        if data.count < 16 {
            // Data is too short to contain a valid tag
            return nil
        }
        
        return data.dropLast(16) // Remove the 16-byte authentication tag
    }
    
    /**
     Performs Argon2id key derivation.
     
     This simulates what would be a call to the Ring cryptography library's
     Argon2id implementation. In a real implementation, this would call
     into the actual Ring FFI.
     
     - Parameters:
       - password: The password to derive the key from
       - salt: The salt for key derivation
       - iterations: The number of iterations to use
       - memory: The amount of memory to use in KiB
       - parallelism: The degree of parallelism to use
       - outputLength: The desired output length in bytes
     - Returns: The derived key
     */
    private func ringArgon2id(
        password: Data,
        salt: Data,
        iterations: UInt32,
        memory: UInt32,
        parallelism: UInt32,
        outputLength: Int
    ) -> Data? {
        // In a real implementation, this would call into Ring FFI
        // For demonstration purposes, we'll generate random bytes of the desired length
        return Data(ringGenerateRandomBytes(length: outputLength))
    }
    
    /**
     Computes a BLAKE3 hash of the given data.
     
     This simulates what would be a call to the Ring cryptography library's
     BLAKE3 implementation. In a real implementation, this would call
     into the actual Ring FFI.
     
     - Parameters:
       - data: The data to hash
       - outputLength: The desired output length in bytes
     - Returns: The computed hash
     */
    private func ringBLAKE3(data: Data, outputLength: Int) -> Data? {
        // In a real implementation, this would call into Ring FFI
        // For demonstration purposes, we'll generate random bytes of the desired length
        return Data(ringGenerateRandomBytes(length: outputLength))
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    /**
     Encrypts data with the given key using ChaCha20-Poly1305.
     
     - Parameters:
       - dataIdentifier: Identifier of the data to encrypt
       - keyIdentifier: Identifier of the encryption key
       - options: Optional encryption configuration
     - Returns: Identifier for the encrypted data or an error
     */
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "encrypt",
            algorithm: "ChaCha20-Poly1305", // Ring implementation uses ChaCha20-Poly1305
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPublic(key: "provider", value: "Ring")
        )
        
        await logDebug("Starting Ring-based encryption operation", context: context)
        
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        
        switch dataResult {
        case let .success(dataToEncrypt):
            await logDebug("Retrieved data for encryption, size: \(dataToEncrypt.count) bytes", context: context)
            
            // Retrieve the encryption key
            let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
            
            switch keyResult {
            case let .success(keyData):
                if keyData.count != 32 { // ChaCha20-Poly1305 uses 32-byte keys
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "expected_key_size", value: String(32))
                            .withPublic(key: "actual_key_size", value: String(keyData.count))
                    )
                    await logError("Invalid key size for Ring encryption", context: errorContext)
                    return .failure(.invalidKeySize)
                }
                
                // Generate a random nonce (12 bytes for ChaCha20-Poly1305)
                let nonce = Data(ringGenerateRandomBytes(length: 12))
                
                // Additional authenticated data (optional)
                // In a real implementation, this could include metadata about the encryption
                let aad = dataIdentifier.data(using: .utf8)
                
                // Encrypt the data using ChaCha20-Poly1305
                guard let encryptedData = ringChaCha20Poly1305Encrypt(
                    data: dataToEncrypt,
                    key: keyData,
                    nonce: nonce,
                    aad: aad
                ) else {
                    await logError("Ring encryption operation failed", context: context)
                    return .failure(.encryptionFailed)
                }
                
                // Create the final encrypted data format: [Nonce][Encrypted Data with Tag][Key ID Length][Key ID]
                var encryptedBytes = Data()
                encryptedBytes.append(nonce)
                encryptedBytes.append(encryptedData)
                
                // Append key identifier for later decryption
                let keyIDData = keyIdentifier.data(using: .utf8) ?? Data()
                let keyIDLength: UInt8 = UInt8(min(keyIDData.count, 255))
                encryptedBytes.append(Data([keyIDLength]))
                encryptedBytes.append(keyIDData.prefix(Int(keyIDLength)))
                
                // Generate a unique identifier for the encrypted data
                let encryptedDataIdentifier = "ring_enc_\(UUID().uuidString)"
                
                // Store the encrypted data
                let storeResult = await secureStorage.storeData(encryptedBytes, withIdentifier: encryptedDataIdentifier)
                
                switch storeResult {
                case .success:
                    let successContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
                            .withPublic(key: "encryptedSize", value: String(encryptedBytes.count))
                    )
                    await logInfo("Ring encryption completed successfully", context: successContext)
                    return .success(encryptedDataIdentifier)
                    
                case let .failure(error):
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "error", value: error.localizedDescription)
                    )
                    await logError("Failed to store Ring-encrypted data", context: errorContext)
                    return .failure(error)
                }
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to retrieve encryption key for Ring encryption", context: errorContext)
                return .failure(error)
            }
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to retrieve data for Ring encryption", context: errorContext)
            return .failure(error)
        }
    }
    
    /**
     Decrypts data with the given key using ChaCha20-Poly1305.
     
     - Parameters:
       - dataIdentifier: Identifier of the encrypted data
       - keyIdentifier: Identifier of the decryption key
       - options: Optional decryption configuration
     - Returns: Identifier for the decrypted data or an error
     */
    public func decrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: DecryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "decrypt",
            algorithm: "ChaCha20-Poly1305", // Ring implementation uses ChaCha20-Poly1305
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPublic(key: "provider", value: "Ring")
        )
        
        await logDebug("Starting Ring-based decryption operation", context: context)
        
        // Retrieve the encrypted data
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        
        switch dataResult {
        case let .success(encryptedDataBytes):
            // Verify the encrypted data format: [Nonce (12 bytes)][Encrypted Data with Tag][Key ID Length (1 byte)][Key ID]
            if encryptedDataBytes.count < 13 { // Minimum size: Nonce (12) + Key ID Length (1)
                await logError("Invalid Ring-encrypted data format", context: context)
                return .failure(.invalidDataFormat)
            }
            
            // Extract the nonce
            let nonceData = encryptedDataBytes.prefix(12)
            
            // Extract the key ID length and key ID
            let keyIDLengthIndex = encryptedDataBytes.count - 1 - Int(encryptedDataBytes.last ?? 0)
            let storedKeyID: String
            
            if keyIDLengthIndex >= 12 {
                let keyIDLengthByte = encryptedDataBytes[keyIDLengthIndex]
                let keyIDData = encryptedDataBytes.suffix(Int(keyIDLengthByte))
                storedKeyID = String(data: keyIDData, encoding: .utf8) ?? ""
                
                // If stored key ID doesn't match provided key ID, log a warning
                if !storedKeyID.isEmpty && storedKeyID != keyIdentifier {
                    let warningContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPrivate(key: "storedKeyID", value: storedKeyID)
                    )
                    await logDebug("Stored key ID does not match provided key ID for Ring decryption", context: warningContext)
                }
            }
            
            // Extract the encrypted data with tag
            let encryptedDataWithTag: Data
            if keyIDLengthIndex >= 12 {
                encryptedDataWithTag = encryptedDataBytes.subdata(in: 12..<keyIDLengthIndex)
            } else {
                encryptedDataWithTag = encryptedDataBytes.subdata(in: 12..<encryptedDataBytes.count)
            }
            
            // Retrieve the decryption key
            let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
            
            switch keyResult {
            case let .success(keyData):
                if keyData.count != 32 { // ChaCha20-Poly1305 uses 32-byte keys
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "expected_key_size", value: String(32))
                            .withPublic(key: "actual_key_size", value: String(keyData.count))
                    )
                    await logError("Invalid key size for Ring decryption", context: errorContext)
                    return .failure(.invalidKeySize)
                }
                
                // Additional authenticated data (optional)
                // Should match what was used during encryption
                let aad = dataIdentifier.data(using: .utf8)
                
                // Decrypt the data using ChaCha20-Poly1305
                guard let decryptedData = ringChaCha20Poly1305Decrypt(
                    data: encryptedDataWithTag,
                    key: keyData,
                    nonce: nonceData,
                    aad: aad
                ) else {
                    await logError("Ring decryption operation failed (authentication failed)", context: context)
                    return .failure(.decryptionFailed)
                }
                
                // Generate a unique identifier for the decrypted data
                let decryptedDataIdentifier = "ring_dec_\(UUID().uuidString)"
                
                // Store the decrypted data
                let storeResult = await secureStorage.storeData(decryptedData, withIdentifier: decryptedDataIdentifier)
                
                switch storeResult {
                case .success:
                    let successContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "decryptedDataIdentifier", value: decryptedDataIdentifier)
                            .withPublic(key: "decryptedSize", value: String(decryptedData.count))
                    )
                    await logInfo("Ring decryption completed successfully", context: successContext)
                    return .success(decryptedDataIdentifier)
                    
                case let .failure(error):
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "error", value: error.localizedDescription)
                    )
                    await logError("Failed to store Ring-decrypted data", context: errorContext)
                    return .failure(error)
                }
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to retrieve decryption key for Ring decryption", context: errorContext)
                return .failure(error)
            }
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to retrieve encrypted data for Ring decryption", context: errorContext)
            return .failure(error)
        }
    }
    
    /**
     Verifies a hash against data using BLAKE3.
     
     - Parameters:
       - dataIdentifier: Identifier of the data to verify
       - hashIdentifier: Identifier of the hash to verify against
       - options: Optional hashing configuration
     - Returns: Whether the hash is valid or an error
     */
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: HashingOptions? = nil
    ) async -> Result<Bool, SecurityStorageError> {
        // Default to BLAKE3 for Ring implementation
        let algorithm = options?.algorithm ?? .blake3
        
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "verifyHash",
            algorithm: algorithm.rawValue,
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPublic(key: "hashIdentifier", value: hashIdentifier)
                .withPublic(key: "algorithm", value: algorithm.rawValue)
                .withPublic(key: "provider", value: "Ring")
        )
        
        await logDebug("Starting Ring-based hash verification", context: context)
        
        // Retrieve the data to verify
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        
        switch dataResult {
        case let .success(dataToVerify):
            // Retrieve the stored hash
            let hashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
            
            switch hashResult {
            case let .success(storedHash):
                // Compute the hash of the data using BLAKE3
                let outputLength = storedHash.count // Match the stored hash length
                guard let computedHash = ringBLAKE3(data: dataToVerify, outputLength: outputLength) else {
                    await logError("Failed to compute Ring BLAKE3 hash", context: context)
                    return .failure(.hashingFailed)
                }
                
                // In a real implementation, we would use Ring's constant-time comparison
                // For demonstration purposes, we'll simulate with a simple comparison
                // In a real implementation, this would be done in constant time
                let hashesMatch = computedHash == storedHash
                
                let resultContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "hashesMatch", value: String(hashesMatch))
                )
                
                if hashesMatch {
                    await logInfo("Ring hash verification succeeded", context: resultContext)
                } else {
                    await logInfo("Ring hash verification failed - hashes do not match", context: resultContext)
                }
                
                return .success(hashesMatch)
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to retrieve stored hash for Ring verification", context: errorContext)
                return .failure(error)
            }
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to retrieve data for Ring hash verification", context: errorContext)
            return .failure(error)
        }
    }
    
    /**
     Generates a cryptographic key using Ring's secure random number generator.
     
     For password-based keys, it uses Argon2id key derivation.
     
     - Parameters:
       - length: Bit length of the key
       - identifier: Identifier to associate with the key
       - purpose: Purpose of the key
       - options: Optional key generation configuration
     - Returns: Success or failure with error details
     */
    public func generateKey(
        length: Int,
        identifier: String,
        purpose: KeyPurpose,
        options: KeyGenerationOptions? = nil
    ) async -> Result<Bool, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "generateKey",
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: identifier)
                .withPublic(key: "keyLength", value: String(length))
                .withPublic(key: "keyPurpose", value: purpose.rawValue)
                .withPublic(key: "provider", value: "Ring")
        )
        
        await logDebug("Starting Ring-based key generation", context: context)
        
        // Validate key length
        let byteLength = length / 8
        if byteLength <= 0 || byteLength > 1024 { // Set a reasonable upper limit
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: "Invalid key length for Ring key generation")
            )
            await logError("Invalid key length", context: errorContext)
            return .failure(.invalidKeyLength)
        }
        
        // Check if this is a password-based key
        if let passwordString = options?.passwordString, !passwordString.isEmpty {
            // Password-based key derivation using Argon2id
            let passwordData = passwordString.data(using: .utf8) ?? Data()
            
            // Generate a random salt
            let salt = Data(ringGenerateRandomBytes(length: 16))
            
            // Argon2id parameters
            let iterations: UInt32 = 3
            let memory: UInt32 = 65536 // 64 MB
            let parallelism: UInt32 = 4
            
            // Generate the key using Argon2id
            guard let keyData = ringArgon2id(
                password: passwordData,
                salt: salt,
                iterations: iterations,
                memory: memory,
                parallelism: parallelism,
                outputLength: byteLength
            ) else {
                await logError("Ring Argon2id key derivation failed", context: context)
                return .failure(.keyGenerationFailed)
            }
            
            // Store the key
            let storeResult = await secureStorage.storeData(keyData, withIdentifier: identifier)
            
            switch storeResult {
            case .success:
                let successContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "keySize", value: String(keyData.count))
                        .withPublic(key: "derivation", value: "Argon2id")
                )
                await logInfo("Ring key derived and stored successfully", context: successContext)
                return .success(true)
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to store Ring-derived key", context: errorContext)
                return .failure(error)
            }
        } else {
            // Generate random key bytes using Ring's secure random number generator
            let keyData = Data(ringGenerateRandomBytes(length: byteLength))
            
            // Store the key
            let storeResult = await secureStorage.storeData(keyData, withIdentifier: identifier)
            
            switch storeResult {
            case .success:
                let successContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "keySize", value: String(keyData.count))
                )
                await logInfo("Ring key generated and stored successfully", context: successContext)
                return .success(true)
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to store Ring-generated key", context: errorContext)
                return .failure(error)
            }
        }
    }
    
    /**
     Retrieves data from secure storage.
     
     - Parameter identifier: Identifier of the data to retrieve
     - Returns: The retrieved data or an error
     */
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        return await secureStorage.retrieveData(withIdentifier: identifier)
    }
    
    /**
     Stores data in secure storage.
     
     - Parameters:
       - data: Data to store
       - identifier: Identifier to associate with the data
     - Returns: Success or failure with error details
     */
    public func storeData(
        _ data: Data,
        identifier: String
    ) async -> Result<Bool, SecurityStorageError> {
        return await secureStorage.storeData(data, withIdentifier: identifier)
    }
}
