import ConfigurationInterfaces
import Foundation
import LoggingInterfaces
import SecurityInterfaces

/**
 Factory for creating configuration service instances.

 This factory creates and configures the configuration service with appropriate
 providers and dependencies.
 */
public class ConfigurationServiceFactory {
  /**
   Creates a configuration service with the specified providers and dependencies.

   - Parameters:
      - providers: Specific providers to use, or nil to use defaults
      - logger: Logger for configuration operations
      - securityService: Optional security service for cryptographic operations
   - Returns: A fully configured configuration service
   */
  public static func createConfigurationService(
    providers: [ConfigSourceType: ConfigurationProviderProtocol]?=nil,
    logger: PrivacyAwareLoggingProtocol,
    securityService: CryptoServiceProtocol?=nil
  ) -> ConfigurationServiceProtocol {
    // Use provided providers or create defaults
    let resolvedProviders=providers ?? createDefaultProviders()

    // Create command factory
    let commandFactory=ConfigCommandFactory(
      providers: resolvedProviders,
      logger: logger,
      securityService: securityService
    )

    // Create and return the configuration service actor
    return ConfigurationServicesActor(
      commandFactory: commandFactory,
      logger: logger
    )
  }

  /**
   Creates configuration service with default file and memory providers.

   - Parameters:
      - logger: Logger for configuration operations
      - securityService: Optional security service for cryptographic operations
   - Returns: A configuration service with default providers
   */
  public static func createDefaultConfigurationService(
    logger: PrivacyAwareLoggingProtocol,
    securityService: CryptoServiceProtocol?=nil
  ) -> ConfigurationServiceProtocol {
    createConfigurationService(
      providers: createDefaultProviders(),
      logger: logger,
      securityService: securityService
    )
  }

  /**
   Creates a file-based configuration service.

   - Parameters:
      - logger: Logger for configuration operations
      - securityService: Optional security service for cryptographic operations
   - Returns: A configuration service using file storage
   */
  public static func createFileConfigurationService(
    logger: PrivacyAwareLoggingProtocol,
    securityService: CryptoServiceProtocol?=nil
  ) -> ConfigurationServiceProtocol {
    let fileProvider=FileConfigurationProvider()

    return createConfigurationService(
      providers: [.file: fileProvider],
      logger: logger,
      securityService: securityService
    )
  }

  /**
   Creates a memory-based configuration service.

   - Parameters:
      - logger: Logger for configuration operations
      - securityService: Optional security service for cryptographic operations
   - Returns: A configuration service using in-memory storage
   */
  public static func createMemoryConfigurationService(
    logger: PrivacyAwareLoggingProtocol,
    securityService: CryptoServiceProtocol?=nil
  ) -> ConfigurationServiceProtocol {
    // We'd normally implement a MemoryConfigurationProvider here
    // For now, fallback to file provider
    let fileProvider=FileConfigurationProvider()

    return createConfigurationService(
      providers: [.memory: fileProvider],
      logger: logger,
      securityService: securityService
    )
  }

  /**
   Creates a hybrid configuration service with multiple providers.

   - Parameters:
      - logger: Logger for configuration operations
      - securityService: Optional security service for cryptographic operations
   - Returns: A configuration service with multiple provider types
   */
  public static func createHybridConfigurationService(
    logger: PrivacyAwareLoggingProtocol,
    securityService: CryptoServiceProtocol?=nil
  ) -> ConfigurationServiceProtocol {
    createConfigurationService(
      providers: createDefaultProviders(),
      logger: logger,
      securityService: securityService
    )
  }

  // MARK: - Private Methods

  /**
   Creates the default set of configuration providers.

   - Returns: Map of providers by source type
   */
  private static func createDefaultProviders()
  -> [ConfigSourceType: ConfigurationProviderProtocol] {
    let fileProvider=FileConfigurationProvider()

    // In a full implementation, we'd create other providers here
    // such as MemoryConfigurationProvider, RemoteConfigurationProvider, etc.

    return [
      .file: fileProvider,
      // Using file provider for other types as a fallback
      .memory: fileProvider,
      .remote: fileProvider,
      .custom: fileProvider
    ]
  }
}
