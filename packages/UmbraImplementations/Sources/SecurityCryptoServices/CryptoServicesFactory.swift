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
     providerType: .apple,
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
      - providerType: The type of security provider to use (optional)
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol
   */
  public static func createCryptoService(
    providerType: SecurityProviderType?=nil,
    logger: LoggingProtocol
  ) async -> any CryptoServiceProtocol {
    // Import the actor from the implementations module and initialise it
    let impl=CryptoActorImplementations.CryptoServiceActor(
      providerType: providerType,
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
      - providerType: The type of security provider to use (optional)
      - storageURL: Custom URL for key storage (optional)
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of SecureStorageProtocol
   */
  public static func createSecureStorage(
    providerType: SecurityProviderType?=nil,
    storageURL: URL?=nil,
    logger: LoggingProtocol
  ) async -> any SecureStorageProtocol {
    // Create secure storage with the specified parameters
    let impl=CryptoActorImplementations.SecureStorageActor(
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
    let impl=CryptoActorImplementations.ProviderRegistryActor(
      logger: logger
    )

    // Return as protocol type
    return impl
  }
}
