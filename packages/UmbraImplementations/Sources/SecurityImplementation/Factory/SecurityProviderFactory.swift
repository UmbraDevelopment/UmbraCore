import BuildConfig
import CoreSecurityTypes
import CryptoInterfaces
import CryptoServicesCore
import CryptoServicesStandard
import CryptoServicesXfn
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyManagement

/**
 Factory for creating security providers with different security configurations.

 This factory provides convenient methods for creating security providers with
 pre-configured security levels suitable for different use cases, and supports
 the UmbraCore backend strategies:

 - Restic: Default integration with Restic's cryptographic approach
 - RingFFI: Ring cryptography library with Argon2id via FFI
 - AppleCK: Apple CryptoKit for sandboxed environments

 All providers follow the Alpha Dot Five architecture principles and implement
 proper privacy controls for sensitive cryptographic operations.
 */
public struct SecurityProviderFactory {

  /// Shared singleton instance
  public static let shared=SecurityProviderFactory()

  /**
   Creates a security provider of the specified type with appropriate configuration.

   - Parameters:
     - ofType: The type of security provider to create
     - logger: Optional logger for security events
     - backendStrategy: Optional override for the backend strategy
     - environment: Optional override for the environment configuration
   - Returns: A configured SecurityProviderProtocol instance
   */
  public func createProvider(
    ofType providerType: SecurityProviderType,
    logger: LoggingInterfaces.LoggingProtocol?=nil,
    backendStrategy: BackendStrategy?=nil,
    environment: BuildConfig.UmbraEnvironment?=nil
  ) async -> SecurityProviderProtocol {
    // Use the provided values or fallback to BuildConfig defaults
    let effectiveBackend=backendStrategy ?? BuildConfig.activeBackendStrategy
    let effectiveEnvironment=environment ?? BuildConfig.activeEnvironment

    // Determine the effective provider type based on backend strategy
    let effectiveProviderType: SecurityProviderType=switch effectiveBackend {
      case .restic:
        // Restic integration (default)
        providerType
      case .ringFFI:
        // Ring FFI with Argon2id
        .ring
      case .appleCK:
        // Apple CryptoKit for sandboxed environments
        .appleCryptoKit
    }

    // Configure the logger based on environment
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger=logger
    } else {
      // Create environment-appropriate logger with suitable settings
      let factory=LoggingServiceFactory.shared

      switch effectiveEnvironment {
        case .debug, .development:
          // Enhanced logging for development environments
          let developmentLogger=await factory.createDevelopmentLogger(
            minimumLevel: .debug,
            formatter: nil
          )
          actualLogger=await SecurityLoggingUtilities.createLoggingWrapper(
            logger: developmentLogger
          )

        case .alpha, .beta:
          // Balanced logging for testing environments
          let testingLogger=await factory.createSecureLogger(
            minimumLevel: .info,
            subsystem: "com.umbra.security",
            category: "Testing"
          )
          actualLogger=await SecurityLoggingUtilities.createLoggingWrapper(
            logger: testingLogger
          )

        case .production:
          // Production logging with appropriate privacy controls
          let productionLogger=await factory.createSecureLogger(
            minimumLevel: .warning,
            subsystem: "com.umbra.security",
            category: "Production"
          )
          actualLogger=await SecurityLoggingUtilities.createLoggingWrapper(
            logger: productionLogger
          )
      }
    }

    // Create the appropriate crypto service
    let cryptoService: CryptoServiceProtocol

      // Select security level based on environment and backend
      = if effectiveEnvironment == .production || effectiveEnvironment == .beta
    {
      // High security for production and beta environments
      await CryptoServiceRegistry.createService(
        type: .crossPlatform,
        logger: actualLogger
      )
    } else if effectiveBackend == .ringFFI {
      // Maximum security for Ring FFI backend
      await CryptoServiceRegistry.createService(
        type: .crossPlatform,
        logger: actualLogger
      )
    } else {
      // Standard security for development environments
      await CryptoServiceRegistry.createService(
        type: .standard,
        logger: actualLogger
      )
    }

    // Create and return the security provider with appropriate configuration
    return SecurityProviderCore(
      cryptoService: cryptoService,
      logger: actualLogger,
      providerType: effectiveProviderType
    )
  }

  /**
   Creates a security provider with standard security level.

   This provider offers a good balance between security and performance,
   suitable for most common application scenarios. It uses:
   - AES-256 encryption with GCM mode
   - PBKDF2 with 10,000 iterations for key derivation
   - Secure random number generation
   - Privacy-aware logging

   - Parameter logger: Optional logger for security events
   - Returns: A configured SecurityProviderProtocol instance
   */
  public static func createStandardSecurityProvider(
    logger: LoggingInterfaces.LoggingProtocol?=nil
  ) async -> SecurityProviderProtocol {
    await shared.createProvider(
      ofType: .basic,
      logger: logger,
      environment: .development
    )
  }

  /**
   Creates a security provider with high security level.

   This provider offers enhanced security suitable for sensitive applications.
   It uses:
   - AES-256 encryption with GCM mode and additional integrity checks
   - Argon2id for key derivation
   - Hardware-backed secure random generation where available
   - Enhanced security event logging

   - Parameter logger: Optional logger for security events
   - Returns: A configured SecurityProviderProtocol instance
   */
  public static func createHighSecurityProvider(
    logger: LoggingInterfaces.LoggingProtocol?=nil
  ) async -> SecurityProviderProtocol {
    await shared.createProvider(
      ofType: .platform,
      logger: logger,
      environment: .beta
    )
  }

  /**
   Creates a security provider with maximum security level.

   This provider offers the highest level of security for extremely sensitive
   data, with some performance tradeoff. It uses:
   - AES-256 encryption with GCM mode and additional integrity verification
   - Argon2id with high memory and CPU usage for key derivation
   - Hardware-backed secure enclave where available
   - Comprehensive security audit logging
   - Additional defence-in-depth measures

   - Parameter logger: Optional logger for security events
   - Returns: A configured SecurityProviderProtocol instance
   */
  public static func createMaximumSecurityProvider(
    logger: LoggingInterfaces.LoggingProtocol?=nil
  ) async -> SecurityProviderProtocol {
    await shared.createProvider(
      ofType: .custom,
      logger: logger,
      backendStrategy: .ringFFI,
      environment: .production
    )
  }
}
