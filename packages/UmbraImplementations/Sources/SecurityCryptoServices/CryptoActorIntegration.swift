import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import CoreSecurityTypes
import DomainSecurityTypes
import UmbraErrors

// Create a namespace to avoid conflicts with Swift's native 'actor' keyword
// and provide access to our actor implementations
public enum CryptoActorImplementations {
    // Re-export the actor types from the implementation files
    public typealias CryptoServiceActor = SecurityCryptoServices.CryptoServiceActor
    public typealias ProviderRegistryActor = SecurityCryptoServices.ProviderRegistryActor
    public typealias SecureStorageActor = SecurityCryptoServices.SecureStorageActor
}
