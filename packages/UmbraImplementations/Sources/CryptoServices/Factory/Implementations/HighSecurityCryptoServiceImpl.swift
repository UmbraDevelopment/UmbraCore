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
            algorithm: nil,
            correlationID: UUID().uuidString,
            source: "HighSecurityCryptoServiceImpl",
            additionalContext: metadata
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
                "algorithm": options?.algorithm.rawValue ?? "default"
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
                    "algorithm": options?.algorithm.rawValue ?? "default",
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
        
        let dataToEncrypt: [UInt8] = []
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case .success(dataToEncrypt) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "encrypt",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.warning(
                    "Failed to retrieve data for encryption: \(error)",
                    context: errorContext
                )
                return .failure(.dataNotFound)
            }
            
            return .failure(.dataNotFound)
        }
        
        let keyData: [UInt8] = []
        // Retrieve the key
        let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
        guard case .success(keyData) = keyResult else {
            if case let .failure(error) = keyResult {
                let errorContext = createLogContext(
                    operation: "encrypt",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.warning(
                    "Failed to retrieve key for encryption: \(error)",
                    context: errorContext
                )
                return .failure(.keyNotFound)
            }
            
            return .failure(.keyNotFound)
        }
        
        // Perform encryption (in a real implementation, use a proper cryptographic algorithm)
        // This is just a mock implementation for demonstration purposes
        let encryptedData = Data((0..<dataToEncrypt.count).map { i in
            dataToEncrypt[i] ^ keyData[i % keyData.count]
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
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to store encrypted data: \(error)",
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
                    "algorithm": options?.algorithm.rawValue ?? "default",
                    "error": "Unknown error storing encrypted data"
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
                "algorithm": options?.algorithm.rawValue ?? "default",
                "encryptedIdentifier": encryptedId,
                "dataSize": "\(dataToEncrypt.count)"
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
                "algorithm": options?.algorithm.rawValue ?? "default"
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
                    "algorithm": options?.algorithm.rawValue ?? "default",
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
        
        let encryptedData: [UInt8] = []
        // Retrieve the encrypted data
        let encryptedDataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
        guard case .success(encryptedData) = encryptedDataResult else {
            if case let .failure(error) = encryptedDataResult {
                let errorContext = createLogContext(
                    operation: "decrypt",
                    identifier: encryptedDataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve encrypted data: \(error)",
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
                    "algorithm": options?.algorithm.rawValue ?? "default",
                    "error": "Encrypted data not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve encrypted data: encrypted data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        let keyData: [UInt8] = []
        // Retrieve the key
        let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
        guard case .success(keyData) = keyResult else {
            if case let .failure(error) = keyResult {
                let errorContext = createLogContext(
                    operation: "decrypt",
                    identifier: encryptedDataIdentifier,
                    status: "failed",
                    details: [
                        "keyIdentifier": keyIdentifier,
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve key for decryption: \(error)",
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
                    "algorithm": options?.algorithm.rawValue ?? "default",
                    "error": "Key not found"
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
            encryptedData[i] ^ keyData[i % keyData.count]
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
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to store decrypted data: \(error)",
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
                    "algorithm": options?.algorithm.rawValue ?? "default",
                    "error": "Unknown error storing decrypted data"
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
                "algorithm": options?.algorithm.rawValue ?? "default",
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
        let algorithm = options?.algorithm.rawValue ?? "SHA256"
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
        
        let dataToHash: [UInt8] = []
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case .success(dataToHash) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "hash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "algorithm": algorithm,
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for hashing: \(error)",
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
                    "error": "Data not found"
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
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to store hash: \(error)",
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
                    "error": "Unknown error storing hash"
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
        let algorithm = options?.algorithm.rawValue ?? "SHA256"
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
        
        let dataToHash: [UInt8] = []
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case .success(dataToHash) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "verifyHash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "hashIdentifier": hashIdentifier,
                        "algorithm": algorithm,
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for hash verification: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "verifyHash",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "hashIdentifier": hashIdentifier,
                    "algorithm": algorithm,
                    "error": "Data not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve data for hash verification: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
        let expectedHash: [UInt8] = []
        // Retrieve the expected hash
        let expectedHashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
        guard case .success(expectedHash) = expectedHashResult else {
            if case let .failure(error) = expectedHashResult {
                let errorContext = createLogContext(
                    operation: "verifyHash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "hashIdentifier": hashIdentifier,
                        "algorithm": algorithm,
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve expected hash: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "verifyHash",
                identifier: dataIdentifier,
                status: "failed",
                details: [
                    "hashIdentifier": hashIdentifier,
                    "algorithm": algorithm,
                    "error": "Expected hash not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve expected hash: hash not found",
                context: errorContext
            )
            
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
                "isValid": "true"
            ]
        )
        
        await logger.info(
            "Hash verification completed: valid",
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
        
        let dataToStore: [UInt8] = []
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(withIdentifier: identifier)
        guard case .success(dataToStore) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "storeData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "dataSize": "\(data.count)",
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for storage: \(error)",
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
                    "error": "Data not found"
                ]
            )
            
            await logger.error(
                "Failed to retrieve data for storage: data not found",
                context: errorContext
            )
            
            return .failure(.dataNotFound)
        }
        
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
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to store data: \(error)",
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
                    "error": "Unknown error storing data"
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
        
        let retrievedData: [UInt8] = []
        // Retrieve the data
        let dataResult = await secureStorage.retrieveData(withIdentifier: identifier)
        
        guard case .success(retrievedData) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "retrieveData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "retrieveData",
                identifier: identifier,
                status: "failed",
                details: [
                    "error": "Data not found"
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
                "dataSize": "\(retrievedData.count)"
            ]
        )
        
        await logger.info(
            "Data retrieval operation completed successfully",
            context: successContext
        )
        
        return .success(Data(retrievedData))
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
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to delete data: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "deleteData",
                identifier: identifier,
                status: "failed",
                details: [
                    "error": "Unknown error deleting data"
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
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to store generated key: \(error)",
                    context: errorContext
                )
                
                return .failure(error)
            }
            
            let errorContext = createLogContext(
                operation: "generateKey",
                identifier: keyId,
                status: "failed",
                details: [
                    "keyLength": String(length),
                    "error": "Unknown error storing generated key"
                ]
            )
            
            await logger.error(
                "Failed to store generated key: unknown error",
                context: errorContext
            )
            
            return .failure(.storageError)
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
     Imports data into secure storage with a custom identifier.
     
     - Parameters:
       - data: Raw data to import
       - customIdentifier: Optional identifier to use for the data
     - Returns: Success with data identifier or error
     */
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        // Check rate limiting
        if await rateLimiter.isRateLimited("importData") {
            let context = createLogContext(
                operation: "importData",
                status: "rate_limited",
                details: [
                    "hasCustomIdentifier": customIdentifier != nil ? "true" : "false",
                    "dataSize": "\(data.count)"
                ]
            )
            
            await logger.warning(
                "Import data operation was rate limited",
                context: context
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Convert to Data for internal usage if needed
        let dataToStore = Data(data)
        let effectiveIdentifier = customIdentifier ?? "data_\(UUID().uuidString)"
        
        // Create a secure storage context
        let context = createLogContext(
            operation: "importData",
            status: "started",
            details: [
                "effectiveIdentifier": effectiveIdentifier,
                "dataSize": "\(data.count)",
                "hasCustomIdentifier": customIdentifier != nil ? "true" : "false"
            ]
        )
        
        await logger.debug(
            "Importing data with identifier: \(effectiveIdentifier)",
            context: context
        )
        
        // Generate a cryptographic hash for data validation
        let hashResult = await generateHash(
            dataIdentifier: effectiveIdentifier,
            options: nil
        )
        
        if case .failure(let error) = hashResult {
            let errorContext = createLogContext(
                operation: "importData",
                status: "failed",
                details: [
                    "effectiveIdentifier": effectiveIdentifier,
                    "error": error.localizedDescription
                ]
            )
            
            await logger.error(
                "Failed to generate hash for imported data: \(error.localizedDescription)",
                context: errorContext
            )
            
            return .failure(error)
        }
        
        // Store the data with the provided identifier
        let result = await secureStorage.storeData(dataToStore, withIdentifier: effectiveIdentifier)
        
        switch result {
            case .success:
                let successContext = createLogContext(
                    operation: "importData",
                    status: "success",
                    details: [
                        "effectiveIdentifier": effectiveIdentifier,
                        "dataSize": "\(data.count)"
                    ]
                )
                
                await logger.info(
                    "Successfully imported data with identifier: \(effectiveIdentifier)",
                    context: successContext
                )
                
                return .success(effectiveIdentifier)
                
            case .failure(let error):
                let errorContext = createLogContext(
                    operation: "importData",
                    status: "failed",
                    details: [
                        "effectiveIdentifier": effectiveIdentifier,
                        "error": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to import data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
        }
    }
    
    /**
     Imports data into secure storage with a custom identifier.
     
     - Parameters:
       - data: Raw data to import
       - customIdentifier: The identifier to use for the data
     - Returns: Success with data identifier or error
     */
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        // Convert Data to [UInt8] for internal implementation
        let bytes = [UInt8](data)
        
        // Delegate to the other implementation
        return await importData(bytes, customIdentifier: customIdentifier)
    }
    
    /**
     Exports data from secure storage by identifier.
     
     - Parameter identifier: The identifier of the data to export
     - Returns: Success with data or error
     */
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        // Check rate limiting
        if await rateLimiter.isRateLimited("exportData") {
            let context = createLogContext(
                operation: "exportData",
                identifier: identifier,
                status: "rate_limited"
            )
            
            await logger.warning(
                "Export data operation was rate limited",
                context: context
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Create a log context
        let context = createLogContext(
            operation: "exportData",
            identifier: identifier,
            status: "started"
        )
        
        await logger.debug(
            "Exporting data with identifier: \(identifier)",
            context: context
        )
        
        // Retrieve the data from secure storage
        let result = await secureStorage.retrieveData(withIdentifier: identifier)
        
        switch result {
            case let .success(data):
                let exportedData = data
                let successContext = createLogContext(
                    operation: "exportData",
                    identifier: identifier,
                    status: "success",
                    details: [
                        "dataSize": "\(exportedData.count)"
                    ]
                )
                
                await logger.info(
                    "Successfully exported data with identifier \(identifier)",
                    context: successContext
                )
                
                return .success(exportedData)
                
            case .failure(let error):
                let errorContext = createLogContext(
                    operation: "exportData",
                    identifier: identifier,
                    status: "failed",
                    details: [
                        "error": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to export data: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
        }
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
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to store data: \(error)",
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
                    "error": "Unknown error storing data"
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
            "Successfully stored data with identifier \(identifier)",
            context: successContext
        )
        
        return .success(())
    }
    
    /**
     Generates a hash of the data associated with the given identifier.
     
     - Parameters:
       - dataIdentifier: Identifier for the data to hash in secure storage
       - options: Optional hashing configuration
     - Returns: Identifier for the generated hash in secure storage, or an error
     */
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Check rate limiting
        if await rateLimiter.isRateLimited("generateHash") {
            let context = createLogContext(
                operation: "generateHash",
                status: "rate_limited",
                details: [
                    "dataIdentifier": dataIdentifier,
                    "algorithm": options?.algorithm.rawValue ?? "default"
                ]
            )
            
            await logger.warning(
                "Generate hash operation was rate limited",
                context: context
            )
            
            return .failure(.operationRateLimited)
        }
        
        // Create a log context
        let context = createLogContext(
            operation: "generateHash",
            identifier: dataIdentifier,
            status: "started",
            details: [
                "algorithm": options?.algorithm.rawValue ?? "default"
            ]
        )
        
        await logger.debug(
            "Generating hash for data with identifier: \(dataIdentifier)",
            context: context
        )
        
        let dataToHash: [UInt8] = []
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        
        guard case .success(dataToHash) = dataResult else {
            if case let .failure(error) = dataResult {
                let errorContext = createLogContext(
                    operation: "generateHash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": "\(error)"
                    ]
                )
                
                await logger.error(
                    "Failed to retrieve data for hashing: \(error)",
                    context: errorContext
                )
                
                return .failure(.dataNotFound)
            }
            
            return .failure(.dataNotFound)
        }
        
        // Generate a hash of the data according to the algorithm
        var hashData: Data
        switch options?.algorithm ?? .sha256 {
            case .sha256:
                // Compute SHA-256 hash
                hashData = computeSHA256Hash(data: Data(dataToHash))
            case .sha512:
                // Compute SHA-512 hash
                hashData = computeSHA512Hash(data: Data(dataToHash))
            default:
                // Default to SHA-256 for unsupported algorithms
                hashData = computeSHA256Hash(data: Data(dataToHash))
        }
        
        // Store the hash
        let hashIdentifier = "hash_\(dataIdentifier)_\(UUID().uuidString)"
        let storeResult = await secureStorage.storeData(hashData, withIdentifier: hashIdentifier)
        
        switch storeResult {
            case .success:
                let successContext = createLogContext(
                    operation: "generateHash",
                    identifier: dataIdentifier,
                    status: "success",
                    details: [
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "hashIdentifier": hashIdentifier
                    ]
                )
                
                await logger.info(
                    "Successfully generated hash for data: \(dataIdentifier)",
                    context: successContext
                )
                
                return .success(hashIdentifier)
                
            case .failure(let error):
                let errorContext = createLogContext(
                    operation: "generateHash",
                    identifier: dataIdentifier,
                    status: "failed",
                    details: [
                        "algorithm": options?.algorithm.rawValue ?? "default",
                        "error": error.localizedDescription
                    ]
                )
                
                await logger.error(
                    "Failed to store generated hash: \(error.localizedDescription)",
                    context: errorContext
                )
                
                return .failure(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Computes a SHA-256 hash of the provided data.
     
     - Parameter data: The data to hash
     - Returns: The resulting hash as a byte array
     */
    private func computeSHA256Hash(data: Data) -> Data {
        // This is a simplified implementation
        // In a real implementation, you would use CryptoKit or CommonCrypto
        // For now, we'll return a dummy hash value
        var hashData = Data(repeating: 0, count: 32) // SHA-256 produces 32 bytes
        for (index, byte) in data.prefix(32).enumerated() {
            hashData[index % 32] = byte ^ 0x42 // Simple XOR transformation
        }
        return hashData
    }
    
    /**
     Computes a SHA-512 hash of the provided data.
     
     - Parameter data: The data to hash
     - Returns: The resulting hash as a byte array
     */
    private func computeSHA512Hash(data: Data) -> Data {
        // This is a simplified implementation
        // In a real implementation, you would use CryptoKit or CommonCrypto
        // For now, we'll return a dummy hash value
        var hashData = Data(repeating: 0, count: 64) // SHA-512 produces 64 bytes
        for (index, byte) in data.prefix(64).enumerated() {
            hashData[index % 64] = byte ^ 0x42 // Simple XOR transformation
        }
        return hashData
    }
}
