import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import LoggingInterfaces

/**
 # CryptoServices
 
 Main entry point for the actor-based cryptographic services in UmbraCore.
 This provides factory methods to access the various cryptographic actors.
 
 ## Usage
 
 ```swift
 // Create a crypto service actor with a specific provider
 let logger = YourLoggerImplementation()
 let cryptoService = try await CryptoServices.createCryptoServiceActor(
     providerType: .apple,
     logger: logger
 )
 
 // Encrypt data
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```
 */
public enum CryptoServices {
    /**
     Creates a new CryptoServiceActor with the specified provider type.
     
     - Parameters:
        - providerType: The type of security provider to use (optional)
        - logger: Logger for recording operations
     - Returns: A new CryptoServiceActor instance
     */
    public static func createCryptoServiceActor(
        providerType: SecurityProviderType? = nil,
        logger: LoggingProtocol
    ) -> CryptoServiceActor {
        return CryptoServiceActor(providerType: providerType, logger: logger)
    }
    
    /**
     Creates a new SecureStorageActor for key management.
     
     - Parameters:
        - providerType: The type of security provider to use (optional)
        - storageURL: Custom URL for key storage (optional)
        - logger: Logger for recording operations
     - Returns: A new SecureStorageActor instance
     */
    public static func createSecureStorageActor(
        providerType: SecurityProviderType? = nil,
        storageURL: URL? = nil,
        logger: LoggingProtocol
    ) -> SecureStorageActor {
        return SecureStorageActor(
            providerType: providerType,
            storageURL: storageURL,
            logger: logger
        )
    }
    
    /**
     Creates a new ProviderRegistryActor for managing security providers.
     
     - Parameter logger: Logger for recording operations
     - Returns: A new ProviderRegistryActor instance
     */
    public static func createProviderRegistryActor(
        logger: LoggingProtocol
    ) -> ProviderRegistryActor {
        return ProviderRegistryActor(logger: logger)
    }
}
