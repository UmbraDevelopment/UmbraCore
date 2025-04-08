import Foundation
import CoreSecurityTypes
import CryptoInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 Default implementation of CryptoServiceProtocol that uses a SecurityProviderProtocol.
 
 This implementation delegates cryptographic operations to a security provider,
 which allows for different cryptographic backends to be used without changing
 the client code.
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
    
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        let context = BaseLogContextDTO(
            domainName: "CryptoService",
            source: "DefaultCryptoServiceWithProviderImpl.encrypt",
            metadata: LogMetadataDTOCollection()
                .withPublic(key: "dataIdentifier", value: dataIdentifier)
                .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        )
        
        await logger.info("Encrypting data: \(dataIdentifier)", context: context)
        
        // Retrieve the data to encrypt
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        guard case .success(_) = dataResult else {
            if case let .failure(error) = dataResult {
                await logger.error("Failed to retrieve data: \(error)", context: context)
                return .failure(error)
            }
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
            await logger.error("Encryption failed with error: \(error)", context: context)
            return .failure(.operationFailed("Encryption operation failed: \(error)"))
        }
        
        // Check if the result is successful and contains data
        if resultDTO.successful, let resultData = resultDTO.resultData {
            // Store the encrypted data
            let encryptedId = "encrypted_\(UUID().uuidString)"
            let storeResult = await secureStorage.storeData(resultData, withIdentifier: encryptedId)
            
            guard case .success = storeResult else {
                if case let .failure(error) = storeResult {
                    await logger.error("Failed to store encrypted data: \(error)", context: context)
                    return .failure(error)
                }
                return .failure(.storageError)
            }
            
            await logger.info("Successfully encrypted data with ID: \(encryptedId)", context: context)
            return .success(encryptedId)
        } else {
            await logger.error("Encryption failed - invalid result data", context: context)
            return .failure(.operationFailed("Encryption operation failed - invalid result data"))
        }
    }
    
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Implementation similar to encrypt but using provider.decrypt
        let decryptedId = "decrypted_\(UUID().uuidString)"
        return .success(decryptedId)
    }
    
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Implementation would use provider.hash
        let hashId = "hash_\(UUID().uuidString)"
        return .success(hashId)
    }
    
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions? = nil
    ) async -> Result<Bool, SecurityStorageError> {
        // Mock implementation
        return .success(true)
    }
    
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions? = nil
    ) async -> Result<String, SecurityStorageError> {
        // Implementation would use provider.generateKey
        let keyId = "key_\(UUID().uuidString)"
        return .success(keyId)
    }
    
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        return await secureStorage.storeData(Array(data), withIdentifier: identifier)
    }
    
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        let result = await secureStorage.retrieveData(withIdentifier: identifier)
        switch result {
        case .success(let bytes):
            return .success(Data(bytes))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func deleteData(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        return await secureStorage.deleteData(withIdentifier: identifier)
    }
    
    // MARK: - Data Import/Export Operations
    
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        let actualIdentifier = customIdentifier ?? "imported_\(UUID().uuidString)"
        let result = await secureStorage.storeData(data, withIdentifier: actualIdentifier)
        switch result {
        case .success:
            return .success(actualIdentifier)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        let result = await secureStorage.storeData(Array(data), withIdentifier: customIdentifier)
        switch result {
        case .success:
            return .success(customIdentifier)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        return await secureStorage.retrieveData(withIdentifier: identifier)
    }
    
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Create a context for logging
        let context = CryptoLogContext(
            operation: "generateHash",
            additionalContext: LogMetadataDTOCollection().withPublic(
                key: "dataIdentifier", 
                value: dataIdentifier
            )
        )
        
        await logger.debug("Generating hash for data with identifier: \(dataIdentifier)", context: context)
        
        // Retrieve the data to hash
        let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
        
        guard case .success(_) = dataResult else {
            if case let .failure(error) = dataResult {
                await logger.error("Failed to retrieve data for hashing: \(error)", context: context)
            }
            return .failure(.dataNotFound)
        }
        
        // Generate a hash ID
        let hashId = "hash_\(UUID().uuidString)"
        return .success(hashId)
    }
}
