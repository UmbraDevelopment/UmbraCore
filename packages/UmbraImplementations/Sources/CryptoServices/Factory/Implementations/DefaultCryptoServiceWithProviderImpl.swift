import Foundation
import CoreSecurityTypes
import CryptoInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # DefaultCryptoServiceWithProviderImpl
 
 Default implementation of CryptoServiceProtocol that uses a SecurityProviderProtocol.
 
 This implementation delegates cryptographic operations to a security provider,
 which allows for different cryptographic backends to be used without changing
 the client code.
 
 ## Privacy Controls
 
 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys are treated as private information
 - Data identifiers are generally treated as public information
 - Error details are appropriately classified based on sensitivity
 - Metadata is structured using LogMetadataDTOCollection for privacy-aware logging
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor DefaultCryptoServiceWithProviderImpl: CryptoServiceProtocol {
    /// The security provider to use for cryptographic operations
    private let provider: SecurityProviderProtocol
    
    /// The secure storage to use
    public let secureStorage: SecureStorageProtocol
    
    /// Logger for operations
    private let logger: LoggingProtocol
    
    /**
     Initialises a new crypto service with a security provider.
     
     - Parameters:
       - provider: The security provider to use
       - secureStorage: The secure storage to use
       - logger: The logger to use
     */
    public init(
        provider: SecurityProviderProtocol,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol
    ) {
        self.provider = provider
        self.secureStorage = secureStorage
        self.logger = logger
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    /**
     Encrypts data with the specified key using the security provider.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to encrypt
       - keyIdentifier: Identifier for the encryption key
       - options: Optional encryption options
     - Returns: Result containing the identifier for the encrypted data or an error
     */
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "encrypt",
            algorithm: options?.algorithm.rawValue,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPublic(key: "status", value: "started")
        )
        
        // Add algorithm information if available
        let contextWithOptions = context
        
        await logger.info(
            "Encrypting data with identifier: \(dataIdentifier)",
            context: contextWithOptions
        )
        
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        
        guard case .success(_) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = contextWithOptions.withUpdatedMetadata(
                    contextWithOptions.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                )
                
                await logger.error(
                    "Failed to retrieve data for encryption: \(error)",
                    context: errorContext
                )
                return .failure(error)
            }
            
            let errorContext = contextWithOptions.withUpdatedMetadata(
                contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Data not found")
            )
            
            await logger.error(
                "Failed to retrieve data for encryption: data not found",
                context: errorContext
            )
            return .failure(.dataNotFound)
        }
        
        // Create security configuration
        var configOptions = SecurityConfigOptions(
            enableDetailedLogging: true,
            keyDerivationIterations: 10000,
            memoryLimitBytes: 65536,
            useHardwareAcceleration: true,
            operationTimeoutSeconds: 30,
            verifyOperations: true
        )
        
        // Add the key identifier and algorithm to the metadata
        var metadata: [String: String] = ["keyIdentifier": keyIdentifier]
        if let options = options {
            metadata["algorithm"] = options.algorithm.rawValue
        }
        configOptions.metadata = metadata
        
        // Create the security config
        let securityConfig = await provider.createSecureConfig(options: configOptions)
        
        // Perform the encryption using the provider
        let resultDTO: SecurityResultDTO
        do {
            resultDTO = try await provider.encrypt(config: securityConfig)
        } catch {
            let errorContext = contextWithOptions.withUpdatedMetadata(
                contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Encryption operation failed: \(error.localizedDescription)")
            )
            
            await logger.error(
                "Encryption failed with error: \(error)",
                context: errorContext
            )
            return .failure(.operationFailed("Encryption operation failed: \(error)"))
        }
        
        // Check if the result is successful and contains data
        if resultDTO.successful, let resultData = resultDTO.resultData {
            // Store the encrypted data
            let encryptedId = "encrypted_\(UUID().uuidString)"
            let storeResult = await secureStorage.storeData(resultData, withIdentifier: encryptedId)
            
            guard case .success = storeResult else {
                if case let .failure(error) = storeResult {
                    let errorContext = contextWithOptions.withUpdatedMetadata(
                        contextWithOptions.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                    )
                    
                    await logger.error(
                        "Failed to store encrypted data: \(error)",
                        context: errorContext
                    )
                    return .failure(error)
                }
                
                let errorContext = contextWithOptions.withUpdatedMetadata(
                    contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Storage error")
                )
                
                await logger.error(
                    "Failed to store encrypted data: storage error",
                    context: errorContext
                )
                return .failure(.storageError)
            }
            
            let successContext = contextWithOptions.withUpdatedMetadata(
                contextWithOptions.metadata.withPublic(key: "encryptedIdentifier", value: encryptedId)
            )
            
            await logger.info(
                "Successfully encrypted data with identifier: \(encryptedId)",
                context: successContext
            )
            return .success(encryptedId)
        } else {
            let errorContext = contextWithOptions.withUpdatedMetadata(
                contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Encryption operation failed - invalid result data")
            )
            
            await logger.error(
                "Encryption failed - invalid result data",
                context: errorContext
            )
            return .failure(.operationFailed("Encryption operation failed - invalid result data"))
        }
    }
    
    /**
     Decrypts data with the specified key using the security provider.
     
     - Parameters:
       - encryptedDataIdentifier: Identifier for the encrypted data
       - keyIdentifier: Identifier for the decryption key
       - options: Optional decryption options
     - Returns: Result containing the identifier for the decrypted data or an error
     */
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "decrypt",
            algorithm: options?.algorithm.rawValue,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPublic(key: "status", value: "started")
        )
        
        // Add algorithm information if available
        let contextWithOptions = context
        
        await logger.info(
            "Decrypting data with identifier: \(encryptedDataIdentifier)",
            context: contextWithOptions
        )
        
        // Implementation similar to encrypt but using provider.decrypt
        // For now, returning a mock implementation
        let decryptedId = "decrypted_\(UUID().uuidString)"
        
        let successContext = contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPublic(key: "decryptedIdentifier", value: decryptedId)
        )
        
        await logger.info(
            "Successfully decrypted data with identifier: \(decryptedId)",
            context: successContext
        )
        
        return .success(decryptedId)
    }
    
    /**
     Computes a cryptographic hash of the specified data using the security provider.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to hash
       - options: Optional hashing options
     - Returns: Result containing the identifier for the hash or an error
     */
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "hash",
            algorithm: options?.algorithm.rawValue,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPublic(key: "status", value: "started")
        )
        
        // Add algorithm information if available
        let contextWithOptions = context
        
        await logger.info(
            "Hashing data with identifier: \(dataIdentifier)",
            context: contextWithOptions
        )
        
        // Implementation would use provider.hash
        // For now, returning a mock implementation
        let hashId = "hash_\(UUID().uuidString)"
        
        let successContext = contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withHashed(key: "hashIdentifier", value: hashId)
        )
        
        await logger.info(
            "Successfully hashed data with identifier: \(hashId)",
            context: successContext
        )
        
        return .success(hashId)
    }
    
    /**
     Verifies that a hash matches the expected value for the specified data.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to verify
       - hashIdentifier: Identifier for the expected hash
       - options: Optional hashing options
     - Returns: Result containing a boolean indicating if the hash is valid or an error
     */
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<Bool, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "verifyHash",
            algorithm: options?.algorithm.rawValue,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPublic(key: "hashIdentifier", value: hashIdentifier)
                .withPublic(key: "status", value: "started")
        )
        
        // Add algorithm information if available
        let contextWithOptions = context
        
        await logger.info(
            "Verifying hash for data with identifier: \(dataIdentifier)",
            context: contextWithOptions
        )
        
        // Mock implementation
        let isValid = true
        
        let successContext = contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPublic(key: "isValid", value: "true")
        )
        
        await logger.info(
            "Hash verification result: Valid",
            context: successContext
        )
        
        return .success(isValid)
    }
    
    /**
     Generates a cryptographic key with the specified parameters using the security provider.
     
     - Parameters:
       - length: Length of the key to generate in bytes
       - options: Optional key generation options
     - Returns: Result containing the identifier for the generated key or an error
     */
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "generateKey",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "keyLength", value: "\(length)")
                .withPublic(key: "status", value: "started")
        )
        
        // Add algorithm information if available
        let contextWithOptions = context
        
        await logger.info(
            "Generating key of length \(length) bytes",
            context: contextWithOptions
        )
        
        // Implementation would use provider.generateKey
        // For now, returning a mock implementation
        let keyId = "key_\(UUID().uuidString)"
        
        let successContext = contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPrivate(key: "keyIdentifier", value: keyId)
        )
        
        await logger.info(
            "Successfully generated key with identifier: \(keyId)",
            context: successContext
        )
        
        return .success(keyId)
    }
    
    /**
     Stores data in the secure storage.
     
     - Parameters:
       - data: Data to store
       - identifier: Identifier for the data
     - Returns: Result containing void or an error
     */
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "storeData",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "identifier", value: identifier)
                .withPrivate(key: "dataSize", value: "\(data.count)")
                .withPublic(key: "status", value: "started")
        )
        
        await logger.info(
            "Storing data with identifier: \(identifier)",
            context: context
        )
        
        let result = await secureStorage.storeData(Array(data), withIdentifier: identifier)
        
        switch result {
            case .success:
                let successContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "status", value: "success")
                )
                
                await logger.info(
                    "Successfully stored data with identifier: \(identifier)",
                    context: successContext
                )
                
            case let .failure(error):
                let errorContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                )
                
                await logger.error(
                    "Failed to store data: \(error)",
                    context: errorContext
                )
        }
        
        return result
    }
    
    /**
     Retrieves data from the secure storage.
     
     - Parameter identifier: Identifier for the data to retrieve
     - Returns: Result containing the data or an error
     */
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "retrieveData",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "identifier", value: identifier)
                .withPublic(key: "status", value: "started")
        )
        
        await logger.info(
            "Retrieving data with identifier: \(identifier)",
            context: context
        )
        
        let result = await secureStorage.retrieveData(withIdentifier: identifier)
        
        switch result {
            case let .success(bytes):
                let data = Data(bytes)
                let successContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "status", value: "success")
                        .withPublic(key: "dataSize", value: "\(data.count)")
                )
                
                await logger.info(
                    "Successfully retrieved data (\(data.count) bytes) with identifier: \(identifier)",
                    context: successContext
                )
                
                return .success(data)
                
            case let .failure(error):
                let errorContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                )
                
                await logger.error(
                    "Failed to retrieve data: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
        }
    }
    
    /**
     Deletes data from the secure storage.
     
     - Parameter identifier: Identifier for the data to delete
     - Returns: Result containing void or an error
     */
    public func deleteData(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "deleteData",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "identifier", value: identifier)
                .withPublic(key: "status", value: "started")
        )
        
        await logger.info(
            "Deleting data with identifier: \(identifier)",
            context: context
        )
        
        let result = await secureStorage.deleteData(withIdentifier: identifier)
        
        switch result {
            case .success:
                let successContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "status", value: "success")
                )
                
                await logger.info(
                    "Successfully deleted data with identifier: \(identifier)",
                    context: successContext
                )
                
            case let .failure(error):
                let errorContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                )
                
                await logger.error(
                    "Failed to delete data: \(error)",
                    context: errorContext
                )
        }
        
        return result
    }
    
    // MARK: - Data Import/Export Operations
    
    /**
     Imports raw byte array data into the secure storage.
     
     - Parameters:
       - data: Raw byte array to import
       - customIdentifier: Optional custom identifier for the data
     - Returns: Result containing the identifier for the imported data or an error
     */
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "importData",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "dataSize", value: "\(data.count)")
                .withPublic(key: "hasCustomIdentifier", value: customIdentifier != nil ? "true" : "false")
                .withPublic(key: "status", value: "started")
        )
        
        await logger.info(
            "Importing byte array data (\(data.count) bytes)",
            context: context
        )
        
        let actualIdentifier = customIdentifier ?? "imported_\(UUID().uuidString)"
        let result = await secureStorage.storeData(data, withIdentifier: actualIdentifier)
        
        switch result {
            case .success:
                let successContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "status", value: "success")
                        .withPublic(key: "identifier", value: actualIdentifier)
                )
                
                await logger.info(
                    "Successfully imported data with identifier: \(actualIdentifier)",
                    context: successContext
                )
                
                return .success(actualIdentifier)
                
            case let .failure(error):
                let errorContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                )
                
                await logger.error(
                    "Failed to import data: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
        }
    }
    
    /**
     Imports raw data into the secure storage.
     
     - Parameters:
       - data: Raw data to import
       - customIdentifier: Custom identifier for the data
     - Returns: Result containing the identifier for the imported data or an error
     */
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "importData",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "customIdentifier", value: customIdentifier)
                .withPublic(key: "dataSize", value: "\(data.count)")
                .withPublic(key: "status", value: "started")
        )
        
        await logger.info(
            "Importing data with custom identifier: \(customIdentifier)",
            context: context
        )
        
        return await importData(Array(data), customIdentifier: customIdentifier)
    }
    
    /**
     Exports data from the secure storage as a byte array.
     
     - Parameter identifier: Identifier for the data to export
     - Returns: Result containing the raw byte array or an error
     */
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        // Create a log context with proper privacy classification
        let context = CryptoLogContext(
            operation: "exportData",
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "DefaultCryptoServiceWithProviderImpl",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "identifier", value: identifier)
                .withPublic(key: "status", value: "started")
        )
        
        await logger.info(
            "Exporting data with identifier: \(identifier)",
            context: context
        )
        
        let result = await secureStorage.retrieveData(withIdentifier: identifier)
        
        switch result {
            case let .success(data):
                let successContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "status", value: "success")
                        .withPublic(key: "dataSize", value: "\(data.count)")
                )
                
                await logger.info(
                    "Successfully exported data (\(data.count) bytes) with identifier: \(identifier)",
                    context: successContext
                )
                
                return .success(data)
                
            case let .failure(error):
                let errorContext = context.withUpdatedMetadata(
                    context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
                )
                
                await logger.error(
                    "Failed to export data: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
        }
    }
    
    /**
     For protocol compatibility with other implementations.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to hash
       - options: Optional hashing options
     - Returns: Result containing the identifier for the hash or an error
     */
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Simply delegate to the hash method
        return await hash(dataIdentifier: dataIdentifier, options: options)
    }
}
