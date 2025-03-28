import Foundation
import SecurityCoreInterfaces
import LoggingInterfaces
import CryptoServices
import SecurityKeyManagement
import LoggingServices

/**
 # SecurityProviderFactory
 
 Factory for creating instances of the SecurityProviderImpl with appropriate dependencies.
 
 ## Factory Pattern
 
 The factory pattern allows for easy creation of security providers with either:
 - Default dependencies
 - Custom dependencies for testing or specialised scenarios
 */
public enum SecurityProviderFactory {
    /**
     Creates a SecurityProvider with default implementations of all dependencies.
     
     - Parameter logger: Optional custom logger (uses default if nil)
     - Returns: A properly configured SecurityProviderProtocol instance
     */
    public static func createSecurityProvider(
        logger: LoggerProtocol? = nil
    ) async -> SecurityProviderProtocol {
        // Get the default implementations
        let cryptoService = await createDefaultCryptoService()
        let keyManager = await createDefaultKeyManager()
        let actualLogger = logger ?? LoggingServices.createLogger(subsystem: "com.umbra.security")
        
        // Create and return the provider
        return SecurityProviderImpl(
            cryptoService: cryptoService,
            keyManager: keyManager,
            logger: actualLogger
        )
    }
    
    /**
     Creates a SecurityProvider with custom dependencies.
     
     This method is particularly useful for testing scenarios where
     you want to inject mock dependencies.
     
     - Parameters:
       - cryptoService: Custom implementation of CryptoServiceProtocol
       - keyManager: Custom implementation of KeyManagementProtocol
       - logger: Custom implementation of LoggerProtocol
     - Returns: A SecurityProviderProtocol instance with the specified dependencies
     */
    public static func createSecurityProvider(
        cryptoService: CryptoServiceProtocol,
        keyManager: KeyManagementProtocol,
        logger: LoggerProtocol
    ) -> SecurityProviderProtocol {
        return SecurityProviderImpl(
            cryptoService: cryptoService,
            keyManager: keyManager,
            logger: logger
        )
    }
    
    // MARK: - Helper Methods
    
    /**
     Creates the default crypto service implementation.
     
     - Returns: A properly configured CryptoServiceProtocol instance
     */
    private static func createDefaultCryptoService() async -> CryptoServiceProtocol {
        return await CryptoServices.createService()
    }
    
    /**
     Creates the default key management implementation.
     
     - Returns: A properly configured KeyManagementProtocol instance
     */
    private static func createDefaultKeyManager() async -> KeyManagementProtocol {
        return await SecurityKeyManagement.createService()
    }
}
