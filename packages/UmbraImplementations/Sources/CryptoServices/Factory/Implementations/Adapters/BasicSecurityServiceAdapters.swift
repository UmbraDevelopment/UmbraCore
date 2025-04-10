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
internal final class BasicEncryptionServiceAdapter: BaseSecurityServiceAdapter, EncryptionServiceAdapter {
    /// Secure storage for persisting data
    let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        super.init(logger: logger)
    }
    
    /**
     Encrypts data using the specified configuration.
     
     - Parameter config: Security configuration with encryption parameters
     - Returns: Result containing encrypted data and metadata
     - Throws: If encryption fails
     */
    public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        logger.debug("Starting encryption operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        // Extract data from metadata if available
        guard let inputDataBase64 = config.options?.metadata?["inputData"],
              let inputData = Data(base64Encoded: inputDataBase64) else {
            throw SecurityError.encryptionFailed(reason: "Missing or invalid input data")
        }
        
        // Extract key identifier or key data
        let keyIdentifier = config.options?.metadata?["keyIdentifier"]
        let keyData: Data
        
        if let keyId = keyIdentifier {
            // Retrieve key from secure storage
            do {
                keyData = try await secureStorage.retrieveData(forKey: keyId)
            } catch {
                throw SecurityError.keyNotFound(identifier: keyId)
            }
        } else if let keyBase64 = config.options?.metadata?["key"],
                  let key = Data(base64Encoded: keyBase64) {
            keyData = key
        } else {
            // Generate a random key for this operation
            var key = Data(count: 32) // 256-bit key
            let status = key.withUnsafeMutableBytes { 
                SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) 
            }
            
            guard status == errSecSuccess else {
                throw SecurityError.keyGenerationFailed(reason: "Failed to generate random key")
            }
            
            keyData = key
        }
        
        // Generate random IV
        var iv = Data(count: 16)
        let ivStatus = iv.withUnsafeMutableBytes { 
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) 
        }
        
        guard ivStatus == errSecSuccess else {
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
        
        guard cryptStatus == kCCSuccess else {
            throw SecurityError.encryptionFailed(reason: "Encryption failed with status: \(cryptStatus)")
        }
        
        // Resize the result to the actual bytes encrypted
        encryptedData.count = encryptedLength
        
        // Prepend IV to encrypted data
        let resultData = iv + encryptedData
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        logger.debug("Completed encryption operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        return SecurityResultDTO.success(
            resultData: resultData,
            executionTimeMs: duration,
            metadata: ["operationID": operationID]
        )
    }
    
    /**
     Decrypts data using the specified configuration.
     
     - Parameter config: Security configuration with decryption parameters
     - Returns: Result containing decrypted data and metadata
     - Throws: If decryption fails
     */
    public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        logger.debug("Starting decryption operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        // Extract encrypted data from metadata
        guard let encryptedDataBase64 = config.options?.metadata?["encryptedData"],
              let encryptedDataWithIV = Data(base64Encoded: encryptedDataBase64) else {
            throw SecurityError.decryptionFailed(reason: "Missing or invalid encrypted data")
        }
        
        // Ensure data is long enough to contain IV
        guard encryptedDataWithIV.count > 16 else {
            throw SecurityError.decryptionFailed(reason: "Data too short to contain IV")
        }
        
        // Extract IV from first 16 bytes
        let iv = encryptedDataWithIV.prefix(16)
        let encryptedData = encryptedDataWithIV.dropFirst(16)
        
        // Extract key identifier or key data
        let keyIdentifier = config.options?.metadata?["keyIdentifier"]
        let keyData: Data
        
        if let keyId = keyIdentifier {
            // Retrieve key from secure storage
            do {
                keyData = try await secureStorage.retrieveData(forKey: keyId)
            } catch {
                throw SecurityError.keyNotFound(identifier: keyId)
            }
        } else if let keyBase64 = config.options?.metadata?["key"],
                  let key = Data(base64Encoded: keyBase64) {
            keyData = key
        } else {
            throw SecurityError.decryptionFailed(reason: "No key identifier or key data provided")
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
        
        guard cryptStatus == kCCSuccess else {
            throw SecurityError.decryptionFailed(reason: "Decryption failed with status: \(cryptStatus)")
        }
        
        // Resize the result to the actual bytes decrypted
        decryptedData.count = decryptedLength
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        logger.debug("Completed decryption operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicEncryptionService"
                     ))
        
        return SecurityResultDTO.success(
            resultData: decryptedData,
            executionTimeMs: duration,
            metadata: [
                "operationID": operationID,
                "algorithm": config.encryptionAlgorithm.rawValue
            ]
        )
    }
}

