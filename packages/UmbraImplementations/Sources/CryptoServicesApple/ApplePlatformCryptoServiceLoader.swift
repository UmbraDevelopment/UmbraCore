import CryptoInterfaces
import CryptoServicesCore
import SecurityInterfaces
import LoggingInterfaces
import BuildConfig
import Foundation

/**
 # ApplePlatformCryptoServiceLoader
 
 Loader for the Apple-native CryptoKit-based crypto service implementation.
 
 This loader creates instances of the ApplePlatformCryptoService, which provides
 optimised cryptographic operations specifically for Apple platforms using
 the CryptoKit framework with hardware acceleration where available.
 */
public enum ApplePlatformCryptoServiceLoader: CryptoServiceLoader {
    /**
     Creates an Apple platform-specific crypto service implementation.
     
     - Parameters:
       - secureStorage: The secure storage to use
       - logger: Optional logger for recording operations
       - environment: The environment configuration
     - Returns: An ApplePlatformCryptoService implementation
     */
    public static func createService(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) async -> CryptoServiceProtocol {
        return await ApplePlatformCryptoService(
            secureStorage: secureStorage,
            logger: logger,
            environment: environment
        )
    }
}
