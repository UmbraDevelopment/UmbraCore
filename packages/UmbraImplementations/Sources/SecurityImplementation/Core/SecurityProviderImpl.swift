import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import LoggingInterfaces

/**
 # SecurityProviderImpl
 
 This actor implements the SecurityProviderProtocol and provides thread-safe operations
 for encryption, decryption, key management, secure storage, and digital signatures.
 
 ## Actor Design
 
 The implementation uses the actor model to ensure thread safety, providing isolation
 for operations that modify shared state. This eliminates the need for explicit locks
 or synchronisation mechanisms.
 
 ## Dependencies
 
 - CryptoServiceProtocol: Handles cryptographic operations
 - KeyManagementProtocol: Manages cryptographic keys
 - LoggerProtocol: Provides logging capabilities
 */
public actor SecurityProviderImpl: SecurityProviderProtocol {
    // MARK: - Dependencies
    
    private let cryptoService: CryptoServiceProtocol
    private let keyManager: KeyManagementProtocol
    internal let logger: LoggerProtocol
    
    // MARK: - Properties
    
    /// Tracks currently active operations to prevent duplicate operations
    private var activeOperations: [String: SecurityOperation] = [:]
    
    // MARK: - Initialisation
    
    /**
     Initialises a new SecurityProviderImpl with the required dependencies.
     
     - Parameters:
       - cryptoService: Service for cryptographic operations
       - keyManager: Service for key management
       - logger: Logger for recording security operations
     */
    public init(
        cryptoService: CryptoServiceProtocol,
        keyManager: KeyManagementProtocol,
        logger: LoggerProtocol
    ) {
        self.cryptoService = cryptoService
        self.keyManager = keyManager
        self.logger = logger
    }
    
    // MARK: - SecurityProviderProtocol Implementation
    
    /**
     Encrypts data with the specified configuration.
     
     - Parameter config: Configuration for the encryption operation
     - Returns: Result containing encrypted data or error
     */
    public func encrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.encrypt
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateEncryptionConfig(config)
            
            // Get the input data from the config
            guard let inputDataString = config.options["inputData"],
                  let inputData = Data(base64Encoded: inputDataString) else {
                throw SecurityError.invalidInput("Invalid input data format")
            }
            
            // Convert Data to SecureBytes
            let secureInputBytes = SecureBytes(data: inputData)
            
            // Get the key identifier
            guard let keyIdentifier = config.options["keyIdentifier"] else {
                throw SecurityError.invalidInput("Missing key identifier")
            }
            
            // Perform the encryption
            let encryptedBytes = try await cryptoService.encrypt(
                data: secureInputBytes,
                withKey: keyIdentifier,
                algorithm: config.algorithm,
                keySize: config.keySize,
                mode: config.mode
            )
            
            // Convert SecureBytes back to Data for the result
            let resultData = encryptedBytes.extractData()
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: resultData.base64EncodedString(),
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Decrypts data with the specified configuration.
     
     - Parameter config: Configuration for the decryption operation
     - Returns: Result containing decrypted data or error
     */
    public func decrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.decrypt
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateDecryptionConfig(config)
            
            // Get the input data from the config
            guard let inputDataString = config.options["inputData"],
                  let inputData = Data(base64Encoded: inputDataString) else {
                throw SecurityError.invalidInput("Invalid input data format")
            }
            
            // Convert Data to SecureBytes
            let secureInputBytes = SecureBytes(data: inputData)
            
            // Get the key identifier
            guard let keyIdentifier = config.options["keyIdentifier"] else {
                throw SecurityError.invalidInput("Missing key identifier")
            }
            
            // Perform the decryption
            let decryptedBytes = try await cryptoService.decrypt(
                data: secureInputBytes,
                withKey: keyIdentifier,
                algorithm: config.algorithm,
                mode: config.mode
            )
            
            // Convert SecureBytes back to Data for the result
            let resultData = decryptedBytes.extractData()
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: resultData.base64EncodedString(),
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Generates a new cryptographic key with the specified configuration.
     
     - Parameter config: Configuration for the key generation operation
     - Returns: Result containing key identifier or error
     */
    public func generateKey(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.generateKey
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateKeyGenerationConfig(config)
            
            // Generate a custom identifier if provided, otherwise use a UUID
            let keyIdentifier = config.options["keyIdentifier"] ?? UUID().uuidString
            
            // Generate the key
            try await keyManager.generateKey(
                identifier: keyIdentifier,
                algorithm: config.algorithm,
                keySize: config.keySize
            )
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result with the key identifier
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: keyIdentifier,
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Securely stores data with the specified configuration.
     
     - Parameter config: Configuration for the secure storage operation
     - Returns: Result containing success status or error
     */
    public func secureStore(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.secureStore
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateSecureStorageConfig(config)
            
            // Get the data to store
            guard let dataString = config.options["storeData"],
                  let inputData = Data(base64Encoded: dataString) else {
                throw SecurityError.invalidInput("Invalid data format for secure storage")
            }
            
            // Convert Data to SecureBytes
            let secureBytes = SecureBytes(data: inputData)
            
            // Get the storage identifier
            guard let identifier = config.options["storageIdentifier"] else {
                throw SecurityError.invalidInput("Missing storage identifier")
            }
            
            // Store the data securely
            try await keyManager.storeSecurely(
                secureBytes,
                withIdentifier: identifier
            )
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: "Data stored securely with identifier: \(identifier)",
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Securely retrieves data with the specified configuration.
     
     - Parameter config: Configuration for the secure retrieval operation
     - Returns: Result containing retrieved data or error
     */
    public func secureRetrieve(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.secureRetrieve
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateSecureRetrievalConfig(config)
            
            // Get the storage identifier
            guard let identifier = config.options["storageIdentifier"] else {
                throw SecurityError.invalidInput("Missing storage identifier")
            }
            
            // Retrieve the data securely
            let retrievedBytes = try await keyManager.retrieveSecurely(withIdentifier: identifier)
            
            // Convert SecureBytes back to Data for the result
            let resultData = retrievedBytes.extractData()
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: resultData.base64EncodedString(),
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Securely deletes data with the specified configuration.
     
     - Parameter config: Configuration for the secure deletion operation
     - Returns: Result containing success status or error
     */
    public func secureDelete(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.secureDelete
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateSecureDeletionConfig(config)
            
            // Get the storage identifier
            guard let identifier = config.options["storageIdentifier"] else {
                throw SecurityError.invalidInput("Missing storage identifier")
            }
            
            // Delete the data securely
            try await keyManager.deleteSecurely(withIdentifier: identifier)
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: "Data with identifier \(identifier) securely deleted",
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Signs data with the specified configuration.
     
     - Parameter config: Configuration for the signing operation
     - Returns: Result containing signature or error
     */
    public func sign(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.sign
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateSigningConfig(config)
            
            // Get the input data from the config
            guard let inputDataString = config.options["inputData"],
                  let inputData = Data(base64Encoded: inputDataString) else {
                throw SecurityError.invalidInput("Invalid input data format")
            }
            
            // Convert Data to SecureBytes
            let secureInputBytes = SecureBytes(data: inputData)
            
            // Get the key identifier
            guard let keyIdentifier = config.options["keyIdentifier"] else {
                throw SecurityError.invalidInput("Missing key identifier")
            }
            
            // Perform the signing operation
            let signature = try await cryptoService.sign(
                data: secureInputBytes,
                withKey: keyIdentifier,
                hashAlgorithm: config.hashAlgorithm
            )
            
            // Convert signature to base64 encoded string
            let signatureData = signature.extractData()
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return successful result
            return SecurityResultDTO(
                success: true,
                operationId: operationId,
                result: signatureData.base64EncodedString(),
                error: nil
            )
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
    
    /**
     Verifies a signature with the specified configuration.
     
     - Parameter config: Configuration for the verification operation
     - Returns: Result containing verification status or error
     */
    public func verify(config: SecurityConfigDTO) async -> SecurityResultDTO {
        let operationId = UUID().uuidString
        let startTime = Date()
        let operation = SecurityOperation.verify
        
        activeOperations[operationId] = operation
        defer { activeOperations.removeValue(forKey: operationId) }
        
        do {
            // Log operation start
            await logOperationStart(operation: operation, config: config)
            
            // Validate the configuration
            try validateVerificationConfig(config)
            
            // Get the input data from the config
            guard let inputDataString = config.options["inputData"],
                  let inputData = Data(base64Encoded: inputDataString) else {
                throw SecurityError.invalidInput("Invalid input data format")
            }
            
            // Convert Data to SecureBytes
            let secureInputBytes = SecureBytes(data: inputData)
            
            // Get the signature
            guard let signatureBase64 = config.options["signature"],
                  let signatureData = Data(base64Encoded: signatureBase64) else {
                throw SecurityError.invalidInput("Invalid signature format")
            }
            
            // Convert signature Data to SecureBytes
            let signatureBytes = SecureBytes(data: signatureData)
            
            // Get the key identifier
            guard let keyIdentifier = config.options["keyIdentifier"] else {
                throw SecurityError.invalidInput("Missing key identifier")
            }
            
            // Perform the verification
            let isVerified = try await cryptoService.verify(
                signature: signatureBytes,
                forData: secureInputBytes,
                withKey: keyIdentifier,
                hashAlgorithm: config.hashAlgorithm
            )
            
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationSuccess(operation: operation, duration: duration)
            
            // Return result based on verification status
            if isVerified {
                return SecurityResultDTO(
                    success: true,
                    operationId: operationId,
                    result: "Signature verified successfully",
                    error: nil
                )
            } else {
                return SecurityResultDTO(
                    success: false,
                    operationId: operationId,
                    result: nil,
                    error: "Signature verification failed"
                )
            }
        } catch {
            // Calculate duration
            let duration = Date().timeIntervalSince(startTime) * 1000
            await logOperationFailure(operation: operation, error: error, duration: duration)
            
            // Map to appropriate error
            let securityError = SecurityErrorHandler.mapError(error)
            
            // Return failure result
            return SecurityResultDTO(
                success: false,
                operationId: operationId,
                result: nil,
                error: securityError.localizedDescription
            )
        }
    }
}
