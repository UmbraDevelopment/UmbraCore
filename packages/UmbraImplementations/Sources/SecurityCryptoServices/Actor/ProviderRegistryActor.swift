import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import LoggingInterfaces

/**
 # ProviderRegistryActor
 
 A Swift actor that manages the registration and selection of security providers.
 This serves as a centralised registry for all available security implementations,
 allowing for dynamic selection based on client requirements.
 
 ## Usage
 
 ```swift
 // Create the registry
 let registry = ProviderRegistryActor(logger: logger)
 
 // Register providers (typically done at application startup)
 await registry.registerProvider(for: .apple, factory: { SecurityProviderFactory.createProvider(type: .apple) })
 
 // Get the best provider for current platform
 let provider = try await registry.selectProvider(for: .currentPlatform)
 ```
 
 ## Thread Safety
 
 All registry operations are automatically thread-safe due to Swift's actor isolation.
 Provider factories are stored within the actor and can only be accessed through
 the defined asynchronous interfaces.
 */
public actor ProviderRegistryActor {
    // MARK: - Types
    
    /// Function that creates a provider instance
    public typealias ProviderFactory = @Sendable () throws -> EncryptionProviderProtocol
    
    /// Represents an environment where providers will operate
    public enum ProviderEnvironment {
        /// Use the best provider for the current platform
        case currentPlatform
        
        /// Use a provider suitable for low-power operation
        case lowPower
        
        /// Use a provider with FIPS compliance
        case fipsCompliant
        
        /// Use a provider optimised for performance
        case highPerformance
        
        /// Use a provider with specific security certifications
        case certified(standards: [String])
        
        /// Use a specific provider type
        case specific(type: SecurityProviderType)
    }
    
    // MARK: - Properties
    
    /// Maps provider types to their factory functions
    private var providerFactories: [SecurityProviderType: ProviderFactory] = [:]
    
    /// Logger for recording operations
    private let logger: LoggingProtocol
    
    // MARK: - Initialisation
    
    /**
     Initialises a new provider registry with default factories.
     
     - Parameter logger: Logger for recording operations
     */
    public init(logger: LoggingProtocol) {
        self.logger = logger
        
        // Register default factories (directly to avoid actor-isolation issues)
        // Basic provider is always available
        self.providerFactories[.basic] = {
            return try SecurityProviderFactory.createProvider(type: .basic)
        }
        
        // Apple provider if available
        #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        self.providerFactories[.apple] = {
            return try SecurityProviderFactory.createProvider(type: .apple)
        }
        #endif
        
        // Ring provider if available
        #if canImport(RingCrypto)
        self.providerFactories[.ring] = {
            return try SecurityProviderFactory.createProvider(type: .ring)
        }
        #endif
        
        // We'll log the initialization in an async context after creation
        Task {
            let count = await self.providerFactories.count
            await logger.info("Initialised ProviderRegistryActor with \(count) default providers", metadata: nil)
        }
    }
    
    // MARK: - Provider Registration
    
    /**
     Registers a provider factory for a specific provider type.
     
     - Parameters:
        - type: The provider type to register
        - factory: Factory function that creates provider instances
     */
    public func registerProvider(for type: SecurityProviderType, factory: @escaping ProviderFactory) async {
        providerFactories[type] = factory
        await logger.info("Registered provider factory for type: \(type.rawValue)", metadata: nil)
    }
    
    /**
     Unregisters a provider factory.
     
     - Parameter type: The provider type to unregister
     - Returns: True if a factory was removed, false if none was registered
     */
    public func unregisterProvider(for type: SecurityProviderType) async -> Bool {
        guard providerFactories.removeValue(forKey: type) != nil else {
            return false
        }
        
        await logger.info("Unregistered provider factory for type: \(type.rawValue)", metadata: nil)
        return true
    }
    
    // MARK: - Provider Selection
    
    /**
     Selects a provider based on the specified environment.
     
     - Parameter environment: The environment to select a provider for
     - Returns: An appropriate provider instance for the environment
     - Throws: SecurityProtocolError if no suitable provider is found
     */
    public func selectProvider(for environment: ProviderEnvironment) async throws -> EncryptionProviderProtocol {
        switch environment {
        case .currentPlatform:
            return try await selectBestProviderForCurrentPlatform()
            
        case .lowPower:
            return try await selectProviderForLowPower()
            
        case .fipsCompliant:
            return try await selectProviderForFipsCompliance()
            
        case .highPerformance:
            return try await selectProviderForHighPerformance()
            
        case .certified(let standards):
            return try await selectProviderWithCertifications(standards)
            
        case .specific(let type):
            return try await selectSpecificProvider(type)
        }
    }
    
    /**
     Creates a list of all available providers in priority order.
     
     - Returns: Array of provider instances in decreasing order of preference
     */
    public func listAvailableProviders() async throws -> [EncryptionProviderProtocol] {
        var providers: [EncryptionProviderProtocol] = []
        
        // Create instances of all registered providers
        for (type, factory) in providerFactories {
            do {
                let provider = try factory()
                providers.append(provider)
                await logger.debug("Created provider instance for type: \(type.rawValue)", metadata: nil)
            } catch {
                await logger.warning("Failed to create provider for \(type.rawValue): \(error.localizedDescription)", metadata: nil)
                // Continue to next provider
            }
        }
        
        // Check if we have any providers
        if providers.isEmpty {
            await logger.error("No security providers available", metadata: nil)
            throw SecurityProtocolError.unsupportedOperation(name: "No security providers available")
        }
        
        return providers
    }
    
    // MARK: - Private Selection Methods
    
    /**
     Selects the best provider for the current platform.
     
     - Returns: The best provider for the current platform
     - Throws: SecurityProtocolError if no suitable provider is found
     */
    private func selectBestProviderForCurrentPlatform() async throws -> EncryptionProviderProtocol {
        // Prioritize providers based on platform
        #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        // On Apple platforms, prefer Apple's CryptoKit
        if let factory = providerFactories[.apple] {
            do {
                let provider = try factory()
                await logger.info("Selected Apple provider for current platform", metadata: nil)
                return provider
            } catch {
                await logger.warning("Failed to create Apple provider: \(error.localizedDescription)", metadata: nil)
                // Fall through to next option
            }
        }
        #endif
        
        // Next prefer Ring if available (good cross-platform option)
        if let factory = providerFactories[.ring] {
            do {
                let provider = try factory()
                await logger.info("Selected Ring provider for current platform", metadata: nil)
                return provider
            } catch {
                await logger.warning("Failed to create Ring provider: \(error.localizedDescription)", metadata: nil)
                // Fall through to basic option
            }
        }
        
        // Fall back to basic provider
        if let factory = providerFactories[.basic] {
            do {
                let provider = try factory()
                await logger.info("Selected Basic provider for current platform", metadata: nil)
                return provider
            } catch {
                await logger.error("Failed to create Basic provider: \(error.localizedDescription)", metadata: nil)
                // This is really bad - we can't even create the most basic provider
            }
        }
        
        // If we get here, no provider could be created
        await logger.error("No suitable provider found for current platform", metadata: nil)
        throw SecurityProtocolError.unsupportedOperation(name: "No suitable provider available")
    }
    
    /**
     Selects a provider optimised for low power operation.
     
     - Returns: A provider suitable for low-power environments
     - Throws: SecurityProtocolError if no suitable provider is found
     */
    private func selectProviderForLowPower() async throws -> EncryptionProviderProtocol {
        // For low power, prefer the basic provider as it has the simplest implementation
        if let factory = providerFactories[.basic] {
            do {
                let provider = try factory()
                await logger.info("Selected Basic provider for low power operation", metadata: nil)
                return provider
            } catch {
                await logger.warning("Failed to create Basic provider: \(error.localizedDescription)", metadata: nil)
            }
        }
        
        // If basic provider isn't available, fall back to any available provider
        return try await selectBestProviderForCurrentPlatform()
    }
    
    /**
     Selects a provider that offers FIPS compliance.
     
     - Returns: A FIPS-compliant provider
     - Throws: SecurityProtocolError if no suitable provider is found
     */
    private func selectProviderForFipsCompliance() async throws -> EncryptionProviderProtocol {
        // In a real implementation, we would check which providers are FIPS certified
        // For now, we'll prefer Ring as it's based on a FIPS-validated library
        if let factory = providerFactories[.ring] {
            do {
                let provider = try factory()
                await logger.info("Selected Ring provider for FIPS compliance", metadata: nil)
                return provider
            } catch {
                await logger.warning("Failed to create Ring provider: \(error.localizedDescription)", metadata: nil)
            }
        }
        
        // Fall back to platform default
        await logger.warning("No FIPS-compliant provider available, falling back to platform default", metadata: nil)
        return try await selectBestProviderForCurrentPlatform()
    }
    
    /**
     Selects a provider optimised for high performance.
     
     - Returns: A high-performance provider
     - Throws: SecurityProtocolError if no suitable provider is found
     */
    private func selectProviderForHighPerformance() async throws -> EncryptionProviderProtocol {
        // On Apple platforms, prefer Apple's CryptoKit for performance
        #if canImport(CryptoKit) && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        if let factory = providerFactories[.apple] {
            do {
                let provider = try factory()
                await logger.info("Selected Apple provider for high performance", metadata: nil)
                return provider
            } catch {
                await logger.warning("Failed to create Apple provider: \(error.localizedDescription)", metadata: nil)
            }
        }
        #endif
        
        // Ring is also generally high performance
        if let factory = providerFactories[.ring] {
            do {
                let provider = try factory()
                await logger.info("Selected Ring provider for high performance", metadata: nil)
                return provider
            } catch {
                await logger.warning("Failed to create Ring provider: \(error.localizedDescription)", metadata: nil)
            }
        }
        
        // Fall back to platform default
        return try await selectBestProviderForCurrentPlatform()
    }
    
    /**
     Selects a provider that meets specific certification standards.
     
     - Parameter standards: Array of certification standard identifiers
     - Returns: A provider meeting the certification requirements
     - Throws: SecurityProtocolError if no suitable provider is found
     */
    private func selectProviderWithCertifications(_ standards: [String]) async throws -> EncryptionProviderProtocol {
        // In a real implementation, we would check which providers meet which standards
        // For now, we'll use a simplistic approach
        
        // If standards include "FIPS", use the FIPS-compliant provider
        if standards.contains(where: { $0.contains("FIPS") }) {
            return try await selectProviderForFipsCompliance()
        }
        
        // For other standards, fall back to default
        await logger.warning("No provider found matching standards: \(standards.joined(separator: ", ")), falling back to default", metadata: nil)
        return try await selectBestProviderForCurrentPlatform()
    }
    
    /**
     Selects a specific provider by type.
     
     - Parameter type: The provider type to select
     - Returns: A provider of the specified type
     - Throws: SecurityProtocolError if the provider can't be created
     */
    private func selectSpecificProvider(_ type: SecurityProviderType) async throws -> EncryptionProviderProtocol {
        guard let factory = providerFactories[type] else {
            await logger.error("No factory registered for provider type: \(type.rawValue)", metadata: nil)
            throw SecurityProtocolError.unsupportedOperation(name: "Provider type not available: \(type.rawValue)")
        }
        
        do {
            let provider = try factory()
            await logger.info("Selected specific provider type: \(type.rawValue)", metadata: nil)
            return provider
        } catch {
            await logger.error("Failed to create provider of type \(type.rawValue): \(error.localizedDescription)", metadata: nil)
            throw SecurityProtocolError.cryptographicError("Failed to create provider: \(error.localizedDescription)")
        }
    }
}
