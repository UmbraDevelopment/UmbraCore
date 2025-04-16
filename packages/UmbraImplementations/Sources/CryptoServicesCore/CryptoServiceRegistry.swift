import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # Crypto Service Registry

 This component provides a centralised registry for cryptographic service implementations.
 It handles instantiation and configuration of the appropriate implementation
 based on the requested type, platform, and available capabilities.

 The registry acts as a service locator, making it easier for clients to obtain
 the security provider implementation they need without having to know the
 concrete implementation details.
 */
public enum CryptoServiceRegistry {
  /**
   Creates a cryptographic service of the specified type.

   This method serves as a factory for creating configured cryptographic
   service implementations. It handles instantiation of the correct
   implementation based on the requested type, platform capabilities,
   and configuration.

   - Parameters:
      - type: The type of cryptographic service to create
      - secureStorage: Optional secure storage implementation to use
      - logger: Optional logger implementation to use
      - environment: Optional environment to use for platform-specific decisions
   - Returns: A cryptographic service implementation
   */
  public static func createService(
    type: SecurityProviderType,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil,
    environment: CryptoServicesCore.CryptoEnvironment?=nil
  ) async -> CryptoServiceProtocol {
    // Create the factory with the explicit implementation type
    let factory=CryptoServiceFactory(serviceType: type)

    // Create the service using the factory
    return await factory.createService(
      secureStorage: secureStorage,
      logger: logger,
      environment: environment?.name
    )
  }

  /**
   Creates a cryptographic service based on a legacy CryptoServiceType.

   This method provides backward compatibility for code still using the
   deprecated CryptoServiceType enum.

   - Parameters:
      - legacyType: The legacy service type to create
      - secureStorage: Optional secure storage implementation to use
      - logger: Optional logger implementation to use
      - environment: Optional environment to use for platform-specific decisions
   - Returns: A cryptographic service implementation
   */
  @available(*, deprecated, message: "Use createService with SecurityProviderType instead")
  public static func createService(
    type legacyType: CryptoServiceType,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil,
    environment: CryptoServicesCore.CryptoEnvironment?=nil
  ) async -> CryptoServiceProtocol {
    // Convert the legacy type to the new type
    let providerType=legacyType.securityProviderType

    // Call the standard creation method
    return await createService(
      type: providerType,
      secureStorage: secureStorage,
      logger: logger,
      environment: environment
    )
  }
}
