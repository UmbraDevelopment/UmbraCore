import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # CryptoServicesFactory

 A factory for creating cryptographic service components without exposing
 implementation details or naming conflicts with Swift keywords.

 This factory handles the proper instantiation of all actor-based cryptographic
 services, avoiding direct references to implementation types that might clash
 with Swift reserved keywords.

 ## Usage

 ```swift
 // Create a crypto service with a specific provider
 let logger = DefaultLogger()
 let cryptoService = await CryptoServicesFactory.createCryptoService(
     providerType: .cryptoKit,
     logger: logger
 )

 // Encrypt data - note the await keyword for actor method calls
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```
 */
public enum CryptoServicesFactory {
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
    // Create the secure storage first
    let storageURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("UmbraSecureStorage", isDirectory: true)
      .appendingPathComponent(UUID().uuidString)
    
    let secureStorage = await createSecureStorage(
      providerType: providerType,
      storageURL: storageURL,
      logger: logger
    )
    
    // Create the provider registry
    let providerRegistry = await createProviderRegistry(logger: logger)
    
    // Now create the crypto service with the dependencies
    let impl = await CryptoActorIntegration.CryptoServiceActor(
      providerRegistry: providerRegistry,
      secureStorage: secureStorage,
      logger: logger
    )

    // Return the implementation as the protocol type
    return impl
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
    // Create secure storage with the specified parameters
    let impl = CryptoActorIntegration.SecureStorageActor(
      providerType: providerType,
      storageURL: storageURL,
      logger: logger
    )

    // Return as protocol type
    return impl
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
    // Create provider registry
    let impl = CryptoActorIntegration.ProviderRegistryActor(
      logger: logger
    )

    // Return as protocol type
    return impl
  }
}
