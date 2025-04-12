import CryptoInterfaces
import SecurityInterfaces
import LoggingInterfaces
import BuildConfig
import CoreSecurityTypes
import LoggingTypes
import CryptoTypes
import Foundation

/**
 # CryptoServiceFactory
 
 Factory for creating CryptoServiceProtocol implementations.
 
 This factory requires explicit selection of which cryptographic implementation to use,
 enforcing a clear decision by the developer rather than relying on automatic selection.
 Each implementation has different characteristics, security properties, and platform
 compatibility that the developer must consider when making a selection.
 
 ## Implementation Types
 
 - `standard`: Default implementation using AES encryption with Restic integration
 - `crossPlatform`: Implementation using RingFFI with Argon2id for any environment
 - `applePlatform`: Apple-native implementation using CryptoKit with optimisations
 
 ## Usage Examples
 
 ```swift
 // Create a factory with explicit service type selection
 let factory = CryptoServiceFactory(serviceType: .standard)
 
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
    private let serviceType: CryptoServiceType
    
    // MARK: - Initialisation
    
    /**
     Initialises a crypto service factory with the explicitly selected service type.
     
     - Parameter serviceType: The type of cryptographic service to create (required)
     */
    public init(serviceType: CryptoServiceType) {
        self.serviceType = serviceType
    }
    
    // MARK: - Service Creation
    
    /**
     Creates a crypto service with the selected implementation type.
     
     - Parameters:
       - secureStorage: Optional secure storage to use
       - logger: Optional logger to use
       - environment: Optional override for the environment configuration
     - Returns: A CryptoServiceProtocol implementation of the selected type
     */
    public func createService(
        secureStorage: SecureStorageProtocol? = nil,
        logger: LoggingProtocol? = nil,
        environment: UmbraEnvironment? = nil
    ) async -> CryptoServiceProtocol {
        // Use the provided environment or fallback to BuildConfig
        let effectiveEnvironment = environment ?? BuildConfig.activeEnvironment
        
        // Create the appropriate secure storage if not provided
        let actualSecureStorage: SecureStorageProtocol = if let secureStorage {
            secureStorage
        } else {
            await createLocalSecureStorage(
                logger: logger,
                environment: effectiveEnvironment
            )
        }
        
        // Update BuildConfig to reflect the explicitly selected service type
        // This ensures any dependent systems use the correct backend strategy
        BuildConfig.activeBackendStrategy = serviceType.backendStrategy
        
        // Log the explicitly selected service type
        if let logger = logger {
            await logger.info(
                "Creating crypto service with explicit type: \(serviceType.rawValue)",
                metadata: [
                    "serviceType": .public(serviceType.rawValue),
                    "environment": .public(effectiveEnvironment.rawValue)
                ]
            )
        }
        
        // Use conditional compilation to load the appropriate implementation
        // Each build configuration will only include one implementation
        #if CRYPTO_IMPLEMENTATION_STANDARD
            // Return the standard implementation
            return await StandardCryptoService(
                secureStorage: actualSecureStorage,
                logger: logger,
                environment: effectiveEnvironment
            )
        #elseif CRYPTO_IMPLEMENTATION_XFN
            // Return the cross-platform implementation
            return await CrossPlatformCryptoService(
                secureStorage: actualSecureStorage,
                logger: logger, 
                environment: effectiveEnvironment
            )
        #elseif CRYPTO_IMPLEMENTATION_APPLE
            // Return the Apple platform-specific implementation
            return await ApplePlatformCryptoService(
                secureStorage: actualSecureStorage,
                logger: logger,
                environment: effectiveEnvironment
            )
        #else
            // For now, in development, we'll return a stub implementation
            // This code path shouldn't be reached in production builds
            return StubCryptoService(
                serviceType: serviceType,
                secureStorage: actualSecureStorage,
                logger: logger, 
                environment: effectiveEnvironment
            )
        #endif
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Creates an appropriate implementation of secure storage for the environment.
     
     - Parameters:
       - logger: Optional logger for the storage operations
       - environment: The environment to configure storage for
     - Returns: A secure storage implementation
     */
    private func createLocalSecureStorage(
        logger: LoggingProtocol? = nil,
        environment: UmbraEnvironment = BuildConfig.activeEnvironment
    ) async -> SecureStorageProtocol {
        // Return a default secure storage implementation
        // In a full implementation, this would create the appropriate secure storage
        // based on the environment and platform
        return TemporarySecureStorage()
    }
}

