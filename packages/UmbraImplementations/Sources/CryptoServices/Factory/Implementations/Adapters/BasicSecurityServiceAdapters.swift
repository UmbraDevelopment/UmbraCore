import CommonCrypto
import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces

// MARK: - Basic Encryption Service Adapter

/**
 # BasicEncryptionServiceAdapter
 
 Provides AES encryption and decryption using CommonCrypto.
 */
internal actor BasicEncryptionServiceAdapter: EncryptionServiceAdapter {
    /// Logger utility for operation tracking
    private let logger: SecurityServiceLogger
    
    /// Secure storage for persisting data
    private let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        self.logger = SecurityServiceLogger(logger: logger)
    }
    
    /**
     Encrypts data using the specified configuration.
     
     - Parameter config: Security configuration with encryption parameters
     - Returns: Result of the encryption operation
     - Throws: If encryption fails
     */
    public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        await logger.logger.debug("Starting encryption operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        // Extract key ID and encrypted data from metadata
        guard let metadata = config.options?.metadata,
              let inputDataBase64 = metadata["inputData"],
              let keyId = metadata["keyIdentifier"] else {
            throw SecurityError.encryptionFailed(reason: "Missing required metadata")
        }
        
        // Decode the input data
        guard let inputData = Data(base64Encoded: inputDataBase64) else {
            throw SecurityError.encryptionFailed(reason: "Invalid input data encoding")
        }
        
        // Retrieve key from secure storage
        var keyData: Data
        do {
            keyData = try await secureStorage.retrieveData(forKey: keyId)
        } catch {
            throw SecurityError.keyNotFound(identifier: keyId)
        }
        
        // Create initialization vector (IV)
        var iv = Data(count: kCCBlockSizeAES128)
        let result = iv.withUnsafeMutableBytes { ivPtr in
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, ivPtr.baseAddress!)
        }
        
        if result != errSecSuccess {
            throw SecurityError.encryptionFailed(reason: "Failed to generate IV")
        }
        
        // Perform encryption
        let algorithm: CCAlgorithm
        let options: CCOptions
        let blockSize: Int
        
        switch config.encryptionAlgorithm {
        case .aes256CBC:
            algorithm = CCAlgorithm(kCCAlgorithmAES)
            options = CCOptions(kCCOptionPKCS7Padding)
            blockSize = kCCBlockSizeAES128
        case .aes256GCM:
            algorithm = CCAlgorithm(kCCAlgorithmAES)
            options = CCOptions(kCCOptionPKCS7Padding)
            blockSize = kCCBlockSizeAES128
        case .chacha20Poly1305:
            throw SecurityError.unsupportedAlgorithm(name: config.encryptionAlgorithm.rawValue)
        default:
            throw SecurityError.encryptionFailed(reason: "Unsupported algorithm: \(config.encryptionAlgorithm.rawValue)")
        }
        
        let dataLength = inputData.count
        var encryptedData = Data(count: dataLength + blockSize)
        var encryptedLength = 0
        
        let cryptStatus = encryptedData.withUnsafeMutableBytes { encryptedPtr in
            inputData.withUnsafeBytes { dataPtr in
                keyData.withUnsafeBytes { keyPtr in
                    iv.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            algorithm,
                            options,
                            keyPtr.baseAddress, keyData.count,
                            ivPtr.baseAddress,
                            dataPtr.baseAddress, dataLength,
                            encryptedPtr.baseAddress, encryptedData.count,
                            &encryptedLength
                        )
                    }
                }
            }
        }
        
        if cryptStatus != kCCSuccess {
            throw SecurityError.encryptionFailed(reason: "Encryption failed with status \(cryptStatus)")
        }
        
        // Trim the encrypted data to the actual length
        encryptedData = encryptedData.prefix(encryptedLength)
        
        // Prepend the IV to the encrypted data for decryption later
        let resultData = iv + encryptedData
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        await logger.logger.debug("Completed encryption operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        // Create and return the result
        return SecurityResultDTO.success(
            resultData: resultData,
            executionTimeMs: duration,
            metadata: ["algorithm": config.encryptionAlgorithm.rawValue]
        )
    }
    
    /**
     Decrypts data using the specified configuration.
     
     - Parameter config: Security configuration with decryption parameters
     - Returns: Result of the decryption operation
     - Throws: If decryption fails
     */
    public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        await logger.logger.debug("Starting decryption operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        // Extract key ID and encrypted data from metadata
        guard let metadata = config.options?.metadata,
              let encryptedDataBase64 = metadata["inputData"],
              let keyId = metadata["keyIdentifier"] else {
            throw SecurityError.decryptionFailed(reason: "Missing required metadata")
        }
        
        // Decode the encrypted data
        guard let encryptedDataWithIV = Data(base64Encoded: encryptedDataBase64) else {
            throw SecurityError.decryptionFailed(reason: "Invalid encrypted data encoding")
        }
        
        // Extract IV and actual encrypted data
        guard encryptedDataWithIV.count > kCCBlockSizeAES128 else {
            throw SecurityError.decryptionFailed(reason: "Encrypted data too short")
        }
        
        let iv = encryptedDataWithIV.prefix(kCCBlockSizeAES128)
        let encryptedData = encryptedDataWithIV.dropFirst(kCCBlockSizeAES128)
        
        // Retrieve key from secure storage
        var keyData: Data
        do {
            keyData = try await secureStorage.retrieveData(forKey: keyId)
        } catch {
            throw SecurityError.keyNotFound(identifier: keyId)
        }
        
        // Perform decryption
        let algorithm: CCAlgorithm
        let options: CCOptions
        let blockSize: Int
        
        switch config.encryptionAlgorithm {
        case .aes256CBC:
            algorithm = CCAlgorithm(kCCAlgorithmAES)
            options = CCOptions(kCCOptionPKCS7Padding)
            blockSize = kCCBlockSizeAES128
        case .aes256GCM:
            algorithm = CCAlgorithm(kCCAlgorithmAES)
            options = CCOptions(kCCOptionPKCS7Padding)
            blockSize = kCCBlockSizeAES128
        case .chacha20Poly1305:
            throw SecurityError.unsupportedAlgorithm(name: config.encryptionAlgorithm.rawValue)
        default:
            throw SecurityError.decryptionFailed(reason: "Unsupported algorithm: \(config.encryptionAlgorithm.rawValue)")
        }
        
        let dataLength = encryptedData.count
        var decryptedData = Data(count: dataLength + blockSize)
        var decryptedLength = 0
        
        let cryptStatus = decryptedData.withUnsafeMutableBytes { decryptedPtr in
            encryptedData.withUnsafeBytes { dataPtr in
                keyData.withUnsafeBytes { keyPtr in
                    iv.withUnsafeBytes { ivPtr in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            algorithm,
                            options,
                            keyPtr.baseAddress, keyData.count,
                            ivPtr.baseAddress,
                            dataPtr.baseAddress, dataLength,
                            decryptedPtr.baseAddress, decryptedData.count,
                            &decryptedLength
                        )
                    }
                }
            }
        }
        
        if cryptStatus != kCCSuccess {
            throw SecurityError.decryptionFailed(reason: "Decryption failed with status \(cryptStatus)")
        }
        
        // Trim the decrypted data to the actual length
        decryptedData = decryptedData.prefix(decryptedLength)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        await logger.logger.debug("Completed decryption operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        // Create and return the result
        return SecurityResultDTO.success(
            resultData: decryptedData,
            executionTimeMs: duration,
            metadata: ["algorithm": config.encryptionAlgorithm.rawValue]
        )
    }
}

