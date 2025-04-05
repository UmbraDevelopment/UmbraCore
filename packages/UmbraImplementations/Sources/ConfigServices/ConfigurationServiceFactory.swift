import ConfigInterfaces
import LoggingInterfaces
import LoggingServices
import LoggingTypes

/// ConfigurationServiceFactory
///
/// Factory for creating instances of ConfigurationServiceProtocol.
/// This factory follows the dependency injection pattern to create
/// properly configured configuration service instances with their dependencies.
///
/// # Usage Example
/// ```swift
/// let configService = ConfigurationServiceFactory.createDefault()
/// try await configService.initialise(source: defaultSource)
/// ```
public enum ConfigurationServiceFactory {
  /// Creates a default instance of ConfigurationServiceProtocol
  /// - Returns: A configured instance of ConfigurationServiceProtocol
  public static func createDefault() -> ConfigurationServiceProtocol {
    // Create and return the configuration service actor
    ConfigurationServiceActor(logger: nil)
  }

  /// Creates a pre-initialised instance of ConfigurationServiceProtocol
  /// - Parameters:
  ///   - source: The primary configuration source to use
  ///   - logger: Optional logger for configuration operations
  /// - Returns: A configured and initialised instance of ConfigurationServiceProtocol
  /// - Note: This method initialises the service as part of the factory creation.
  ///         Any initialisation errors will be thrown from this method.
  public static func createPreInitialised(
    source: ConfigSourceDTO,
    logger _: LoggingInterfaces.DomainLogger?=nil
  ) async throws -> ConfigurationServiceProtocol {
    // Create the service
    let service=createDefault()

    // Initialise it
    try await service.initialise(source: source)

    return service
  }

  /// Creates a default JSON file configuration source
  /// - Parameter filePath: Path to the JSON file
  /// - Returns: A configured ConfigSourceDTO for a JSON file
  public static func createJsonFileSource(filePath: String) -> ConfigSourceDTO {
    ConfigSourceDTO.jsonFile(
      identifier: "json-file-config",
      name: "JSON Configuration File",
      filePath: filePath
    )
  }

  /// Creates a default in-memory configuration source
  /// - Returns: A configured ConfigSourceDTO for in-memory configuration
  public static func createMemorySource() -> ConfigSourceDTO {
    ConfigSourceDTO.memory(
      identifier: "memory-config",
      name: "In-Memory Configuration"
    )
  }

  /// Creates a default secure keychain configuration source
  /// - Parameter serviceName: The keychain service name
  /// - Returns: A configured ConfigSourceDTO for keychain storage
  public static func createKeychainSource(serviceName: String) -> ConfigSourceDTO {
    ConfigSourceDTO.keychain(
      identifier: "keychain-config",
      name: "Secure Keychain Storage",
      serviceName: serviceName
    )
  }

  /// Simplifies service creation with domain-specific configuration
  /// - Parameters:
  ///   - domain: The domain name for the service
  ///   - serviceName: The service name
  ///   - logger: Optional logger for the service
  /// - Returns: A configured instance with domain-specific settings
  public static func createForDomain(
    _: String,
    serviceName _: String,
    logger: LoggingInterfaces.DomainLogger?=nil
  ) -> ConfigurationServiceProtocol {
    // Configure domain-specific settings
    let service=ConfigurationServiceActor(logger: logger)

    // Return the configured service
    return service
  }
}
