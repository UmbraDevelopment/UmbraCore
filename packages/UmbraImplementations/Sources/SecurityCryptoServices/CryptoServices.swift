import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # CryptoServices

 Main entry point for the cryptographic services in UmbraCore following
 the Alpha Dot Five architecture principles with actor-based concurrency.

 This provides factory methods to access various cryptographic services
 through a clean interface that avoids implementation details.

 ## Usage

 ```swift
 // Create a crypto service with a specific provider
 let logger = YourLoggerImplementation()
 let cryptoService = await CryptoServices.createCryptoService(
     providerType: .cryptoKit,
     logger: logger
 )

 // Encrypt data - note the await keyword for actor method calls
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```
 */
public enum CryptoServices {
  /**
   Creates a new crypto service with the specified provider type.
   The implementation follows the actor-based concurrency model of the
   Alpha Dot Five architecture.

   - Parameters:
      - providerType: The type of security provider to use
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol
   */
  public static func createCryptoService(
    providerType: SecurityProviderType,
    logger: LoggingProtocol
  ) async -> any CryptoServiceProtocol {
    await CryptoServicesFactory.createCryptoService(
      providerType: providerType,
      logger: logger
    )
  }

  /**
   Creates a new secure storage service for key management.
   The implementation follows the actor-based concurrency model of the
   Alpha Dot Five architecture.

   - Parameters:
      - providerType: The type of security provider to use
      - storageURL: Custom URL for key storage
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of SecureStorageProtocol
   */
  public static func createSecureStorage(
    providerType: SecurityProviderType,
    storageURL: URL,
    logger: LoggingProtocol
  ) async -> any SecureStorageProtocol {
    await CryptoServicesFactory.createSecureStorage(
      providerType: providerType,
      storageURL: storageURL,
      logger: logger
    )
  }

  /**
   Creates a new provider registry for managing security providers.
   The implementation follows the actor-based concurrency model of the
   Alpha Dot Five architecture.

   - Parameter logger: Logger for recording operations
   - Returns: A new actor-based implementation of ProviderRegistryProtocol
   */
  public static func createProviderRegistry(
    logger: LoggingProtocol
  ) async -> any ProviderRegistryProtocol {
    await CryptoServicesFactory.createProviderRegistry(
      logger: logger
    )
  }
}
