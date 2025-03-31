import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # CryptoServices

 Main entry point for the cryptographic services in UmbraCore.
 This provides factory methods to access various cryptographic services
 through a clean interface that avoids implementation details.

 ## Usage

 ```swift
 // Create a crypto service with a specific provider
 let logger = YourLoggerImplementation()
 let cryptoService = CryptoServices.createCryptoService(
     providerType: .apple,
     logger: logger
 )

 // Encrypt data
 let encryptedData = try await cryptoService.encrypt(data: secureData, using: secureKey)
 ```
 */
public enum CryptoServices {
  /**
   Creates a new crypto service with the specified provider type.

   - Parameters:
      - providerType: The type of security provider to use (optional)
      - logger: Logger for recording operations
   - Returns: A new implementation of CryptoServiceProtocol
   */
  public static func createCryptoService(
    providerType: SecurityProviderType?=nil,
    logger: LoggingProtocol
  ) -> any CryptoServiceProtocol {
    CryptoServicesFactory.createCryptoService(
      providerType: providerType,
      logger: logger
    )
  }

  /**
   Creates a new secure storage service for key management.

   - Parameters:
      - providerType: The type of security provider to use (optional)
      - storageURL: Custom URL for key storage (optional)
      - logger: Logger for recording operations
   - Returns: A new implementation of SecureStorageProtocol
   */
  public static func createSecureStorage(
    providerType: SecurityProviderType?=nil,
    storageURL: URL?=nil,
    logger: LoggingProtocol
  ) -> any SecureStorageProtocol {
    CryptoServicesFactory.createSecureStorage(
      providerType: providerType,
      storageURL: storageURL,
      logger: logger
    )
  }

  /**
   Creates a new provider registry for managing security providers.

   - Parameter logger: Logger for recording operations
   - Returns: A new implementation of ProviderRegistryProtocol
   */
  public static func createProviderRegistry(
    logger: LoggingProtocol
  ) -> any ProviderRegistryProtocol {
    CryptoServicesFactory.createProviderRegistry(
      logger: logger
    )
  }
}
