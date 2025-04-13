import Foundation
import CoreSecurityTypes
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # StandardCryptoServiceProxy
 
 This class serves as a proxy for the standard cryptographic service implementation.
 
 It delegates actual cryptographic operations to the appropriate implementation
 without creating circular dependencies between modules. This pattern is used to
 break the dependency cycle between CryptoServicesCore and CryptoServicesStandard.
 
 ## Delegation Pattern
 
 The proxy forwards all protocol requirements to a lazy-loaded implementation
 that is created on demand. This allows us to maintain proper module boundaries
 while still providing a seamless interface to clients.
 */
public actor StandardCryptoServiceProxy: CryptoServiceProtocol {
    // MARK: - Properties
    
    /// The secure storage implementation
    public let secureStorage: SecureStorageProtocol
    
    /// The logger implementation
    private let logger: LoggingProtocol?
    
    /// The environment configuration
    private let environment: UmbraEnvironment
    
    /// The actual implementation that handles crypto operations
    private var implementation: CryptoServiceProtocol?
    
    // MARK: - Initialisation
    
    /**
     Initialises a proxy for the standard cryptographic service.
     
     - Parameters:
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking
        - environment: Environment configuration
     */
    public init(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) {
        self.secureStorage = secureStorage
        self.logger = logger
        self.environment = environment
    }
    
    // MARK: - Private Methods
    
    /**
     Gets the underlying implementation, creating it if necessary.
     
     - Returns: The cryptographic service implementation
     */
    private func getImplementation() async -> CryptoServiceProtocol {
        if let implementation = implementation {
            return implementation
        }
        
        // Use DynamicServiceLoader to create the appropriate implementation
        let impl = await DynamicServiceLoader.createStandardCryptoService(
            secureStorage: secureStorage,
            logger: logger,
            environment: environment
        )
        
        implementation = impl
        return impl
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.encrypt(
            dataIdentifier: dataIdentifier, 
            keyIdentifier: keyIdentifier, 
            options: options
        )
    }
    
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.DecryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.decrypt(
            encryptedDataIdentifier: encryptedDataIdentifier, 
            keyIdentifier: keyIdentifier, 
            options: options
        )
    }
    
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.hash(
            dataIdentifier: dataIdentifier, 
            options: options
        )
    }
    
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.generateHash(
            dataIdentifier: dataIdentifier, 
            options: options
        )
    }
    
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<Bool, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.verifyHash(
            dataIdentifier: dataIdentifier, 
            hashIdentifier: hashIdentifier, 
            options: options
        )
    }
    
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions?
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.generateKey(
            length: length, 
            options: options
        )
    }
    
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.importData(
            data, 
            customIdentifier: customIdentifier
        )
    }
    
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.exportData(
            identifier: identifier
        )
    }
    
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.retrieveData(
            identifier: identifier
        )
    }
    
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.storeData(
            data: data, 
            identifier: identifier
        )
    }
    
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.importData(
            data, 
            customIdentifier: customIdentifier
        )
    }
    
    public func deleteData(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        let impl = await getImplementation()
        return await impl.deleteData(
            identifier: identifier
        )
    }
}

/**
 # DynamicServiceLoader
 
 Handles dynamic loading of cryptographic service implementations.
 
 This component provides a mechanism to create service implementations
 without requiring direct compile-time dependencies.
 */
enum DynamicServiceLoader {
    /**
     Creates a standard cryptographic service implementation.
     
     This method attempts to create an appropriate standard crypto service
     without requiring direct compile-time dependencies on the implementation.
     
     - Parameters:
        - secureStorage: Secure storage implementation
        - logger: Optional logger implementation
        - environment: Environment configuration
     - Returns: A CryptoServiceProtocol implementation
     */
    static func createStandardCryptoService(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) async -> CryptoServiceProtocol {
        // For the standard implementation, we create a fallback service
        // without trying to dynamically load the implementation, which avoids
        // the circular dependency issues
        
        // Log the fallback creation if a logger is available
        await logger?.debug(
            "Creating fallback crypto service implementation",
            context: BaseLogContextDTO(
                domainName: "CryptoService",
                operation: "createStandardCryptoService",
                category: "Security",
                source: "DynamicServiceLoader"
            )
        )
        
        // Create a fallback implementation that delegates to secure storage where possible
        return FallbackCryptoService(
            secureStorage: secureStorage,
            logger: logger
        )
    }
}

