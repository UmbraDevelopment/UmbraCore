import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
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
public actor ProviderRegistryActor {
  // MARK: - Types

  /// Function that creates a provider instance
  public typealias ProviderFactory=@Sendable () throws -> EncryptionProviderProtocol

  /// Security capability flags
  public enum SecurityCapability: String, CaseIterable, Sendable {
    /// Standard encryption operations
    case standardEncryption

    /// FIPS compliant operations
    case fipsCompliant

    /// High-performance optimisations
    case highPerformance

    /// Low-power optimisations
    case lowPower
  }

  // MARK: - Properties

  /// Registry of provider factories by type
  private var providerFactories: [SecurityProviderType: ProviderFactory]

  /// Logger for recording operations
  private let logger: LoggingProtocol

  /// Configuration options for the registry
  public struct Configuration: Sendable {
    /// Whether to automatically register standard providers
    public let autoRegisterStandardProviders: Bool

    /// The preferred provider type when multiple options are available
    public let preferredProviderType: SecurityProviderType?

    /// Whether to allow fallback to less secure providers when necessary
    public let allowFallbackProviders: Bool

    /**
     Initialises a new Configuration with specified options.

     - Parameters:
        - autoRegisterStandardProviders: Whether to register standard providers automatically
        - preferredProviderType: The preferred provider type to use when available
        - allowFallbackProviders: Whether to allow fallback to less secure providers
     */
    public init(
      autoRegisterStandardProviders: Bool=true,
      preferredProviderType: SecurityProviderType?=nil,
      allowFallbackProviders: Bool=true
    ) {
      self.autoRegisterStandardProviders=autoRegisterStandardProviders
      self.preferredProviderType=preferredProviderType
      self.allowFallbackProviders=allowFallbackProviders
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
        return try SecurityProviderFactory.createProvider(type: .basic)
      }

      // Apple provider if available
      #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        providerFactories[.apple]={ @Sendable in
          return try SecurityProviderFactory.createProvider(type: .apple)
        }
      #endif

      // Ring provider if available
      #if canImport(RingCrypto)
        providerFactories[.ring]={ @Sendable in
          return try SecurityProviderFactory.createProvider(type: .ring)
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
    // Create a proper context with privacy-aware metadata
    let context = SecurityLogContext(
      operation: "registerProvider",
      source: "ProviderRegistryActor",
      metadata: LogMetadataDTOCollection().withPublic(key: "providerType", value: "\(type)")
    )
    
    await logger.debug("Registering provider of type: \(type)", context: context)

    // Check if provider already exists
    if providerFactories[type] != nil {
      let warningContext = SecurityLogContext(
        operation: "registerProvider",
        source: "ProviderRegistryActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "providerType", value: "\(type)")
          .withPublic(key: "action", value: "replace")
      )
      
      await logger.warning(
        "Provider of type \(type) already registered, will be replaced",
        context: warningContext
      )
    }

    // Register the provider factory
    providerFactories[type] = factory

    // Verify the provider can be instantiated
    do {
      let provider = try factory()
      let successContext = SecurityLogContext(
        operation: "verifyProvider",
        source: "ProviderRegistryActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "providerType", value: "\(type)")
          .withPublic(key: "providerDescription", value: provider.providerType.description)
      )
      
      await logger.debug(
        "Successfully verified provider: \(type) - \(provider.providerType.description)",
        context: successContext
      )
    } catch {
      // Remove the factory if it fails verification
      providerFactories.removeValue(forKey: type)
      
      let errorContext = SecurityLogContext(
        operation: "verifyProvider",
        source: "ProviderRegistryActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "providerType", value: "\(type)")
          .withPublic(key: "errorType", value: "\(type(of: error))")
          .withPrivate(key: "errorMessage", value: error.localizedDescription)
      )
      
      await logger.error(
        "Provider factory verification failed: \(error.localizedDescription)",
        context: errorContext
      )
      throw error
    }
  }

  /**
   Unregisters a provider of the specified type.

   - Parameter type: The type of provider to unregister
   - Returns: True if a provider was unregistered, false otherwise
   */
  @discardableResult
  public func unregisterProvider(type: SecurityProviderType) async -> Bool {
    let context = SecurityLogContext(
      operation: "unregisterProvider",
      source: "ProviderRegistryActor",
      metadata: LogMetadataDTOCollection().withPublic(key: "providerType", value: "\(type)")
    )
    
    await logger.debug("Unregistering provider of type: \(type)", context: context)
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
    var providers: [EncryptionProviderProtocol]=[]
    var failedTypes: [SecurityProviderType]=[]

    // Create instances of all registered providers
    for (type, factory) in providerFactories {
      do {
        let provider=try factory()
        providers.append(provider)
        let successContext = SecurityLogContext(
          operation: "instantiateProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "providerType", value: "\(type)")
            .withPublic(key: "providerDescription", value: provider.providerType.description)
        )
        
        await logger.debug(
          "Successfully instantiated provider: \(type) - \(provider.providerType.description)",
          context: successContext
        )
      } catch {
        failedTypes.append(type)
        let errorContext = SecurityLogContext(
          operation: "instantiateProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "providerType", value: "\(type)")
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
        
        await logger.warning(
          "Failed to instantiate provider \(type): \(error.localizedDescription)",
          context: errorContext
        )
      }
    }

    // If no providers could be instantiated, that's an error
    if providers.isEmpty && !providerFactories.isEmpty {
      let errorContext = SecurityLogContext(
        operation: "listAvailableProviders",
        source: "ProviderRegistryActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "failedTypes", value: failedTypes.map(\.description).joined(separator: ", "))
      )
      
      await logger.error("No encryption providers could be instantiated", context: errorContext)
      throw SecurityProtocolError
        .unsupportedOperation(
          name: "No encryption providers could be instantiated. Failed types: \(failedTypes.map(\.description).joined(separator: ", "))"
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
    capabilities: [SecurityCapability]=[]
  ) async throws -> EncryptionProviderProtocol {
    let effectiveCapabilities=capabilities.isEmpty ? [.standardEncryption] : capabilities
    let context = SecurityLogContext(
      operation: "selectProvider",
      source: "ProviderRegistryActor",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "capabilities", value: effectiveCapabilities.map(\.rawValue).joined(separator: ", "))
    )
    
    await logger.debug(
      "Selecting provider for capabilities: \(effectiveCapabilities.map(\.rawValue).joined(separator: ", "))",
      context: context
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
        let successContext = SecurityLogContext(
          operation: "selectPreferredProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "providerType", value: "\(preferredType)")
            .withPublic(key: "providerDescription", value: provider.providerType.description)
        )
        
        await logger.debug(
          "Using preferred provider: \(preferredType) - \(provider.providerType.description)",
          context: successContext
        )
        return provider
      } catch {
        let errorContext = SecurityLogContext(
          operation: "selectPreferredProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "providerType", value: "\(preferredType)")
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
        
        await logger.warning(
          "Preferred provider \(preferredType) failed to instantiate: \(error.localizedDescription)",
          context: errorContext
        )
        // Continue to try other providers
      }
    }

    // Try to find a provider that meets capabilities
    let providers=try await listAvailableProviders()

    // For now, we don't have a way to check capabilities directly,
    // so we'll use a simple ranking system based on provider type
    if let provider=providers.first {
      let successContext = SecurityLogContext(
        operation: "selectProvider",
        source: "ProviderRegistryActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "providerType", value: "\(provider.providerType)")
          .withPublic(key: "providerDescription", value: provider.providerType.description)
      )
      
      await logger.debug(
        "Selected provider: \(provider.providerType.description)",
        context: successContext
      )
      return provider
    }

    // If fallback is allowed, try to find any working provider
    if configuration.allowFallbackProviders {
      let fallbackContext = SecurityLogContext(
        operation: "selectProvider",
        source: "ProviderRegistryActor",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "action", value: "fallback")
      )
      
      await logger.warning(
        "No provider found meeting all capabilities, attempting fallback",
        context: fallbackContext
      )

      // Try to get any working provider
      if let (_, factory)=providerFactories.first {
        do {
          let provider=try factory()
          let fallbackSuccessContext = SecurityLogContext(
            operation: "selectFallbackProvider",
            source: "ProviderRegistryActor",
            metadata: LogMetadataDTOCollection()
              .withPublic(key: "providerType", value: "\(provider.providerType)")
              .withPublic(key: "providerDescription", value: provider.providerType.description)
          )
          
          await logger.warning(
            "Using fallback provider: \(provider.providerType.description)",
            context: fallbackSuccessContext
          )
          return provider
        } catch {
          let fallbackErrorContext = SecurityLogContext(
            operation: "selectFallbackProvider",
            source: "ProviderRegistryActor",
            metadata: LogMetadataDTOCollection()
              .withPublic(key: "errorType", value: "\(type(of: error))")
              .withPrivate(key: "errorMessage", value: error.localizedDescription)
          )
          
          await logger.error(
            "Fallback provider failed to instantiate: \(error.localizedDescription)",
            context: fallbackErrorContext
          )
        }
      }
    }

    // No suitable provider found
    let errorContext = SecurityLogContext(
      operation: "selectProvider",
      source: "ProviderRegistryActor",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "capabilities", value: effectiveCapabilities.map(\.rawValue).joined(separator: ", "))
    )
    
    await logger.error(
      "No provider meeting capabilities: \(effectiveCapabilities.map(\.rawValue).joined(separator: ", "))",
      context: errorContext
    )
    throw SecurityProtocolError.unsupportedOperation(
      name: "No provider meeting capabilities: \(effectiveCapabilities.map(\.rawValue).joined(separator: ", "))"
    )
  }

  /**
   Selects a provider that is FIPS compliant.

   - Returns: A FIPS-compliant provider
   - Throws: Error if no FIPS-compliant provider is available
   */
  private func selectProviderForFipsCompliance() async throws -> EncryptionProviderProtocol {
    let context = SecurityLogContext(
      operation: "selectFipsCompliantProvider",
      source: "ProviderRegistryActor",
      metadata: LogMetadataDTOCollection()
    )
    
    await logger.debug("Selecting FIPS-compliant provider", context: context)

    // In a real implementation, we would check which providers are FIPS certified
    // For now, we'll prefer Ring as it's based on a FIPS-validated library
    if let factory=providerFactories[.ring] {
      do {
        let provider=try factory()
        let successContext = SecurityLogContext(
          operation: "selectFipsCompliantProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "providerType", value: "\(provider.providerType)")
            .withPublic(key: "providerDescription", value: provider.providerType.description)
        )
        
        await logger.debug(
          "Selected FIPS-compliant provider: \(provider.providerType.description)",
          context: successContext
        )
        return provider
      } catch {
        let errorContext = SecurityLogContext(
          operation: "selectFipsCompliantProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
        
        await logger.warning(
          "FIPS-compliant provider .ring failed to instantiate: \(error.localizedDescription)",
          context: errorContext
        )
        // Continue to try other providers
      }
    }

    // Check if Apple provider is available as a potential fallback for FIPS
    if let factory=providerFactories[.apple] {
      do {
        let provider=try factory()
        let fallbackSuccessContext = SecurityLogContext(
          operation: "selectFipsCompliantProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "providerType", value: "\(provider.providerType)")
            .withPublic(key: "providerDescription", value: provider.providerType.description)
        )
        
        await logger.warning(
          "Using Apple provider as fallback for FIPS compliance: \(provider.providerType.description)",
          context: fallbackSuccessContext
        )
        return provider
      } catch {
        let fallbackErrorContext = SecurityLogContext(
          operation: "selectFipsCompliantProvider",
          source: "ProviderRegistryActor",
          metadata: LogMetadataDTOCollection()
            .withPublic(key: "errorType", value: "\(type(of: error))")
            .withPrivate(key: "errorMessage", value: error.localizedDescription)
        )
        
        await logger.error(
          "Apple provider FIPS fallback failed to instantiate: \(error.localizedDescription)",
          context: fallbackErrorContext
        )
      }
    }

    // No FIPS-compliant provider found
    let errorContext = SecurityLogContext(
      operation: "selectFipsCompliantProvider",
      source: "ProviderRegistryActor",
      metadata: LogMetadataDTOCollection()
    )
    
    await logger.error(
      "No FIPS-compliant provider could be instantiated",
      context: errorContext
    )
    throw SecurityProtocolError.unsupportedOperation(
      name: "No FIPS-compliant provider could be instantiated"
    )
  }
}