// MARK: - Basic Hashing Service Adapter

/**
 # BasicHashingServiceAdapter
 
 Provides SHA-256, SHA-384, and SHA-512 hash functions.
 */
internal final class BasicHashingServiceAdapter: BaseSecurityServiceAdapter, HashingServiceAdapter {
    /// Secure storage for persisting data
    let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        super.init(logger: logger)
    }
    
    /**
     Performs a hash operation on the provided data.
     
     - Parameter config: Security configuration with hashing parameters
     - Returns: Result containing the hash and metadata
     - Throws: If hashing fails
     */
    public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        logger.debug("Starting hash operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        // Extract data from metadata
        guard let inputDataBase64 = config.options?.metadata?["inputData"],
              let inputData = Data(base64Encoded: inputDataBase64) else {
            throw SecurityError.hashingFailed(reason: "Missing or invalid input data")
        }
        
        // Determine hash algorithm
        let algorithm: CCHmacAlgorithm
        var digestLength: Int
        
        switch config.hashAlgorithm {
        case .sha256:
            algorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
            digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        case .sha384:
            algorithm = CCHmacAlgorithm(kCCHmacAlgSHA384)
            digestLength = Int(CC_SHA384_DIGEST_LENGTH)
        case .sha512:
            algorithm = CCHmacAlgorithm(kCCHmacAlgSHA512)
            digestLength = Int(CC_SHA512_DIGEST_LENGTH)
        default:
            throw SecurityError.hashingFailed(reason: "Unsupported algorithm: \(config.hashAlgorithm.rawValue)")
        }
        
        // Perform hashing
        var hashData = Data(count: digestLength)
        
        switch config.hashAlgorithm {
        case .sha256:
            _ = hashData.withUnsafeMutableBytes { hashPtr in
                inputData.withUnsafeBytes { dataPtr in
                    CC_SHA256(dataPtr.baseAddress, CC_LONG(inputData.count), hashPtr.baseAddress)
                }
            }
        case .sha384:
            _ = hashData.withUnsafeMutableBytes { hashPtr in
                inputData.withUnsafeBytes { dataPtr in
                    CC_SHA384(dataPtr.baseAddress, CC_LONG(inputData.count), hashPtr.baseAddress)
                }
            }
        case .sha512:
            _ = hashData.withUnsafeMutableBytes { hashPtr in
                inputData.withUnsafeBytes { dataPtr in
                    CC_SHA512(dataPtr.baseAddress, CC_LONG(inputData.count), hashPtr.baseAddress)
                }
            }
        default:
            throw SecurityError.hashingFailed(reason: "Unsupported algorithm: \(config.hashAlgorithm.rawValue)")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        logger.debug("Completed hash operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        return SecurityResultDTO.success(
            resultData: hashData,
            executionTimeMs: duration,
            metadata: [
                "operationID": operationID,
                "algorithm": config.hashAlgorithm.rawValue
            ]
        )
    }
    
    /**
     Verifies a hash against the original data.
     
     - Parameter config: Security configuration with verification parameters
     - Returns: Result indicating whether the hash is valid
     - Throws: If verification fails
     */
    public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        logger.debug("Starting hash verification operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        // Extract data and expected hash from metadata
        guard let inputDataBase64 = config.options?.metadata?["inputData"],
              let inputData = Data(base64Encoded: inputDataBase64) else {
            throw SecurityError.hashingFailed(reason: "Missing or invalid input data")
        }
        
        guard let expectedHashBase64 = config.options?.metadata?["expectedHash"],
              let expectedHash = Data(base64Encoded: expectedHashBase64) else {
            throw SecurityError.hashingFailed(reason: "Missing or invalid expected hash")
        }
        
        // Compute hash of input data
        let hashResult = try await hash(config: config)
        let computedHash = hashResult.resultData
        
        // Compare hashes
        let isValid = (computedHash == expectedHash)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        logger.debug("Completed hash verification operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public),
                         "isValid": (value: isValid ? "true" : "false", privacy: .public)
                       ],
                       source: "BasicHashingService"
                     ))
        
        return SecurityResultDTO.success(
            resultData: Data([isValid ? 1 : 0]), // 1 for valid, 0 for invalid
            executionTimeMs: duration,
            metadata: [
                "operationID": operationID,
                "algorithm": config.hashAlgorithm.rawValue,
                "isValid": isValid ? "true" : "false"
            ]
        )
    }
}

// MARK: - Basic Key Generation Service Adapter

