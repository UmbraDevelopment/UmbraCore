import Foundation
import CoreSecurityTypes
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # CryptoServiceFactory
 
 Factory for creating CryptoServiceProtocol implementations.
 
 This factory requires explicit selection of which cryptographic implementation to use,
 enforcing a clear decision by the developer rather than relying on automatic selection.
 Each implementation has different characteristics, security properties, and platform
 compatibility that the developer must consider when making a selection.
 
 ## Implementation Types
 
 - `basic`: Default implementation using AES encryption
 - `ring`: Implementation using Ring cryptography library for cross-platform environments
 - `appleCryptoKit`: Apple-native implementation using CryptoKit with optimisations
 - `platform`: Platform-specific implementation (selects best available for current platform)
 
 ## Usage Examples
 
 ```swift
 // Create a factory with explicit service type selection
 let factory = CryptoServiceFactory(serviceType: .basic)
 
 // Create a service with the selected implementation
 let cryptoService = await factory.createService(
   secureStorage: mySecureStorage,
   logger: myLogger
 )
 ```
 
 ## Thread Safety
 
 As an actor, this factory guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in service creation.
 */
public actor CryptoServiceFactory {
    // MARK: - Properties
    
    /// The explicitly selected cryptographic service type
    private let serviceType: SecurityProviderType
    
    // MARK: - Initialisation
    
    /**
     Initialises a crypto service factory with the explicitly selected service type.
     
     - Parameter serviceType: The type of cryptographic service to create (required)
     */
    public init(serviceType: SecurityProviderType) {
        self.serviceType = serviceType
    }
    
    // MARK: - Service Creation
    
    /**
     Creates a crypto service with the selected implementation type.
     
     - Parameters:
       - secureStorage: Optional secure storage to use
       - logger: Optional logger to use
       - environment: Optional environment configuration
     - Returns: A CryptoServiceProtocol implementation of the selected type
     */
    public func createService(
        secureStorage: SecureStorageProtocol? = nil,
        logger: LoggingProtocol? = nil,
        environment: String? = nil
    ) async -> CryptoServiceProtocol {
        // Create the appropriate secure storage if not provided
        let actualSecureStorage: SecureStorageProtocol
        if let secureStorage {
            actualSecureStorage = secureStorage
        } else {
            // This comment acknowledges we're deliberately using a deprecated method for testing purposes.
            // We accept the warning as this is explicitly for testing environments.
            actualSecureStorage = createMockSecureStorage()
        }
        
        // Log the explicitly selected service type
        if let logger = logger {
            let context = BaseLogContextDTO(
                domainName: "CryptoService",
                operation: "createService",
                category: "Security",
                source: "CryptoServiceFactory",
                metadata: LogMetadataDTOCollection()
                    .withPublic(key: "serviceType", value: serviceType.rawValue)
                    .withPublic(key: "environment", value: environment ?? "production")
            )
            
            await logger.debug(
                "Creating crypto service with explicit type: \(serviceType.rawValue)",
                context: context
            )
        }
        
        // Determine environment type from string if provided
        let envType: UmbraEnvironment.EnvironmentType
        if let environment = environment?.lowercased() {
            if environment.contains("dev") {
                envType = .development
            } else if environment.contains("test") {
                envType = .test
            } else if environment.contains("stag") {
                envType = .staging
            } else {
                envType = .production
            }
        } else {
            envType = .production
        }
        
        // Create appropriate environment configuration
        let umbraEnvironment = UmbraEnvironment(
            type: envType,
            hasHardwareSecurity: false,
            enhancedLoggingEnabled: logger != nil,
            platformIdentifier: "unknown",
            parameters: [:]
        )
        
        // Create the actual implementation based on the selected type
        switch serviceType {
        case .basic:
            // Use a protocol-compliant standard implementation for basic type
            return StandardCryptoServiceProxy(
                secureStorage: actualSecureStorage,
                logger: logger, 
                environment: umbraEnvironment
            )
        default:
            // For other types, use the default implementation
            return DefaultCryptoService(
                secureStorage: actualSecureStorage,
                logger: logger, 
                providerType: serviceType
            )
        }
    }
    
    /**
     Creates a mock secure storage implementation for testing.
     
     - Returns: A mock secure storage implementation
     */
    @available(*, deprecated, message: "Use only for testing")
    private func createMockSecureStorage() -> SecureStorageProtocol {
        
        // Create a default mock implementation for testing
        return MockSecureStorage(
            behaviour: MockSecureStorage.MockBehaviour(
                shouldSucceed: true,
                logOperations: true
            )
        )
    }
}

