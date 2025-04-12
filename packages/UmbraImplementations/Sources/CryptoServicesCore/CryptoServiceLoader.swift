import CryptoInterfaces
import SecurityInterfaces
import LoggingInterfaces
import BuildConfig
import Foundation

/**
 # CryptoServiceLoader
 
 Protocol for loading crypto service implementations based on the selected type.
 
 This protocol defines the interface for loader implementations that are responsible
 for instantiating the appropriate crypto service implementation. Each implementation
 module will provide its own loader that conforms to this protocol.
 */
public protocol CryptoServiceLoader {
    /**
     Creates a crypto service implementation.
     
     - Parameters:
       - secureStorage: The secure storage to use
       - logger: Optional logger for recording operations
       - environment: The environment configuration
     - Returns: An implementation of CryptoServiceProtocol
     */
    static func createService(
        secureStorage: SecureStorageProtocol,
        logger: LoggingProtocol?,
        environment: UmbraEnvironment
    ) async -> CryptoServiceProtocol
}