// MARK: - Basic Hashing Service Adapter

/**
 # BasicHashingServiceAdapter
 
 Provides cryptographic hashing operations using CommonCrypto.
 */
internal actor BasicHashingServiceAdapter: HashingServiceAdapter {
    /// Logger utility for operation tracking
    private let logger: SecurityServiceLogger
    
    /// Secure storage for persisting data
    private let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        self.logger = SecurityServiceLogger(logger: logger)
    }
    
    /**
     Hashes data using the specified configuration.
     
     - Parameter config: Security configuration with hashing parameters
     - Returns: Result of the hashing operation
     - Throws: If hashing fails
     */
    public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        await logger.logger.debug("Starting hash operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        // Extract data from metadata
        guard let metadata = config.options?.metadata,
              let inputDataBase64 = metadata["inputData"] else {
            throw SecurityError.hashingFailed(reason: "Missing required metadata")
        }
        
        // Decode the input data
        guard let inputData = Data(base64Encoded: inputDataBase64) else {
            throw SecurityError.hashingFailed(reason: "Invalid input data encoding")
        }
        
        // Perform hashing based on algorithm
        let hashData: Data
        
        switch config.hashAlgorithm {
        case .sha256:
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            inputData.withUnsafeBytes { dataBytes in
                CC_SHA256(dataBytes.baseAddress, CC_LONG(inputData.count), &hash)
            }
            hashData = Data(hash)
            
        case .sha512:
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            inputData.withUnsafeBytes { dataBytes in
                CC_SHA512(dataBytes.baseAddress, CC_LONG(inputData.count), &hash)
            }
            hashData = Data(hash)
            
        case .blake2b:
            throw SecurityError.hashingFailed(reason: "BLAKE2b algorithm not supported in this implementation")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        await logger.logger.debug("Completed hash operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        // Create and return the result
        return SecurityResultDTO.success(
            resultData: hashData,
            executionTimeMs: duration,
            metadata: ["algorithm": config.hashAlgorithm.rawValue]
        )
    }
    
    /**
     Verifies a hash against the original data.
     
     - Parameter config: Security configuration with hash verification parameters
     - Returns: Result of the verification operation
     - Throws: If verification fails
     */
    public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        await logger.logger.debug("Starting hash verification operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        // Extract data from metadata
        guard let metadata = config.options?.metadata,
              let inputDataBase64 = metadata["inputData"],
              let expectedHashBase64 = metadata["expectedHash"] else {
            throw SecurityError.hashingFailed(reason: "Missing required metadata")
        }
        
        // Decode the input data and expected hash
        guard let inputData = Data(base64Encoded: inputDataBase64),
              let expectedHash = Data(base64Encoded: expectedHashBase64) else {
            throw SecurityError.hashingFailed(reason: "Invalid data encoding")
        }
        
        // Compute the hash of the input data
        let hashConfig = SecurityConfigDTO(
            encryptionAlgorithm: config.encryptionAlgorithm,
            hashAlgorithm: config.hashAlgorithm,
            providerType: config.providerType,
            options: SecurityConfigOptions(
                enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
                keyDerivationIterations: config.options?.keyDerivationIterations ?? 10000,
                memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
                useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
                operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30,
                verifyOperations: config.options?.verifyOperations ?? true,
                metadata: ["inputData": inputDataBase64]
            )
        )
        
        // Compute hash
        let hashResult = try await hash(config: hashConfig)
        
        guard let computedHash = hashResult.resultData else {
            throw SecurityError.hashingFailed(reason: "Failed to compute hash")
        }
        
        // Compare the computed hash with the expected hash
        let hashesMatch = computedHash == expectedHash
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        await logger.logger.debug("Completed hash verification operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: hashesMatch ? "match" : "mismatch", privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        // Create and return the result
        return SecurityResultDTO.success(
            resultData: Data([UInt8(hashesMatch ? 1 : 0)]),
            executionTimeMs: duration,
            metadata: [
                "algorithm": config.hashAlgorithm.rawValue,
                "verified": hashesMatch ? "true" : "false"
            ]
        )
    }
}

// MARK: - Basic Key Generation Service Adapter

/**
 # BasicKeyGenerationServiceAdapter
 
 Provides secure key generation operations for cryptographic use.
 */
internal actor BasicKeyGenerationServiceAdapter: KeyGenerationServiceAdapter {
    /// Logger utility for operation tracking
    private let logger: SecurityServiceLogger
    
    /// Secure storage for persisting data
    private let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        self.logger = SecurityServiceLogger(logger: logger)
    }
    
    /**
     Generates a cryptographic key based on the provided configuration.
     
     - Parameter config: Security configuration with key generation parameters
     - Returns: Result containing the generated key data
     - Throws: If key generation fails
     */
    public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        await logger.logger.debug("Starting key generation operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicKeyGenerationService"
                     ))
        
        // Extract key parameters from metadata
        guard let metadata = config.options?.metadata else {
            throw SecurityError.keyGenerationFailed(reason: "Missing metadata")
        }
        
        // Determine key size (default to 256 bits for AES-256)
        let keySizeStr = metadata["keySize"] ?? "256"
        guard let keySize = Int(keySizeStr), keySize > 0 else {
            throw SecurityError.keyGenerationFailed(reason: "Invalid key size")
        }
        
        // Convert bits to bytes
        let keySizeBytes = keySize / 8
        
        // Generate random key data
        var keyData = Data(count: keySizeBytes)
        let result = keyData.withUnsafeMutableBytes { keyPtr in
            SecRandomCopyBytes(kSecRandomDefault, keySizeBytes, keyPtr.baseAddress!)
        }
        
        if result != errSecSuccess {
            throw SecurityError.keyGenerationFailed(reason: "Failed to generate random bytes")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        await logger.logger.debug("Completed key generation operation",
                     context: logger.createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public),
                         "keySize": (value: keySizeStr, privacy: .public)
                       ],
                       source: "BasicKeyGenerationService"
                     ))
        
        // Create and return the result
        return SecurityResultDTO.success(
            resultData: keyData,
            executionTimeMs: duration,
            metadata: [
                "algorithm": config.encryptionAlgorithm.rawValue,
                "keySize": keySizeStr
            ]
        )
    }
}

// MARK: - Basic Configuration Service Adapter

/**
 # BasicConfigurationServiceAdapter
 
 Provides configuration management for security operations.
 */
internal actor BasicConfigurationServiceAdapter: ConfigurationServiceAdapter {
    /// Logger utility for operation tracking
    private let logger: SecurityServiceLogger
    
    /// Secure storage for persisting data
    private let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        self.logger = SecurityServiceLogger(logger: logger)
    }
    
    /**
     Creates a security configuration with the specified options.
     
     - Parameter options: The configuration options to use
     - Returns: A security configuration DTO
     */
    public func createSecureConfig(options: SecurityConfigOptions) -> SecurityConfigDTO {
        // Create a basic security configuration with sensible defaults
        return SecurityConfigDTO(
            encryptionAlgorithm: .aes256CBC,
            hashAlgorithm: .sha256,
            providerType: .basic,
            options: options
        )
    }
}

/**
 Error types for security operations.
 */
enum SecurityError: Error {
    case encryptionFailed(reason: String)
    case decryptionFailed(reason: String)
    case hashingFailed(reason: String)
    case keyGenerationFailed(reason: String)
    case keyNotFound(identifier: String)
    case unsupportedAlgorithm(name: String)
}