/**
 Temporary extension to BuildConfig for updating backend strategy.
 
 This would be replaced with a proper mechanism in the final implementation.
 */
extension BuildConfig {
    static func updateBackendStrategy(_ strategy: BackendStrategy) {
        // This is a stub that would be replaced with actual implementation
        // to update the BuildConfig with the selected strategy
    }
}

/**
 # DynamicCryptoServiceLoader
 
 Helper for loading the appropriate crypto service implementation based on the selected type.
 
 This is a temporary stub implementation that will be replaced with actual dynamic
 loading code once the individual implementations are completed.
 */
private enum DynamicCryptoServiceLoader {
    static func loadImplementation(
        type: CryptoServiceType,
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) -> CryptoServiceProtocol {
        // This is a temporary stub implementation
        // In a full implementation, this would dynamically load the correct
        // implementation from the appropriate module
        return StubCryptoService(
            serviceType: type,
            secureStorage: secureStorage,
            logger: logger,
            environment: environment
        )
    }
}

/**
 Temporary stub implementation of SecureStorageProtocol for use during development.
 
 This will be replaced with actual implementations in the production code.
 */
private struct TemporarySecureStorage: SecureStorageProtocol {
    func storeData(_ data: Data, withIdentifier identifier: String) async -> Result<Bool, SecurityStorageError> {
        return .success(true)
    }
    
    func retrieveData(withIdentifier identifier: String) async -> Result<Data, SecurityStorageError> {
        return .failure(.dataNotFound)
    }
    
    func deleteData(withIdentifier identifier: String) async -> Result<Bool, SecurityStorageError> {
        return .success(true)
    }
}

/**
 Temporary stub implementation of CryptoServiceProtocol for use during development.
 
 This will be replaced with actual implementations in the production code.
 */
private struct StubCryptoService: CryptoServiceProtocol {
    let serviceType: CryptoServiceType
    let secureStorage: SecureStorageProtocol
    let logger: LoggingProtocol?
    let environment: UmbraEnvironment
    
    func encrypt(dataIdentifier: String, keyIdentifier: String, options: EncryptionOptions?) async -> Result<String, SecurityStorageError> {
        return .failure(.operationNotSupported("Stub implementation for \(serviceType.rawValue) does not support encrypt"))
    }
    
    func decrypt(dataIdentifier: String, keyIdentifier: String, options: DecryptionOptions?) async -> Result<String, SecurityStorageError> {
        return .failure(.operationNotSupported("Stub implementation for \(serviceType.rawValue) does not support decrypt"))
    }
    
    func verifyHash(dataIdentifier: String, hashIdentifier: String, options: HashingOptions?) async -> Result<Bool, SecurityStorageError> {
        return .failure(.operationNotSupported("Stub implementation for \(serviceType.rawValue) does not support verifyHash"))
    }
    
    func generateKey(length: Int, identifier: String, purpose: KeyPurpose, options: KeyGenerationOptions?) async -> Result<Bool, SecurityStorageError> {
        return .failure(.operationNotSupported("Stub implementation for \(serviceType.rawValue) does not support generateKey"))
    }
    
    func retrieveData(identifier: String) async -> Result<Data, SecurityStorageError> {
        return await secureStorage.retrieveData(withIdentifier: identifier)
    }
    
    func storeData(_ data: Data, identifier: String) async -> Result<Bool, SecurityStorageError> {
        return await secureStorage.storeData(data, withIdentifier: identifier)
    }
}