/**
 # BasicKeyGenerationServiceAdapter
 
 Generates secure random keys using SecRandomCopyBytes.
 */
internal final class BasicKeyGenerationServiceAdapter: BaseSecurityServiceAdapter, KeyGenerationServiceAdapter {
    /// Secure storage for persisting data
    let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        super.init(logger: logger)
    }
    
    /**
     Generates a cryptographic key with the specified parameters.
     
     - Parameter config: Security configuration with key generation parameters
     - Returns: Result containing the generated key
     - Throws: If key generation fails
     */
    public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let operationID = UUID().uuidString
        let startTime = Date()
        
        // Extract key size from metadata, default to 256 bits if not specified
        let keySize = Int(config.options?.metadata?["keySize"] ?? "256") ?? 256
        let keySizeBytes = keySize / 8
        
        logger.debug("Starting key generation operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "keySize": (value: String(keySize), privacy: .public)
                       ],
                       source: "BasicKeyGenerationService"
                     ))
        
        // Generate random key
        var keyData = Data(count: keySizeBytes)
        let status = keyData.withUnsafeMutableBytes { 
            SecRandomCopyBytes(kSecRandomDefault, keySizeBytes, $0.baseAddress!) 
        }
        
        guard status == errSecSuccess else {
            throw SecurityError.keyGenerationFailed(reason: "Failed to generate random key with status: \(status)")
        }
        
        // Store key if identifier provided
        if let keyIdentifier = config.options?.metadata?["keyIdentifier"] {
            do {
                try await secureStorage.storeData(keyData, forKey: keyIdentifier)
                
                logger.debug("Stored generated key",
                             context: createLogContext(
                               [
                                 "operationID": (value: operationID, privacy: .public),
                                 "keyIdentifier": (value: keyIdentifier, privacy: .private)
                               ],
                               source: "BasicKeyGenerationService"
                             ))
            } catch {
                logger.error("Failed to store generated key",
                             context: createLogContext(
                               [
                                 "operationID": (value: operationID, privacy: .public),
                                 "keyIdentifier": (value: keyIdentifier, privacy: .private),
                                 "error": (value: error.localizedDescription, privacy: .public)
                               ],
                               source: "BasicKeyGenerationService"
                             ))
                
                throw SecurityError.keyGenerationFailed(reason: "Failed to store key: \(error.localizedDescription)")
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000
        
        logger.debug("Completed key generation operation",
                     context: createLogContext(
                       [
                         "operationID": (value: operationID, privacy: .public),
                         "duration": (value: String(format: "%.2f", duration), privacy: .public),
                         "status": (value: "success", privacy: .public)
                       ],
                       source: "BasicKeyGenerationService"
                     ))
        
        return SecurityResultDTO.success(
            resultData: keyData,
            executionTimeMs: duration,
            metadata: [
                "operationID": operationID,
                "keySize": String(keySize)
            ]
        )
    }
}

// MARK: - Basic Configuration Service Adapter

/**
 # BasicConfigurationServiceAdapter
 
 Creates and validates security configurations.
 */
internal final class BasicConfigurationServiceAdapter: BaseSecurityServiceAdapter, ConfigurationServiceAdapter {
    /// Secure storage for persisting data
    let secureStorage: SecureStorageProtocol
    
    /**
     Initialises the adapter with common dependencies.
     
     - Parameters:
        - secureStorage: The secure storage implementation
        - logger: The logger for operation tracking
     */
    init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol) {
        self.secureStorage = secureStorage
        super.init(logger: logger)
    }
    
    /**
     Creates a security configuration with the specified options.
     
     - Parameter options: Security configuration options
     - Returns: A configured SecurityConfigDTO
     */
    public func createSecureConfig(options: SecurityConfigOptions) -> SecurityConfigDTO {
        logger.debug("Creating security configuration",
                     context: createLogContext(
                       [
                         "useHardwareAcceleration": (value: String(options.useHardwareAcceleration), privacy: .public),
                         "keyDerivationIterations": (value: String(options.keyDerivationIterations), privacy: .public)
                       ],
                       source: "BasicConfigurationService"
                     ))
        
        return SecurityConfigDTO(
            encryptionAlgorithm: .aes256,
            hashAlgorithm: .sha256,
            providerType: .basic,
            options: options
        )
    }
}

/**
 Internal security error type for cryptographic operations.
 */
internal enum SecurityError: Error {
    case encryptionFailed(reason: String)
    case decryptionFailed(reason: String)
    case hashingFailed(reason: String)
    case keyGenerationFailed(reason: String)
    case keyNotFound(identifier: String)
    case unsupportedAlgorithm(name: String)
}
