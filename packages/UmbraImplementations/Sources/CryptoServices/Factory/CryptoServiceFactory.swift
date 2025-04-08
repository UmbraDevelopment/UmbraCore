import CryptoInterfaces
import SecurityCoreInterfaces

import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityInterfaces
import SecurityProviderRegistryInterfaces
import SecurityProviders
import SecureStorageImplementations
import Throttling
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
   - Parameter logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let actualSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await DefaultCryptoServiceImpl(
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  /**
   Creates the default crypto service.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A standard CryptoServiceProtocol implementation
   */
  public static func createDefaultService(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let actualSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await DefaultCryptoServiceImpl(
      secureStorage: actualSecureStorage,
      logger: actualLogger
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let defaultSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await LoggingCryptoServiceImpl(
      wrapped: DefaultCryptoServiceImpl(
        secureStorage: defaultSecureStorage,
        logger: actualLogger
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: PrivacyAwareLoggingProtocol = (logger as? PrivacyAwareLoggingProtocol) ?? LoggingServiceFactory.createPrivacyAwareLogger()
    let defaultSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await EnhancedLoggingCryptoServiceImpl(
      wrapped: DefaultCryptoServiceImpl(
        secureStorage: defaultSecureStorage,
        logger: actualLogger
      ),
      secureStorage: defaultSecureStorage,
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: PrivacyAwareLoggingProtocol = (logger as? PrivacyAwareLoggingProtocol) ?? LoggingServiceFactory.createPrivacyAwareLogger()
    let defaultSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)
    let rateLimiter = DefaultRateLimiter()

    let service = await EnhancedSecureCryptoServiceImpl(
      wrapped: DefaultCryptoServiceImpl(
        secureStorage: defaultSecureStorage,
        logger: actualLogger
      ),
      logger: actualLogger,
      rateLimiter: rateLimiter
    )

    return await LoggingCryptoServiceImpl(
      wrapped: service,
      logger: logger ?? LoggingServiceFactory.createStandardLogger()
    )
  }

  /**
   Creates a mock crypto service implementation for testing.

   - Parameters:
     - configuration: Configuration options for the mock
     - logger: Logger for operations
     - secureStorage: Secure storage for the mock implementation
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock(
    configuration: MockCryptoServiceImpl.Configuration = .init(),
    logger: LoggingProtocol? = nil,
    secureStorage: SecureStorageProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let actualSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await MockCryptoServiceImpl(
      configuration: configuration,
      logger: actualLogger,
      secureStorage: actualSecureStorage
    )
  }

  /**
   Creates a crypto service implementation based on the environment.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
     - environment: Deployment environment
   - Returns: A CryptoServiceProtocol implementation appropriate for the environment
   */
  public static func createEnvironmentAppropriateService(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil,
    environment: DeploymentEnvironment = .production
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let defaultSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    switch environment {
      case .development:
        return await DefaultCryptoServiceImpl(
          secureStorage: defaultSecureStorage,
          logger: actualLogger
        )

      case .testing:
        return await MockCryptoServiceImpl(
          configuration: MockCryptoServiceImpl.Configuration(
            encryptionSucceeds: true,
            decryptionSucceeds: true,
            hashSucceeds: true,
            keyGenerationSucceeds: true
          ),
          logger: actualLogger,
          secureStorage: defaultSecureStorage
        )

      case .staging, .production:
        let privacyLogger: PrivacyAwareLoggingProtocol = (logger as? PrivacyAwareLoggingProtocol) ?? LoggingServiceFactory.createPrivacyAwareLogger()

        return await EnhancedLoggingCryptoServiceImpl(
          wrapped: DefaultCryptoServiceImpl(
            secureStorage: defaultSecureStorage,
            logger: actualLogger
          ),
          secureStorage: defaultSecureStorage,
          logger: privacyLogger
        )
    }
  }

  // MARK: - Provider-Specific Implementations

  /**
   Creates a crypto service with a specific provider type.

   - Parameters:
     - providerType: Type of security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation with the specified provider
   */
  public static func createWithProviderType(
    providerType: SecurityProviderType,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let registry = await createProviderRegistry(logger: actualLogger)
    let actualProvider = await registry.createProvider(type: providerType)
    let actualSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await DefaultCryptoServiceWithProviderImpl(
      provider: actualProvider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  /**
   Creates a crypto service with a specific provider.

   - Parameters:
     - provider: Security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation with the specified provider
   */
  public static func createWithProvider(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let actualSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await DefaultCryptoServiceWithProviderImpl(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  // MARK: - Provider Registry Support

  /**
   Creates a provider registry for managing security providers.
   
   - Parameter logger: Optional logger for operations
   - Returns: A provider registry implementation
   */
  public static func createProviderRegistry(
    logger: LoggingProtocol? = nil
  ) async -> SecurityProviderRegistryProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()

    return await DefaultSecurityProviderRegistry(logger: actualLogger)
  }

  // MARK: - Storage-Related Methods

  /**
   Creates a secure storage implementation.
   
   - Parameters:
     - provider: Optional security provider to use
     - storageURL: Optional URL for storage location
     - logger: Optional logger for operations
   - Returns: A secure storage implementation
   */
  public static func createSecureStorage(
    provider: SecurityProviderProtocol? = nil,
    storageURL: URL? = nil,
    logger: LoggingProtocol? = nil
  ) async -> SecureStorageProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let actualProvider: SecurityProviderProtocol

    if let provider = provider {
      actualProvider = provider
    } else {
      let registry = await createProviderRegistry(logger: actualLogger)
      actualProvider = await registry.createProvider(type: SecurityProviderType.default)
    }

    return await DefaultSecureStorageImpl(
      provider: actualProvider,
      storageURL: storageURL,
      logger: actualLogger
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
     - secureStorage: Secure storage for the mock implementation
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public static func createMock(
    configuration: MockCryptoServiceImpl.Configuration = .init(),
    logger: LoggingProtocol? = nil,
    secureStorage: SecureStorageProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol = logger ?? LoggingServiceFactory.createStandardLogger()
    let actualSecureStorage = secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await MockCryptoServiceImpl(
      configuration: configuration,
      logger: actualLogger,
      secureStorage: actualSecureStorage
    )
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
    secureLogger: PrivacyAwareLoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    if let secureLogger {
      return await EnhancedLoggingCryptoServiceImpl(
        wrapped: wrapped,
        secureStorage: wrapped.secureStorage,
        logger: secureLogger
      )
    } else {
      return await LoggingCryptoServiceImpl(
        wrapped: wrapped,
        logger: logger
      )
    }
  }

  // MARK: - Provider Creation Helpers

  private static func createBasicSecurityProvider(
    _ type: SecurityProviderType
  ) async -> SecurityProviderProtocol? {
    BasicSecurityProvider()
  }
}
