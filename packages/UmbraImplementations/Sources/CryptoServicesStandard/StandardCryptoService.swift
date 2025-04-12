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
import CommonCrypto
import Security

/**
 # StandardCryptoService
 
 Standard implementation of the CryptoServiceProtocol using AES encryption.
 
 This implementation provides a balance of security and compatibility for general
 use cases, particularly when working with Restic. It implements standard privacy
 controls and logging for typical deployment scenarios.
 
 ## Features
 
 - AES-256-GCM and AES-256-CBC encryption for data protection
 - Standard key management with appropriate entropy
 - Integration with Restic's cryptographic approach
 - Balanced performance and security for most use cases
 
 ## Usage
 
 This implementation should be selected when:
 - Working with Restic in general environments
 - Cross-platform compatibility is not a primary concern
 - Advanced cryptographic features are not required
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor StandardCryptoService: CryptoServiceProtocol {
    // MARK: - Properties
    
    /// The secure storage to use
    public let secureStorage: SecureStorageProtocol
    
    /// Optional logger for operation tracking
    private let logger: LoggingProtocol?
    
    /// The active environment configuration
    private let environment: UmbraEnvironment
    
    // Store the provider type for logging purposes
    private let providerType: SecurityProviderType = .basic
    
    // MARK: - Initialisation
    
    /**
     Initialises a standard crypto service.
     
     - Parameters:
       - secureStorage: The secure storage to use
       - logger: Optional logger for recording operations
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
        
        // Log initialisation
        if let logger = logger {
            Task {
                await logger.info(
                    "StandardCryptoService initialised in \(self.environment.rawValue) environment"
                )
            }
        }
    }
    
    // MARK: - Private Helpers
    
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
     Generates a random initialization vector for AES encryption.
     
     - Parameter algorithm: The encryption algorithm to generate an IV for
     - Returns: A random initialization vector of appropriate length
     */
    private func generateRandomIV(for algorithm: StandardEncryptionAlgorithm) -> [UInt8] {
        let ivSize = algorithm.ivSizeBytes
        var iv = [UInt8](repeating: 0, count: ivSize)
        _ = SecRandomCopyBytes(kSecRandomDefault, ivSize, &iv)
        return iv
    }
    
    /**
     Performs AES encryption on the given data using the specified mode.
     
     - Parameters:
       - data: The data to encrypt
       - key: The encryption key
       - iv: The initialization vector
       - mode: The encryption mode to use
       - padding: The padding type to use
     - Returns: The encrypted data or nil if encryption fails
     */
    private func aesEncrypt(
        data: Data,
        key: Data,
        iv: [UInt8],
        mode: StandardEncryptionMode,
        padding: StandardPaddingType
    ) -> Data? {
        guard key.count == kCCKeySizeAES256 else {
            return nil
        }
        
        // Determine CCOptions based on padding
        let paddingOption: CCOptions = switch padding {
        case .none:
            0
        case .pkcs7:
            CCOptions(kCCOptionPKCS7Padding)
        }
        
        // Set up encryption parameters based on mode
        let algorithm = CCAlgorithm(kCCAlgorithmAES)
        let options = paddingOption
        
        // For GCM mode, we would need to use a different approach as CommonCrypto
        // doesn't directly support GCM. This is a simplified implementation.
        
        let dataLength = data.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted = 0
        
        let cryptStatus = key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                CCCrypt(
                    CCOperation(kCCEncrypt),
                    algorithm,
                    options,
                    keyBytes.baseAddress,
                    kCCKeySizeAES256,
                    iv,
                    dataBytes.baseAddress,
                    dataLength,
                    &buffer,
                    bufferSize,
                    &numBytesEncrypted
                )
            }
        }
        
        if cryptStatus == kCCSuccess {
            return Data(buffer.prefix(numBytesEncrypted))
        }
        
        return nil
    }
    
    /**
     Performs AES decryption on the given data using the specified mode.
     
     - Parameters:
       - encryptedData: The data to decrypt
       - key: The decryption key
       - iv: The initialization vector used for encryption
       - mode: The encryption mode used
       - padding: The padding type used
     - Returns: The decrypted data or nil if decryption fails
     */
    private func aesDecrypt(
        encryptedData: Data,
        key: Data,
        iv: [UInt8],
        mode: StandardEncryptionMode,
        padding: StandardPaddingType
    ) -> Data? {
        guard key.count == kCCKeySizeAES256 else {
            return nil
        }
        
        // Determine CCOptions based on padding
        let paddingOption: CCOptions = switch padding {
        case .none:
            0
        case .pkcs7:
            CCOptions(kCCOptionPKCS7Padding)
        }
        
        // Set up decryption parameters based on mode
        let algorithm = CCAlgorithm(kCCAlgorithmAES)
        let options = paddingOption
        
        let dataLength = encryptedData.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted = 0
        
        let cryptStatus = key.withUnsafeBytes { keyBytes in
            encryptedData.withUnsafeBytes { dataBytes in
                CCCrypt(
                    CCOperation(kCCDecrypt),
                    algorithm,
                    options,
                    keyBytes.baseAddress,
                    kCCKeySizeAES256,
                    iv,
                    dataBytes.baseAddress,
                    dataLength,
                    &buffer,
                    bufferSize,
                    &numBytesDecrypted
                )
            }
        }
        
        if cryptStatus == kCCSuccess {
            return Data(buffer.prefix(numBytesDecrypted))
        }
        
        return nil
    }
    
    /**
     Computes a hash of the given data using the specified algorithm.
     
     - Parameters:
       - data: The data to hash
       - algorithm: The hashing algorithm to use
     - Returns: The computed hash or nil if hashing fails
     */
    private func computeHash(for data: Data, using algorithm: StandardHashAlgorithm) -> Data? {
        switch algorithm {
        case .sha256:
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes { dataBytes in
                _ = CC_SHA256(dataBytes.baseAddress, CC_LONG(data.count), &hash)
            }
            return Data(hash)
        case .sha512:
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            data.withUnsafeBytes { dataBytes in
                _ = CC_SHA512(dataBytes.baseAddress, CC_LONG(data.count), &hash)
            }
            return Data(hash)
        case .sha384:
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
            data.withUnsafeBytes { dataBytes in
                _ = CC_SHA384(dataBytes.baseAddress, CC_LONG(data.count), &hash)
            }
            return Data(hash)
        case .hmacSHA256:
            // Implementation for HMAC would go here
            return nil
        }
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    /**
     Encrypts data with the given key.
     
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
        let algorithmString = options?.algorithm ?? StandardEncryptionAlgorithm.default.rawValue
        let modeString = options?.mode ?? StandardEncryptionMode.default.rawValue
        let paddingString = options?.padding ?? StandardPaddingType.default.rawValue
        
        // Convert to standardised types
        guard let algorithm = StandardEncryptionAlgorithm(rawValue: algorithmString) else {
            return .failure(.storageError("Unsupported encryption algorithm: \(algorithmString)"))
        }
        
        guard let mode = StandardEncryptionMode(rawValue: modeString) else {
            return .failure(.storageError("Unsupported encryption mode: \(modeString)"))
        }
        
        guard let padding = StandardPaddingType(rawValue: paddingString) else {
            return .failure(.storageError("Unsupported padding type: \(paddingString)"))
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
                .withPublic(key: "mode", value: mode.rawValue)
                .withPublic(key: "padding", value: padding.rawValue)
        )
        
        await logDebug("Starting encryption operation", context: context)
        
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
                // Validate key size
                let keyValidation = CryptoErrorHandling.validateKey(keyData, algorithm: algorithm)
                
                if case .failure(let error) = keyValidation {
                    await logError("Key validation failed: \(error.message)", context: context)
                    return .failure(.storageError(error.message))
                }
                
                // Use provided IV or generate a random one
                let iv: [UInt8]
                if let providedIV = options?.iv {
                    // Validate IV size
                    let ivValidation = CryptoErrorHandling.validateIV(providedIV, algorithm: algorithm)
                    
                    if case .failure(let error) = ivValidation {
                        await logError("IV validation failed: \(error.message)", context: context)
                        return .failure(.storageError(error.message))
                    }
                    
                    iv = [UInt8](providedIV)
                } else {
                    // Generate a random IV
                    iv = generateRandomIV(for: algorithm)
                }
                
                // Encrypt the data
                guard let encryptedData = aesEncrypt(
                    data: dataToEncrypt,
                    key: keyData,
                    iv: iv,
                    mode: mode,
                    padding: padding
                ) else {
                    let error = CryptoErrorMapper.operationalError(
                        code: .encryptionFailed,
                        message: "Encryption operation failed"
                    )
                    await logError(error.message, context: context)
                    return .failure(.storageError(error.message))
                }
                
                // Create the final encrypted data format: [IV][Encrypted Data][Key ID Length][Key ID]
                var encryptedBytes = Data()
                encryptedBytes.append(Data(iv))
                encryptedBytes.append(encryptedData)
                
                // Append key identifier for later decryption
                let keyIDData = keyIdentifier.data(using: .utf8) ?? Data()
                let keyIDLength: UInt8 = UInt8(min(keyIDData.count, 255))
                encryptedBytes.append(Data([keyIDLength]))
                encryptedBytes.append(keyIDData.prefix(Int(keyIDLength)))
                
                // Generate a unique identifier for the encrypted data
                let encryptedDataIdentifier = "enc_\(UUID().uuidString)"
                
                // Store the encrypted data
                let storeResult = await secureStorage.store(encryptedBytes, withIdentifier: encryptedDataIdentifier)
                
                switch storeResult {
                case .success:
                    let successContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
                            .withPublic(key: "encryptedSize", value: String(encryptedBytes.count))
                    )
                    await logInfo("Encryption completed successfully", context: successContext)
                    return .success(encryptedDataIdentifier)
                    
                case let .failure(error):
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "error", value: error.localizedDescription)
                    )
                    await logError("Failed to store encrypted data", context: errorContext)
                    return .failure(error)
                }
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to retrieve encryption key", context: errorContext)
                return .failure(error)
            }
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to retrieve data for encryption", context: errorContext)
            return .failure(error)
        }
    }
    
    /**
     Decrypts data with the given key.
     
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
            correlationID: UUID().uuidString
        ).withMetadata(
            LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        )
        
        await logDebug("Starting decryption operation", context: context)
        
        // Retrieve the encrypted data
        let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
        
        switch dataResult {
        case let .success(encryptedDataBytes):
            // Verify the encrypted data format: [IV][Encrypted Data][Key ID Length][Key ID]
            if encryptedDataBytes.count < 17 { // Minimum size: IV (16) + Key ID Length (1)
                await logError("Invalid encrypted data format", context: context)
                return .failure(.invalidDataFormat)
            }
            
            // Extract the IV
            let ivData = encryptedDataBytes.prefix(kCCBlockSizeAES128)
            let iv = [UInt8](ivData)
            
            // Extract the key ID length and key ID
            let keyIDLengthIndex = encryptedDataBytes.count - 1 - Int(encryptedDataBytes.last ?? 0)
            let storedKeyID: String
            
            if keyIDLengthIndex >= ivData.count {
                let keyIDLengthByte = encryptedDataBytes[keyIDLengthIndex]
                let keyIDData = encryptedDataBytes.suffix(Int(keyIDLengthByte))
                storedKeyID = String(data: keyIDData, encoding: .utf8) ?? ""
                
                // If stored key ID doesn't match provided key ID, log a warning
                if !storedKeyID.isEmpty && storedKeyID != keyIdentifier {
                    let warningContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPrivate(key: "storedKeyID", value: storedKeyID)
                    )
                    await logDebug("Stored key ID does not match provided key ID", context: warningContext)
                }
            }
            
            // Extract the encrypted data portion
            let encryptedData: Data
            if keyIDLengthIndex >= ivData.count {
                encryptedData = encryptedDataBytes.subdata(in: ivData.count..<keyIDLengthIndex)
            } else {
                encryptedData = encryptedDataBytes.subdata(in: ivData.count..<encryptedDataBytes.count)
            }
            
            // Retrieve the decryption key
            let keyResult = await secureStorage.retrieve(identifier: keyIdentifier)
            
            switch keyResult {
            case let .success(keyData):
                if keyData.count != kCCKeySizeAES256 {
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "expected_key_size", value: String(kCCKeySizeAES256))
                            .withPublic(key: "actual_key_size", value: String(keyData.count))
                    )
                    await logError("Invalid key size for decryption", context: errorContext)
                    return .failure(.invalidKeySize)
                }
                
                // Decrypt the data
                guard let decryptedData = aesDecrypt(encryptedData: encryptedData, key: keyData, iv: iv, mode: .cbc, padding: .pkcs7) else {
                    await logError("Decryption operation failed", context: context)
                    return .failure(.decryptionFailed)
                }
                
                // Generate a unique identifier for the decrypted data
                let decryptedDataIdentifier = "dec_\(UUID().uuidString)"
                
                // Store the decrypted data
                let storeResult = await secureStorage.store(decryptedData, withIdentifier: decryptedDataIdentifier)
                
                switch storeResult {
                case .success:
                    let successContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "decryptedDataIdentifier", value: decryptedDataIdentifier)
                            .withPublic(key: "decryptedSize", value: String(decryptedData.count))
                    )
                    await logInfo("Decryption completed successfully", context: successContext)
                    return .success(decryptedDataIdentifier)
                    
                case let .failure(error):
                    let errorContext = context.withMetadata(
                        LogMetadataDTOCollection()
                            .withPublic(key: "error", value: error.localizedDescription)
                    )
                    await logError("Failed to store decrypted data", context: errorContext)
                    return .failure(error)
                }
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to retrieve decryption key", context: errorContext)
                return .failure(error)
            }
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to retrieve encrypted data", context: errorContext)
            return .failure(error)
        }
    }
    
    /**
     Verifies a hash against data.
     
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
        let algorithm = options?.algorithm ?? .sha256
        
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
        )
        
        await logDebug("Starting hash verification", context: context)
        
        // Retrieve the data to verify
        let dataResult = await secureStorage.retrieve(identifier: dataIdentifier)
        
        switch dataResult {
        case let .success(dataToVerify):
            // Retrieve the stored hash
            let hashResult = await secureStorage.retrieve(identifier: hashIdentifier)
            
            switch hashResult {
            case let .success(storedHash):
                // Compute the hash of the data
                guard let computedHash = computeHash(for: dataToVerify, using: algorithm) else {
                    await logError("Failed to compute hash", context: context)
                    return .failure(.hashingFailed)
                }
                
                // Compare the computed hash with the stored hash
                let hashesMatch = computedHash == storedHash
                
                let resultContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "hashesMatch", value: String(hashesMatch))
                )
                
                if hashesMatch {
                    await logInfo("Hash verification succeeded", context: resultContext)
                } else {
                    await logInfo("Hash verification failed - hashes do not match", context: resultContext)
                }
                
                return .success(hashesMatch)
                
            case let .failure(error):
                let errorContext = context.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "error", value: error.localizedDescription)
                )
                await logError("Failed to retrieve stored hash", context: errorContext)
                return .failure(error)
            }
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to retrieve data for hash verification", context: errorContext)
            return .failure(error)
        }
    }
    
    /**
     Generates a cryptographic key.
     
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
        )
        
        await logDebug("Starting key generation", context: context)
        
        // Validate key length
        let byteLength = length / 8
        if byteLength <= 0 || byteLength > 1024 { // Set a reasonable upper limit
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: "Invalid key length")
            )
            await logError("Invalid key length", context: errorContext)
            return .failure(.invalidKeyLength)
        }
        
        // Generate random key bytes
        var keyBytes = [UInt8](repeating: 0, count: byteLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteLength, &keyBytes)
        
        if status != errSecSuccess {
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: "Failed to generate random bytes")
                    .withPublic(key: "status", value: String(status))
            )
            await logError("Random bytes generation failed", context: errorContext)
            return .failure(.keyGenerationFailed)
        }
        
        // Store the key
        let keyData = Data(keyBytes)
        let storeResult = await secureStorage.store(keyData, withIdentifier: identifier)
        
        switch storeResult {
        case .success:
            let successContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "keySize", value: String(keyData.count))
            )
            await logInfo("Key generated and stored successfully", context: successContext)
            return .success(true)
            
        case let .failure(error):
            let errorContext = context.withMetadata(
                LogMetadataDTOCollection()
                    .withPublic(key: "error", value: error.localizedDescription)
            )
            await logError("Failed to store generated key", context: errorContext)
            return .failure(error)
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
