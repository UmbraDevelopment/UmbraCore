import CoreErrors
import CoreTypesInterfaces
import UmbraCoreTypes

/// Default implementation of the CoreProvider protocol
public final class DefaultCoreProvider: CoreProvider {
  /// The unique identifier for this provider
  public let providerID: String="com.umbra.core.default.provider"

  /// A human-readable name for this provider
  public let providerName: String="Umbra Default Security Provider"

  /// The version of this provider
  public let providerVersion: String="1.0.0"

  /// Default initialiser
  public init() {}

  /// Check if this provider is available and ready to use
  /// - Returns: True if the provider is available and ready
  public func isAvailable() async -> Bool {
    // Default provider is always available
    true
  }

  /// Reset the provider to its initial state
  /// - Returns: Result indicating success or failure with error
  public func reset() async -> SecurityResult<Void> {
    // Default implementation has no state to reset
    .success(())
  }

  /// Get capabilities supported by this provider
  /// - Returns: List of capability identifiers
  public func getCapabilities() async -> [String] {
    [
      CoreCapability.encryption,
      CoreCapability.decryption,
      CoreCapability.keyGeneration,
      CoreCapability.randomGeneration,
      CoreCapability.hashing
    ]
  }
}

/// Configurable implementation of the CoreProvider protocol
public final class ConfigurableCoreProvider: CoreProvider {
  /// Provider configuration
  private let configuration: ProviderConfiguration

  /// Create a new configurable provider
  /// - Parameter configuration: Provider configuration
  public init(configuration: ProviderConfiguration) {
    self.configuration=configuration
  }

  /// The unique identifier for this provider
  public var providerID: String {
    configuration.providerID
  }

  /// A human-readable name for this provider
  public var providerName: String {
    configuration.providerName
  }

  /// The version of this provider
  public var providerVersion: String {
    configuration.providerVersion
  }

  /// Check if this provider is available and ready to use
  /// - Returns: True if the provider is available and ready
  public func isAvailable() async -> Bool {
    // Configurable provider is always available
    true
  }

  /// Reset the provider to its initial state
  /// - Returns: Result indicating success or failure with error
  public func reset() async -> SecurityResult<Void> {
    // Configurable implementation has no state to reset
    .success(())
  }

  /// Get capabilities supported by this provider
  /// - Returns: List of capability identifiers
  public func getCapabilities() async -> [String] {
    configuration.capabilities
  }
}
