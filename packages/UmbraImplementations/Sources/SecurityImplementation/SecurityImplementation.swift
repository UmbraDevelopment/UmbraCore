import CoreSecurityTypes
import Foundation
import LoggingTypes
import LoggingServices
import LoggingInterfaces
import SecurityCoreInterfaces

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createLogMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var logMetadata = LogMetadataDTOCollection()
  for (key, value) in dict {
    logMetadata = logMetadata.withPublic(key: key, value: value)
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
    if let logger = logger {
      return await SecurityServiceFactory.createWithLogger(logger)
    } else {
      // Create a factory instance first
      let factory = LoggingServiceFactory.shared
      let logger = await factory.createPrivacyAwareLogger(
        subsystem: "com.umbra.security",
        category: "SecurityProvider"
      )
      
      // Create an adapter to convert PrivacyAwareLoggingActor to LoggingProtocol
      let loggingAdapter = PrivacyAwareLoggingAdapter(logger: logger)
      
      return await SecurityServiceFactory.createStandard(
        logger: loggingAdapter
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
    keyManager: KeyManagementProtocol,
    logger: any LoggingProtocol
  ) async -> SecurityProviderProtocol {
    // Create a factory instance
    let factory = LoggingServiceFactory.shared
    
    // Create a secure logger with privacy-aware capabilities
    let secureLogger = await factory.createComprehensivePrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "SecurityProvider",
      environment: .production
    )
    
    // Create default configuration
    let configuration = SecurityConfigurationDTO(
      securityLevel: .standard,
      loggingLevel: .info
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
    return await SecurityServiceFactory.createForDevelopment()
  }

  /**
   Creates a security provider for production environments.

   This method provides a security provider with strict security settings
   and minimal logging suitable for production use.

   - Returns: A security provider configured for production use
   */
  public static func createProductionSecurityProvider() async -> SecurityProviderProtocol {
    return await SecurityServiceFactory.createForProduction()
  }

  /**
   The current version of the SecurityImplementation module.
   */
  public static let version="1.0.0"
}

/// Adapter to convert PrivacyAwareLoggingActor to LoggingProtocol
private class PrivacyAwareLoggingAdapter: LoggingProtocol {
  private let logger: PrivacyAwareLoggingActor
  
  init(logger: PrivacyAwareLoggingActor) {
    self.logger = logger
  }
  
  func debug(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.debug(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func info(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.info(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func warning(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.warning(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func error(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.error(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func critical(_ message: String, metadata: LogMetadataDTOCollection?) {
    Task {
      await logger.critical(message, context: LogContextDTO(metadata: metadata ?? LogMetadataDTOCollection()))
    }
  }
  
  func log(_ level: LoggingInterfaces.LogLevel, _ message: String, context: LoggingTypes.LogContextDTO) async {
    switch level {
    case .trace:
      await logger.trace(message, context: context)
    case .debug:
      await logger.debug(message, context: context)
    case .info:
      await logger.info(message, context: context)
    case .notice:
      await logger.info(message, context: context) // Map notice to info
    case .warning:
      await logger.warning(message, context: context)
    case .error:
      await logger.error(message, context: context)
    case .critical:
      await logger.critical(message, context: context)
    }
  }
}
