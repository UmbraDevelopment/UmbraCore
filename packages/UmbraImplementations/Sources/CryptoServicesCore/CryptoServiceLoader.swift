import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # Crypto Service Loader Protocol
 
 Protocol for components that can create cryptographic service implementations.
 This protocol defines the interface for service loaders that can instantiate
 cryptographic services based on specific requirements.
 
 Service loaders are responsible for creating the correct implementation based on
 the requested configuration, including secure storage and logging.
 */
public protocol CryptoServiceLoaderProtocol {
    /**
     Creates a cryptographic service implementation.
     
     This method should create and configure a service implementation based on the
     provided parameters. The implementation may vary based on the platform,
     environment, and other factors.
     
     - Parameters:
        - secureStorage: The secure storage to use with the service
        - logger: Optional logger to use for operations
        - environment: Environment information for configuration
     - Returns: A configured crypto service implementation
     */
    static func createService(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) async -> CryptoServiceProtocol
}
