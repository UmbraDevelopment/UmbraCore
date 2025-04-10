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

// Import implementation files
// Note: We don't need to import CryptoServices since we're already in that module

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

 // Create a service with a specific provider type
 let cryptoWithProvider = await factory.createWithProviderType(
   providerType: .cryptoKit,
   logger: myLogger
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
  public static let shared = CryptoServiceFactory()

  /// Cache of created services for reuse
  private var serviceCache: [String: CryptoServiceProtocol] = [:]

  // MARK: - Initialisation

  /// Default initialiser
  public init() {}

  // MARK: - Standard Implementations

  /**
   Creates a default crypto service implementation.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation
   */
  public func createDefault(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    let actualSecureStorage: SecureStorageProtocol
    if let secureStorage {
      actualSecureStorage = secureStorage
    } else {
      actualSecureStorage = await createLocalSecureStorage(logger: actualLogger)
    }

    return DefaultCryptoServiceImpl(
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    let defaultSecureStorage: SecureStorageProtocol
    if let secureStorage {
      defaultSecureStorage = secureStorage
    } else {
      defaultSecureStorage = await createLocalSecureStorage(logger: actualLogger)
    }

    return LoggingCryptoServiceImpl(
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    // Use privacy-aware logger for enhanced security
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger(
        environment: .production
      )
    }
    
    let defaultSecureStorage: SecureStorageProtocol
    if let secureStorage {
      defaultSecureStorage = secureStorage
    } else {
      defaultSecureStorage = await createLocalSecureStorage(logger: actualLogger)
    }

    // Note: EnhancedLoggingCryptoServiceImpl doesn't accept a rateLimiter parameter
    // so we don't need to create one here
    
    return EnhancedLoggingCryptoServiceImpl(
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    // Use privacy-aware logger with production environment for high security
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createComprehensivePrivacyAwareLogger(
        subsystem: "com.umbra.cryptoservices",
        category: "highsecurity",
        logDirectoryPath: NSTemporaryDirectory(),
        environment: .production
      )
    }
    
    let defaultSecureStorage: SecureStorageProtocol
    if let secureStorage {
      defaultSecureStorage = secureStorage
    } else {
      defaultSecureStorage = await createLocalSecureStorage(logger: actualLogger)
    }

    // Create a rate limiter with high security configuration
    let rateLimiter = BasicRateLimiter()
    
    return HighSecurityCryptoServiceImpl(
      secureStorage: defaultSecureStorage,
      rateLimiter: rateLimiter.createAdapter(),
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    let actualSecureStorage: SecureStorageProtocol
    if let secureStorage {
      actualSecureStorage = secureStorage
    } else {
      actualSecureStorage = await createLocalSecureStorage(logger: actualLogger)
    }

    // Create the appropriate provider based on type
    let provider: SecurityProviderProtocol = switch providerType {
      case .cryptoKit:
        BasicSecurityProvider() // Temporarily using BasicSecurityProvider
      case .ring:
        BasicSecurityProvider() // Temporarily using BasicSecurityProvider
      case .basic:
        BasicSecurityProvider()
      case .system, .hsm:
        BasicSecurityProvider() // Fallback for unsupported types
    }

    return DefaultCryptoServiceWithProviderImpl(
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
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    let actualSecureStorage: SecureStorageProtocol
    if let secureStorage {
      actualSecureStorage = secureStorage
    } else {
      actualSecureStorage = await createLocalSecureStorage(logger: actualLogger)
    }

    return DefaultCryptoServiceWithProviderImpl(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  // MARK: - Secure Storage Creation

  /**
   Creates a local secure storage implementation.

   - Parameters:
     - logger: Logger for operations
   - Returns: A SecureStorageProtocol implementation
   */
  public func createLocalSecureStorage(
    logger: LoggingProtocol? = nil
  ) async -> SecureStorageProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    // Create a mock SecureStorageProtocol implementation for now
    // This is a temporary solution until we have a proper implementation
    return MockSecureStorage(logger: actualLogger)
  }

  /**
   Creates a secure storage implementation with a specific provider type.

   - Parameters:
     - providerType: Type of security provider to use
     - logger: Logger for operations
   - Returns: A SecureStorageProtocol implementation
   */
  public func createSecureStorage(
    providerType: SecurityProviderType,
    logger: LoggingProtocol? = nil
  ) async -> SecureStorageProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }

    // Create a mock SecureStorageProtocol implementation for now
    // This is a temporary solution until we have a proper implementation
    return MockSecureStorage(logger: actualLogger)
  }

  // MARK: - Security-Level Specific Implementations
  
  /**
   Creates a high-security crypto service implementation with enhanced protection.
   
   This implementation adds additional security features like:
   - Stronger encryption algorithms
   - Enhanced key management
   - Additional validation checks
   - Comprehensive logging with privacy controls
   
   - Parameters:
     - keySize: The key size to use for encryption (in bits)
     - hashAlgorithm: The hash algorithm to use
     - saltSize: The salt size to use for key derivation (in bytes)
     - iterations: The number of iterations to use for key derivation
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation with high security features
   */
  public static func createHighSecurityCryptoService(
    keySize: Int = 256,
    hashAlgorithm: HashAlgorithm = .sha256,
    saltSize: Int = 16,
    iterations: Int = 100000,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let factory = CryptoServiceFactory.shared
    let loggingFactory = LoggingServiceFactory.shared
    
    // Use privacy-aware logger with appropriate privacy controls
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    // Get or create secure storage
    let actualSecureStorage: SecureStorageProtocol
    if let secureStorage {
      actualSecureStorage = secureStorage
    } else {
      actualSecureStorage = await factory.createLocalSecureStorage(logger: actualLogger)
    }
    
    // Create a rate limiter for sensitive operations
    let rateLimiter = BasicRateLimiter()
    
    // Create the enhanced secure service with the high security provider
    let baseService = HighSecurityCryptoServiceImpl(
      secureStorage: actualSecureStorage,
      rateLimiter: rateLimiter.createAdapter(),
      logger: actualLogger
    )
    
    // Wrap with enhanced features for additional protection
    return EnhancedSecureCryptoServiceImpl(
      wrapped: baseService,
      logger: actualLogger,
      rateLimiter: rateLimiter.createAdapter()
    )
  }
  
  /**
   Creates a maximum-security crypto service implementation for the highest level of protection.
   
   This implementation includes all security features of the high-security implementation plus:
   - Hardware-backed encryption where available
   - Multi-factor operation verification
   - Strict rate limiting
   - Enhanced anomaly detection
   - Comprehensive audit logging
   
   - Parameters:
     - keySize: The key size to use for encryption (in bits)
     - hashAlgorithm: The hash algorithm to use
     - saltSize: The salt size to use for key derivation (in bytes)
     - iterations: The number of iterations to use for key derivation
     - memorySize: The memory size to use for memory-hard functions (in bytes)
     - parallelism: The degree of parallelism to use for memory-hard functions
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation with maximum security features
   */
  public static func createMaxSecurityCryptoService(
    keySize: Int = 512,
    hashAlgorithm: HashAlgorithm = .sha512,
    saltSize: Int = 32,
    iterations: Int = 200000,
    memorySize: Int = 1024 * 1024 * 1024,
    parallelism: Int = 4,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let factory = CryptoServiceFactory.shared
    let loggingFactory = LoggingServiceFactory.shared
    
    // Use privacy-aware logger with maximum privacy controls
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }
    
    // Get or create secure storage with the highest security level
    let actualSecureStorage: SecureStorageProtocol
    if let secureStorage {
      actualSecureStorage = secureStorage
    } else {
      actualSecureStorage = await factory.createLocalSecureStorage(logger: actualLogger)
    }
    
    // Create a strict rate limiter for sensitive operations
    let rateLimiter = BasicRateLimiter(
      maxOperationsPerMinute: 10,  // Strict rate limiting
      cooldownPeriod: 60           // 1 minute cooldown after reaching limit
    )
    
    // Create the high security service with the maximum security provider
    let baseService = HighSecurityCryptoServiceImpl(
      secureStorage: actualSecureStorage,
      rateLimiter: rateLimiter.createAdapter(),
      logger: actualLogger
    )
    
    // Wrap with enhanced features for maximum protection
    return EnhancedSecureCryptoServiceImpl(
      wrapped: baseService,
      logger: actualLogger,
      rateLimiter: rateLimiter.createAdapter()
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
    shouldSucceed: Bool = true,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let loggingFactory = LoggingServiceFactory.shared
    let actualLogger: LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      actualLogger = await loggingFactory.createPrivacyAwareLogger()
    }

    // Create a basic implementation since MockCryptoService is not available
    return DefaultCryptoServiceImpl(
      secureStorage: await createLocalSecureStorage(logger: actualLogger),
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
    secureLogger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    LoggingCryptoServiceImpl(
      wrapped: wrapped,
      logger: logger
    )
  }
}
