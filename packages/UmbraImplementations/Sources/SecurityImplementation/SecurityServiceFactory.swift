import CoreSecurityTypes
import CryptoInterfaces
import CryptoServicesCore
import CryptoServicesCore.Testing
import CryptoServicesStandard
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/// Factory for creating instances of the SecurityProviderProtocol.
///
/// This factory provides methods for creating fully configured security service
/// instances with various configurations and crypto service integrations, ensuring
/// proper domain separation and delegation to crypto services.
///
/// All security services created by this factory use privacy-aware logging through
/// SecureLoggerActor, following the Alpha Dot Five architecture principles.
public enum SecurityServiceFactory {
  /// Creates a standard security service with default configuration
  /// - Parameters:
  ///   - logger: The logger to use for general logging
  ///   - secureLogger: The secure logger to use for privacy-aware logging (created if nil)
  /// - Returns: A security service instance
  public static func createStandard(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: LoggingInterfaces.LoggingProtocol?=nil
  ) async -> SecurityProviderProtocol {
    // Create a secure logger if one wasn't provided
    let actualSecureLogger: LoggingInterfaces.LoggingProtocol=if let secureLogger {
      secureLogger
    } else {
      await createSecureLogger(logger: logger)
    }

    // Create default configuration
    let configuration=CoreSecurityTypes.SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256,
      providerType: CoreSecurityTypes.SecurityProviderType.cryptoKit
    )

    // Create the security service with secure logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: actualSecureLogger,
      configuration: configuration
    )
  }

  /// Creates a security service with the specified logger
  /// - Parameter logger: The logger to use
  /// - Returns: A security service instance
  public static func createWithLogger(
    _ logger: LoggingInterfaces.LoggingProtocol
  ) async -> SecurityProviderProtocol {
    await createWithLoggers(logger: logger, secureLogger: nil, configuration: nil)
  }

  /// Creates a security service with the specified loggers
  /// - Parameters:
  ///   - logger: The standard logger to use for general operations
  ///   - secureLogger: The secure logger to use for privacy-aware logging (created if nil)
  ///   - configuration: The security configuration to use (created if nil)
  /// - Returns: A fully configured security service with privacy-aware logging
  public static func createWithLoggers(
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: LoggingInterfaces.LoggingProtocol?=nil,
    configuration: CoreSecurityTypes.SecurityConfigDTO?=nil
  ) async -> SecurityProviderProtocol {
    // Create dependencies
    let cryptoService = await CryptoServiceRegistry.createService(
        type: .standard,
        logger: logger
    )

    // Create a secure logger if one wasn't provided
    let actualSecureLogger: LoggingInterfaces.LoggingProtocol=if let secureLogger {
      secureLogger
    } else {
      await createSecureLogger(logger: logger)
    }

    // Create default configuration if needed
    let configurationInstance: CoreSecurityTypes.SecurityConfigDTO=if let config=configuration {
      config
    } else {
      CoreSecurityTypes.SecurityConfigDTO(
        encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
        hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256,
        providerType: CoreSecurityTypes.SecurityProviderType.cryptoKit
      )
    }

    // Create the security service with the configured dependencies
    return SecurityServiceActor(
      cryptoService: cryptoService,
      logger: logger,
      secureLogger: actualSecureLogger,
      configuration: configurationInstance
    )
  }

  /**
   Creates a mock security service for testing.
   
   - Returns: A security provider that provides mock implementations for testing
   */
  public static func createForTesting() async -> SecurityProviderProtocol {
    let baseLogger = NoOpLoggerImpl()
    let logger = await SecurityLoggingUtilities.createLoggingWrapper(logger: baseLogger)
    
    // Use the standardised MockCryptoService from CryptoServicesCore.Testing
    let cryptoService = MockCryptoService(
      secureStorage: MockSecureStorage(), 
      mockBehaviour: MockCryptoService.MockBehaviour(logOperations: true)
    )
    
    return SecurityProviderImpl(
      cryptoService: cryptoService,
      keyManager: TestKeyManager(),
      logger: logger
    )
  }

  /// Creates a security service for development with verbose logging
  /// - Returns: A security service instance with verbose logging
  public static func createForDevelopment() async -> SecurityProviderProtocol {
    let loggingFactory=LoggingServiceFactory.shared
    let logger=await loggingFactory.createPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "SecurityImplementation",
      environment: .development
    )

    // Create default configuration
    let configuration=CoreSecurityTypes.SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256,
      providerType: CoreSecurityTypes.SecurityProviderType.cryptoKit
    )

    // Create the security service with verbose logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: nil,
      configuration: configuration
    )
  }

  /// Creates a security service for production with secure logging
  /// - Returns: A security service instance with production logging
  public static func createForProduction() async -> SecurityProviderProtocol {
    let loggingFactory=LoggingServiceFactory.shared
    let logger=await loggingFactory.createProductionPrivacyAwareLogger(
      subsystem: "com.umbra.security",
      category: "SecurityImplementation"
    )

    // Create default configuration
    let configuration=CoreSecurityTypes.SecurityConfigDTO(
      encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
      hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256,
      providerType: CoreSecurityTypes.SecurityProviderType.cryptoKit
    )

    // Create the security service with production logging
    return await createWithLoggers(
      logger: logger,
      secureLogger: nil,
      configuration: configuration
    )
  }

  /// Creates a secure logger for privacy-aware logging of security operations
  /// - Parameters:
  ///   - logger: The base logger to use
  /// - Returns: A secure logger for privacy-aware logging
  private static func createSecureLogger(
    logger _: LoggingInterfaces.LoggingProtocol
  ) async -> LoggingInterfaces.LoggingProtocol {
    // First create a standard logger to use as the base logger
    let loggingFactory=LoggingServiceFactory.shared
    let baseLogger=await loggingFactory.createService(
      minimumLevel: .info
    )

    // Wrap the standard logger with our protocol adapter to return a LoggingProtocol
    return await SecurityLoggingUtilities.createLoggingWrapper(logger: baseLogger)

    // Note: We don't return the SecureLoggerActor since it doesn't conform to LoggingProtocol
    // The SecureLoggerActor should be created where needed by the consumer
  }
}

/// Helper function to create metadata dictionary from LogMetadataDTOCollection
private func createMetadataDictionary(_: LogMetadataDTOCollection) -> [String: String] {
  // Since LogMetadataDTOCollection doesn't conform to Sequence, we can't iterate it directly
  // Return empty dictionary for now - this will need to be implemented based on
  // the actual LogMetadataDTOCollection API
  [:]
}

/**
 A simple key manager for testing purposes.
 */
private final class TestKeyManager: KeyManagementProtocol {
  public func storeKey(_ key: [UInt8], withIdentifier identifier: String) async -> Result<Void, KeyManagementError> {
    return .success(())
  }
  
  public func retrieveKey(withIdentifier identifier: String) async -> Result<[UInt8], KeyManagementError> {
    return .success([0, 1, 2, 3, 4, 5])
  }
  
  public func deleteKey(withIdentifier identifier: String) async -> Result<Void, KeyManagementError> {
    return .success(())
  }
}
