import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/// Protocol defining the requirements for a provider registry.
/// The registry manages the registration, discovery, and selection of encryption providers.
public protocol ProviderRegistryProtocol: Sendable {
    /// Registers a provider with the registry
    func registerProvider(type: SecurityProviderType, factory: @escaping @Sendable () throws -> EncryptionProviderProtocol) async throws
    
    /// Selects a provider based on the requested capabilities
    func selectProvider(capabilities: [ProviderCapability]) async throws -> EncryptionProviderProtocol
    
    /// Selects a provider of a specific type
    func selectProvider(type: SecurityProviderType) async throws -> EncryptionProviderProtocol
    
    /// Sets the preferred provider type for specific capabilities
    func setPreferredProvider(type: SecurityProviderType, forCapabilities capabilities: [ProviderCapability]) async
    
    /// Checks if the registry has a provider that supports FIPS compliance
    func hasFIPSCompliantProvider() async -> Bool
}
