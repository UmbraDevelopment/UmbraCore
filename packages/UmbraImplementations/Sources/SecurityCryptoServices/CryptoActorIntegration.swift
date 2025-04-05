import CoreSecurityTypes
import CryptoActorImplementations
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # CryptoActorIntegration

 This file provides type aliases for actor types defined in the CryptoActorImplementations
 module, making them available to consumers of the SecurityCryptoServices module.

 This indirection allows us to keep the actor implementations separate from the interface,
 while still providing a convenient way to access them.
 */
public enum CryptoActorIntegration {
  // Re-export the actor types directly from the CryptoActorImplementations module
  // The actors are defined at the top level in that module
  public typealias CryptoServiceActor=CryptoActorImplementations.CryptoServiceActor
  public typealias ProviderRegistryActor=CryptoActorImplementations.ProviderRegistryActor
  public typealias SecureStorageActor=CryptoActorImplementations.SecureStorageActor
}
