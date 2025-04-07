import CryptoInterfaces
import SecurityCoreInterfaces

import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityInterfaces
import UmbraErrors

/**
 # CryptoServiceFactory

 Factory for creating CryptoServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 of providing asynchronous factory methods that return actor-based
 implementations.

 ## CANONICAL IMPLEMENTATION
 This is the canonical factory for all cryptographic service implementations
 in the UmbraCore project. All other factory methods (such as those in CryptoServices)
 should delegate to this implementation. This design eliminates duplication and
 ensures consistent behaviour across all cryptographic service creations.

 ## Usage Examples

 ### Standard Implementation
 ```swift
 // Create a default implementation
 let cryptoService = await CryptoServiceFactory.createDefault(secureStorage: mySecureStorage)

 // Create a service with custom secure logger
 let customService = await CryptoServiceFactory.createDefaultService(
   secureStorage: mySecureStorage,
   secureLogger: mySecureLogger
 )
 ```

 ### Security Provider-Specific Implementations
 ```swift
 // Create a service with a specific provider type
 let cryptoWithProvider = await CryptoServiceFactory.createWithProviderType(
   providerType: .cryptoKit,
   logger: myLogger
 )

 // For more control, create with explicit provider instance
 let myProvider = await ProviderFactory.createProvider(.appleCommonCrypto)
 let cryptoService = await CryptoServiceFactory.createWithProvider(
   provider: myProvider,
   secureStorage: mySecureStorage,
   logger: myLogger
 )
 ```

 ### Logging and Testing Implementations
 ```swift
 // Create a logging implementation
 let loggingService = await CryptoServiceFactory.createLoggingDecorator(
   wrapped: cryptoService,
   logger: myLogger,
   secureLogger: mySecureLogger
 )

 // Create a mock implementation for testing
 let mockService = await CryptoServiceFactory.createMock()
 ```
 */
public enum CryptoServiceFactory {
  // MARK: - Standard Implementations

