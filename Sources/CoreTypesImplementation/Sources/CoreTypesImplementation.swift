import CoreErrors
import CoreTypesInterfaces
import UmbraCoreTypes

/// Main factory for creating CoreTypes implementations
public enum CoreTypesFactory {
  /// Create the default CoreProvider implementation
  /// - Returns: A standard CoreProvider implementation
  public static func createDefaultProvider() -> CoreProvider {
    DefaultCoreProvider()
  }

  /// Create a provider with the specified configuration
  /// - Parameter configuration: Provider configuration options
  /// - Returns: A configured CoreProvider implementation
  public static func createProvider(configuration: ProviderConfiguration) -> CoreProvider {
    ConfigurableCoreProvider(configuration: configuration)
  }
}

/// Configuration options for CoreProvider implementations
public struct ProviderConfiguration: Sendable {
  /// The provider ID
  public let providerID: String

  /// The provider name
  public let providerName: String

  /// The provider version
  public let providerVersion: String

  /// Custom capabilities
  public let capabilities: [String]

  /// Create a new provider configuration
  /// - Parameters:
  ///   - providerId: The provider ID
  ///   - providerName: The provider name
  ///   - providerVersion: The provider version
  ///   - capabilities: Custom capabilities (defaults to standard set)
  public init(
    providerID: String,
    providerName: String,
    providerVersion: String,
    capabilities: [String]=[
      CoreCapability.encryption,
      CoreCapability.decryption,
      CoreCapability.keyGeneration,
      CoreCapability.randomGeneration,
      CoreCapability.hashing
    ]
  ) {
    self.providerID=providerID
    self.providerName=providerName
    self.providerVersion=providerVersion
    self.capabilities=capabilities
  }
}
