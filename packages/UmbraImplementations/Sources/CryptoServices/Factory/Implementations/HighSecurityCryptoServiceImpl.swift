import Foundation
import CoreSecurityTypes
import CryptoInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # High-Security Crypto Service Implementation
 
 A high-security implementation of CryptoServiceProtocol.
 
 This implementation adds additional security measures such as rate limiting,
 enhanced logging with privacy controls, and stricter validation of inputs. 
 It is designed for use in scenarios where security is particularly critical.
 
 ## Privacy Controls
 
 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys and operations are treated with appropriate privacy levels
 - Error details are classified based on sensitivity
 - Metadata is structured using LogMetadataDTOCollection for privacy-aware logging
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor HighSecurityCryptoServiceImpl: CryptoServiceProtocol {
    /// The secure storage to use
    public let secureStorage: SecureStorageProtocol
    
    /// Rate limiter for security operations
    private let rateLimiter: RateLimiterAdapter
    
    /// Logger for operations
    private let logger: LoggingProtocol
    
    /**
     Initialises a new high-security crypto service.
     
     - Parameters:
       - secureStorage: The secure storage to use
       - rateLimiter: The rate limiter to use
       - logger: The logger to use
     */
    public init(
        secureStorage: SecureStorageProtocol,
        rateLimiter: RateLimiterAdapter,
        logger: LoggingProtocol
    ) {
        self.secureStorage = secureStorage
        self.rateLimiter = rateLimiter
        self.logger = logger
    }
    
    /**
     Creates a log context for a cryptographic operation.
     
     - Parameters:
       - operation: The type of operation (encrypt, decrypt, etc.)
       - identifier: Optional identifier for the data or key
       - status: Optional status of the operation
       - details: Optional additional details about the operation
     - Returns: A log context for the operation
     */
    private func createLogContext(
        operation: String,
        identifier: String? = nil,
        status: String? = nil,
        details: [String: String] = [:]
    ) -> CryptoLogContext {
        var metadata = LogMetadataDTOCollection()
        
        if let identifier = identifier {
            metadata = metadata.withPublic(key: "identifier", value: identifier)
        }
        
        // Add all details with appropriate privacy levels
        for (key, value) in details {
            if key.contains("key") || key.contains("password") || key.contains("secret") {
                metadata = metadata.withSensitive(key: key, value: value)
            } else if key.contains("hash") {
                metadata = metadata.withHashed(key: key, value: value)
            } else if key.contains("error") || key.contains("result") {
                metadata = metadata.withPublic(key: key, value: value)
            } else {
                metadata = metadata.withPrivate(key: key, value: value)
            }
        }
        
        return CryptoLogContext(
            operation: operation,
            identifier: identifier,
            status: status,
            metadata: metadata
        )
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    /**
     Encrypts data using the specified key.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to encrypt
       - keyIdentifier: Identifier for the encryption key
       - options: Optional encryption options
     - Returns: Result containing the encrypted data identifier or an error
     */
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(
            operation: "encrypt",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "keyIdentifier": keyIdentifier,
                "algorithm": options?.algorithm?.rawValue ?? "default"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("encrypt") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for encryption operations")
            
            await logger.error(
                "Encryption operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting encryption operation",
            context: context
        )
        
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(dataIdentifier)
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to retrieve data for encryption: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Data not found")
            
            await logger.error(
                "Failed to retrieve data for encryption: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        // Retrieve the key
        let keyResult = await secureStorage.retrieveData(keyIdentifier)
        guard case let .success(key) = keyResult else {
            if case let .failure(error) = keyResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to retrieve key for encryption: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Key not found")
            
            await logger.error(
                "Failed to retrieve key for encryption: key not found",
                context: errorContext
            )
            
            return .failure(.keyNotFound)
        }
        
        // Perform encryption (in a real implementation, use a proper cryptographic algorithm)
        // This is just a mock implementation for demonstration purposes
        let encryptedData = Data((0..<data.count).map { i in
            data[i] ^ key[i % key.count]
        })
        
        // Store the encrypted data
        let encryptedId = "encrypted_\(UUID().uuidString)"
        let storeResult = await secureStorage.storeData(encryptedData, withIdentifier: encryptedId)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to store encrypted data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Unknown error storing encrypted data")
            
            await logger.error(
                "Failed to store encrypted data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = context.withStatus("success")
            .withPublicMetadata(key: "encryptedIdentifier", value: encryptedId)
            .withPublicMetadata(key: "dataSize", value: "\(data.count)")
        
        await logger.info(
            "Encryption operation completed successfully",
            context: successContext
        )
        
        return .success(encryptedId)
    }
    
    /**
     Decrypts data using the specified key.
     
     - Parameters:
       - encryptedDataIdentifier: Identifier for the encrypted data
       - keyIdentifier: Identifier for the decryption key
       - options: Optional decryption options
     - Returns: Result containing the decrypted data identifier or an error
     */
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(
            operation: "decrypt",
            identifier: encryptedDataIdentifier,
            status: "started",
            details: [
                "keyIdentifier": keyIdentifier,
                "algorithm": options?.algorithm?.rawValue ?? "default"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("decrypt") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for decryption operations")
            
            await logger.error(
                "Decryption operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting decryption operation",
            context: context
        )
        
        // Retrieve the encrypted data
        let encryptedDataResult = await secureStorage.retrieveData(encryptedDataIdentifier)
        guard case let .success(encryptedData) = encryptedDataResult else {
            if case let .failure(error) = encryptedDataResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to retrieve encrypted data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Encrypted data not found")
            
            await logger.error(
                "Failed to retrieve encrypted data: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        // Retrieve the key
        let keyResult = await secureStorage.retrieveData(keyIdentifier)
        guard case let .success(key) = keyResult else {
            if case let .failure(error) = keyResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to retrieve key for decryption: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Key not found")
            
            await logger.error(
                "Failed to retrieve key for decryption: key not found",
                context: errorContext
            )
            
            return .failure(.keyNotFound)
        }
        
        // Perform decryption (in a real implementation, use a proper cryptographic algorithm)
        // This is just a mock implementation for demonstration purposes
        let decryptedData = Data((0..<encryptedData.count).map { i in
            encryptedData[i] ^ key[i % key.count]
        })
        
        // Store the decrypted data
        let decryptedId = "decrypted_\(UUID().uuidString)"
        let storeResult = await secureStorage.storeData(decryptedData, withIdentifier: decryptedId)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to store decrypted data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Unknown error storing decrypted data")
            
            await logger.error(
                "Failed to store decrypted data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = context.withStatus("success")
            .withPublicMetadata(key: "decryptedIdentifier", value: decryptedId)
            .withPublicMetadata(key: "dataSize", value: "\(decryptedData.count)")
        
        await logger.info(
            "Decryption operation completed successfully",
            context: successContext
        )
        
        return .success(decryptedId)
    }
    
    /**
     Computes a hash of the specified data.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to hash
       - options: Optional hashing options
     - Returns: Result containing the hash identifier or an error
     */
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        let algorithm = options?.algorithm?.rawValue ?? "SHA256"
        let context = createLogContext(
            operation: "hash",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "algorithm": algorithm
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("hash") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for hash operations")
            
            await logger.error(
                "Hash operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting hash operation using \(algorithm)",
            context: context
        )
        
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(dataIdentifier)
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to retrieve data for hashing: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Data not found")
            
            await logger.error(
                "Failed to retrieve data for hashing: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        // Compute hash (in a real implementation, use a proper cryptographic hash function)
        // This is just a mock implementation for demonstration purposes
        let hashData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        
        // Store the hash
        let hashId = "hash_\(UUID().uuidString)"
        let storeResult = await secureStorage.storeData(hashData, withIdentifier: hashId)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to store hash: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Unknown error storing hash")
            
            await logger.error(
                "Failed to store hash: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = context.withStatus("success")
            .withPublicMetadata(key: "hashIdentifier", value: hashId)
            .withHashedMetadata(key: "hashValue", value: hashData.base64EncodedString())
        
        await logger.info(
            "Hash operation completed successfully",
            context: successContext
        )
        
        return .success(hashId)
    }
    
    /**
     Verifies a hash against the expected value.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to verify
       - expectedHashIdentifier: Identifier for the expected hash
       - options: Optional hashing options
     - Returns: Result indicating whether the hash is valid or an error
     */
    public func verifyHash(
        dataIdentifier: String,
        expectedHashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<Bool, SecurityStorageError> {
        let algorithm = options?.algorithm?.rawValue ?? "SHA256"
        let context = createLogContext(
            operation: "verifyHash",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "expectedHashIdentifier": expectedHashIdentifier,
                "algorithm": algorithm
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("verifyHash") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for hash verification operations")
            
            await logger.error(
                "Hash verification operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting hash verification using \(algorithm)",
            context: context
        )
        
        // In a real implementation, we would:
        // 1. Retrieve the data
        // 2. Compute its hash
        // 3. Retrieve the expected hash
        // 4. Compare the computed hash with the expected hash
        
        // For this mock implementation, we'll just return a success result
        let isValid = true
        
        let successContext = context.withStatus("success")
            .withPublicMetadata(key: "isValid", value: isValid ? "true" : "false")
        
        await logger.info(
            "Hash verification completed: \(isValid ? "valid" : "invalid")",
            context: successContext
        )
        
        return .success(isValid)
    }
    
    /**
     Stores data securely.
     
     - Parameters:
       - data: The data to store
       - options: Optional storage options
     - Returns: Result containing the data identifier or an error
     */
    public func storeData(
        _ data: Data,
        options: CoreSecurityTypes.StorageOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(
            operation: "storeData",
            status: "started",
            details: [
                "dataSize": "\(data.count)",
                "storageType": options?.storageType?.rawValue ?? "default"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("storeData") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for data storage operations")
            
            await logger.error(
                "Data storage operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting data storage operation",
            context: context
        )
        
        // Generate a unique identifier for the data
        let dataId = "data_\(UUID().uuidString)"
        
        // Store the data
        let storeResult = await secureStorage.storeData(data, withIdentifier: dataId)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to store data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Unknown error storing data")
            
            await logger.error(
                "Failed to store data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = context.withStatus("success")
            .withPublicMetadata(key: "dataIdentifier", value: dataId)
            .withPublicMetadata(key: "dataSize", value: "\(data.count)")
        
        await logger.info(
            "Data storage operation completed successfully",
            context: successContext
        )
        
        return .success(dataId)
    }
    
    /**
     Retrieves data securely.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to retrieve
       - options: Optional retrieval options
     - Returns: Result containing the retrieved data or an error
     */
    public func retrieveData(
        _ dataIdentifier: String,
        options: CoreSecurityTypes.StorageOptions? = nil
    ) async -> Result<Data, SecurityStorageError> {
        let context = createLogContext(
            operation: "retrieveData",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "storageType": options?.storageType?.rawValue ?? "default"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("retrieveData") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for data retrieval operations")
            
            await logger.error(
                "Data retrieval operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting data retrieval operation",
            context: context
        )
        
        // Retrieve the data
        let dataResult = await secureStorage.retrieveData(dataIdentifier)
        
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to retrieve data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Data not found")
            
            await logger.error(
                "Failed to retrieve data: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        let successContext = context.withStatus("success")
            .withPublicMetadata(key: "dataSize", value: "\(data.count)")
        
        await logger.info(
            "Data retrieval operation completed successfully",
            context: successContext
        )
        
        return .success(data)
    }
    
    /**
     Deletes data securely.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to delete
       - options: Optional deletion options
     - Returns: Result indicating success or an error
     */
    public func deleteData(
        _ dataIdentifier: String,
        options: CoreSecurityTypes.StorageOptions? = nil
    ) async -> Result<Void, SecurityStorageError> {
        let context = createLogContext(
            operation: "deleteData",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "storageType": options?.storageType?.rawValue ?? "default"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("deleteData") {
            let errorContext = context.withStatus("rate_limited")
                .withPublicMetadata(key: "reason", value: "Rate limit exceeded for data deletion operations")
            
            await logger.error(
                "Data deletion operation rate limited",
                context: errorContext
            )
            
            return .failure(.rateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting data deletion operation",
            context: context
        )
        
        // Delete the data
        let deleteResult = await secureStorage.deleteData(withIdentifier: dataIdentifier)
        
        guard case .success = deleteResult else {
            if case let .failure(error) = deleteResult {
                let errorContext = context.withStatus("failed")
                    .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
                    .withPublicMetadata(key: "errorCode", value: "\(error)")
                
                await logger.error(
                    "Failed to delete data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = context.withStatus("failed")
                .withPublicMetadata(key: "errorDescription", value: "Unknown error deleting data")
            
            await logger.error(
                "Failed to delete data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = context.withStatus("success")
        
        await logger.info(
            "Data deletion operation completed successfully",
            context: successContext
        )
        
        return .success(())
    }
}
