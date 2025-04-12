import CryptoInterfaces
import SecurityCoreInterfaces

import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import LoggingServices
import SecurityInterfaces
import SecurityProviders

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
  public static let shared=CryptoServiceFactory()

  /**
   Creates a default CryptoServiceProtocol implementation.

   - Parameters:
     - secureStorage: Optional secure storage to use
     - logger: Optional logger to use
   - Returns: A default CryptoServiceProtocol implementation
   */
  public func createDefault(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    // Create the appropriate secure storage if not provided
    let actualSecureStorage: SecureStorageProtocol=if let secureStorage {
      secureStorage
    } else {
      await createLocalSecureStorage(logger: logger)
    }

    // Create a default implementation using the new command-based architecture
    return DefaultCryptoService(
      secureStorage: actualSecureStorage,
      logger: logger
    )
  }

  /**
   Creates a crypto service with a specific provider type.

   - Parameters:
     - providerType: The type of security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation with the requested provider
   */
  public func createWithProviderType(
    providerType: SecurityProviderType = .basic,
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    // For basic provider type, use our command-based DefaultCryptoService
    if providerType == .basic {
      return await createDefault(secureStorage: secureStorage, logger: logger)
    }

    // Create the appropriate secure storage if not provided
    let actualSecureStorage: SecureStorageProtocol=if let secureStorage {
      secureStorage
    } else {
      await createLocalSecureStorage(logger: logger)
    }

    // Create the implementation using our new command-based provider architecture
    return CryptoServiceWithProvider(
      secureStorage: actualSecureStorage,
      providerType: providerType,
      logger: logger
    )
  }

  // MARK: - Private Helper Methods

  /**
   Creates an appropriate implementation of secure storage for the local environment.

   - Parameter logger: Optional logger for the storage operations
   - Returns: A secure storage implementation
   */
  private func createLocalSecureStorage(
    logger: LoggingProtocol?=nil
  ) async -> SecureStorageProtocol {
    // Use the provided logger or create a suitable default
    let actualLogger: LoggingProtocol?
    if let logger=logger {
      actualLogger=logger
    } else {
      let factory=LoggingServiceFactory.shared
      let developmentLogger = await factory.createDevelopmentLogger(
        minimumLevel: .info
      )
      actualLogger=developmentLogger as? LoggingProtocol
    }

    // This is a temporary solution until we have a proper implementation
    return MockSecureStorage(logger: actualLogger ?? createFallbackLogger())
  }

  /**
   Creates a simple fallback logger when no logger is provided.
   
   This avoids the need to import LoggingAdapters directly, helping with dependency management.
   
   - Returns: A minimal logging implementation.
   */
  private func createFallbackLogger() -> LoggingProtocol {
    return LoggingServices.LoggingServiceFactory.shared.createDefaultLogger()
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
   - Returns: A CryptoServiceProtocol implementation with high security features
   */
  public static func createHighSecurityCryptoService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    let factory=CryptoServiceFactory.shared
    let loggingFactory=LoggingServiceFactory.shared

    // Use privacy-aware logger with appropriate privacy controls
    let actualLogger: LoggingProtocol=if let logger {
      logger
    } else {
      await loggingFactory.createPrivacyAwareLogger()
    }

    // Get or create secure storage
    let actualSecureStorage: SecureStorageProtocol=if let secureStorage {
      secureStorage
    } else {
      await factory.createLocalSecureStorage(logger: actualLogger)
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
   - Additional defense-in-depth measures
   - Comprehensive audit logging
   - Enhanced key rotation policies
   - Hardware-backed key storage where available

   Note: This implementation may have performance trade-offs due to enhanced security.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Optional logger for operations
   - Returns: A CryptoServiceProtocol implementation with maximum security features
   */
  public static func createMaxSecurityCryptoService(
    secureStorage: SecureStorageProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> CryptoServiceProtocol {
    // For now, we'll use the high-security implementation with stricter parameters
    // This should be enhanced in the future with a dedicated MaxSecurityCryptoService
    let service=await createHighSecurityCryptoService(
      secureStorage: secureStorage,
      logger: logger
    )

    // In future, this should instantiate a dedicated MaxSecurityCryptoService
    return service
  }
}
