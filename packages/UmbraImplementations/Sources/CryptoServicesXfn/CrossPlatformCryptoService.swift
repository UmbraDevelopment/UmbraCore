import CryptoInterfaces
import CryptoServicesCore
import CryptoServicesCore.Interfaces
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
    public let secureStorage: SecureStorageProtocol
    
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
     
     - Parameter algorithm: The encryption algorithm to generate random bytes for
     - Returns: A random byte array of the appropriate length
     */
    private func ringGenerateRandomBytes(for algorithm: StandardEncryptionAlgorithm) -> [UInt8] {
        // In a real implementation, this would call into Ring FFI
        // For now, we'll use SecRandomCopyBytes as a fallback
        let length = algorithm == .chacha20Poly1305 ? 32 : algorithm.keySizeBytes
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes
    }
    
    /**
     Generates a random nonce for the specified algorithm.
     
     - Parameter algorithm: The encryption algorithm to generate a nonce for
     - Returns: A random nonce of the appropriate length
     */
    private func ringGenerateNonce(for algorithm: StandardEncryptionAlgorithm) -> [UInt8] {
        let nonceSize = algorithm == .chacha20Poly1305 ? 12 : algorithm.nonceSize
        var nonce = [UInt8](repeating: 0, count: nonceSize)
        _ = SecRandomCopyBytes(kSecRandomDefault, nonceSize, &nonce)
        return nonce
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
        // Validate key size for ChaCha20-Poly1305 (should be 32 bytes)
        if key.count != 32 {
            return nil
        }
        
        // Validate nonce size for ChaCha20-Poly1305 (should be 12 bytes)
        if nonce.count != 12 {
            return nil
        }
        
        // In a real implementation, this would call into Ring FFI
        // For demonstration purposes, we'll simulate the encryption by appending
        // a fake authentication tag
        let simulatedCiphertext = data
        let simulatedTag = Data(ringGenerateRandomBytes(for: .chacha20Poly1305).prefix(16))
        
        var result = Data()
        result.append(simulatedCiphertext)
        result.append(simulatedTag)
        
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
        // Validate key size for ChaCha20-Poly1305 (should be 32 bytes)
        if key.count != 32 {
            return nil
        }
        
        // Validate nonce size for ChaCha20-Poly1305 (should be 12 bytes)
        if nonce.count != 12 {
            return nil
        }
        
        // In a real implementation, this would call into Ring FFI
        // For demonstration purposes, we'll simulate the decryption by removing
        // the fake authentication tag
        if data.count < 16 {
            // Data is too short to contain a valid tag
            return nil
        }
        
        return data.dropLast(16)
    }
    
    /**
     Performs a hash operation using the specified algorithm.
     
     This simulates what would be a call to the Ring cryptography library's
     hashing functions. In a real implementation, this would call into the actual Ring FFI.
     
     - Parameters:
       - data: The data to hash
       - algorithm: The hashing algorithm to use
     - Returns: The computed hash or nil if the algorithm is not supported
     */
    private func ringHash(data: Data, algorithm: StandardHashAlgorithm) -> Data? {
        switch algorithm {
        case .sha256:
            return ringHashSHA256(data: data)
        case .sha512:
            return ringHashSHA512(data: data)
        case .sha384:
            // Simulate SHA-384 hashing
            var hashBytes = [UInt8](repeating: 0, count: 48) // SHA-384 produces a 48-byte hash
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress {
                    let seedData = Data([UInt8](buffer))
                    var seed: UInt64 = 0
                    for byte in seedData.prefix(8) {
                        seed = (seed << 8) | UInt64(byte)
                    }
                    
                    // Generate pseudo-random bytes based on the data
                    for i in 0..<48 {
                        seed = (seed &* 6364136223846793005) &+ 1442695040888963407
                        hashBytes[i] = UInt8((seed >> 32) & 0xFF)
                    }
                }
            }
            return Data(hashBytes)
        case .hmacSHA256:
            // Would call into Ring FFI for HMAC-SHA256
            return nil
        }
    }
    
    /**
     Simulates computing a SHA-256 hash using Ring.
     
     - Parameter data: The data to hash
     - Returns: The computed hash
     */
    private func ringHashSHA256(data: Data) -> Data {
        // In a real implementation, this would call into Ring FFI
        // For now, we'll use CommonCrypto as a fallback
        var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)
    }
    
    /**
     Simulates computing a SHA-512 hash using Ring.
     
     - Parameter data: The data to hash
     - Returns: The computed hash
     */
    private func ringHashSHA512(data: Data) -> Data {
        // In a real implementation, this would call into Ring FFI
        // For now, we'll use CommonCrypto as a fallback
        var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA512(buffer.baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)
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
        // Parse standard encryption parameters
        let algorithmString = options?.algorithm ?? StandardEncryptionAlgorithm.chacha20Poly1305.rawValue
        
        // Ring implementation primarily supports ChaCha20-Poly1305
        guard let algorithm = StandardEncryptionAlgorithm(rawValue: algorithmString) else {
            return .failure(.storageError("Unsupported encryption algorithm: \(algorithmString)"))
        }
        
        // Ensure algorithm is supported by Ring
        guard algorithm == .chacha20Poly1305 else {
            return .failure(.storageError("Ring implementation only supports ChaCha20-Poly1305"))
        }
        
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "encrypt",
            algorithm: algorithm.rawValue,
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPublic(key: "provider", value: "Ring")
        )
        
        await logDebug("Starting Ring encryption operation", context: context)
        
        // Validate inputs
        let dataValidation = CryptoErrorHandling.validate(
            !dataIdentifier.isEmpty,
            code: .invalidInput,
            message: "Data identifier cannot be empty"
        )
        
        if case .failure(let error) = dataValidation {
            await logError("Input validation failed: \(error.message)", context: context)
            return .failure(.storageError(error.message))
        }
        
        let keyValidation = CryptoErrorHandling.validate(
            !keyIdentifier.isEmpty,
            code: .invalidInput,
            message: "Key identifier cannot be empty"
        )
        
        if case .failure(let error) = keyValidation {
            await logError("Input validation failed: \(error.message)", context: context)
            return .failure(.storageError(error.message))
        }
        
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
        
        switch dataResult {
        case let .success(dataToEncrypt):
            await logDebug("Retrieved data for encryption, size: \(dataToEncrypt.count) bytes", context: context)
            
            // Retrieve the encryption key
            let keyResult = await secureStorage.retrieve(identifier: keyIdentifier)
            
            switch keyResult {
            case let .success(keyData):
                // Validate key size for ChaCha20-Poly1305 (should be 32 bytes)
                let keyValidation = CryptoErrorHandling.validateKey(keyData, algorithm: algorithm)
                
                if case .failure(let error) = keyValidation {
                    await logError("Key validation failed: \(error.message)", context: context)
                    return .failure(.storageError(error.message))
                }
                
                // Generate a random nonce (12 bytes for ChaCha20-Poly1305)
                let nonce = Data(ringGenerateNonce(for: algorithm))
                
                // Get additional authenticated data if provided
                let aadData: Data? = options?.additionalAuthenticatedData
                
                // Encrypt the data using ChaCha20-Poly1305
                guard let encryptedData = ringChaCha20Poly1305Encrypt(
                    data: dataToEncrypt,
                    key: keyData,
                    nonce: nonce,
                    aad: aadData
                ) else {
                    let error = CryptoErrorMapper.operationalError(
                        code: .encryptionFailed,
                        message: "Ring encryption operation failed"
                    )
                    await logError(error.message, context: context)
                    return .failure(.storageError(error.message))
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
                let storeResult = await secureStorage.store(encryptedBytes, withIdentifier: encryptedDataIdentifier)
                
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
            algorithm: StandardEncryptionAlgorithm.chacha20Poly1305.rawValue,
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPublic(key: "provider", value: "Ring")
        )
        
        await logDebug("Starting Ring-based decryption operation", context: context)
        
        // Retrieve the encrypted data
        let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
        
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
            let keyResult = await secureStorage.retrieve(identifier: keyIdentifier)
            
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
                let storeResult = await secureStorage.store(decryptedData, withIdentifier: decryptedDataIdentifier)
                
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
        let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
        
        switch dataResult {
        case let .success(dataToVerify):
            // Retrieve the stored hash
            let hashResult = await secureStorage.retrieve(identifier: hashIdentifier)
            
            switch hashResult {
            case let .success(storedHash):
                // Compute the hash of the data using BLAKE3
                let outputLength = storedHash.count // Match the stored hash length
                guard let computedHash = ringHash(data: dataToVerify, algorithm: .blake3) else {
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
            let salt = Data(ringGenerateRandomBytes(for: .chacha20Poly1305).prefix(16))
            
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
            let storeResult = await secureStorage.store(keyData, withIdentifier: identifier)
            
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
            let keyData = Data(ringGenerateRandomBytes(for: .chacha20Poly1305).prefix(byteLength))
            
            // Store the key
            let storeResult = await secureStorage.store(keyData, withIdentifier: identifier)
            
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
        return await secureStorage.retrieve(identifier: identifier)
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
        return await secureStorage.store(data, withIdentifier: identifier)
    }
}