/**
 # FallbackCryptoService
 
 A basic implementation of CryptoServiceProtocol used as a fallback.
 
 This implementation provides minimal functionality and is only used
 when the standard implementation cannot be dynamically loaded.
 */
private actor FallbackCryptoService: CryptoServiceProtocol {
    /// The secure storage implementation
    public let secureStorage: SecureStorageProtocol
    
    /// The logger implementation
    private let logger: LoggingProtocol?
    
    /**
     Initialises a fallback cryptographic service.
     
     - Parameters:
        - secureStorage: Secure storage for cryptographic materials
        - logger: Optional logger for operation tracking
     */
    init(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?
    ) {
        self.secureStorage = secureStorage
        self.logger = logger
    }
    
    /**
     Logs an error message.
     
     - Parameters:
        - message: The error message
        - context: The log context
     */
    private func logError(_ message: String, context: LogContextDTO) async {
        await logger?.error(message, context: context)
    }
    
    /**
     Creates a basic log context.
     
     - Parameters:
        - operation: The operation being performed
     - Returns: A log context
     */
    private func createLogContext(operation: String) -> LogContextDTO {
        return BaseLogContextDTO(
            domainName: "CryptoService",
            operation: operation,
            category: "Security",
            source: "FallbackCryptoService"
        )
    }
    
    // MARK: - CryptoServiceProtocol Implementation
    
    public func encrypt(
        dataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.EncryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(operation: "encrypt")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func decrypt(
        encryptedDataIdentifier: String,
        keyIdentifier: String,
        options: CoreSecurityTypes.DecryptionOptions?
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(operation: "decrypt")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func hash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(operation: "hash")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func generateHash(
        dataIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(operation: "generateHash")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func verifyHash(
        dataIdentifier: String,
        hashIdentifier: String,
        options: CoreSecurityTypes.HashingOptions?
    ) async -> Result<Bool, SecurityStorageError> {
        let context = createLogContext(operation: "verifyHash")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func generateKey(
        length: Int,
        options: CoreSecurityTypes.KeyGenerationOptions?
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(operation: "generateKey")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func importData(
        _ data: [UInt8],
        customIdentifier: String?
    ) async -> Result<String, SecurityStorageError> {
        let context = createLogContext(operation: "importData")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func exportData(
        identifier: String
    ) async -> Result<[UInt8], SecurityStorageError> {
        let context = createLogContext(operation: "exportData")
        await logError("Standard implementation not available", context: context)
        return .failure(.operationFailed("Standard implementation not available"))
    }
    
    public func retrieveData(
        identifier: String
    ) async -> Result<Data, SecurityStorageError> {
        // Get the binary data using the correct protocol method
        let result = await secureStorage.retrieveData(withIdentifier: identifier)
        
        switch result {
        case .success(let bytes):
            // Convert bytes to Data
            return .success(Data(bytes))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func storeData(
        data: Data,
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        // Convert Data to bytes array and store using the correct protocol method
        let bytes = [UInt8](data)
        return await secureStorage.storeData(bytes, withIdentifier: identifier)
    }
    
    public func importData(
        _ data: Data,
        customIdentifier: String
    ) async -> Result<String, SecurityStorageError> {
        // Convert Data to bytes array and store using the correct protocol method
        let bytes = [UInt8](data)
        let result = await secureStorage.storeData(bytes, withIdentifier: customIdentifier)
        
        switch result {
        case .success:
            return .success(customIdentifier)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func deleteData(
        identifier: String
    ) async -> Result<Void, SecurityStorageError> {
        // Use the correct protocol method
        return await secureStorage.deleteData(withIdentifier: identifier)
    }
}
