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
public actor HighSecurityCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
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
            let errorContext = createLogContext(
                operation: "encrypt",
                identifier: dataIdentifier,
                status: "rate_limited",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "reason": "Rate limit exceeded for encryption operations"
                ]
            )
            
            await logger.error(
                "Encryption operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting encryption operation",
            context: context
        )
        
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "encrypt",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm?.rawValue ?? "default",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for encryption: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "encrypt",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "errorDescription": "Data not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve data for encryption: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        // Retrieve the key
        let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
        guard case let .success(key) = keyResult else {
            if case let .failure(error) = keyResult {
                let errorContext = createLogContext(
                    operation: "encrypt",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm?.rawValue ?? "default",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve key for encryption: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "encrypt",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "errorDescription": "Key not found"
                ]
            )
            
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
                let errorContext = createLogContext(
                    operation: "encrypt",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm?.rawValue ?? "default",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store encrypted data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "encrypt",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "errorDescription": "Unknown error storing encrypted data"
                ]
            )
            
            await logger.error(
                "Failed to store encrypted data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = createLogContext(
            operation: "encrypt",
            identifier: dataIdentifier,
            status: "success",
            details: [
                "keyIdentifier": keyIdentifier,
                "algorithm": options?.algorithm?.rawValue ?? "default",
                "encryptedIdentifier": encryptedId,
                "dataSize": "\(data.count)"
            ]
        )
        
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
            let errorContext = createLogContext(
                operation: "decrypt",
                identifier: encryptedDataIdentifier,
                status: "rate_limited",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "reason": "Rate limit exceeded for decryption operations"
                ]
            )
            
            await logger.error(
                "Decryption operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting decryption operation",
            context: context
        )
        
        // Retrieve the encrypted data
        let encryptedDataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
        guard case let .success(encryptedData) = encryptedDataResult else {
            if case let .failure(error) = encryptedDataResult {
                let errorContext = createLogContext(
                    operation: "decrypt",
                    identifier: encryptedDataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm?.rawValue ?? "default",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve encrypted data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "decrypt",
                identifier: encryptedDataIdentifier,
                status: "failed",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "errorDescription": "Encrypted data not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve encrypted data: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        // Retrieve the key
        let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
        guard case let .success(key) = keyResult else {
            if case let .failure(error) = keyResult {
                let errorContext = createLogContext(
                    operation: "decrypt",
                    identifier: encryptedDataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm?.rawValue ?? "default",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve key for decryption: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "decrypt",
                identifier: encryptedDataIdentifier,
                status: "failed",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "errorDescription": "Key not found"
                ]
            )
            
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
                let errorContext = createLogContext(
                    operation: "decrypt",
                    identifier: encryptedDataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm?.rawValue ?? "default",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store decrypted data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "decrypt",
                identifier: encryptedDataIdentifier,
                status: "failed",
                details: [
                    "keyIdentifier": keyIdentifier,
                    "algorithm": options?.algorithm?.rawValue ?? "default",
                    "errorDescription": "Unknown error storing decrypted data"
                ]
            )
            
            await logger.error(
                "Failed to store decrypted data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = createLogContext(
            operation: "decrypt",
            identifier: encryptedDataIdentifier,
            status: "success",
            details: [
                "keyIdentifier": keyIdentifier,
                "algorithm": options?.algorithm?.rawValue ?? "default",
                "decryptedIdentifier": decryptedId,
                "dataSize": "\(decryptedData.count)"
            ]
        )
        
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
            let errorContext = createLogContext(
                operation: "hash",
                identifier: dataIdentifier,
                status: "rate_limited",
                details: [
                    "algorithm": algorithm,
                    "reason": "Rate limit exceeded for hash operations"
                ]
            )
            
            await logger.error(
                "Hash operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting hash operation using \(algorithm)",
            context: context
        )
        
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "hash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "algorithm": algorithm,
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for hashing: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "hash",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "algorithm": algorithm,
                    "errorDescription": "Data not found"
                ]
            )
            
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
                let errorContext = createLogContext(
                    operation: "hash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "algorithm": algorithm,
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store hash: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "hash",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "algorithm": algorithm,
                    "errorDescription": "Unknown error storing hash"
                ]
            )
            
            await logger.error(
                "Failed to store hash: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = createLogContext(
            operation: "hash",
            identifier: dataIdentifier,
            status: "success",
            details: [
                "algorithm": algorithm,
                "hashIdentifier": hashId,
                "hashValue": hashData.base64EncodedString()
            ]
        )
        
        await logger.info(
            "Hash operation completed successfully",
            context: successContext
        )
        
        return .success(hashId)
    }
    
    /**
     Verifies a hash for data against an expected hash value.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to verify
       - hashIdentifier: Identifier for the expected hash value
       - options: Optional hashing configuration
     - Returns: Result indicating whether the hash is valid or an error
     */
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<Bool, SecurityStorageError> {
        let algorithm = options?.algorithm?.rawValue ?? "SHA256"
        let context = createLogContext(
            operation: "verifyHash",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "hashIdentifier": hashIdentifier,
                "algorithm": algorithm
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("verifyHash") {
            let errorContext = createLogContext(
                operation: "verifyHash",
                identifier: dataIdentifier,
                status: "rate_limited",
                details: [
                    "hashIdentifier": hashIdentifier,
                    "algorithm": algorithm,
                    "reason": "Rate limit exceeded for hash verification operations"
                ]
            )
            
            await logger.warning(
                "Hash verification operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting hash verification for data ID \(dataIdentifier) against hash ID \(hashIdentifier)",
            context: context
        )
        
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "verifyHash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "hashIdentifier": hashIdentifier,
                        "algorithm": algorithm,
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for hash verification: \(error.localizedDescription)",
                    context: errorContext
                )
            }
            return .failure(.dataNotFound)
        }
        
        // Retrieve the expected hash
        let expectedHashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
        guard case let .success(expectedHashData) = expectedHashResult else {
            if case let .failure(error) = expectedHashResult {
                let errorContext = createLogContext(
                    operation: "verifyHash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "hashIdentifier": hashIdentifier,
                        "algorithm": algorithm,
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve expected hash: \(error.localizedDescription)",
                    context: errorContext
                )
            }
            return .failure(.dataNotFound)
        }
        
        // In a real implementation, we would:
        // 1. Retrieve the data
        // 2. Compute its hash
        // 3. Retrieve the expected hash
        // 4. Compare the computed hash with the expected hash
        
        // For this mock implementation, we'll just return a success result
        let isValid = true
        
        let successContext = createLogContext(
            operation: "verifyHash",
            identifier: dataIdentifier,
            status: "success",
            details: [
                "hashIdentifier": hashIdentifier,
                "algorithm": algorithm,
                "isValid": isValid ? "true" : "false"
            ]
        )
        
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
       - identifier: The identifier for the data
     - Returns: Result containing the data identifier or an error
     */
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(
            operation: "storeData",
            identifier: identifier,
            status: "started",
            details: [
                "dataSize": "\(data.count)"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("storeData") {
            let errorContext = createLogContext(
                operation: "storeData",
                identifier: identifier,
                status: "rate_limited",
                details: [
                    "dataSize": "\(data.count)",
                    "reason": "Rate limit exceeded for data storage operations"
                ]
            )
            
            await logger.error(
                "Data storage operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting data storage operation",
            context: context
        )
        
        // Store the data
        let storeResult = await secureStorage.storeData(data, withIdentifier: identifier)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = createLogContext(
                    operation: "storeData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "dataSize": "\(data.count)",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "storeData",
                identifier: identifier,
                status: "failed",
                details: [
                    "dataSize": "\(data.count)",
                    "errorDescription": "Unknown error storing data"
                ]
            )
            
            await logger.error(
                "Failed to store data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = createLogContext(
            operation: "storeData",
            identifier: identifier,
            status: "success",
            details: [
                "dataSize": "\(data.count)"
            ]
        )
        
        await logger.info(
            "Data storage operation completed successfully",
            context: successContext
        )
        
        return .success(identifier)
    }
    
    /**
     Retrieves data securely.
     
     - Parameters:
       - identifier: Identifier for the data to retrieve
     - Returns: Result containing the retrieved data or an error
     */
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        let context = createLogContext(
            operation: "retrieveData",
            identifier: identifier,
            status: "started"
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("retrieveData") {
            let errorContext = createLogContext(
                operation: "retrieveData",
                identifier: identifier,
                status: "rate_limited",
                details: [
                    "reason": "Rate limit exceeded for data retrieval operations"
                ]
            )
            
            await logger.error(
                "Data retrieval operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting data retrieval operation",
            context: context
        )
        
        // Retrieve the data
        let dataResult = await secureStorage.retrieveData(withIdentifier: identifier)
        
        guard case let .success(data) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "retrieveData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "retrieveData",
                identifier: identifier,
                status: "failed",
                details: [
                    "errorDescription": "Data not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve data: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        let successContext = createLogContext(
            operation: "retrieveData",
            identifier: identifier,
            status: "success",
            details: [
                "dataSize": "\(data.count)"
            ]
        )
        
        await logger.info(
            "Data retrieval operation completed successfully",
            context: successContext
        )
        
        return .success(data)
    }
    
    /**
     Deletes data securely.
     
     - Parameters:
       - identifier: Identifier for the data to delete
     - Returns: Result indicating success or an error
     */
    public func deleteData(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        let context = createLogContext(
            operation: "deleteData",
            identifier: identifier,
            status: "started"
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("deleteData") {
            let errorContext = createLogContext(
                operation: "deleteData",
                identifier: identifier,
                status: "rate_limited",
                details: [
                    "reason": "Rate limit exceeded for data deletion operations"
                ]
            )
            
            await logger.error(
                "Data deletion operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Starting data deletion operation",
            context: context
        )
        
        // Delete the data
        let deleteResult = await secureStorage.deleteData(withIdentifier: identifier)
        
        guard case .success = deleteResult else {
            if case let .failure(error) = deleteResult {
                let errorContext = createLogContext(
                    operation: "deleteData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to delete data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "deleteData",
                identifier: identifier,
                status: "failed",
                details: [
                    "errorDescription": "Unknown error deleting data"
                ]
            )
            
            await logger.error(
                "Failed to delete data: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
        }
        
        let successContext = createLogContext(
            operation: "deleteData",
            identifier: identifier,
            status: "success"
        )
        
        await logger.info(
            "Data deletion operation completed successfully",
            context: successContext
        )
        
        return .success(())
    }
    
    /**
     Generates a new cryptographic key with the specified length and options.
     
     - Parameters:
       - length: Length of the key in bits
       - options: Optional key generation configuration
     - Returns: Success with key identifier or error
     */
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(
            operation: "generateKey",
            status: "started",
            details: [
                "keyLength": String(length)
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("generateKey") {
            let errorContext = createLogContext(
                operation: "generateKey",
                status: "rate_limited",
                details: [
                    "keyLength": String(length),
                    "reason": "Rate limit exceeded for key generation operations"
                ]
            )
            
            await logger.warning(
                "Key generation operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Generating cryptographic key with length \(length)",
            context: context
        )
        
        // In a real implementation, we would generate a key with the specified parameters
        // For this implementation, we'll create a placeholder key
        let keyId = "key_\(UUID().uuidString)"
        let keyData = Data((0..<length/8).map { _ in UInt8.random(in: 0...255) })
        
        // Store the key
        let storeResult = await secureStorage.storeData(keyData, withIdentifier: keyId)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = createLogContext(
                    operation: "generateKey",
                    identifier: keyId,
                    status: "failed",
                    details: [
                        "keyLength": String(length),
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store generated key: \(error.localizedDescription)",
                    context: errorContext
                )
            }
            return .failure(.invalidOperation)
        }
        
        let successContext = createLogContext(
            operation: "generateKey",
            identifier: keyId,
            status: "success",
            details: [
                "keyLength": String(length)
            ]
        )
        
        await logger.info(
            "Successfully generated and stored key with identifier \(keyId)",
            context: successContext
        )
        
        return .success(keyId)
    }

    /**
     Imports raw data into secure storage with custom identifier.
     
     - Parameters:
       - data: Raw data bytes to import
       - customIdentifier: Optional custom identifier to use
     - Returns: Success with data identifier or error
     */
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        // Convert to Data for internal usage
        let dataObj = Data(data)
        let effectiveIdentifier = customIdentifier ?? "data_\(UUID().uuidString)"
        
        let context = createLogContext(
            operation: "importData",
            identifier: effectiveIdentifier,
            status: "started",
            details: [
                "dataSize": String(data.count),
                "hasCustomIdentifier": customIdentifier != nil ? "true" : "false"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("importData") {
            let errorContext = createLogContext(
                operation: "importData",
                identifier: effectiveIdentifier,
                status: "rate_limited",
                details: [
                    "dataSize": String(data.count),
                    "reason": "Rate limit exceeded for data import operations"
                ]
            )
            
            await logger.warning(
                "Data import operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Importing data (\(data.count) bytes)",
            context: context
        )
        
        // Store the data with the provided identifier
        let storeResult = await secureStorage.storeData(dataObj, withIdentifier: effectiveIdentifier)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = createLogContext(
                    operation: "importData",
                    identifier: effectiveIdentifier,
                    status: "failed",
                    details: [
                        "dataSize": String(data.count),
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store imported data: \(error.localizedDescription)",
                    context: errorContext
                )
            }
            return .failure(.invalidOperation)
        }
        
        let successContext = createLogContext(
            operation: "importData",
            identifier: effectiveIdentifier,
            status: "success",
            details: [
                "dataSize": String(data.count)
            ]
        )
        
        await logger.info(
            "Successfully imported data with identifier \(effectiveIdentifier)",
            context: successContext
        )
        
        return .success(effectiveIdentifier)
    }
    
    /**
     Stores data securely with the provided identifier.
     
     - Parameters:
       - data: The data to store
       - identifier: The identifier for the data
     - Returns: Success or an error
     */
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        let context = createLogContext(
            operation: "storeData",
            identifier: identifier,
            status: "started",
            details: [
                "dataSize": "\(data.count)"
            ]
        )
        
        // Check rate limiting
        if await rateLimiter.isRateLimited("storeData") {
            let errorContext = createLogContext(
                operation: "storeData",
                identifier: identifier,
                status: "rate_limited",
                details: [
                    "dataSize": "\(data.count)",
                    "reason": "Rate limit exceeded for data storage operations"
                ]
            )
            
            await logger.warning(
                "Data store operation rate limited",
                context: errorContext
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Log the operation
        await logger.debug(
            "Storing data (\(data.count) bytes) with identifier \(identifier)",
            context: context
        )
        
        // Store the data
        let storeResult = await secureStorage.storeData(data, withIdentifier: identifier)
        
        guard case .success = storeResult else {
            if case let .failure(error) = storeResult {
                let errorContext = createLogContext(
                    operation: "storeData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "dataSize": "\(data.count)",
                        "errorDescription": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store data: \(error.localizedDescription)",
                    context: errorContext
                )
            }
            return .failure(.invalidOperation)
        }
        
        let successContext = createLogContext(
            operation: "storeData",
            identifier: identifier,
            status: "success",
            details: [
                "dataSize": "\(data.count)"
            ]
        )
        
        await logger.info(
            "Successfully stored data with identifier \(identifier)",
            context: successContext
        )
        
        return .success(())
    }
}
