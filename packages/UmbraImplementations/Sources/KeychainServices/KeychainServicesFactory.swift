import Foundation
import KeychainInterfaces
import SecurityCoreInterfaces
import LoggingInterfaces
import LoggingTypes
import UmbraErrors

/**
 # KeychainServicesFactory
 
 A factory for creating keychain service components that hides implementation details
 and avoids naming conflicts with Swift keywords.
 
 This factory handles the proper instantiation of all keychain services whilst
 providing a clean interface that uses protocol types rather than concrete implementations.
 
 ## Usage
 
 ```swift
 // Create a keychain service with a custom logger
 let logger = YourLoggerImplementation()
 let keychainService = await KeychainServicesFactory.createKeychainService(logger: logger)
 
 // Store a value in the keychain
 try await keychainService.storeValue("MyPassword", forKey: "MyApp.password")
 ```
 */
public enum KeychainServicesFactory {
    // Default service identifier for the keychain
    private static let defaultServiceIdentifier = "com.umbra.keychainservice"
    
    /**
     Creates a new keychain service with the specified logger.
     
     - Parameters:
       - serviceIdentifier: An identifier for the keychain service (optional)
       - logger: Logger for recording operations (optional)
     - Returns: A new implementation of KeychainServiceProtocol
     */
    public static func createKeychainService(
        serviceIdentifier: String? = nil,
        logger: LoggingProtocol? = nil
    ) async -> any KeychainServiceProtocol {
        // Use the standard implementation but return as protocol type
        let actualLogger = logger ?? DefaultLogger()
        
        return KeychainServiceImpl(
            serviceIdentifier: serviceIdentifier ?? defaultServiceIdentifier,
            logger: actualLogger
        )
    }
    
    /**
     Creates a KeychainSecurityActor that integrates keychain and key management services.
     
     This factory method provides a unified interface for operations that require both 
     keychain storage and security key management, such as storing encrypted secrets.
     
     - Parameters:
        - keychainService: Optional custom keychain service (will create default if nil)
        - keyManager: Optional custom key manager (will load from SecurityKeyManagement if nil)
        - logger: Optional custom logger for operation logging
     
     - Returns: A configured KeychainSecurityActor
     */
    public static func createSecurityService(
        keychainService: KeychainServiceProtocol? = nil,
        keyManager: KeyManagementProtocol? = nil,
        logger: LoggingProtocol? = nil
    ) async -> any KeychainSecurityProtocol {
        // Determine which keychain service to use
        let actualKeychainService: KeychainServiceProtocol
        
        if let keychainService = keychainService {
            actualKeychainService = keychainService
        } else {
            actualKeychainService = await createKeychainService(logger: logger)
        }
        
        let actualLogger = logger ?? DefaultLogger()
        
        // For key manager, we need to dynamically load it from SecurityKeyManagement
        let actualKeyManager: KeyManagementProtocol
        
        // Try to create key manager using dynamic loading
        if let factory = try? KeyManagerAsyncFactory.createInstance(),
           let keyManager = await factory.createKeyManager()
        {
            actualKeyManager = keyManager
        } else {
            // Fallback to a basic implementation
            actualKeyManager = SimpleKeyManager(logger: actualLogger)
        }
        
        // Create and return the security implementation
        return await KeychainSecurityImpl(
            keychainService: actualKeychainService,
            keyManager: actualKeyManager,
            logger: actualLogger
        )
    }
}
