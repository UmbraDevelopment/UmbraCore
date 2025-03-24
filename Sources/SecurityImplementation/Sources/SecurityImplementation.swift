/**
 # UmbraCore Security Implementation

 This file provides the main entry point for the SecurityImplementation module of UmbraCore.
 It offers factory methods to create default and custom security providers that implement
 the SecurityProviderProtocol.

 ## Usage

 The primary way to use this module is to create a security provider using one of the
 factory methods, then use that provider to perform security operations:

 ```swift
 let securityProvider = SecurityImplementation.createDefaultSecurityProvider()

 // Use the provider to perform security operations
 let config = securityProvider.createSecureConfig(options: [
     "algorithm": "AES-GCM",
     "keySize": 256
 ])

 let result = await securityProvider.performSecureOperation(
     operation: .symmetricEncryption,
     config: config
 )
 ```

 ## Architecture

 The SecurityImplementation module follows a modular architecture with clear separation
 of concerns:

 * **SecurityProvider**: Facade that coordinates between cryptographic and key management services
 * **CryptoServiceCore**: Handles cryptographic operations (encryption, decryption, hashing)
 * **KeyManager**: Manages cryptographic keys (generation, storage, retrieval)
 * **Specialised Components**: Focused implementations for specific functionality

 ## Design Patterns

 This module employs several design patterns:

 1. **Facade Pattern**: The SecurityProvider acts as a facade, providing a simplified interface
    to the complex security subsystem.

 2. **Factory Method Pattern**: This file provides factory methods to create security providers
    with appropriate configuration.

 3. **Strategy Pattern**: Different cryptographic algorithms and key management strategies
    can be swapped out without changing the client code.

 ## Security Considerations

 * This implementation follows security best practices but should be reviewed
   before use in production systems.
 * Cryptographic operations use industry-standard algorithms (AES-GCM, SHA-256, etc.)
 * Key management follows proper lifecycle practices (secure generation, storage, rotation)
 */

import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Entry point for the SecurityImplementation module.
///
/// This namespace provides factory methods to create security providers that
/// implement the SecurityProviderProtocol.
public enum SecurityImplementation {
  /**
   Create a default security provider with standard configuration.

   This provider is configured with:
   - AES-GCM symmetric encryption
   - SHA-256 hashing
   - Secure random key generation

   - Returns: A security provider implementing SecurityProviderProtocol

   ## Example

   ```swift
   let provider = SecurityImplementation.createDefaultSecurityProvider()
   let config = provider.createSecureConfig(options: nil)
   let result = await provider.performSecureOperation(
       operation: .symmetricEncryption,
       config: config
   )
   ```
   */
  public static func createDefaultSecurityProvider() -> SecurityProviderProtocol {
    SecurityProvider()
  }

  /**
   Create a custom security provider with the specified services.

   This method allows you to provide custom implementations of the crypto service
   and key manager, which can be useful for testing or when special functionality
   is required.

   - Parameters:
     - cryptoService: Custom implementation of the crypto service
     - keyManager: Custom implementation of the key manager
   - Returns: A security provider implementing SecurityProviderProtocol

   ## Example

   ```swift
   let cryptoService = MyCustomCryptoService()
   let keyManager = MyCustomKeyManager()

   let provider = SecurityImplementation.createSecurityProvider(
       cryptoService: cryptoService,
       keyManager: keyManager
   )
   ```
   */
  public static func createSecurityProvider(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) -> SecurityProviderProtocol {
    SecurityProvider(cryptoService: cryptoService, keyManager: keyManager)
  }
}
