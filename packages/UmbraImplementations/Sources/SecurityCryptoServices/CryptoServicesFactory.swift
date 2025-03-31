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
 let cryptoService = try await CryptoServicesFactory.createCryptoService(
     providerType: .apple,
     logger: logger
 )

 // Encrypt data
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```
 */
public enum CryptoServicesFactory {
  /**
   Creates a new crypto service with the specified provider type.

   - Parameters:
      - providerType: The type of security provider to use (optional)
      - logger: Logger for recording operations
   - Returns: A new crypto service implementation
   */
  public static func createCryptoService(
    providerType: SecurityProviderType?=nil,
    logger: LoggingProtocol
  ) -> any CryptoServiceProtocol {
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

   - Parameters:
      - providerType: The type of security provider to use (optional)
      - storageURL: Custom URL for key storage (optional)
      - logger: Logger for recording operations
   - Returns: A new secure storage service implementation
   */
  public static func createSecureStorage(
    providerType: SecurityProviderType?=nil,
    storageURL: URL?=nil,
    logger: LoggingProtocol
  ) -> any SecureStorageProtocol {
    // Import the actor from the implementations module and initialise it
    let impl=CryptoActorImplementations.SecureStorageActor(
      providerType: providerType,
      storageURL: storageURL,
      logger: logger
    )

    // Return the implementation as the protocol type
    return impl
  }

  /**
   Creates a new provider registry for managing security providers.

   - Parameter logger: Logger for recording operations
   - Returns: A new provider registry implementation
   */
  public static func createProviderRegistry(
    logger: LoggingProtocol
  ) -> any ProviderRegistryProtocol {
    // Import the actor from the implementations module and initialise it
    let impl=CryptoActorImplementations.ProviderRegistryActor(logger: logger)

    // Return the implementation as the protocol type
    return impl
  }
}