  /**
   Creates a default crypto service implementation.

   - Parameter secureStorage: Optional secure storage service to use
   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault(
    secureStorage: SecureStorageProtocol?=nil
  ) async -> CryptoServiceProtocol {
    await createDefaultService(secureStorage: secureStorage)
  }

  /**
   Creates the default crypto service.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A standard CryptoServiceProtocol implementation
   */
  public static func createDefaultService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    return await DefaultCryptoServiceImpl(
      secureStorage: secureStorage ?? createLocalSecureStorage(logger: actualLogger),
      logger: actualLogger,
      options: FactoryCryptoOptions()
    )
  }

  /**
   Creates a logging crypto service implementation.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation with basic logging
   */
  public static func createLoggingService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    return await LoggingCryptoServiceImpl(
      wrapped: DefaultCryptoServiceImpl(
        secureStorage: secureStorage ?? createLocalSecureStorage(logger: actualLogger),
        logger: actualLogger,
        options: FactoryCryptoOptions()
      ),
      logger: actualLogger
    )
  }

  /**
   Creates an enhanced logging crypto service implementation.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation with enhanced privacy-aware logging
   */
  public static func createEnhancedLoggingService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    return await EnhancedLoggingCryptoServiceImpl(
      wrapped: DefaultCryptoServiceImpl(
        secureStorage: secureStorage ?? createLocalSecureStorage(logger: actualLogger),
        logger: actualLogger,
        options: FactoryCryptoOptions()
      ),
      logger: actualLogger
    )
  }

  /**
   Creates a high security crypto service implementation.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation with enhanced security
   */
  public static func createHighSecurityService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    // Create secure service with enhanced parameters
    let service=await EnhancedSecureCryptoServiceImpl(
      wrapped: DefaultCryptoServiceImpl(
        secureStorage: secureStorage ?? createLocalSecureStorage(logger: actualLogger),
        logger: actualLogger,
        options: FactoryCryptoOptions(
          defaultIterations: 10000, // Higher iteration count for PBKDF2
          enforceStrongKeys: true
        )
      ),
      storage: createSecureStorage(),
      logger: actualLogger
    )

    return await LoggingCryptoServiceImpl(
      wrapped: service,
      logger: actualLogger
    )
  }

  /**
   Creates a mock crypto service implementation for testing.

   - Parameters:
     - shouldSucceed: Whether operations should succeed
     - logger: Logger for operations
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMockService(
    shouldSucceed: Bool=true,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    return await MockCryptoServiceImpl(
      configuration: MockCryptoConfiguration(
        encryptionSucceeds: shouldSucceed,
        decryptionSucceeds: shouldSucceed,
        hashingSucceeds: shouldSucceed,
        verificationSucceeds: shouldSucceed,
        keyGenerationSucceeds: shouldSucceed,
        storageSucceeds: shouldSucceed,
        retrievalSucceeds: shouldSucceed
      ),
      logger: actualLogger
    )
  }

  /**
   Creates a crypto service implementation based on the environment.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation appropriate for the environment
   */
  public static func createEnvironmentAppropriateService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil,
    environment: DeploymentEnvironment = .production
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    switch environment {
      case .development:
        return await DefaultCryptoServiceImpl(
          secureStorage: secureStorage ?? createLocalSecureStorage(logger: actualLogger),
          logger: actualLogger,
          options: FactoryCryptoOptions(
            defaultIterations: 1000, // Lower for development speed
            enforceStrongKeys: false // More lenient for development
          )
        )

      case .testing:
        return await MockCryptoServiceImpl(
          configuration: MockCryptoConfiguration(
            encryptionSucceeds: true,
            decryptionSucceeds: true,
            hashingSucceeds: true,
            verificationSucceeds: true,
            keyGenerationSucceeds: true,
            storageSucceeds: true,
            retrievalSucceeds: true
          ),
          logger: actualLogger
        )

      case .staging:
        return await EnhancedLoggingCryptoServiceImpl(
          wrapped: DefaultCryptoServiceImpl(
            secureStorage: secureStorage ?? createLocalSecureStorage(logger: actualLogger),
            logger: actualLogger,
            options: FactoryCryptoOptions(
              defaultIterations: 5000, // Medium strength for staging
              enforceStrongKeys: true
            )
          ),
          logger: actualLogger
        )

      case .production:
        // Use the high security service
        return await createHighSecurityService(
          secureStorage: secureStorage,
          logger: actualLogger
        )
    }
  }

  // MARK: - Provider-Specific Implementations

  /**
   Creates a new crypto service with the specified provider type.
   This is the consolidated implementation that handles provider creation internally.

   This method integrates functionality previously available in separate factory implementations,
   providing a unified interface for creating cryptographic services with specific provider types.

   - Parameters:
     - providerType: The type of security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol
   */
  public static func createWithProviderType(
    providerType: SecurityProviderType,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    // Use the provided secure storage or create a default one
    let actualSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    // Create provider based on the specified type
    // This approach uses the provider registry to create providers dynamically
    let provider: SecurityProviderProtocol?=switch providerType {
      case .cryptoKit:
        await createBasicSecurityProvider(.cryptoKit)
      case .ring:
        await createBasicSecurityProvider(.ring)
      case .basic:
        await createBasicSecurityProvider(.basic)
      case .system:
        await createBasicSecurityProvider(.system)
      case .hsm:
        await createBasicSecurityProvider(.basic) // Fallback for HSM
    }

    guard let provider else {
      await actualLogger.error(
        "Failed to create provider of type \(providerType). Falling back to basic implementation.",
        metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
        source: "CryptoServiceFactory"
      )

      // Return a basic implementation as fallback
      return await createWithProviderType(
        .basic,
        secureStorage: actualSecureStorage,
        logger: actualLogger
      )
    }

    // Now use the provider to create the crypto service
    return await createWithProvider(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  /**
   Creates a new crypto service with the specified security provider.
   The implementation follows the actor-based concurrency model of the
   Alpha Dot Five architecture.

   - Parameters:
      - provider: The security provider to use (should be obtained from appropriate factory)
      - secureStorage: Optional secure storage service to use
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol
   */
  public static func createWithProvider(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()

    // Use the provided secure storage or create a default one
    let actualSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    // Create a crypto service implementation using DefaultCryptoServiceWithProviderImpl
    let cryptoService=await DefaultCryptoServiceWithProviderImpl(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )

    // Return as the protocol type
    return cryptoService
  }

  /**
   Creates a new secure storage service for key management.

   - Parameters:
      - storageURL: Custom URL for key storage
      - logger: Logger for recording operations
   - Returns: A new secure storage implementation
   */
  public static func createSecureStorage(
    storageURL: URL?=nil,
    logger: LoggingProtocol?=nil
  ) async -> SecureStorageProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()
    let url=storageURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("CryptoSecureStorage")

    // Create a simple in-memory secure storage
    return InMemorySecureStorage(
      logger: actualLogger,
      baseURL: url
    )
  }

  /**
   Creates a local secure storage implementation.

   - Parameter logger: Logger for operations
   - Returns: A SecureStorageProtocol implementation
   */
  private static func createLocalSecureStorage(
    logger: LoggingProtocol
  ) async -> SecureStorageProtocol {
    await createSecureStorage(logger: logger)
  }

  /**
   Creates a mock crypto service for testing.

   - Parameters:
     - configuration: Configuration options for the mock
     - logger: Logger for operations
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock(
    configuration: MockCryptoServiceImpl.Configuration = .init(),
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger=logger ?? LoggingServiceFactory.createStandardLogger()
    return await MockCryptoServiceImpl(configuration: configuration, logger: actualLogger)
  }

  /**
   Creates a logging decorator around a crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap
     - logger: Logger for operations
     - secureLogger: Privacy-aware secure logger for sensitive operations
   - Returns: A CryptoServiceProtocol implementation with logging
   */
  public static func createLoggingDecorator(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol,
    secureLogger: PrivacyAwareLoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    if let secureLogger {
      await EnhancedLoggingCryptoServiceImpl(
        wrapped: wrapped,
        secureStorage: wrapped.secureStorage, // Pass secureStorage from wrapped service
        logger: secureLogger
      )
    } else {
      await LoggingCryptoServiceImpl(
        wrapped: wrapped,
        logger: logger
      )
    }
  }

  // MARK: - Provider Creation Helpers

  private static func createBasicSecurityProvider(
    _ type: SecurityProviderType
  ) async -> SecurityProviderProtocol? {
    BasicSecurityProvider(type: type)
  }
}