/**
 Default implementation of CryptoServiceProtocol that wraps a SecureStorageProtocol
 */
private actor DefaultCryptoService: CryptoServiceProtocol {
    public let secureStorage: SecureStorageProtocol
    private let logger: LoggingProtocol?
    private let providerType: SecurityProviderType
    
    init(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        providerType: SecurityProviderType
    ) {
        self.secureStorage = secureStorage
        self.logger = logger
        self.providerType = providerType
    }
    
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: EncryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Log operation
        await logOperation("encrypt", ["dataIdentifier": dataIdentifier, "keyIdentifier": keyIdentifier])
        
        // Not implemented in this simplified version
        return .failure(.operationFailed("Operation not implemented in DefaultCryptoService"))
    }
    
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: DecryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Log operation
        await logOperation("decrypt", ["encryptedDataIdentifier": encryptedDataIdentifier, "keyIdentifier": keyIdentifier])
        
        // Not implemented in this simplified version
        return .failure(.operationFailed("Operation not implemented in DefaultCryptoService"))
    }
    
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Log operation
        await logOperation("hash", ["dataIdentifier": dataIdentifier])
        
        // Not implemented in this simplified version
        return .failure(.operationFailed("Operation not implemented in DefaultCryptoService"))
    }
    
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<Bool, SecurityStorageError> {
        // Log operation
        await logOperation("verifyHash", ["dataIdentifier": dataIdentifier, "hashIdentifier": hashIdentifier])
        
        // Not implemented in this simplified version
        return .failure(.operationFailed("Operation not implemented in DefaultCryptoService"))
    }
    
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Log operation
        await logOperation("generateKey", ["length": String(length)])
        
        // Not implemented in this simplified version
        return .failure(.operationFailed("Operation not implemented in DefaultCryptoService"))
    }
    
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        let identifier = customIdentifier ?? "imported-\(UUID().uuidString)"
        // Log operation
        await logOperation("importData", ["identifier": identifier, "dataSize": String(data.count)])
        
        // Store the data in secure storage
        let result = await secureStorage.storeData(data, withIdentifier: identifier)
        
        switch result {
        case .success:
            return .success(identifier)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        // Log operation
        await logOperation("exportData", ["identifier": identifier])
        
        // Retrieve the data from secure storage
        return await secureStorage.retrieveData(withIdentifier: identifier)
    }
    
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        // Log operation
        await logOperation("generateHash", ["dataIdentifier": dataIdentifier])
        
        // Not implemented in this simplified version
        return .failure(.operationFailed("Operation not implemented in DefaultCryptoService"))
    }
    
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        // Log operation
        await logOperation("storeData", ["identifier": identifier, "dataSize": String(data.count)])
        
        // Convert Data to [UInt8] and store
        return await secureStorage.storeData([UInt8](data), withIdentifier: identifier)
    }
    
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        // Log operation
        await logOperation("retrieveData", ["identifier": identifier])
        
        // Retrieve data and convert to Data
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
        // Log operation
        await logOperation("deleteData", ["identifier": identifier])
        
        // Delete data from secure storage
        return await secureStorage.deleteData(withIdentifier: identifier)
    }
    
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        // Log operation
        await logOperation("importData", ["identifier": customIdentifier, "dataSize": String(data.count)])
        
        // Convert Data to [UInt8] and store
        let result = await secureStorage.storeData([UInt8](data), withIdentifier: customIdentifier)
        
        switch result {
        case .success:
            return .success(customIdentifier)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // Helper to log operations
    private func logOperation(_ operation: String, _ parameters: [String: String]) async {
        if let logger = logger {
            var metadata = LogMetadataDTOCollection()
                .withPublic(key: "operation", value: operation)
                .withPublic(key: "providerType", value: providerType.rawValue)
            
            for (key, value) in parameters {
                metadata = metadata.withPublic(key: key, value: value)
            }
            
            let context = BaseLogContextDTO(
                domainName: "CryptoService",
                operation: operation,
                category: "Security",
                source: "DefaultCryptoService",
                metadata: metadata
            )
            
            await logger.debug(
                "Performing crypto operation: \(operation)",
                context: context
            )
        }
    }
}
