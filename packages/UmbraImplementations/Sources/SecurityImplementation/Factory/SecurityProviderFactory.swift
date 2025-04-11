import CoreSecurityTypes
import CryptoInterfaces
import CryptoServices
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import SecurityKeyManagement

/**
 Factory for creating security providers with different security configurations.

 This factory provides convenient methods for creating security providers with
 pre-configured security levels suitable for different use cases:

 - Standard: Suitable for most applications with good security/performance balance
 - High: Stronger security for sensitive applications, with some performance tradeoff
 - Maximum: Highest security level, suitable for extremely sensitive data

 All providers follow the Alpha Dot Five architecture principles.
 */
public enum SecurityProviderFactory {

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
    logger: LoggingInterfaces.LoggingProtocol? = nil
  ) async -> SecurityProviderProtocol {
    // Create standard crypto service
    let cryptoService = await CryptoServiceFactory.shared
      .createDefault(logger: logger)

    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      // Create a development logger with appropriate settings
      let factory = LoggingServiceFactory.shared
      let developmentLogger = await factory.createDevelopmentLogger(
        minimumLevel: .debug,
        formatter: nil
      )
      // Convert the LoggingServiceActor to LoggingProtocol using a wrapper
      actualLogger = await SecurityLoggingUtilities.createLoggingWrapper(logger: developmentLogger)
    }

    // Create security provider with standard configuration
    return SecurityProviderCore(
      cryptoService: cryptoService,
      logger: actualLogger,
      providerType: .basic
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
    logger: LoggingInterfaces.LoggingProtocol? = nil
  ) async -> SecurityProviderProtocol {
    // Create high-security crypto service
    let cryptoService = await CryptoServiceFactory.shared
      .createHighSecurityCryptoService(logger: logger)

    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      // Create an advanced logger with appropriate settings
      let factory = LoggingServiceFactory.shared
      let securityLogger = await factory.createSecureLogger(
        minimumLevel: .info,
        subsystem: "com.umbra.security",
        category: "HighSecurity"
      )
      actualLogger = await SecurityLoggingUtilities.createLoggingWrapper(logger: securityLogger)
    }

    // Create security provider with high security configuration
    return SecurityProviderCore(
      cryptoService: cryptoService,
      logger: actualLogger,
      providerType: .platform
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
   - Additional defense-in-depth measures

   - Parameter logger: Optional logger for security events
   - Returns: A configured SecurityProviderProtocol instance
   */
  public static func createMaximumSecurityProvider(
    logger: LoggingInterfaces.LoggingProtocol? = nil
  ) async -> SecurityProviderProtocol {
    // Create maximum-security crypto service
    let cryptoService = await CryptoServiceFactory.shared
      .createMaximumSecurityCryptoService(logger: logger)

    // Use the provided logger or create a default one with comprehensive logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger = logger
    } else {
      // Create a comprehensive logger with appropriate settings
      let factory = LoggingServiceFactory.shared
      let maxSecurityLogger = await factory.createSecureLogger(
        minimumLevel: .debug,
        subsystem: "com.umbra.security",
        category: "MaxSecurity"
      )
      actualLogger = await SecurityLoggingUtilities.createLoggingWrapper(logger: maxSecurityLogger)
    }

    // Create security provider with maximum security configuration
    return SecurityProviderCore(
      cryptoService: cryptoService,
      logger: actualLogger,
      providerType: .custom
    )
  }
}
