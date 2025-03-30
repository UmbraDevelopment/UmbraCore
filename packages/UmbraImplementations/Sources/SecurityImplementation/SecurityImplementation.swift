import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes

/**
 # UmbraCore Security Implementation

 This module provides the main implementation of the security subsystem
 for UmbraCore, following the Alpha Dot Five architecture principles.

 ## Usage

 The primary way to use this module is through the SecurityProviderFactory:

 ```swift
 // Create a standard security provider
 let securityProvider = await SecurityImplementation.createSecurityProvider()

 // Use the provider to perform security operations
 var options = SecurityConfigOptions()
 options.algorithm = "AES"
 options.keySize = 256
 options.mode = "GCM"
 
 let config = await securityProvider.createSecureConfig(options: options)

 let result = await securityProvider.encrypt(config: config)
 ```

 ## Architecture

 The SecurityImplementation module follows a modular architecture with clear
 separation of concerns:

 * **SecurityProviderImpl**: Implementation of the SecurityProviderProtocol
 * **Extensions**: Focused extensions for specific functionality (validation, logging)
 * **Factory**: Factory methods for creating properly configured instances

 ## Thread Safety

 All implementations are thread-safe through Swift's actor system, ensuring
 proper isolation of mutable state and eliminating race conditions.
 */
public enum SecurityImplementation {
  /**
   Creates a standard security provider with default dependencies.

   This method is a convenience wrapper around SecurityProviderFactory.createSecurityProvider().

   - Parameter logger: Optional logger for recording operations
   - Returns: A fully configured SecurityProviderProtocol instance
   */
  public static func createSecurityProvider(
    logger: (any LoggingProtocol)?=nil
  ) async -> SecurityProviderProtocol {
    await SecurityProviderFactory.createSecurityProvider(logger: logger)
  }

  /**
   Creates a security provider with custom dependencies.

   This method is a convenience wrapper around SecurityProviderFactory.createSecurityProvider().

   - Parameters:
     - cryptoService: Custom cryptographic service implementation
     - keyManager: Custom key management service implementation
     - logger: Custom logger for recording operations
   - Returns: A security provider using the specified custom dependencies
   */
  public static func createCustomSecurityProvider(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: any LoggingProtocol
  ) -> SecurityProviderProtocol {
    SecurityProviderFactory.createSecurityProvider(
      cryptoService: cryptoService,
      keyManager: keyManager,
      logger: logger
    )
  }

  /**
   The current version of the SecurityImplementation module.
   */
  public static let version="1.0.0"
}
