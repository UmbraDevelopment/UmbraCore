import CryptoTypes
import CoreDTOs
import LoggingInterfaces
import DomainSecurityTypes
import UmbraErrors
import XPCProtocolsCore
import SecurityCoreInterfaces

/**
 # CryptoXPCServiceActor
 
 Provides cryptographic operations via XPC with proper actor isolation.
 
 This actor encapsulates all cryptographic operations and ensures thread safety
 through Swift concurrency. It handles:
 - Encryption and decryption operations
 - Key management
 - Cryptographic signing and verification
 - Secure random generation
 
 All operations follow the Alpha Dot Five architecture with:
 - Foundation-independent DTOs for data exchange
 - Domain-specific error types
 - Proper actor isolation for all mutable state
 */
public actor CryptoXPCServiceActor: CryptoXPCServiceProtocol {
    // MARK: - Private properties
    
    /// Logger for recording operations and errors
    private let logger: LoggingProtocol
    
    /// Domain-specific logger for crypto operations
    private let cryptoLogger: CryptoLogger
    
    /// Crypto provider for performing operations
    private let cryptoProvider: CryptoProviderProtocol
    
    /// Key store for key management
    private let keyStore: KeyStoreProtocol
    
    // MARK: - Initialisation
    
    /**
     Initialises a new crypto XPC service actor.
     
     - Parameters:
        - cryptoProvider: The provider for cryptographic operations
        - keyStore: The storage for cryptographic keys
        - logger: Logger for recording operations and errors
     */
    public init(
        cryptoProvider: CryptoProviderProtocol,
        keyStore: KeyStoreProtocol,
        logger: LoggingProtocol
    ) {
        self.cryptoProvider = cryptoProvider
        self.keyStore = keyStore
        self.logger = logger
        self.cryptoLogger = CryptoLogger(logger: logger)
    }
    
    // MARK: - Encryption Operations
    
    /**
     Encrypts data using the specified key.
     
     - Parameters:
        - data: The data to encrypt as SecureBytes
        - keyIdentifier: The identifier of the key to use
        - options: Optional configuration options
     
     - Returns: Result with encrypted data as SecureBytes or error
     */
    public func encrypt(
        data: SecureBytes,
        keyIdentifier: String,
        options: CryptoOperationOptionsDTO? = nil
    ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "encrypt",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPrivate(key: "dataSize", value: String(data.bytes.count))
        )
        
        // Validate input
        guard !keyIdentifier.isEmpty else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Empty key identifier")
            await cryptoLogger.logOperationError(
                operation: "encrypt",
                error: error
            )
            return .failure(error)
        }
        
        // Retrieve key
        let keyResult = await keyStore.retrieveKey(identifier: keyIdentifier)
        
        switch keyResult {
        case .success(let key):
            let encryptResult = await cryptoProvider.encrypt(data: data, key: key, options: options)
            
            switch encryptResult {
            case .success(let encryptedData):
                await cryptoLogger.logOperationSuccess(
                    operation: "encrypt",
                    additionalContext: LogMetadataDTOCollection()
                        .withPrivate(key: "resultSize", value: String(encryptedData.bytes.count))
                )
                return .success(encryptedData)
                
            case .failure(let error):
                await cryptoLogger.logOperationError(
                    operation: "encrypt",
                    error: error
                )
                return .failure(error)
            }
            
        case .failure(let error):
            let cryptoError = UmbraErrors.Crypto.Core.keyError("Failed to retrieve key: \(error)")
            await cryptoLogger.logOperationError(
                operation: "encrypt",
                error: cryptoError
            )
            return .failure(cryptoError)
        }
    }
    
    /**
     Decrypts data using the specified key.
     
     - Parameters:
        - encryptedData: The encrypted data as SecureBytes
        - keyIdentifier: The identifier of the key to use
        - options: Optional configuration options
     
     - Returns: Result with decrypted data as SecureBytes or error
     */
    public func decrypt(
        encryptedData: SecureBytes,
        keyIdentifier: String,
        options: CryptoOperationOptionsDTO? = nil
    ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "decrypt",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPrivate(key: "dataSize", value: String(encryptedData.bytes.count))
        )
        
        // Validate input
        guard !keyIdentifier.isEmpty else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Empty key identifier")
            await cryptoLogger.logOperationError(
                operation: "decrypt",
                error: error
            )
            return .failure(error)
        }
        
        // Retrieve key
        let keyResult = await keyStore.retrieveKey(identifier: keyIdentifier)
        
        switch keyResult {
        case .success(let key):
            let decryptResult = await cryptoProvider.decrypt(
                encryptedData: encryptedData,
                key: key,
                options: options
            )
            
            switch decryptResult {
            case .success(let decryptedData):
                await cryptoLogger.logOperationSuccess(
                    operation: "decrypt",
                    additionalContext: LogMetadataDTOCollection()
                        .withPrivate(key: "resultSize", value: String(decryptedData.bytes.count))
                )
                return .success(decryptedData)
                
            case .failure(let error):
                await cryptoLogger.logOperationError(
                    operation: "decrypt",
                    error: error
                )
                return .failure(error)
            }
            
        case .failure(let error):
            let cryptoError = UmbraErrors.Crypto.Core.keyError("Failed to retrieve key: \(error)")
            await cryptoLogger.logOperationError(
                operation: "decrypt",
                error: cryptoError
            )
            return .failure(cryptoError)
        }
    }
    
    // MARK: - Key Management
    
    /**
     Generates a new cryptographic key.
     
     - Parameters:
        - options: Key generation options including strength and algorithm
        - metadata: Optional metadata to associate with the key
     
     - Returns: Result with key identifier or error
     */
    public func generateKey(
        options: KeyGenerationOptionsDTO,
        metadata: KeyMetadataDTO? = nil
    ) async -> Result<String, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "generateKey",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "algorithm", value: options.algorithm.rawValue)
                .withPrivate(key: "keySize", value: String(options.keySize))
        )
        
        // Generate key
        let generateResult = await cryptoProvider.generateKey(options: options)
        
        switch generateResult {
        case .success(let key):
            // Create metadata if not provided
            let keyMetadata = metadata ?? KeyMetadataDTO(
                algorithm: options.algorithm,
                keySize: options.keySize,
                creationDate: TimePointDTO.now(),
                name: "Generated key",
                description: "Automatically generated key",
                tags: []
            )
            
            // Store key with metadata
            let storeResult = await keyStore.storeKey(key: key, metadata: keyMetadata)
            
            switch storeResult {
            case .success(let identifier):
                await cryptoLogger.logOperationSuccess(
                    operation: "generateKey",
                    additionalContext: LogMetadataDTOCollection()
                        .withPrivate(key: "identifier", value: identifier)
                )
                return .success(identifier)
                
            case .failure(let error):
                let cryptoError = UmbraErrors.Crypto.Core.keyError(
                    "Failed to store generated key: \(error)"
                )
                await cryptoLogger.logOperationError(
                    operation: "generateKey",
                    error: cryptoError
                )
                return .failure(cryptoError)
            }
            
        case .failure(let error):
            await cryptoLogger.logOperationError(
                operation: "generateKey",
                error: error
            )
            return .failure(error)
        }
    }
    
    /**
     Exports a cryptographic key.
     
     - Parameter keyIdentifier: The identifier of the key to export
     
     - Returns: Result with the key material as SecureBytes or error
     */
    public func exportKey(
        keyIdentifier: String
    ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "exportKey",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        )
        
        // Validate input
        guard !keyIdentifier.isEmpty else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Empty key identifier")
            await cryptoLogger.logOperationError(
                operation: "exportKey",
                error: error
            )
            return .failure(error)
        }
        
        // Export key
        let exportResult = await keyStore.exportKey(identifier: keyIdentifier)
        
        switch exportResult {
        case .success(let keyData):
            await cryptoLogger.logOperationSuccess(
                operation: "exportKey",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "keyDataSize", value: String(keyData.bytes.count))
            )
            return .success(keyData)
            
        case .failure(let error):
            let cryptoError = UmbraErrors.Crypto.Core.keyError("Failed to export key: \(error)")
            await cryptoLogger.logOperationError(
                operation: "exportKey",
                error: cryptoError
            )
            return .failure(cryptoError)
        }
    }
    
    /**
     Imports a cryptographic key.
     
     - Parameters:
        - keyData: The key material as SecureBytes
        - metadata: Metadata for the imported key
     
     - Returns: Result with key identifier or error
     */
    public func importKey(
        keyData: SecureBytes,
        metadata: KeyMetadataDTO
    ) async -> Result<String, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "importKey",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyDataSize", value: String(keyData.bytes.count))
                .withPrivate(key: "algorithm", value: metadata.algorithm.rawValue)
        )
        
        // Import key
        let importResult = await cryptoProvider.validateKey(keyData: keyData, metadata: metadata)
        
        switch importResult {
        case .success(let key):
            // Store key with metadata
            let storeResult = await keyStore.storeKey(key: key, metadata: metadata)
            
            switch storeResult {
            case .success(let identifier):
                await cryptoLogger.logOperationSuccess(
                    operation: "importKey",
                    additionalContext: LogMetadataDTOCollection()
                        .withPrivate(key: "identifier", value: identifier)
                )
                return .success(identifier)
                
            case .failure(let error):
                let cryptoError = UmbraErrors.Crypto.Core.keyError(
                    "Failed to store imported key: \(error)"
                )
                await cryptoLogger.logOperationError(
                    operation: "importKey",
                    error: cryptoError
                )
                return .failure(cryptoError)
            }
            
        case .failure(let error):
            await cryptoLogger.logOperationError(
                operation: "importKey",
                error: error
            )
            return .failure(error)
        }
    }
    
    /**
     Deletes a cryptographic key.
     
     - Parameter keyIdentifier: The identifier of the key to delete
     
     - Returns: Result with success flag or error
     */
    public func deleteKey(
        keyIdentifier: String
    ) async -> Result<Bool, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "deleteKey",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        )
        
        // Validate input
        guard !keyIdentifier.isEmpty else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Empty key identifier")
            await cryptoLogger.logOperationError(
                operation: "deleteKey",
                error: error
            )
            return .failure(error)
        }
        
        // Delete key
        let deleteResult = await keyStore.deleteKey(identifier: keyIdentifier)
        
        switch deleteResult {
        case .success:
            await cryptoLogger.logOperationSuccess(
                operation: "deleteKey",
                additionalContext: LogMetadataDTOCollection()
                    .withPrivate(key: "keyIdentifier", value: keyIdentifier)
            )
            return .success(true)
            
        case .failure(let error):
            let cryptoError = UmbraErrors.Crypto.Core.keyError("Failed to delete key: \(error)")
            await cryptoLogger.logOperationError(
                operation: "deleteKey",
                error: cryptoError
            )
            return .failure(cryptoError)
        }
    }
    
    // MARK: - Signing and Verification
    
    /**
     Signs data using the specified key.
     
     - Parameters:
        - data: The data to sign
        - keyIdentifier: The identifier of the signing key
        - options: Optional signing options
     
     - Returns: Result with signature as SecureBytes or error
     */
    public func sign(
        data: SecureBytes,
        keyIdentifier: String,
        options: SigningOptionsDTO? = nil
    ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "sign",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPrivate(key: "dataSize", value: String(data.bytes.count))
        )
        
        // Validate input
        guard !keyIdentifier.isEmpty else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Empty key identifier")
            await cryptoLogger.logOperationError(
                operation: "sign",
                error: error
            )
            return .failure(error)
        }
        
        // Retrieve key
        let keyResult = await keyStore.retrieveKey(identifier: keyIdentifier)
        
        switch keyResult {
        case .success(let key):
            let signResult = await cryptoProvider.sign(data: data, key: key, options: options)
            
            switch signResult {
            case .success(let signature):
                await cryptoLogger.logOperationSuccess(
                    operation: "sign",
                    additionalContext: LogMetadataDTOCollection()
                        .withPrivate(key: "signatureSize", value: String(signature.bytes.count))
                )
                return .success(signature)
                
            case .failure(let error):
                await cryptoLogger.logOperationError(
                    operation: "sign",
                    error: error
                )
                return .failure(error)
            }
            
        case .failure(let error):
            let cryptoError = UmbraErrors.Crypto.Core.keyError("Failed to retrieve key: \(error)")
            await cryptoLogger.logOperationError(
                operation: "sign",
                error: cryptoError
            )
            return .failure(cryptoError)
        }
    }
    
    /**
     Verifies a signature against data using the specified key.
     
     - Parameters:
        - signature: The signature to verify
        - data: The original data
        - keyIdentifier: The identifier of the verification key
        - options: Optional verification options
     
     - Returns: Result with verification result or error
     */
    public func verify(
        signature: SecureBytes,
        data: SecureBytes,
        keyIdentifier: String,
        options: SigningOptionsDTO? = nil
    ) async -> Result<Bool, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "verify",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                .withPrivate(key: "dataSize", value: String(data.bytes.count))
                .withPrivate(key: "signatureSize", value: String(signature.bytes.count))
        )
        
        // Validate input
        guard !keyIdentifier.isEmpty else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Empty key identifier")
            await cryptoLogger.logOperationError(
                operation: "verify",
                error: error
            )
            return .failure(error)
        }
        
        // Retrieve key
        let keyResult = await keyStore.retrieveKey(identifier: keyIdentifier)
        
        switch keyResult {
        case .success(let key):
            let verifyResult = await cryptoProvider.verify(
                signature: signature,
                data: data,
                key: key,
                options: options
            )
            
            switch verifyResult {
            case .success(let isValid):
                await cryptoLogger.logOperationSuccess(
                    operation: "verify",
                    additionalContext: LogMetadataDTOCollection()
                        .withPrivate(key: "isValid", value: String(isValid))
                )
                return .success(isValid)
                
            case .failure(let error):
                await cryptoLogger.logOperationError(
                    operation: "verify",
                    error: error
                )
                return .failure(error)
            }
            
        case .failure(let error):
            let cryptoError = UmbraErrors.Crypto.Core.keyError("Failed to retrieve key: \(error)")
            await cryptoLogger.logOperationError(
                operation: "verify",
                error: cryptoError
            )
            return .failure(cryptoError)
        }
    }
    
    // MARK: - Utility Functions
    
    /**
     Generates secure random bytes.
     
     - Parameter length: Number of random bytes to generate
     
     - Returns: Result with random bytes as SecureBytes or error
     */
    public func generateRandomBytes(
        length: Int
    ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "generateRandomBytes",
            additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "length", value: String(length))
        )
        
        // Validate input
        guard length > 0 else {
            let error = UmbraErrors.Crypto.Core.invalidInput("Length must be greater than zero")
            await cryptoLogger.logOperationError(
                operation: "generateRandomBytes",
                error: error
            )
            return .failure(error)
        }
        
        // Generate random bytes
        let randomResult = await cryptoProvider.generateRandomBytes(length: length)
        
        switch randomResult {
        case .success(let randomBytes):
            await cryptoLogger.logOperationSuccess(
                operation: "generateRandomBytes",
                additionalContext: LogMetadataDTOCollection()
                    .withPublic(key: "generated", value: String(randomBytes.bytes.count))
            )
            return .success(randomBytes)
            
        case .failure(let error):
            await cryptoLogger.logOperationError(
                operation: "generateRandomBytes",
                error: error
            )
            return .failure(error)
        }
    }
    
    /**
     Calculates a hash of the provided data.
     
     - Parameters:
        - data: The data to hash
        - algorithm: The hashing algorithm to use
     
     - Returns: Result with hash as SecureBytes or error
     */
    public func hash(
        data: SecureBytes,
        algorithm: HashAlgorithm
    ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core> {
        await cryptoLogger.logOperationStart(
            operation: "hash",
            additionalContext: LogMetadataDTOCollection()
                .withPrivate(key: "dataSize", value: String(data.bytes.count))
                .withPublic(key: "algorithm", value: algorithm.rawValue)
        )
        
        // Calculate hash
        let hashResult = await cryptoProvider.hash(data: data, algorithm: algorithm)
        
        switch hashResult {
        case .success(let hashValue):
            await cryptoLogger.logOperationSuccess(
                operation: "hash",
                additionalContext: LogMetadataDTOCollection()
                    .withPublic(key: "hashSize", value: String(hashValue.bytes.count))
            )
            return .success(hashValue)
            
        case .failure(let error):
            await cryptoLogger.logOperationError(
                operation: "hash",
                error: error
            )
            return .failure(error)
        }
    }
}

/**
 # CryptoLogger
 
 Domain-specific logger for cryptographic operations.
 
 This logger provides standardised logging for all cryptographic operations
 with proper privacy controls and context handling.
 */
fileprivate struct CryptoLogger {
    private let logger: LoggingProtocol
    
    init(logger: LoggingProtocol) {
        self.logger = logger
    }
    
    func logOperationStart(
        operation: String,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        await logger.log(
            level: .debug,
            message: "Starting crypto operation: \(operation)",
            metadata: additionalContext
        )
    }
    
    func logOperationSuccess(
        operation: String,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        await logger.log(
            level: .debug,
            message: "Successfully completed crypto operation: \(operation)",
            metadata: additionalContext
        )
    }
    
    func logOperationError(
        operation: String,
        error: Error,
        additionalContext: LogMetadataDTOCollection? = nil
    ) async {
        var context = additionalContext ?? LogMetadataDTOCollection()
        context = context.withPrivate(key: "error", value: "\(error)")
        
        await logger.log(
            level: .error,
            message: "Failed crypto operation: \(operation)",
            metadata: context
        )
    }
}
