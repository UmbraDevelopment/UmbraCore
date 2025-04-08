import CryptoInterfaces
import SecurityCoreInterfaces

import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityInterfaces
import SecurityProviders

// import SecureStorageImplementations  // This module doesn't exist
// Removed APIServices import to break dependency cycle
import UmbraErrors

/**
 # CryptoServiceFactory

 Factory for creating CryptoServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 by implementing an actor-based design for thread safety and
 providing asynchronous factory methods that return actor-based
 implementations.

 ## CANONICAL IMPLEMENTATION
 This is the canonical factory for all cryptographic service implementations
 in the UmbraCore project. All other factory methods (such as those in CryptoServices)
 should delegate to this implementation. This design eliminates duplication and
 ensures consistent behaviour across all cryptographic service creations.

 ## Usage Examples

 ### Standard Implementation
 ```swift
 // Create the factory
 let factory = CryptoServiceFactory()

 // Create a default implementation
 let cryptoService = await factory.createDefault(secureStorage: mySecureStorage)

 // Create a service with custom secure logger
 let customService = await factory.createDefaultService(
   secureStorage: mySecureStorage,
   secureLogger: mySecureLogger
 )
 ```

 ### Security Provider-Specific Implementations
 ```swift
 // Create a service with a specific provider type
 let cryptoWithProvider = await factory.createWithProviderType(
   providerType: .cryptoKit,
   logger: myLogger
 )

 // For more control, create with explicit provider instance
 let myProvider = await ProviderFactory.createProvider(.appleCommonCrypto)
 let cryptoService = await factory.createWithProvider(
   provider: myProvider,
   secureStorage: mySecureStorage,
   logger: myLogger
 )
 ```

 ### Logging and Testing Implementations
 ```swift
 // Create a logging implementation
 let loggingService = await factory.createLoggingDecorator(
   wrapped: cryptoService,
   logger: myLogger,
   secureLogger: mySecureLogger
 )

 // Create a mock implementation for testing
 let mockService = await factory.createMock()
 ```
 */
public actor CryptoServiceFactory {
  // MARK: - Properties

  /// Shared instance for singleton access pattern
  public static let shared=CryptoServiceFactory()

  /// Cache of created services for reuse
  private var serviceCache: [String: CryptoServiceProtocol]=[:]

  // MARK: - Initialisation

  /// Default initialiser
  public init() {}

  // MARK: - Standard Implementations

  /**
   Creates a default crypto service implementation.

   - Parameter secureStorage: Optional secure storage service to use
   - Parameter logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation
   */
  public func createDefault(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()
    let actualSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

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
  public func createDefaultService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()
    let actualSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

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
  public func createLoggingService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()
    let defaultSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

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
  public func createEnhancedLoggingService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    // Use privacy-aware logger for enhanced security
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger(
        environment: .production
      )
    let defaultSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    // TODO: Re-evaluate if EnhancedLoggingCryptoServiceImpl requires PrivacyAwareLoggingProtocol
    //       For now, passing standard logger to satisfy build.
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
  public func createHighSecurityService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    // Use privacy-aware logger with production environment for high security
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createComprehensivePrivacyAwareLogger(
        subsystem: "com.umbra.cryptoservices",
        category: "highsecurity",
        logDirectoryPath: NSTemporaryDirectory(),
        environment: .production
      )
    let defaultSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    // Create a rate limiter with high security configuration
    let rateLimiter=RateLimiterAdapter(
      rateLimiter: TokenBucketRateLimiter(configuration: .highSecurity),
      domain: "crypto"
    )

    return await HighSecurityCryptoServiceImpl(
      secureStorage: defaultSecureStorage,
      rateLimiter: rateLimiter,
      logger: actualLogger
    )
  }

  // MARK: - Provider-Specific Implementations

  /**
   Creates a crypto service with a specific provider type.

   - Parameters:
     - providerType: The type of security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation using the specified provider
   */
  public func createWithProviderType(
    providerType: SecurityProviderType,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()
    let actualSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    // Create the appropriate provider based on type
    let provider: SecurityProviderProtocol=switch providerType {
      case .platform:
        AppleSecurityProvider(logger: actualLogger)
      case .custom:
        RingSecurityProvider(logger: actualLogger)
      case .default:
        DefaultSecurityProvider(logger: actualLogger)
    }

    return await DefaultCryptoServiceWithProviderImpl(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  /**
   Creates a crypto service with an explicit provider.

   - Parameters:
     - provider: The security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation using the specified provider
   */
  public func createWithProvider(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()
    let actualSecureStorage=secureStorage ?? await createLocalSecureStorage(logger: actualLogger)

    return await DefaultCryptoServiceWithProviderImpl(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  // MARK: - Secure Storage Creation

  /**
   Creates a local secure storage implementation.

   - Parameters:
     - provider: Optional security provider to use
     - logger: Logger for operations
   - Returns: A SecureStorageProtocol implementation
   */
  public func createLocalSecureStorage(
    provider: SecurityProviderProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> SecureStorageProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()
    let actualProvider: SecurityProviderProtocol=if let provider {
      provider
    } else {
      // Default to platform provider for secure storage
      AppleSecurityProvider(logger: actualLogger)
    }

    return SecureCryptoStorage(
      provider: actualProvider,
      logger: actualLogger
    )
  }

  /**
   Creates a secure storage implementation with a specific provider type.

   - Parameters:
     - providerType: The type of security provider to use
     - logger: Logger for operations
   - Returns: A SecureStorageProtocol implementation using the specified provider
   */
  public func createSecureStorage(
    providerType: SecurityProviderType = .platform,
    logger: LoggingProtocol?=nil
  ) async -> SecureStorageProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()

    // Create the appropriate provider based on type
    let provider: SecurityProviderProtocol=switch providerType {
      case .platform:
        AppleSecurityProvider(logger: actualLogger)
      case .custom:
        RingSecurityProvider(logger: actualLogger)
      case .default:
        DefaultSecurityProvider(logger: actualLogger)
    }

    return SecureCryptoStorage(
      provider: provider,
      logger: actualLogger
    )
  }

  // MARK: - Testing Implementations

  /**
   Creates a mock crypto service for testing.

   - Parameters:
     - shouldSucceed: Whether operations should succeed
     - logger: Logger for operations
   - Returns: A mock CryptoServiceProtocol implementation
   */
  public func createMock(
    shouldSucceed: Bool=true,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let actualLogger: LoggingProtocol=logger ?? await LoggingServiceFactory
      .createPrivacyAwareLogger()

    return MockCryptoService(
      shouldSucceed: shouldSucceed,
      logger: actualLogger
    )
  }

  /**
   Creates a logging decorator around an existing crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap
     - logger: Logger for operations
     - secureLogger: Optional secure logger for sensitive operations
   - Returns: A CryptoServiceProtocol implementation with logging
   */
  public func createLoggingDecorator(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol,
    secureLogger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    await LoggingCryptoServiceImpl(
      wrapped: wrapped,
      logger: logger,
      secureLogger: secureLogger ?? logger
    )
  }
}
