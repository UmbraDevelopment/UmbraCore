import CryptoInterfaces
import SecurityCoreInterfaces

import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityInterfaces
import SecurityProviders
import BuildConfig

import UmbraErrors

/**
 # CryptoServiceFactory

 Factory for creating CryptoServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 by implementing an actor-based design for thread safety and
 providing asynchronous factory methods that return actor-based
 implementations.

 ## Environment and Backend Strategy Support
 
 This factory supports different environment configurations:
 - Debug/Development: Enhanced logging with more debugging features
 - Alpha/Beta: Testing environments with balanced logging and performance
 - Production: Optimised performance with appropriate security controls
 
 It also supports different backend strategies:
 - Restic: Default integration with Restic's cryptographic approach
 - RingFFI: Ring cryptography library with Argon2id via FFI
 - AppleCK: Apple CryptoKit for sandboxed environments

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

 ### High-Security Implementation
 ```swift
 // Create a high-security implementation
 let highSecurityService = await CryptoServiceFactory.createHighSecurityCryptoService(
   logger: myLogger
 )
 ```
 */
public actor CryptoServiceFactory {
  // MARK: - Properties

  /// Shared instance for singleton access pattern
  public static let shared = CryptoServiceFactory()

  /**
   Creates a default CryptoServiceProtocol implementation.

   - Parameters:
     - secureStorage: Optional secure storage to use
     - logger: Optional logger to use
     - backendStrategy: Optional override for the backend strategy
     - environment: Optional override for the environment configuration
   - Returns: A default CryptoServiceProtocol implementation
   */
  public func createDefault(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil,
    backendStrategy: BackendStrategy? = nil,
    environment: UmbraEnvironment? = nil
  ) async -> CryptoServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveBackend = backendStrategy ?? BuildConfig.activeBackendStrategy
    let effectiveEnvironment = environment ?? BuildConfig.activeEnvironment
    
    // Create the appropriate secure storage if not provided
    let actualSecureStorage: SecureStorageProtocol = if let secureStorage {
      secureStorage
    } else {
      await createLocalSecureStorage(
        logger: logger,
        environment: effectiveEnvironment
      )
    }
    
    // Determine appropriate provider type based on backend strategy
    let providerType: SecurityProviderType
    
    switch effectiveBackend {
      case .restic:
        providerType = .basic
      case .ringFFI:
        providerType = .ring
      case .appleCK:
        providerType = .appleCryptoKit
    }

    // Create a default implementation using the appropriate provider
    if effectiveEnvironment.isDevelopment {
      // Use the simpler DefaultCryptoService for development environments
      return DefaultCryptoService(
        secureStorage: actualSecureStorage,
        logger: logger
      )
    } else {
      // Use provider-based implementation for testing and production
      return await CryptoServiceWithProvider(
        secureStorage: actualSecureStorage,
        providerType: providerType, 
        logger: logger,
        backendStrategy: effectiveBackend,
        environment: effectiveEnvironment
      )
    }
  }

  /**
   Creates a crypto service with a specific provider type.

   - Parameters:
     - providerType: The type of security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
     - backendStrategy: Optional override for the backend strategy
     - environment: Optional override for the environment configuration
   - Returns: A CryptoServiceProtocol implementation with the requested provider
   */
  public func createWithProviderType(
    providerType: SecurityProviderType = .basic,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil,
    backendStrategy: BackendStrategy? = nil,
    environment: UmbraEnvironment? = nil
  ) async -> CryptoServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveBackend = backendStrategy ?? BuildConfig.activeBackendStrategy
    let effectiveEnvironment = environment ?? BuildConfig.activeEnvironment
    
    // For basic provider type in development, use our command-based DefaultCryptoService
    if providerType == .basic && effectiveEnvironment.isDevelopment {
      return await createDefault(
        secureStorage: secureStorage, 
        logger: logger,
        backendStrategy: effectiveBackend,
        environment: effectiveEnvironment
      )
    }

    // Create the appropriate secure storage if not provided
    let actualSecureStorage: SecureStorageProtocol = if let secureStorage {
      secureStorage
    } else {
      await createLocalSecureStorage(
        logger: logger,
        environment: effectiveEnvironment
      )
    }

    // Create the implementation using our provider-based architecture
    return await CryptoServiceWithProvider(
      secureStorage: actualSecureStorage,
      providerType: providerType,
      logger: logger,
      backendStrategy: effectiveBackend,
      environment: effectiveEnvironment
    )
  }

  // MARK: - Private Helper Methods

  /**
   Creates an appropriate implementation of secure storage for the environment.

   - Parameters:
     - logger: Optional logger for the storage operations
     - environment: The environment to configure storage for
   - Returns: A secure storage implementation
   */
  private func createLocalSecureStorage(
    logger: LoggingProtocol? = nil,
    environment: UmbraEnvironment = BuildConfig.activeEnvironment
  ) async -> SecureStorageProtocol {
    // Use the provided logger or create a suitable default
    let actualLogger: LoggingProtocol?
    if let logger = logger {
      actualLogger = logger
    } else {
      // Create a domain-specific logger for crypto operations with appropriate privacy settings
      actualLogger = await createCryptoLogger(environment: environment)
    }
    
    // Create a secure storage implementation appropriate for the environment
    return await createSecureStorage(logger: actualLogger, environment: environment)
  }
  
  /**
   Creates a privacy-aware logger specifically configured for cryptographic operations.
   
   This method creates a logger with appropriate privacy settings for cryptographic
   operations based on the environment. It ensures sensitive cryptographic data
   is properly protected in logs.
   
   - Parameters:
     - environment: The environment to configure logging for
   - Returns: A configured logger with appropriate privacy settings
   */
  private func createCryptoLogger(
    environment: UmbraEnvironment = BuildConfig.activeEnvironment
  ) async -> LoggingProtocol {
    // Create a privacy-aware logging configuration based on the environment
    let loggingConfig = createLoggingConfig(for: environment)
    
    // TODO: Future implementation will use the proper domain-specific logger factory
    return PrivacyAwareLogger(
      subsystem: "com.umbra.cryptoservices",
      category: "CryptoOperations",
      defaultPrivacyLevel: loggingConfig.defaultPrivacyLevel
    )
  }
  
  /**
   Creates a privacy-aware logging configuration specifically for cryptographic operations.
   
   Cryptographic operations require special handling of sensitive data. This method
   creates a logging configuration that ensures proper redaction of sensitive material
   based on the environment.
   
   - Parameters:
     - environment: The environment to configure logging for
   - Returns: A privacy-aware logging configuration appropriate for cryptographic operations
   */
  private func createLoggingConfig(
    for environment: UmbraEnvironment
  ) -> PrivacyAwareLoggingConfig {
    switch environment {
      case .debug:
        // Debug builds provide developer-friendly logging with minimal redaction
        return PrivacyAwareLoggingConfig(
          isEnabled: true,
          defaultPrivacyLevel: .private,
          redactionBehavior: .redactInReleaseOnly,
          includeSourceLocation: true,
          maxMetadataEntries: LoggingConstants.maxMetadataEntries * 2
        )
        
      case .development:
        // Development builds have more comprehensive logging
        return PrivacyAwareLoggingConfig(
          isEnabled: true,
          defaultPrivacyLevel: .private,
          redactionBehavior: .redactInReleaseOnly,
          includeSourceLocation: true,
          maxMetadataEntries: LoggingConstants.maxMetadataEntries
        )
        
      case .alpha:
        // Alpha builds balance developer needs with privacy
        return PrivacyAwareLoggingConfig(
          isEnabled: true,
          defaultPrivacyLevel: .private,
          redactionBehavior: .alwaysRedact,
          includeSourceLocation: true,
          maxMetadataEntries: LoggingConstants.maxMetadataEntries
        )
        
      case .beta, .production:
        // Beta and production builds have strict privacy controls
        return PrivacyAwareLoggingConfig(
          isEnabled: true,
          defaultPrivacyLevel: .sensitive,
          redactionBehavior: .alwaysRedact,
          includeSourceLocation: false,
          maxMetadataEntries: LoggingConstants.maxMetadataEntries / 2
        )
    }
  }

  /**
   Creates a secure storage implementation appropriate for the environment.
   
   This method creates a secure storage implementation that adapts to the 
   specific requirements of different environments:
   - Debug/Development: Uses enhanced logging with less strict security
   - Alpha/Beta: Balances security with debugging capabilities
   - Production: Uses maximum security with minimal logging
   
   - Parameters:
     - logger: Optional logger for storage operations
     - environment: The environment to configure storage for
   - Returns: A secure storage implementation appropriate for the environment
   */
  private func createSecureStorage(
    logger: (any LoggingProtocol)? = nil,
    environment: UmbraEnvironment? = nil
  ) async -> SecureStorageProtocol {
    // Determine provider type based on environment
    let providerType: SecurityProviderType
    
    switch environment ?? BuildConfig.activeEnvironment {
      case .development, .debug:
        // Development environments use Apple CryptoKit for ease of debugging
        providerType = .appleCryptoKit
      case .alpha, .beta:
        // Testing environments use the platform-appropriate provider
        providerType = .platform
      case .production:
        // Production uses the most secure option (Ring FFI if available)
        
        // Check backend strategy to determine the most appropriate provider
        switch BuildConfig.activeBackendStrategy {
          case .restic:
            providerType = .basic
          case .ringFFI:
            providerType = .ring
          case .appleCK:
            providerType = .appleCryptoKit
        }
    }
    
    // Use platform-specific secure storage when available
    #if canImport(Security)
    return await createKeychainStorage(
      serviceName: "com.umbra.cryptoservices",
      logger: logger
    )
    #else
    // Fallback for platforms without Keychain
    return InMemorySecureStorage(
      baseURL: URL(string: "memory://umbra.cryptoservices")!,
      logger: logger
    )
    #endif
  }

  /**
   Creates a keychain-based secure storage implementation.
   
   - Parameters:
     - serviceName: The service name for keychain items
     - logger: Optional logger for operations
   - Returns: A SecureStorageProtocol implementation using the keychain
   */
  private func createKeychainStorage(
    serviceName: String,
    logger: (any LoggingProtocol)?
  ) async -> SecureStorageProtocol {
    // Use SimpleSecureStorage which wraps platform keychain access
    return SimpleSecureStorage(
      serviceName: serviceName,
      logger: logger
    )
  }

  /**
   Creates a simple fallback logger when no logger is provided.
   
   This avoids the need to import LoggingAdapters directly, helping with dependency management.
   
   - Returns: A minimal logging implementation.
   */
  private func createFallbackLogger() -> LoggingProtocol {
    // Create a simple console logger as fallback
    return ConsoleLogger()
  }

  // MARK: - Security-Level Specific Implementations

  /**
   Creates a high-security crypto service implementation with enhanced protection.

   This implementation adds additional security features like:
   - Stronger encryption algorithms with authenticated modes (AES-GCM)
   - Enhanced key management with secure generation and storage
   - Additional validation checks and integrity verification
   - Comprehensive logging with privacy controls
   - Command-based architecture for better separation of concerns

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
     - backendStrategy: Optional override for the backend strategy
     - environment: Optional override for the environment configuration
   - Returns: A CryptoServiceProtocol implementation with high security features
   */
  public static func createHighSecurityCryptoService(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil,
    backendStrategy: BackendStrategy? = nil,
    environment: UmbraEnvironment? = nil
  ) async -> CryptoServiceProtocol {
    let factory = CryptoServiceFactory.shared

    // Use the provided values or fallback to BuildConfig defaults
    let effectiveBackend = backendStrategy ?? BuildConfig.activeBackendStrategy
    let effectiveEnvironment = environment ?? BuildConfig.activeEnvironment
    
    // Use privacy-aware logger with appropriate privacy controls
    let actualLogger: LoggingProtocol = if let logger {
      logger
    } else {
      await LoggingServiceFactory.shared.createPrivacyAwareLogger()
    }

    // Get or create secure storage
    let actualSecureStorage: SecureStorageProtocol = if let secureStorage {
      secureStorage
    } else {
      await factory.createLocalSecureStorage(
        logger: actualLogger,
        environment: effectiveEnvironment
      )
    }

    // For Ring FFI backend, use the provider-based implementation
    if effectiveBackend == .ringFFI {
      return await CryptoServiceWithProvider(
        secureStorage: actualSecureStorage,
        providerType: .ring,
        logger: actualLogger,
        backendStrategy: effectiveBackend,
        environment: effectiveEnvironment
      )
    }
    
    // Create the high security service using our command-based implementation
    return HighSecurityCryptoService(
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }

  /**
   Creates a maximum-security crypto service implementation for the highest level of protection.

   This implementation includes all security features of the high-security implementation plus:
   - Most secure encryption algorithms available (ChaCha20-Poly1305)
   - Memory-hard key derivation functions
   - Additional defence-in-depth measures
   - Comprehensive audit logging
   - Enhanced key rotation policies
   - Hardware-backed key storage where available

   Note: This implementation may have performance trade-offs due to enhanced security.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
     - backendStrategy: Optional override for the backend strategy to use
     - environment: Optional override for the environment configuration
   - Returns: A CryptoServiceProtocol implementation with maximum security features
   */
  public static func createMaximumSecurityCryptoService(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil,
    backendStrategy: BackendStrategy? = nil,
    environment: UmbraEnvironment? = nil
  ) async -> CryptoServiceProtocol {
    // Use the provided values or fallback to BuildConfig defaults with a preference for Ring FFI
    let effectiveBackend = backendStrategy ?? .ringFFI  // Default to Ring FFI for max security
    let effectiveEnvironment = environment ?? .production  // Default to production settings
    
    // Always use Ring FFI for maximum security if available
    return await CryptoServiceWithProvider(
      secureStorage: secureStorage,
      providerType: .ring,
      logger: logger,
      backendStrategy: effectiveBackend,
      environment: effectiveEnvironment
    )
  }
}
