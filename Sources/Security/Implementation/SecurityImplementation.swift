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
import UmbraErrors
import Types
import Protocols

/// Central access point for security implementation functionality
///
/// This enum provides factory methods to create security providers and other
/// security-related components. It serves as the main entry point for the
/// SecurityImplementation module.
public enum SecurityImplementation {
  /// Create a default security provider with standard implementations
  ///
  /// This method creates a security provider with the default implementations
  /// of all required components:
  /// - CryptoServiceCore for cryptographic operations
  /// - KeyManager for key management
  ///
  /// Example:
  /// ```swift
  /// let provider = SecurityImplementation.createDefaultSecurityProvider()
  /// let result = await provider.performSecureOperation(...)
  /// ```
  public static func createDefaultSecurityProvider() -> SecurityProviderProtocol {
    SecurityProvider()
  }

  /// Create a security provider with custom service implementations
  ///
  /// This method allows you to provide custom implementations of the
  /// cryptographic service and key manager:
  ///
  /// Example:
  /// ```swift
  /// let customCrypto = MyCryptoService()
  /// let customKeyManager = MyKeyManager()
  /// let provider = SecurityImplementation.createSecurityProvider(
  ///   cryptoService: customCrypto,
  ///   keyManager: customKeyManager
  /// )
  /// ```
  public static func createSecurityProvider(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol
  ) -> SecurityProviderProtocol {
    SecurityProvider(cryptoService: cryptoService, keyManager: keyManager)
  }
}
