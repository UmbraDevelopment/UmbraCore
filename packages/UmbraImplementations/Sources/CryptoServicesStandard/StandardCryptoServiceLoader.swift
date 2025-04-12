import CryptoInterfaces
import CryptoServicesCore
import SecurityInterfaces
import LoggingInterfaces
import BuildConfig
import Foundation

/**
 # StandardCryptoServiceLoader
 
 Loader for the standard AES-based crypto service implementation.
 
 This loader creates instances of the StandardCryptoService, which provides
 general-purpose cryptographic operations using AES for Restic integration.
 */
public enum StandardCryptoServiceLoader: CryptoServiceLoader {
    /**
     Creates a standard crypto service implementation.
     
     - Parameters:
       - secureStorage: The secure storage to use
       - logger: Optional logger for recording operations
       - environment: The environment configuration
     - Returns: A StandardCryptoService implementation
     */
    public static func createService(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) async -> CryptoServiceProtocol {
        return await StandardCryptoService(
            secureStorage: secureStorage,
            logger: logger,
            environment: environment
        )
    }
}
