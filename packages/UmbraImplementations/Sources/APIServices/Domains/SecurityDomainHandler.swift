import APIInterfaces
import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import UmbraErrors
import ErrorCoreTypes

/**
 # Security Domain Handler
 
 Handles security-related API operations within the Alpha Dot Five architecture.
 This implementation provides secure operations for encryption, decryption,
 key management, and secure storage with proper privacy controls.
 
 ## Privacy-Enhanced Logging
 
 All operations are logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.
 
 ## Thread Safety
 
 Operations are thread-safe by leveraging Swift's structured concurrency model
 and actor-based isolation where appropriate.
 
 ## Memory Protection
 
 Security operations include memory protection to prevent data leakage.
 */
public struct SecurityDomainHandler: DomainHandler {
    /// Security service for cryptographic operations
    private let securityService: any SecurityProviderProtocol
    
    /// Logger with privacy controls
    private let logger: LoggingProtocol?
    
    /**
     Initialises a new security domain handler.
     
     - Parameters:
        - service: The security service for cryptographic operations
        - logger: Optional logger for privacy-aware operation recording
     */
    public init(service: any SecurityProviderProtocol, logger: LoggingProtocol? = nil) {
        self.securityService = service
        self.logger = logger
    }
    
    /**
     Executes a security operation and returns its result.
     
     - Parameter operation: The operation to execute
     - Returns: The result of the operation
     - Throws: APIError if the operation fails
     */
    public func execute<T: APIOperation>(_ operation: T) async throws -> Any {
        // Log the operation start with privacy-aware metadata
        let operationName = String(describing: type(of: operation))
        let startMetadata = PrivacyMetadata([
            "operation": PrivacyMetadata.Entry(value: operationName, privacy: .public),
            "event": PrivacyMetadata.Entry(value: "start", privacy: .public)
        ])
        
        await logger?.info(
            "Starting security operation",
            metadata: startMetadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Execute the appropriate operation based on type
            let result = try await executeSecurityOperation(operation)
            
            // Log success
            let successMetadata = PrivacyMetadata([
                "operation": PrivacyMetadata.Entry(value: operationName, privacy: .public),
                "event": PrivacyMetadata.Entry(value: "success", privacy: .public),
                "status": PrivacyMetadata.Entry(value: "completed", privacy: .public)
            ])
            
            await logger?.info(
                "Security operation completed successfully",
                metadata: successMetadata,
                source: "SecurityDomainHandler"
            )
            
            return result
        } catch {
            // Log failure with privacy-aware error details
            let errorMetadata = PrivacyMetadata([
                "operation": PrivacyMetadata.Entry(value: operationName, privacy: .public),
                "event": PrivacyMetadata.Entry(value: "failure", privacy: .public),
                "status": PrivacyMetadata.Entry(value: "failed", privacy: .public),
                "error": PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            ])
            
            await logger?.error(
                "Security operation failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to appropriate API error and rethrow
            throw mapToAPIError(error)
        }
    }
    
    /**
     Determines if this handler supports the given operation.
     
     - Parameter operation: The operation to check support for
     - Returns: true if the operation is supported, false otherwise
     */
    public func supports(_ operation: some APIOperation) -> Bool {
        operation is any SecurityAPIOperation
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Routes the operation to the appropriate handler method based on its type.
     
     - Parameter operation: The operation to execute
     - Returns: The result of the operation
     - Throws: APIError if the operation fails or is unsupported
     */
    private func executeSecurityOperation<T: APIOperation>(_ operation: T) async throws -> Any {
        switch operation {
        case let op as EncryptDataOperation:
            return try await handleEncryptData(op)
        case let op as DecryptDataOperation:
            return try await handleDecryptData(op)
        case let op as GenerateKeyOperation:
            return try await handleGenerateKey(op)
        case let op as RetrieveKeyOperation:
            return try await handleRetrieveKey(op)
        case let op as StoreKeyOperation:
            return try await handleStoreKey(op)
        case let op as DeleteKeyOperation:
            return try await handleDeleteKey(op)
        case let op as HashDataOperation:
            return try await handleHashData(op)
        case let op as StoreSecretOperation:
            return try await handleStoreSecret(op)
        case let op as RetrieveSecretOperation:
            return try await handleRetrieveSecret(op)
        case let op as DeleteSecretOperation:
            return try await handleDeleteSecret(op)
        default:
            throw APIError.operationNotSupported(
                message: "Unsupported security operation: \(type(of: operation))",
                code: "SECURITY_OPERATION_NOT_SUPPORTED"
            )
        }
    }
    
    /**
     Maps domain-specific errors to standardised API errors.
     
     - Parameter error: The original error
     - Returns: An APIError instance
     */
    private func mapToAPIError(_ error: Error) -> APIError {
        // If it's already an APIError, return it
        if let apiError = error as? APIError {
            return apiError
        }
        
        // Handle specific security error types
        if let secError = error as? SecurityError {
            switch secError {
            case .invalidInput(let message):
                return APIError.validationFailed(
                    message: message,
                    code: "SECURITY_VALIDATION_FAILED"
                )
            case .cryptographicError(let message):
                return APIError.securityViolation(
                    message: message,
                    code: "CRYPTOGRAPHIC_ERROR"
                )
            case .keyNotFound(let message):
                return APIError.resourceNotFound(
                    message: message,
                    code: "KEY_NOT_FOUND"
                )
            case .permissionDenied(let message):
                return APIError.permissionDenied(
                    message: message,
                    code: "SECURITY_PERMISSION_DENIED"
                )
            case .operationFailed(let message):
                return APIError.operationFailed(
                    message: message,
                    code: "SECURITY_OPERATION_FAILED",
                    underlyingError: secError
                )
            }
        }
        
        // Default to a generic operation failed error
        return APIError.operationFailed(
            message: error.localizedDescription,
            code: "SECURITY_ERROR",
            underlyingError: error
        )
    }
    
    // MARK: - Operation Handlers
    
    /**
     Handles data encryption operations.
     
     - Parameter operation: The encrypt data operation
     - Returns: An encryption result with the encrypted data and optionally a key identifier
     - Throws: SecurityError if encryption fails
     */
    private func handleEncryptData(_ operation: EncryptDataOperation) async throws -> APIInterfaces.EncryptionResult {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "encrypt", privacy: .public)
        if let algorithm = operation.algorithm {
            metadata["algorithm"] = PrivacyMetadata.Entry(value: algorithm, privacy: .public)
        }
        
        // Log the operation with privacy controls
        await logger?.info(
            "Encrypting data",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Create encryption configuration from operation parameters
            let algorithm: EncryptionAlgorithm = try getAlgorithm(from: operation.algorithm)
            let options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: operation.options
            )
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: algorithm,
                hashAlgorithm: .sha256, // Default hash algorithm
                providerType: .system,
                options: options
            )
            
            // Perform the encryption operation in a secure context
            var securityOperation: SecurityOperation
            if let key = operation.key {
                // Use provided key
                let encryptOperation = SecurityOperation.encrypt(
                    data: operation.data,
                    key: key.toBytes(),
                    algorithm: algorithm
                )
                securityOperation = encryptOperation
            } else {
                // Generate a key
                let encryptWithNewKeyOperation = SecurityOperation.encryptWithGeneratedKey(
                    data: operation.data,
                    algorithm: algorithm
                )
                securityOperation = encryptWithNewKeyOperation
            }
            
            // Execute the operation
            let result = try await securityService.performSecureOperation(
                securityOperation,
                config: config
            )
            
            // Process the result
            guard let encryptResult = result as? CoreSecurityTypes.EncryptionResult else {
                throw SecurityError.operationFailed("Invalid result type returned from encryption operation")
            }
            
            var keyIdentifier: String? = nil
            
            // Store the key if requested
            if operation.storeKey, let key = encryptResult.key {
                let keyID = operation.keyIdentifier ?? UUID().uuidString
                try await securityService.storeSecureKey(key, withIdentifier: keyID)
                keyIdentifier = keyID
            }
            
            // Map to the API result type
            return APIInterfaces.EncryptionResult(
                encryptedData: SendableCryptoMaterial(encryptResult.ciphertext),
                keyIdentifier: keyIdentifier
            )
        } catch {
            // Log the failure with privacy-aware error details
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Encryption failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else {
                throw SecurityError.cryptographicError("Encryption failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles data decryption operations.
     
     - Parameter operation: The decrypt data operation
     - Returns: The decrypted data
     - Throws: SecurityError if decryption fails
     */
    private func handleDecryptData(_ operation: DecryptDataOperation) async throws -> Data {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "decrypt", privacy: .public)
        if let keyID = operation.keyIdentifier {
            metadata["key_id"] = PrivacyMetadata.Entry(value: keyID, privacy: .public)
        }
        
        // Log the operation with privacy controls
        await logger?.info(
            "Decrypting data",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Get the decryption key
            let decryptionKey: Data?
            if let key = operation.key {
                decryptionKey = key
            } else if let keyID = operation.keyIdentifier {
                decryptionKey = try await securityService.retrieveKey(withIdentifier: keyID)
            } else {
                throw SecurityError.invalidInput("No decryption key or key identifier provided")
            }
            
            // Ensure we have a key
            guard let key = decryptionKey else {
                throw SecurityError.keyNotFound("Decryption key not found")
            }
            
            // Create configuration
            let options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: operation.options
            )
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: .aes256GCM, // Default to AES-GCM
                hashAlgorithm: .sha256,
                providerType: .system,
                options: options
            )
            
            // Perform the decryption
            let securityOperation = SecurityOperation.decrypt(
                encryptedData: operation.encryptedData.toBytes(),
                key: key,
                algorithm: .aes256GCM  // Default to AES-GCM since we don't know the specific algorithm
            )
            
            let result = try await securityService.performSecureOperation(
                securityOperation,
                config: config
            )
            
            // Process the result
            guard let decryptedData = result as? Data else {
                throw SecurityError.operationFailed("Invalid result type returned from decryption operation")
            }
            
            return decryptedData
        } catch {
            // Log the failure with privacy-aware error details
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Decryption failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else {
                throw SecurityError.cryptographicError("Decryption failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles key generation operations.
     
     - Parameter operation: The generate key operation
     - Returns: A key generation result with the key and its identifier
     - Throws: SecurityError if key generation fails
     */
    private func handleGenerateKey(_ operation: GenerateKeyOperation) async throws -> KeyGenerationResult {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "generateKey", privacy: .public)
        metadata["length"] = PrivacyMetadata.Entry(value: operation.keyLength?.description ?? "default", privacy: .public)
        if let algorithm = operation.algorithm {
            metadata["algorithm"] = PrivacyMetadata.Entry(value: algorithm, privacy: .public)
        }
        
        // Log the operation
        await logger?.info(
            "Generating cryptographic key",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Create configuration
            let algorithm: EncryptionAlgorithm = try getAlgorithm(from: operation.algorithm)
            var options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: operation.options ?? [:]
            )
            
            if let keyLength = operation.keyLength {
                // Create new options with keyLength included
                options = SecurityConfigOptions(
                    enableDetailedLogging: options.enableDetailedLogging,
                    keyDerivationIterations: options.keyDerivationIterations,
                    memoryLimitBytes: options.memoryLimitBytes,
                    useHardwareAcceleration: options.useHardwareAcceleration,
                    operationTimeoutSeconds: options.operationTimeoutSeconds,
                    verifyOperations: options.verifyOperations,
                    metadata: ["keyLength": keyLength]
                )
            }
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: algorithm,
                hashAlgorithm: .sha256,
                providerType: .system,
                options: options
            )
            
            // Generate the key
            let securityOperation = SecurityOperation.generateKey(
                algorithm: algorithm,
                keyLength: operation.keyLength ?? 256,
                keyType: operation.keyType
            )
            
            let result = try await securityService.performSecureOperation(
                operation: securityOperation,
                config: config
            )
            
            // Process the result
            guard let key = result as? Data else {
                throw SecurityError.operationFailed("Invalid result type returned from key generation operation")
            }
            
            var keyIdentifier: String? = nil
            
            // Store the key if requested
            if operation.storeKey {
                let keyID = operation.keyIdentifier ?? UUID().uuidString
                let keyManager = await securityService.keyManager()
                let storeResult = await keyManager.storeKey(Array(key), withIdentifier: keyID)
                
                switch storeResult {
                case .success:
                    keyIdentifier = keyID
                case .failure(let error):
                    throw SecurityError.keyStorageError(error.localizedDescription)
                }
            }
            
            // Create the result
            return KeyGenerationResult(
                key: SendableCryptoMaterial(key),
                keyIdentifier: keyIdentifier
            )
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Key generation failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else {
                throw SecurityError.cryptographicError("Key generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles key retrieval operations.
     
     - Parameter operation: The retrieve key operation
     - Returns: The retrieved cryptographic key
     - Throws: SecurityError if key retrieval fails
     */
    private func handleRetrieveKey(_ operation: RetrieveKeyOperation) async throws -> SendableCryptoMaterial {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "retrieveKey", privacy: .public)
        metadata["key_id"] = PrivacyMetadata.Entry(value: operation.keyIdentifier, privacy: .public)
        
        // Log the operation
        await logger?.info(
            "Retrieving cryptographic key",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Retrieve the key
            let keyManager = await securityService.keyManager()
            let retrieveResult = await keyManager.retrieveKey(withIdentifier: operation.keyIdentifier)
            
            switch retrieveResult {
            case .success(let keyData):
                return SendableCryptoMaterial(Data(keyData))
            case .failure(let error):
                throw SecurityError.keyNotFound("Key not found for identifier: \(operation.keyIdentifier). Error: \(error.localizedDescription)")
            }
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Key retrieval failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else if (error as NSError).domain == NSOSStatusErrorDomain {
                throw SecurityError.keyNotFound("Key not found or access denied: \(error.localizedDescription)")
            } else {
                throw SecurityError.operationFailed("Key retrieval failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles key storage operations.
     
     - Parameter operation: The store key operation
     - Returns: The key identifier
     - Throws: SecurityError if key storage fails
     */
    private func handleStoreKey(_ operation: StoreKeyOperation) async throws -> String {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "storeKey", privacy: .public)
        if let keyID = operation.keyIdentifier {
            metadata["key_id"] = PrivacyMetadata.Entry(value: keyID, privacy: .public)
        }
        
        // Log the operation
        await logger?.info(
            "Storing cryptographic key",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Generate key identifier if needed
            let keyIdentifier = operation.keyIdentifier ?? UUID().uuidString
            
            // Store the key
            let keyManager = await securityService.keyManager()
            let storeResult = await keyManager.storeKey(Array(operation.key.rawData), withIdentifier: keyIdentifier)
            
            switch storeResult {
            case .success:
                return keyIdentifier
            case .failure(let error):
                throw SecurityError.keyStorageError(error.localizedDescription)
            }
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Key storage failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else {
                throw SecurityError.operationFailed("Key storage failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles key deletion operations.
     
     - Parameter operation: The delete key operation
     - Returns: A boolean indicating successful deletion
     - Throws: SecurityError if key deletion fails
     */
    private func handleDeleteKey(_ operation: DeleteKeyOperation) async throws -> Bool {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "deleteKey", privacy: .public)
        metadata["key_id"] = PrivacyMetadata.Entry(value: operation.keyIdentifier, privacy: .public)
        
        // Log the operation
        await logger?.info(
            "Deleting cryptographic key",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Delete the key
            let keyManager = await securityService.keyManager()
            let deleteResult = await keyManager.deleteKey(withIdentifier: operation.keyIdentifier)
            
            switch deleteResult {
            case .success:
                return true
            case .failure(let error):
                throw SecurityError.operationFailed("Failed to delete key: \(error.localizedDescription)")
            }
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Key deletion failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else if (error as NSError).domain == NSOSStatusErrorDomain {
                // If keychain item not found, consider it a success (idempotent delete)
                return true
            } else {
                throw SecurityError.operationFailed("Key deletion failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles data hashing operations.
     
     - Parameter operation: The hash data operation
     - Returns: The hash result
     - Throws: SecurityError if hashing fails
     */
    private func handleHashData(_ operation: HashDataOperation) async throws -> SendableCryptoMaterial {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "hashData", privacy: .public)
        if let algorithm = operation.algorithm {
            metadata["algorithm"] = PrivacyMetadata.Entry(value: algorithm, privacy: .public)
        }
        
        // Log the operation
        await logger?.info(
            "Hashing data",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Determine hash algorithm
            let hashAlgorithm = try getHashAlgorithm(from: operation.algorithm)
            
            // Create configuration
            let options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: operation.options
            )
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: .aes256GCM, // Not used for hashing
                hashAlgorithm: hashAlgorithm,
                providerType: .system,
                options: options
            )
            
            // Perform the hash operation
            let securityOperation = SecurityOperation.hash(
                data: operation.data.rawData,
                algorithm: hashAlgorithm
            )
            let result = try await securityService.performSecureOperation(
                operation: securityOperation,
                config: config
            )
            
            // Process the result
            guard let hashData = result as? Data else {
                throw SecurityError.operationFailed("Invalid result type returned from hash operation")
            }
            
            return SendableCryptoMaterial(bytes: hashData)
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Hash operation failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else {
                throw SecurityError.cryptographicError("Hash operation failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles secure secret storage operations.
     
     - Parameter operation: The store secret operation
     - Returns: The secret identifier
     - Throws: SecurityError if secret storage fails
     */
    private func handleStoreSecret(_ operation: StoreSecretOperation) async throws -> String {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "storeSecret", privacy: .public)
        if let secretID = operation.identifier {
            metadata["secret_id"] = PrivacyMetadata.Entry(value: secretID, privacy: .public)
        }
        metadata["service"] = PrivacyMetadata.Entry(value: operation.service, privacy: .public)
        
        // Log the operation
        await logger?.info(
            "Storing secret",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Generate identifier if needed
            let secretIdentifier = operation.identifier ?? UUID().uuidString
            
            // Create storage options
            var options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: operation.options
            )
            
            if let accessibility = operation.accessibility {
                // Create new options with accessibility included
                options = SecurityConfigOptions(
                    enableDetailedLogging: options.enableDetailedLogging,
                    keyDerivationIterations: options.keyDerivationIterations,
                    memoryLimitBytes: options.memoryLimitBytes,
                    useHardwareAcceleration: options.useHardwareAcceleration,
                    operationTimeoutSeconds: options.operationTimeoutSeconds,
                    verifyOperations: options.verifyOperations,
                    metadata: ["accessibility": accessibility]
                )
            }
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: .aes256GCM, // Default encryption
                hashAlgorithm: .sha256,
                providerType: .system,
                options: options
            )
            
            // Store the secret
            try await securityService.storeSecureSecret(
                operation.data.rawData,
                withIdentifier: secretIdentifier,
                service: operation.service,
                account: operation.account,
                config: config
            )
            
            return secretIdentifier
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Secret storage failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else {
                throw SecurityError.operationFailed("Secret storage failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles secure secret retrieval operations.
     
     - Parameter operation: The retrieve secret operation
     - Returns: The retrieved secret data
     - Throws: SecurityError if secret retrieval fails
     */
    private func handleRetrieveSecret(_ operation: RetrieveSecretOperation) async throws -> SendableCryptoMaterial {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "retrieveSecret", privacy: .public)
        metadata["secret_id"] = PrivacyMetadata.Entry(value: operation.identifier, privacy: .public)
        metadata["service"] = PrivacyMetadata.Entry(value: operation.service, privacy: .public)
        
        // Log the operation
        await logger?.info(
            "Retrieving secret",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Create configuration
            let options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: operation.options
            )
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: .aes256GCM, // Not used for retrieval
                hashAlgorithm: .sha256,
                providerType: .system,
                options: options
            )
            
            // Retrieve the secret
            let secretData = try await securityService.retrieveSecureSecret(
                withIdentifier: operation.identifier,
                service: operation.service,
                account: operation.account,
                config: config
            )
            
            // Return not nil if data was retrieved successfully
            guard let data = secretData else {
                throw SecurityError.secretNotFound("Secret not found: \(operation.identifier)")
            }
            
            return SendableCryptoMaterial(bytes: data)
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Secret retrieval failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else if (error as NSError).domain == NSOSStatusErrorDomain {
                throw SecurityError.keyNotFound("Secret not found or access denied: \(error.localizedDescription)")
            } else {
                throw SecurityError.operationFailed("Secret retrieval failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Handles secure secret deletion operations.
     
     - Parameter operation: The delete secret operation
     - Returns: A boolean indicating successful deletion
     - Throws: SecurityError if secret deletion fails
     */
    private func handleDeleteSecret(_ operation: DeleteSecretOperation) async throws -> Bool {
        // Create privacy-aware logging metadata
        var metadata = PrivacyMetadata()
        metadata["operation"] = PrivacyMetadata.Entry(value: "deleteSecret", privacy: .public)
        metadata["secret_id"] = PrivacyMetadata.Entry(value: operation.identifier, privacy: .public)
        metadata["service"] = PrivacyMetadata.Entry(value: operation.service, privacy: .public)
        
        // Log the operation
        await logger?.info(
            "Deleting secret",
            metadata: metadata,
            source: "SecurityDomainHandler"
        )
        
        do {
            // Create configuration
            let options = SecurityConfigOptions(
                enableDetailedLogging: false,
                keyDerivationIterations: 100_000,
                memoryLimitBytes: 65536,
                useHardwareAcceleration: true,
                operationTimeoutSeconds: 30.0,
                verifyOperations: true,
                metadata: [:]
            )
            
            let config = SecurityConfigDTO(
                encryptionAlgorithm: .aes256GCM, // Not used for deletion
                hashAlgorithm: .sha256,
                providerType: .system,
                options: options
            )
            
            // Delete the secret
            try await securityService.deleteSecureSecret(
                withIdentifier: operation.identifier,
                service: operation.service,
                account: operation.account,
                config: config
            )
            
            // Check if the secret was deleted successfully
            let stillExists = (try? await securityService.retrieveSecureSecret(
                withIdentifier: operation.identifier,
                service: operation.service,
                account: operation.account,
                config: config
            )) != nil
            
            if stillExists {
                throw SecurityError.operationFailed("Failed to delete secret: \(operation.identifier)")
            }
            
            return true
        } catch {
            // Log the failure
            var errorMetadata = metadata
            errorMetadata["error"] = PrivacyMetadata.Entry(value: error.localizedDescription, privacy: .private)
            
            await logger?.error(
                "Secret deletion failed",
                metadata: errorMetadata,
                source: "SecurityDomainHandler"
            )
            
            // Map to domain-specific error
            if let secError = error as? SecurityError {
                throw secError
            } else if (error as NSError).domain == NSOSStatusErrorDomain {
                // If keychain item not found, consider it a success (idempotent delete)
                return true
            } else {
                throw SecurityError.operationFailed("Secret deletion failed: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Maps the correct hash algorithm based on string input
     - Parameter algorithmString: String identifier of the algorithm
     - Returns: The corresponding CoreSecurityTypes.HashAlgorithm
     - Throws: SecurityError if the algorithm is invalid or unsupported
     */
    private func getHashAlgorithm(from algorithmString: String?) throws -> CoreSecurityTypes.HashAlgorithm {
        guard let algorithmStr = algorithmString else {
            return .sha256 // Default algorithm
        }
        
        switch algorithmStr.lowercased() {
        case "sha1", "sha-1":
            return .sha1
        case "sha256", "sha-256":
            return .sha256
        case "sha384", "sha-384":
            return .sha384
        case "sha512", "sha-512":
            return .sha512
        case "md5":
            // MD5 is supported but not recommended for security-critical applications
            // Since MD5 is not in the HashAlgorithm enum, we'll use SHA1 as the closest alternative
            // with a warning
            logger?.warning("MD5 hash algorithm requested but not supported, falling back to SHA1", metadata: nil)
            return .sha1
        default:
            throw SecurityError.invalidInput("Unsupported hash algorithm: \(algorithmString ?? "nil")")
        }
    }
}

/**
 Security error types for domain-specific error handling.
 */
private enum SecurityError: Error, LocalizedError {
    case invalidInput(String)
    case cryptographicError(String)
    case keyNotFound(String)
    case permissionDenied(String)
    case operationFailed(String)
    case secretNotFound(String)
    case keyStorageError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message),
             .cryptographicError(let message),
             .keyNotFound(let message),
             .permissionDenied(let message),
             .operationFailed(let message),
             .secretNotFound(let message),
             .keyStorageError(let message):
            return message
        }
    }
}
