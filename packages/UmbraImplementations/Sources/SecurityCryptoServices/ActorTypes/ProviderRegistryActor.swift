import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import ProviderFactories
import SecurityCoreInterfaces
import SecurityProviders
import UmbraErrors

/**
 # ProviderRegistryActor

 This actor manages the registration, discovery, and selection of encryption providers
 in the Umbra security system. It serves as the central registry for all available
 cryptographic provider implementations.

 The registry follows the architecture pattern of using actors
 for concurrency safety and proper isolation of security-critical operations.

 ## Features

 - Dynamic provider registration and discovery
 - Provider selection based on security configuration
 - Configurable provider preferences
 - FIPS compliance checking

 ## Usage Example

 ```swift
 // Create the registry
 let registry = ProviderRegistryActor(logger: myLogger)

 // Register a custom provider
 try await registry.registerProvider(type: .custom("MyProvider")) {
     return MyCustomEncryptionProvider()
 }

 // Get the best provider for the current operation
 let provider = try await registry.selectProvider()
 ```
 */
public actor ProviderRegistryActor: ProviderRegistryProtocol {
  // MARK: - Types

  /// Function that creates a provider instance
  public typealias ProviderFactory=@Sendable () throws -> EncryptionProviderProtocol

  /// Provider capability flags
  public typealias ProviderCapability = CoreSecurityTypes.ProviderCapability

  // MARK: - Properties

  /// Registry of provider factories by type
  private var providerFactories: [SecurityProviderType: ProviderFactory]

  /// Logger for recording operations
  private let logger: LoggingProtocol
  
  /// Preferred provider types for specific capabilities
  private var preferredProviders: [ProviderCapability: SecurityProviderType] = [:]

  /// Configuration options for the registry
  public struct Configuration: Sendable {
    /// Whether to automatically register standard providers
    public let autoRegisterStandardProviders: Bool

    /// The preferred provider type when multiple options are available
    public let preferredProviderType: SecurityProviderType?

    /// Whether to allow fallback to less secure providers when necessary
    public let allowFallbackProviders: Bool
    
    /// Provider types that are considered FIPS compliant
    public let fipsCompliantProviders: [SecurityProviderType]

    /**
     Initialises a new Configuration with specified options.

     - Parameters:
        - autoRegisterStandardProviders: Whether to register standard providers automatically
        - preferredProviderType: The preferred provider type to use when available
        - allowFallbackProviders: Whether to allow fallback to less secure providers
        - fipsCompliantProviders: Provider types that are FIPS compliant
     */
    public init(
      autoRegisterStandardProviders: Bool=true,
      preferredProviderType: SecurityProviderType?=nil,
      allowFallbackProviders: Bool=true,
      fipsCompliantProviders: [SecurityProviderType]=[.ring]
    ) {
      self.autoRegisterStandardProviders=autoRegisterStandardProviders
      self.preferredProviderType=preferredProviderType
      self.allowFallbackProviders=allowFallbackProviders
      self.fipsCompliantProviders=fipsCompliantProviders
    }
  }

  /// Current configuration
  private let configuration: Configuration

  // MARK: - Initialisation

  /**
   Initialises a new provider registry with default factories.

   - Parameters:
      - logger: Logger for recording operations
      - configuration: Configuration options for the registry
   */
  public init(
    logger: LoggingProtocol,
    configuration: Configuration=Configuration()
  ) {
    self.logger=logger
    self.configuration=configuration
    providerFactories=[:]

    if configuration.autoRegisterStandardProviders {
      // Register default factories (directly to avoid actor-isolation issues)
      // Basic provider is always available
      providerFactories[.basic]={ @Sendable in
        return try SecurityProviderFactoryImpl.createProvider(type: .basic)
      }

      // System provider if available
      #if canImport(Security)
        providerFactories[.system]={ @Sendable in
          return try SecurityProviderFactoryImpl.createProvider(type: .system)
        }
      #endif

      // CryptoKit provider if available
      #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        providerFactories[.cryptoKit]={ @Sendable in
          return try SecurityProviderFactoryImpl.createProvider(type: .cryptoKit)
        }
      #endif

      // Ring provider if available
      #if canImport(RingCrypto)
        providerFactories[.ring]={ @Sendable in
          return try SecurityProviderFactoryImpl.createProvider(type: .ring)
        }
      #endif
    }
  }

  // MARK: - Provider Registration and Management

  /**
   Registers a new provider factory for the specified type.

   - Parameters:
      - type: The type of provider to register
      - factory: Factory function to create a provider of this type
   - Throws: Error if registration fails
   */
  public func registerProvider(
    type: SecurityProviderType,
    factory: @escaping @Sendable () throws -> EncryptionProviderProtocol
  ) async throws {
    await logger.debug("Registering provider of type: \(type)", metadata: PrivacyMetadata(), source: "ProviderRegistry")

    // Check if provider already exists
    if providerFactories[type] != nil {
      await logger.warning(
        "Provider of type \(type) already registered, will be replaced",
        metadata: PrivacyMetadata(),
        source: "ProviderRegistry"
      )
    }

    // Verify factory by creating a provider
    do {
      let provider=try factory()
      await logger.debug(
        "Successfully verified provider: \(type) - \(provider.providerType.rawValue)",
        metadata: PrivacyMetadata(),
        source: "ProviderRegistry"
      )
    } catch {
      // Remove the factory if it fails verification
      providerFactories.removeValue(forKey: type)
      await logger.error(
        "Provider factory verification failed: \(error.localizedDescription)",
        metadata: PrivacyMetadata(),
        source: "ProviderRegistry"
      )
      throw error
    }

    // Store the factory
    providerFactories[type] = factory
  }

  /**
   Unregisters a provider of the specified type.

   - Parameter type: The type of provider to unregister
   - Returns: True if a provider was unregistered, false otherwise
   */
  @discardableResult
  public func unregisterProvider(type: SecurityProviderType) async -> Bool {
    await logger.debug("Unregistering provider of type: \(type)", metadata: PrivacyMetadata(), source: "ProviderRegistry")
    return providerFactories.removeValue(forKey: type) != nil
  }

  /**
   Lists all available provider types that are currently registered.

   - Returns: Array of registered provider types
   */
  public func listAvailableProviderTypes() async -> [SecurityProviderType] {
    Array(providerFactories.keys)
  }

  /**
   Creates instances of all registered providers.

   - Returns: Array of provider instances
   - Throws: Error if any provider instantiation fails
   */
  public func listAvailableProviders() async throws -> [EncryptionProviderProtocol] {
    var providers = [EncryptionProviderProtocol]()
    var failedTypes = [SecurityProviderType]()

    for (type, factory) in providerFactories {
      do {
        let provider = try factory()
        providers.append(provider)
        await logger.debug(
          "Successfully instantiated provider: \(type) - \(provider.providerType.rawValue)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
      } catch {
        failedTypes.append(type)
        await logger.warning(
          "Failed to instantiate provider \(type): \(error.localizedDescription)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
      }
    }

    // If no providers could be instantiated, that's an error
    if providers.isEmpty && !providerFactories.isEmpty {
      await logger.error("No encryption providers could be instantiated", metadata: PrivacyMetadata(), source: "ProviderRegistry")
      throw SecurityServiceError.providerError(
        "No encryption providers could be instantiated. Failed types: \(failedTypes.map(\.rawValue).joined(separator: ", "))"
      )
    }

    return providers
  }

  // MARK: - Provider Selection

  /**
   Selects the most appropriate provider based on the given capabilities.

   - Parameter capabilities: Security capabilities required for the provider
   - Returns: The selected provider instance
   - Throws: Error if no suitable provider can be found
   */
  public func selectProvider(
    capabilities: [ProviderCapability]=[]
  ) async throws -> EncryptionProviderProtocol {
    let effectiveCapabilities=capabilities.isEmpty ? [.standardEncryption] : capabilities
    await logger.debug(
      "Selecting provider for capabilities: \(effectiveCapabilities.map(\.rawValue).joined(separator: ", "))",
      metadata: PrivacyMetadata(),
      source: "ProviderRegistry"
    )

    // If FIPS compliance is required, use specific selection logic
    if effectiveCapabilities.contains(.fipsCompliant) {
      return try await selectProviderForFipsCompliance()
    }

    // Check for preferred provider if specified in configuration
    if
      let preferredType=configuration.preferredProviderType,
      let factory=providerFactories[preferredType]
    {
      do {
        let provider=try factory()
        await logger.debug(
          "Using preferred provider: \(preferredType) - \(provider.providerType.rawValue)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
        return provider
      } catch {
        await logger.warning(
          "Preferred provider \(preferredType) failed to instantiate: \(error.localizedDescription)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
        // Continue to try other providers
      }
    }

    // Try to find a provider that meets capabilities
    let providers=try await listAvailableProviders()

    // For now, we don't have a way to check capabilities directly,
    // so we'll use a simple ranking system based on provider type
    if let provider=providers.first {
      await logger.debug(
        "Selected provider: \(provider.providerType.rawValue)",
        metadata: PrivacyMetadata(),
        source: "ProviderRegistry"
      )
      return provider
    }

    // If fallback is allowed, try to find any working provider
    if configuration.allowFallbackProviders {
      await logger.warning(
        "No provider found meeting all capabilities, attempting fallback",
        metadata: PrivacyMetadata(),
        source: "ProviderRegistry"
      )

      // Try to get any working provider
      if let (_, factory)=providerFactories.first {
        do {
          let provider=try factory()
          await logger.warning(
            "Using fallback provider: \(provider.providerType.rawValue)",
            metadata: PrivacyMetadata(),
            source: "ProviderRegistry"
          )
          return provider
        } catch {
          await logger.error(
            "Fallback provider failed to instantiate: \(error.localizedDescription)",
            metadata: PrivacyMetadata(),
            source: "ProviderRegistry"
          )
        }
      }
    }

    // No suitable provider found
    throw SecurityServiceError.providerError(
      "No provider meeting capabilities: \(effectiveCapabilities.map(\.rawValue).joined(separator: ", "))"
    )
  }

  /**
   Selects a provider that is FIPS compliant.

   - Returns: A FIPS-compliant provider
   - Throws: Error if no FIPS-compliant provider is available
   */
  private func selectProviderForFipsCompliance() async throws -> EncryptionProviderProtocol {
    await logger.debug("Selecting FIPS-compliant provider", metadata: PrivacyMetadata(), source: "ProviderRegistry")

    // In a real implementation, we would check which providers are FIPS certified
    // For now, we'll prefer Ring as it's based on a FIPS-validated library
    if let factory=providerFactories[.ring] {
      do {
        let provider=try factory()
        await logger.debug(
          "Selected FIPS-compliant provider: \(provider.providerType.rawValue)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
        return provider
      } catch {
        await logger.warning(
          "FIPS-compliant provider .ring failed to instantiate: \(error.localizedDescription)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
        // Continue to try other providers
      }
    }

    // Check if System provider is available as a potential fallback for FIPS
    if let factory = providerFactories[.system] {
      do {
        let provider = try factory()
        await logger.warning(
          "Using System provider as fallback for FIPS compliance: \(provider.providerType.rawValue)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
        return provider
      } catch {
        await logger.error(
          "System provider FIPS fallback failed to instantiate: \(error.localizedDescription)",
          metadata: PrivacyMetadata(),
          source: "ProviderRegistry"
        )
      }
    }

    // No FIPS-compliant provider found
    throw SecurityServiceError.providerError(
      "No FIPS-compliant provider could be instantiated"
    )
  }

  /**
   Sets the preferred provider type for specific capabilities.
   
   - Parameters:
     - type: The provider type to set as preferred
     - capabilities: The capabilities that this provider is preferred for
   */
  public func setPreferredProvider(
    type: SecurityProviderType,
    forCapabilities capabilities: [ProviderCapability]
  ) async {
    await logger.debug(
      "Setting preferred provider \(type.rawValue) for capabilities: \(capabilities.map(\.rawValue).joined(separator: ", "))",
      metadata: PrivacyMetadata(),
      source: "ProviderRegistry"
    )
    
    // Update preferred providers map
    for capability in capabilities {
      preferredProviders[capability] = type
    }
  }
  
  /**
   Selects a provider based on the specified provider type.
   
   - Parameter type: The specific provider type to select
   - Returns: An encryption provider of the specified type
   - Throws: Error if the provider cannot be instantiated
   */
  public func selectProvider(type: SecurityProviderType) async throws -> EncryptionProviderProtocol {
    await logger.debug(
      "Selecting provider of type: \(type.rawValue)",
      metadata: PrivacyMetadata(),
      source: "ProviderRegistry"
    )
    
    guard let factory = providerFactories[type] else {
      throw SecurityServiceError.providerError("Provider of type \(type.rawValue) is not available")
    }
    
    return try factory()
  }
  
  /**
   Checks if any registered provider offers FIPS compliance.
   
   - Returns: `true` if a FIPS-compliant provider is available, `false` otherwise
   */
  public func hasFIPSCompliantProvider() async -> Bool {
    await logger.debug(
      "Checking for FIPS-compliant providers",
      metadata: PrivacyMetadata(),
      source: "ProviderRegistry"
    )
    
    // Check if any provider types are registered as FIPS-compliant
    for (type, factory) in providerFactories {
      if configuration.fipsCompliantProviders.contains(type) {
        // Try to instantiate the provider to verify it's available
        do {
          let _ = try factory()
          return true
        } catch {
          // This provider failed, continue checking others
          continue
        }
      }
    }
    
    return false
  }
}
