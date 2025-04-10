import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createLogMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var logMetadata=LogMetadataDTOCollection()
  for (key, value) in dict {
    logMetadata=logMetadata.withPublic(key: key, value: value)
  }
  return logMetadata
}

/**
 # UmbraCore Security Implementation

 This module provides the main implementation of the security subsystem
 for UmbraCore, following the architecture principles.

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

 ## Logging

 The SecurityImplementation module utilises privacy-aware logging, adhering to
 the Alpha Dot Five architecture principles. This approach ensures that logging
 is conducted in a manner that respects user privacy, whilst still providing
 valuable insights into system operations.
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
    if let logger {
      return await SecurityServiceFactory.createWithLogger(logger)
    } else {
      // Create a factory instance first
      let factory=LoggingServiceFactory.shared
      let loggingService = await factory.createService(
        minimumLevel: .info
      )
      
      // Wrap the logging service with a protocol adapter
      let logger = await SecurityLoggingUtilities.createLoggingWrapper(logger: loggingService)

      return await SecurityServiceFactory.createStandard(
        logger: logger
      )
    }
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
    keyManager _: KeyManagementProtocol,
    logger: any LoggingProtocol
  ) async -> SecurityProviderProtocol {
    // Create a factory instance
    let factory=LoggingServiceFactory.shared

    // Create a secure logger with privacy-aware capabilities
    let secureLogger=await factory.createComprehensivePrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "SecurityProvider",
      environment: .production
    )

    // Create default configuration
    let configuration=CoreSecurityTypes.SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256,
      providerType: CoreSecurityTypes.SecurityProviderType.cryptoKit
    )

    // Create the security service actor directly
    return SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: secureLogger,
      configuration: configuration
    )
  }

  /**
   Creates a security provider for development environments.

   This method provides a security provider with verbose logging and
   relaxed security settings suitable for development.

   - Returns: A security provider configured for development use
   */
  public static func createDevelopmentSecurityProvider() async -> SecurityProviderProtocol {
    await SecurityServiceFactory.createForDevelopment()
  }

  /**
   Creates a security provider for production environments.

   This method provides a security provider with strict security settings
   and minimal logging suitable for production use.

   - Returns: A security provider configured for production use
   */
  public static func createProductionSecurityProvider() async -> SecurityProviderProtocol {
    await SecurityServiceFactory.createForProduction()
  }

  /**
   The current version of the SecurityImplementation module.
   */
  public static let version="1.0.0"
}

/**
 Simple implementation of LogContextDTO for basic logging needs.

 This struct provides a minimal implementation of the LogContextDTO protocol
 that can be used for simple logging without needing to create specialised
 context types.
 */
private struct SimpleLogContext: LogContextDTO {
  /// The domain name for this context
  let domainName: String="SecurityImplementation"

  /// Optional source information
  let source: String?=nil

  /// Optional correlation ID for tracing related log events
  let correlationID: String?=UUID().uuidString

  /// The metadata collection for this context
  let metadata: LogMetadataDTOCollection

  /**
   Creates a new simple log context with the given metadata.

   - Parameter metadata: The metadata for the log context
   */
  init(metadata: LogMetadataDTOCollection) {
    self.metadata=metadata
  }
}
