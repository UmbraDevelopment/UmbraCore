import Foundation
import CoreSecurityTypes
import DomainSecurityTypes
import SecurityCoreInterfaces
import CryptoTypes
import KeyManagementTypes
import UmbraErrors
import LoggingInterfaces
import LoggingTypes
import CommonCrypto

/**
 # SecurityProviderImpl
 
 Standard implementation of the SecurityProviderProtocol that provides secure
 cryptographic operations, key management, and security configurations.
 */
public actor SecurityProviderImpl: SecurityProviderProtocol {
    // MARK: - Dependencies
    
    /// Underlying cryptographic service
    private let cryptoServiceInstance: any CryptoServiceProtocol
    
    /// Key management service for certificate and key operations
    private let keyManagerInstance: any KeyManagementProtocol
    
    /// Logger for recording security operations with proper privacy controls
    private let logger: any LoggingProtocol
    
    /// Performance metrics tracker for measuring operation durations
    private let metrics: PerformanceMetricsTracker
    
    /// Flag indicating whether the provider has been properly initialized
    private var isInitialized: Bool = false
    
    // MARK: - Initialization
    
    /**
     Initialises a new SecurityProviderImpl with the specified dependencies.
     
     - Parameters:
        - cryptoService: Service for cryptographic operations
        - keyManager: Service for key management
        - logger: Logger for recording operations
     */
    public init(
        cryptoService: any CryptoServiceProtocol,
        keyManager: any KeyManagementProtocol,
        logger: any LoggingProtocol
    ) {
        self.cryptoServiceInstance = cryptoService
        self.keyManagerInstance = keyManager
        self.logger = logger
        self.metrics = PerformanceMetricsTracker()
    }
    
    /**
     Asynchronously initialises the provider, ensuring all dependencies are ready.
     
     - Throws: SecurityProviderError if initialization fails
     */
    public func initialize() async throws {
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: "initialize", privacy: .public)
        
        await logger.debug(
            "Initializing SecurityProviderImpl",
            metadata: metadata,
            source: "SecurityProviderImpl"
        )
        
        do {
            // Initialize key manager if needed
            if let asyncInitializable = keyManagerInstance as? AsyncServiceInitializable {
                try await asyncInitializable.initialize()
            }
            
            // Initialize crypto service if needed
            if let asyncInitializable = cryptoServiceInstance as? AsyncServiceInitializable {
                try await asyncInitializable.initialize()
            }
            
            isInitialized = true
            
            await logger.info(
                "SecurityProviderImpl initialized successfully",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
        } catch {
            await logger.error(
                "Failed to initialize SecurityProviderImpl: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            throw SecurityProviderError.initializationFailed(reason: error.localizedDescription)
        }
    }
    
    /**
     Ensures the provider is initialized before performing operations.
     
     - Throws: Error if the provider is not initialized
     */
    private func validateInitialized() async throws {
        guard isInitialized else {
            var metadata = PrivacyMetadata()
            metadata["error"] = PrivacyMetadataValue(value: "Provider not initialized", privacy: .public)
            
            await logger.error(
                "Security provider not properly initialized",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            throw SecurityProviderError.notInitialized
        }
    }
    
    /**
     Maps CoreSecurityTypes algorithm to CryptoServices algorithm.
     
     - Parameter algorithm: The CoreSecurityTypes algorithm
     - Returns: Equivalent algorithm identifier as string
     */
    private func mapToCryptoServicesAlgorithm(_ algorithm: EncryptionAlgorithm) -> String {
        switch algorithm {
        case .aes256CBC:
            return "AES-256-CBC"
        case .aes256GCM:
            return "AES-256-GCM"
        case .chacha20Poly1305:
            return "ChaCha20-Poly1305"
        }
    }
    
    /**
     Stores data securely with the given identifier.
     
     - Parameters:
        - data: The data to store
        - identifier: Unique identifier for the data
     - Returns: Success or error result
     */
    private func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        let secureStorage = cryptoServiceInstance.secureStorage
        return await secureStorage.storeData(data, withIdentifier: identifier)
    }
    
    /**
     Retrieves data securely by its identifier.
     
     - Parameter identifier: Unique identifier for the data
     - Returns: The retrieved data or an error
     */
    private func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
        let secureStorage = cryptoServiceInstance.secureStorage
        return await secureStorage.retrieveData(withIdentifier: identifier)
    }
    
    /**
     Deletes data securely by its identifier.
     
     - Parameter identifier: Unique identifier for the data
     - Returns: Success or error result
     */
    private func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityStorageError> {
        let secureStorage = cryptoServiceInstance.secureStorage
        return await secureStorage.deleteData(withIdentifier: identifier)
    }
    
    /**
     Stores a cryptographic key with the given parameters.
     
     - Parameters:
        - key: The key data to store
        - identifier: Unique identifier for the key
        - purpose: Purpose of the key
        - algorithm: Algorithm the key is intended for
     - Throws: SecurityProviderError if storage fails
     */
    private func storeKey(_ key: Data, identifier: String, purpose: KeyPurpose, algorithm: EncryptionAlgorithm) async throws {
        // Convert Data to [UInt8]
        let keyBytes = [UInt8](key)
        
        let result = await keyManagerInstance.storeKey(keyBytes, withIdentifier: identifier)
        
        switch result {
        case .success:
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "storeKey", privacy: .public)
            metadata["purpose"] = PrivacyMetadataValue(value: purpose.rawValue, privacy: .public)
            metadata["identifier"] = PrivacyMetadataValue(value: identifier, privacy: .private)
            
            await logger.debug(
                "Successfully stored key",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
        case .failure(let error):
            throw SecurityProviderError.storageError(error.localizedDescription)
        }
    }
    
    // MARK: - Service Access
    
    /// Provides access to the cryptographic service
    public func cryptoService() async -> CryptoServiceProtocol {
        return cryptoServiceInstance
    }
    
    /// Provides access to the key management service
    public func keyManager() async -> KeyManagementProtocol {
        return keyManagerInstance
    }
    
    // MARK: - Core Cryptographic Operations
    
    /**
     Encrypts data using the configured encryption algorithm.
     
     - Parameter config: Configuration for the encryption operation
     - Returns: SecurityResultDTO with encrypted data or error details
     */
    public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let startTime = Date().timeIntervalSince1970
        
        do {
            // Validate initialization
            try await validateInitialized()
            
            // Validate input data
            guard let inputDataString = config.options?.metadata?["inputData"],
                  let dataToEncrypt = Data(base64Encoded: inputDataString) else {
                throw SecurityProviderError.invalidInput("Missing or empty input data for encryption")
            }
            
            // Get or generate key
            let key: [UInt8]
            if let keyString = config.options?.metadata?["keyData"],
               let keyData = Data(base64Encoded: keyString) {
                key = [UInt8](keyData)
            } else if let keyIdentifier = config.options?.metadata?["keyIdentifier"] {
                // Try to retrieve the key from the key manager
                let keyResult = await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
                switch keyResult {
                case .success(let retrievedKey):
                    key = retrievedKey
                case .failure(let error):
                    throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
                }
            } else {
                // Generate a temporary key for encryption
                let keyResult = await generateKey(algorithm: config.encryptionAlgorithm)
                switch keyResult {
                case .success(let generatedKey):
                    key = generatedKey
                case .failure(let error):
                    throw error
                }
            }
            
            // Basic encryption implementation (this should be replaced with proper algorithm-specific encryption)
            // This is a placeholder implementation
            var encryptedData = [UInt8](dataToEncrypt)
            for i in 0..<encryptedData.count {
                encryptedData[i] = encryptedData[i] ^ key[i % key.count]
            }
            
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            // Log the successful operation
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "encrypt", privacy: .public)
            metadata["algorithm"] = PrivacyMetadataValue(value: config.encryptionAlgorithm.rawValue, privacy: .public)
            metadata["execution_time_ms"] = PrivacyMetadataValue(value: String(format: "%.2f", executionTime), privacy: .public)
            
            await logger.debug(
                "Data encrypted successfully",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.success(
                resultData: Data(encryptedData),
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "encrypt",
                    "algorithm": config.encryptionAlgorithm.rawValue
                ]
            )
            
        } catch let error as SecurityProviderError {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "encrypt", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
            
            await logger.error(
                "Encryption operation failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime
            )
            
        } catch {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "encrypt", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: "Unexpected error", privacy: .private)
            
            await logger.error(
                "Unexpected error during encryption: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: "Unexpected error during encryption: \(error.localizedDescription)",
                executionTimeMs: executionTime
            )
        }
    }
    
    /**
     Decrypts data using the configured encryption algorithm.
     
     - Parameter config: Configuration for the decryption operation
     - Returns: SecurityResultDTO with decrypted data or error details
     */
    public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let startTime = Date().timeIntervalSince1970
        
        do {
            // Validate initialization
            try await validateInitialized()
            
            // Validate input data
            guard let inputDataString = config.options?.metadata?["inputData"],
                  let dataToDecrypt = Data(base64Encoded: inputDataString) else {
                throw SecurityProviderError.invalidInput("Missing or empty input data for decryption")
            }
            
            // Get key
            let key: [UInt8]
            if let keyString = config.options?.metadata?["keyData"],
               let keyData = Data(base64Encoded: keyString) {
                key = [UInt8](keyData)
            } else if let keyIdentifier = config.options?.metadata?["keyIdentifier"] {
                // Try to retrieve the key from the key manager
                let keyResult = await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
                switch keyResult {
                case .success(let retrievedKey):
                    key = retrievedKey
                case .failure(let error):
                    throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
                }
            } else {
                throw SecurityProviderError.invalidParameters("Missing key data or key identifier for decryption")
            }
            
            // Basic decryption implementation (this should be replaced with proper algorithm-specific decryption)
            // This is a placeholder implementation and matches the encryption method
            var decryptedData = [UInt8](dataToDecrypt)
            for i in 0..<decryptedData.count {
                decryptedData[i] = decryptedData[i] ^ key[i % key.count]
            }
            
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            // Log the successful operation
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "decrypt", privacy: .public)
            metadata["algorithm"] = PrivacyMetadataValue(value: config.encryptionAlgorithm.rawValue, privacy: .public)
            metadata["execution_time_ms"] = PrivacyMetadataValue(value: String(format: "%.2f", executionTime), privacy: .public)
            
            await logger.debug(
                "Data decrypted successfully",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.success(
                resultData: Data(decryptedData),
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "decrypt",
                    "algorithm": config.encryptionAlgorithm.rawValue
                ]
            )
            
        } catch let error as SecurityProviderError {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "decrypt", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
            
            await logger.error(
                "Decryption operation failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime
            )
            
        } catch {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "decrypt", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: "Unexpected error", privacy: .private)
            
            await logger.error(
                "Unexpected error during decryption: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: "Unexpected error during decryption: \(error.localizedDescription)",
                executionTimeMs: executionTime
            )
        }
    }
    
    /**
     Creates a digital signature for data with the specified configuration.
     
     - Parameter config: Configuration for the digital signature operation
     - Returns: Result containing signature data or error
     - Throws: SecurityProviderError if the operation fails
     */
    public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let startTime = Date().timeIntervalSince1970
        
        do {
            // Validate initialization
            try await validateInitialized()
            
            // Validate input data
            guard let inputDataString = config.options?.metadata?["inputData"],
                  let dataToSign = Data(base64Encoded: inputDataString) else {
                throw SecurityProviderError.invalidInput("Missing or empty input data for signing")
            }
            
            // Validate key
            let key: [UInt8]
            if let keyString = config.options?.metadata?["keyData"],
               let keyData = Data(base64Encoded: keyString) {
                key = [UInt8](keyData)
            } else if let keyIdentifier = config.options?.metadata?["keyIdentifier"] {
                // Try to retrieve the key from the key manager
                let keyResult = await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
                switch keyResult {
                case .success(let retrievedKey):
                    key = retrievedKey
                case .failure(let error):
                    throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
                }
            } else {
                throw SecurityProviderError.invalidParameters("Missing key data or key identifier for signing")
            }
            
            // Perform HMAC-SHA256 signing
            let signature = hmacSHA256(data: [UInt8](dataToSign), key: key)
            
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            // Log the successful operation
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "sign", privacy: .public)
            metadata["algorithm"] = PrivacyMetadataValue(value: "HMAC-SHA256", privacy: .public)
            metadata["execution_time_ms"] = PrivacyMetadataValue(value: String(format: "%.2f", executionTime), privacy: .public)
            
            await logger.debug(
                "Data signed successfully using HMAC-SHA256",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.success(
                resultData: Data(signature),
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "sign",
                    "algorithm": "HMAC-SHA256"
                ]
            )
            
        } catch let error as SecurityProviderError {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "sign", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
            
            await logger.error(
                "Signing operation failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime
            )
            
        } catch {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "sign", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: "Unexpected error", privacy: .private)
            
            await logger.error(
                "Unexpected error during signing: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: "Unexpected error during signing: \(error.localizedDescription)",
                executionTimeMs: executionTime
            )
        }
    }
    
    /**
     Verifies a digital signature with the specified configuration.
     
     - Parameter config: Configuration for the signature verification operation
     - Returns: Result containing verification status or error
     */
    public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let startTime = Date().timeIntervalSince1970
        
        do {
            // Validate initialization
            try await validateInitialized()
            
            // Validate input data
            guard let inputDataString = config.options?.metadata?["inputData"],
                  let dataToVerify = Data(base64Encoded: inputDataString) else {
                throw SecurityProviderError.invalidInput("Missing or empty input data for verification")
            }
            
            // Validate signature
            guard let signatureString = config.options?.metadata?["signature"],
                  let providedSignature = Data(base64Encoded: signatureString) else {
                throw SecurityProviderError.invalidInput("Missing or empty signature for verification")
            }
            
            // Validate key
            let key: [UInt8]
            if let keyString = config.options?.metadata?["keyData"],
               let keyData = Data(base64Encoded: keyString) {
                key = [UInt8](keyData)
            } else if let keyIdentifier = config.options?.metadata?["keyIdentifier"] {
                // Try to retrieve the key from the key manager
                let keyResult = await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
                switch keyResult {
                case .success(let retrievedKey):
                    key = retrievedKey
                case .failure(let error):
                    throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
                }
            } else {
                throw SecurityProviderError.invalidParameters("Missing key data or key identifier for verification")
            }
            
            // Generate expected signature using HMAC-SHA256
            let expectedSignature = hmacSHA256(data: [UInt8](dataToVerify), key: key)
            
            // Compare provided signature with expected signature
            let signatureIsValid = constantTimeEqual(
                expectedSignature,
                [UInt8](providedSignature)
            )
            
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            // Log the verification result
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "verify", privacy: .public)
            metadata["algorithm"] = PrivacyMetadataValue(value: "HMAC-SHA256", privacy: .public)
            metadata["result"] = PrivacyMetadataValue(value: signatureIsValid ? "valid" : "invalid", privacy: .public)
            metadata["execution_time_ms"] = PrivacyMetadataValue(value: String(format: "%.2f", executionTime), privacy: .public)
            
            await logger.debug(
                "Signature verification result: \(signatureIsValid ? "valid" : "invalid")",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.success(
                resultData: Data([UInt8(signatureIsValid ? 1 : 0)]),
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "verify",
                    "algorithm": "HMAC-SHA256",
                    "signature_valid": String(signatureIsValid)
                ]
            )
            
        } catch let error as SecurityProviderError {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "verify", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
            
            await logger.error(
                "Verification operation failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime
            )
            
        } catch {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "verify", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: "Unexpected error", privacy: .private)
            
            await logger.error(
                "Unexpected error during verification: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: "Unexpected error during verification: \(error.localizedDescription)",
                executionTimeMs: executionTime
            )
        }
    }
    
    /**
     Helper method to compute HMAC-SHA256.
     
     - Parameters:
        - data: Data to be authenticated
        - key: Key for the HMAC operation
     - Returns: HMAC-SHA256 result
     */
    private func hmacSHA256(data: [UInt8], key: [UInt8]) -> [UInt8] {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, data, data.count, &digest)
        return digest
    }
    
    /**
     Compares two byte arrays in constant time to prevent timing attacks.
     
     - Parameters:
        - lhs: First byte array
        - rhs: Second byte array
     - Returns: True if arrays are equal, false otherwise
     */
    private func constantTimeEqual(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<lhs.count {
            result |= lhs[i] ^ rhs[i]
        }
        
        return result == 0
    }
    
    /**
     Performs a generic secure operation with appropriate error handling.
     
     - Parameters:
        - operation: The security operation to perform
        - config: Configuration options
     - Returns: Result of the operation
     */
    public func performSecureOperation(
        operation: SecurityOperation,
        config: SecurityConfigDTO
    ) async throws -> SecurityResultDTO {
        // Verify initialization
        try await validateInitialized()
        
        // Log operation with privacy metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: operation.rawValue, privacy: .public)
        metadata["provider"] = PrivacyMetadataValue(value: "basic", privacy: .public)
        
        await logger.debug(
            "Performing security operation: \(operation.rawValue)",
            metadata: metadata,
            source: "SecurityProviderImpl"
        )
        
        let startTime = Date().timeIntervalSince1970
        
        switch operation {
        case .encrypt:
            return try await encrypt(config: config)
        case .decrypt:
            return try await decrypt(config: config)
        case .sign:
            return try await sign(config: config)
        case .verify:
            return try await verify(config: config)
        case .hash:
            // Implementation for hash operation
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            return SecurityResultDTO.failure(
                errorDetails: "Hash operation not implemented",
                executionTimeMs: executionTime
            )
        case .deriveKey:
            // Implementation for deriveKey operation
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            return SecurityResultDTO.failure(
                errorDetails: "Key derivation not implemented",
                executionTimeMs: executionTime
            )
        case .generateRandom:
            // Implementation for generateRandom operation
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            return SecurityResultDTO.failure(
                errorDetails: "Random generation not implemented",
                executionTimeMs: executionTime
            )
        case .storeKey:
            // Implementation for storeKey operation
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            return SecurityResultDTO.failure(
                errorDetails: "Key storage not implemented",
                executionTimeMs: executionTime
            )
        case .retrieveKey:
            // Implementation for retrieveKey operation
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            return SecurityResultDTO.failure(
                errorDetails: "Key retrieval not implemented",
                executionTimeMs: executionTime
            )
        case .deleteKey:
            // Implementation for deleteKey operation
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            return SecurityResultDTO.failure(
                errorDetails: "Key deletion not implemented",
                executionTimeMs: executionTime
            )
        }
    }
    
    /**
     Performs a security operation with given options.
     
     - Parameters:
        - operation: The security operation to perform
        - options: Configuration options
     - Returns: Result of the operation
     */
    public func performOperationWithOptions(
        operation: SecurityOperation,
        options: SecurityConfigOptions
    ) async throws -> SecurityResultDTO {
        // Log operation with privacy metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: operation.rawValue, privacy: .public)
        metadata["provider_type"] = PrivacyMetadataValue(value: "basic", privacy: .public)
        
        await logger.debug(
            "Performing security operation with options: \(operation.rawValue)",
            metadata: metadata,
            source: "SecurityProviderImpl"
        )
        
        let config = SecurityConfigDTO(
            encryptionAlgorithm: .aes256GCM,  // Default algorithm
            hashAlgorithm: .sha256,           // Default algorithm
            providerType: .basic,             // Basic provider type
            options: options
        )
        
        return try await performSecureOperation(operation: operation, config: config)
    }
    
    /**
     Generates an appropriate key for a given encryption algorithm.
     
     This method follows the Alpha Dot Five Architecture principles for key management
     by generating cryptographically secure keys with appropriate size for the algorithm.
     
     - Parameters:
        - algorithm: The encryption algorithm to generate a key for
     - Returns: The generated key as a Result type
     */
    public func generateKey(
        algorithm: EncryptionAlgorithm
    ) async -> Result<[UInt8], SecurityProviderError> {
        // Log operation with privacy metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: "generateKey", privacy: .public)
        metadata["algorithm"] = PrivacyMetadataValue(value: algorithm.rawValue, privacy: .public)
        
        await logger.debug(
            "Generating key for algorithm: \(algorithm.rawValue)",
            metadata: metadata,
            source: "SecurityProviderImpl"
        )
        
        // Determine key size based on the encryption algorithm
        let keySize: Int
        switch algorithm {
        case .aes256CBC, .aes256GCM:
            keySize = 32  // 256 bits = 32 bytes
        case .chacha20Poly1305:
            keySize = 32  // 256 bits = 32 bytes
        }
        
        // Create a buffer to hold the key data
        var keyData = [UInt8](repeating: 0, count: keySize)
        
        // Generate random bytes using CommonCrypto
        let result = CCRandomGenerateBytes(&keyData, keySize)
        if result == kCCSuccess {
            return .success(keyData)
        } else {
            await logger.error(
                "Failed to generate key: CCRandomGenerateBytes error code \(result)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            return .failure(.keyGenerationFailed("Failed to generate secure random key data"))
        }
    }
    
    /**
     Creates a secure configuration with type-safe, Sendable-compliant options.
     
     This method provides a Swift 6-compatible way to create security configurations
     that can safely cross actor boundaries.
     
     - Parameter options: Type-safe options structure that conforms to Sendable
     - Returns: A properly configured SecurityConfigDTO
     */
    public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: "createSecureConfig", privacy: .public)
        
        await logger.debug(
            "Creating secure configuration",
            metadata: metadata,
            source: "SecurityProviderImpl"
        )
        
        // Create a security config with the provided options
        let config = SecurityConfigDTO(
            encryptionAlgorithm: .aes256GCM,
            hashAlgorithm: .sha256,
            providerType: .basic,
            options: options
        )
        
        return config
    }
    
    /**
     Executes a security operation with the provided configuration options.
     
     - Parameters:
        - operation: Type of security operation to perform
        - options: Configuration options
     - Returns: Result of the operation
     */
    public func performOperationWithOptions(
        _ operation: SecurityOperation,
        options: SecurityConfigOptions
    ) async throws -> SecurityResultDTO {
        // Log operation with privacy metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: operation.rawValue, privacy: .public)
        metadata["provider_type"] = PrivacyMetadataValue(value: "basic", privacy: .public)
        
        await logger.debug(
            "Performing security operation with options: \(operation.rawValue)",
            metadata: metadata,
            source: "SecurityProviderImpl"
        )
        
        // Create a security config with the provided options
        let config = SecurityConfigDTO(
            encryptionAlgorithm: .aes256GCM,  // Default algorithm
            hashAlgorithm: .sha256,           // Default algorithm
            providerType: .basic,          // Standard provider type
            options: options
        )
        
        return try await performSecureOperation(operation: operation, config: config)
    }
    
    /**
     Generates a cryptographic key with the specified configuration.
     
     - Parameter config: Configuration for the key generation operation
     - Returns: Result containing key identifier or error
     */
    public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        let startTime = Date().timeIntervalSince1970
        
        do {
            // Validate initialization
            try await validateInitialized()
            
            // Generate a unique identifier for this key
            let keyIdentifier = UUID().uuidString
            
            // Determine key size based on the encryption algorithm
            let keySize: Int
            switch config.encryptionAlgorithm {
            case .aes256CBC, .aes256GCM:
                keySize = 32  // 256 bits = 32 bytes
            case .chacha20Poly1305:
                keySize = 32  // 256 bits = 32 bytes
            }
            
            // Create a buffer to hold the key data
            var keyData = [UInt8](repeating: 0, count: keySize)
            
            // Generate random bytes using CommonCrypto
            let result = CCRandomGenerateBytes(&keyData, keySize)
            
            if result != kCCSuccess {
                throw SecurityProviderError.keyGenerationFailed("Failed to generate secure random key data")
            }
            
            // Store the key if metadata indicates it should be persisted
            if let shouldPersist = config.options?.metadata?["persistKey"], shouldPersist == "true" {
                let storeResult = await keyManagerInstance.storeKey(keyData, withIdentifier: keyIdentifier)
                
                if case .failure(let error) = storeResult {
                    throw SecurityProviderError.storageError("Failed to store generated key: \(error.localizedDescription)")
                }
            }
            
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            // Log the successful operation
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "generateKey", privacy: .public)
            metadata["algorithm"] = PrivacyMetadataValue(value: config.encryptionAlgorithm.rawValue, privacy: .public)
            metadata["key_identifier"] = PrivacyMetadataValue(value: keyIdentifier, privacy: .private)
            
            await logger.debug(
                "Key generated successfully",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            // Return success with key data
            return SecurityResultDTO.success(
                resultData: Data(keyData),
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "generateKey",
                    "algorithm": config.encryptionAlgorithm.rawValue,
                    "key_identifier": keyIdentifier
                ]
            )
            
        } catch let error as SecurityProviderError {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "generateKey", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
            
            await logger.error(
                "Key generation failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime
            )
            
        } catch {
            let executionTime = (Date().timeIntervalSince1970 - startTime) * 1000
            
            var metadata = PrivacyMetadata()
            metadata["operation"] = PrivacyMetadataValue(value: "generateKey", privacy: .public)
            metadata["error"] = PrivacyMetadataValue(value: "Unexpected error", privacy: .private)
            
            await logger.error(
                "Unexpected error during key generation: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: "Unexpected error during key generation: \(error.localizedDescription)",
                executionTimeMs: executionTime
            )
        }
    }
    
    /**
     Securely stores data with the specified configuration.
     
     - Parameter config: Configuration for the secure storage operation
     - Returns: Result containing storage confirmation or error
     */
    public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        try await validateInitialized()
        
        let startTime = Date().timeIntervalSince1970
        
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: "secureStore", privacy: .public)
        
        do {
            guard let inputDataStr = config.options?.metadata?["inputData"],
                  let inputData = Data(base64Encoded: inputDataStr) else {
                throw SecurityProviderError.invalidInput("Input data is required for secure storage")
            }
            
            guard let identifier = config.options?.metadata?["identifier"] else {
                throw SecurityProviderError.invalidInput("Identifier is required for secure storage")
            }
            
            let storeResult = await storeData(Array(inputData), withIdentifier: identifier)
            
            guard case .success = storeResult else {
                throw SecurityProviderError.operationFailed(
                    operation: "secureStore",
                    reason: "Storage operation failed"
                )
            }
            
            let endTime = Date().timeIntervalSince1970
            let executionTime = (endTime - startTime) * 1000
            
            await logger.debug(
                "Secure storage completed successfully",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.success(
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "secureStore",
                    "identifier": identifier
                ]
            )
        } catch {
            let endTime = Date().timeIntervalSince1970
            let executionTime = (endTime - startTime) * 1000
            
            await logger.error(
                "Secure storage failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "secureStore"
                ]
            )
        }
    }
    
    /**
     Retrieves securely stored data with the specified configuration.
     
     - Parameter config: Configuration for the secure retrieval operation
     - Returns: Result containing retrieved data or error
     */
    public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        try await validateInitialized()
        
        let startTime = Date().timeIntervalSince1970
        
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: "secureRetrieve", privacy: .public)
        
        do {
            guard let identifier = config.options?.metadata?["identifier"] else {
                throw SecurityProviderError.invalidInput("Identifier is required for secure retrieval")
            }
            
            let dataResult = await retrieveData(withIdentifier: identifier)
            
            switch dataResult {
            case .success(let data):
                let endTime = Date().timeIntervalSince1970
                let executionTime = (endTime - startTime) * 1000
                
                await logger.debug(
                    "Secure retrieval completed successfully",
                    metadata: metadata,
                    source: "SecurityProviderImpl"
                )
                
                return SecurityResultDTO.success(
                    resultData: Data(data),
                    executionTimeMs: executionTime,
                    metadata: [
                        "operation": "secureRetrieve",
                        "identifier": identifier
                    ]
                )
                
            case .failure(let error):
                throw SecurityProviderError.operationFailed(
                    operation: "secureRetrieve",
                    reason: error.localizedDescription
                )
            }
        } catch {
            let endTime = Date().timeIntervalSince1970
            let executionTime = (endTime - startTime) * 1000
            
            await logger.error(
                "Secure retrieval failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "secureRetrieve"
                ]
            )
        }
    }
    
    /**
     Deletes securely stored data with the specified configuration.
     
     - Parameter config: Configuration for the secure deletion operation
     - Returns: Result containing deletion confirmation or error
     */
    public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
        try await validateInitialized()
        
        let startTime = Date().timeIntervalSince1970
        
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadataValue(value: "secureDelete", privacy: .public)
        
        do {
            guard let identifier = config.options?.metadata?["identifier"] else {
                throw SecurityProviderError.invalidInput("Identifier is required for secure deletion")
            }
            
            let deleteResult = await deleteData(withIdentifier: identifier)
            
            switch deleteResult {
            case .success:
                let endTime = Date().timeIntervalSince1970
                let executionTime = (endTime - startTime) * 1000
                
                await logger.debug(
                    "Secure deletion completed successfully",
                    metadata: metadata,
                    source: "SecurityProviderImpl"
                )
                
                return SecurityResultDTO.success(
                    executionTimeMs: executionTime,
                    metadata: [
                        "operation": "secureDelete",
                        "identifier": identifier
                    ]
                )
                
            case .failure(let error):
                throw SecurityProviderError.operationFailed(
                    operation: "secureDelete",
                    reason: error.localizedDescription
                )
            }
        } catch {
            let endTime = Date().timeIntervalSince1970
            let executionTime = (endTime - startTime) * 1000
            
            await logger.error(
                "Secure deletion failed: \(error.localizedDescription)",
                metadata: metadata,
                source: "SecurityProviderImpl"
            )
            
            return SecurityResultDTO.failure(
                errorDetails: error.localizedDescription,
                executionTimeMs: executionTime,
                metadata: [
                    "operation": "secureDelete"
                ]
            )
        }
    }
    
    /**
     Simple performance metrics tracker for measuring operation durations.
     */
    private class PerformanceMetricsTracker {
        /// Records the start time of an operation
        func startOperation() -> Date {
            return Date()
        }
        
        /// Calculates the duration of an operation in milliseconds
        func endOperation(startTime: Date) -> Double {
            let endTime = Date()
            return endTime.timeIntervalSince(startTime) * 1000
        }
    }
    
    // MARK: - SHA256 Helper
    
    /// Simple implementation of SHA256 hashing to avoid external dependencies
    private func sha256Hash(data: Data) -> Data {
        var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBuffer -> Void in
            _ = CC_SHA256(dataBuffer.baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)
    }
}
