import CoreSecurityTypes
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
    logger: LoggingInterfaces.LoggingProtocol?=nil
  ) async -> SecurityProviderProtocol {
    // Create standard crypto service
    let _ = await CryptoServiceFactory.shared
      .createDefault(logger: logger)

    // Create the key manager with appropriate logger
    let _ = KeyManagementFactory.createKeyManager(
      logger: logger as? LoggingServiceProtocol
    )

    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger=logger
    } else {
      // Create a development logger with appropriate settings
      let factory=LoggingServiceFactory.shared
      let developmentLogger=await factory.createDevelopmentLogger(
        minimumLevel: .debug,
        formatter: nil
      )
      // Convert the LoggingServiceActor to LoggingProtocol using a wrapper
      actualLogger=await SecurityLoggingUtilities.createLoggingWrapper(logger: developmentLogger)
    }

    // Create secure logger for privacy-aware logging
    let secureLogger=await SecurityLoggingUtilities.createSecureLogger(
      subsystem: "com.umbra.security",
      category: "SecurityService"
    )

    // Create security service with standard configuration
    return await SecurityServiceFactory.createWithLoggers(
      logger: actualLogger,
      secureLogger: secureLogger,
      configuration: CoreSecurityTypes.SecurityConfigDTO(
        encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
        hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha256,
        providerType: CoreSecurityTypes.SecurityProviderType.basic
      )
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
    // Create high-security crypto service
    let _ = await CryptoServiceFactory
      .createHighSecurityCryptoService(
        keySize: 256,
        hashAlgorithm: .sha256,
        saltSize: 16,
        iterations: 100_000
      )
    let _ = KeyManagementFactory.createKeyManager(
      logger: logger as? LoggingServiceProtocol
    )

    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger=logger
    } else {
      // Create a development logger with appropriate settings
      let factory=LoggingServiceFactory.shared
      let developmentLogger=await factory.createDevelopmentLogger(
        minimumLevel: .debug,
        formatter: nil
      )
      // Convert the LoggingServiceActor to LoggingProtocol using a wrapper
      actualLogger=await SecurityLoggingUtilities.createLoggingWrapper(logger: developmentLogger)
    }

    // Create secure logger for privacy-aware logging
    let secureLogger=await SecurityLoggingUtilities.createSecureLogger(
      subsystem: "com.umbra.security",
      category: "SecurityService"
    )

    // Create security service with high security configuration
    return await SecurityServiceFactory.createWithLoggers(
      logger: actualLogger,
      secureLogger: secureLogger,
      configuration: CoreSecurityTypes.SecurityConfigDTO(
        encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.aes256GCM,
        hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha512,
        providerType: CoreSecurityTypes.SecurityProviderType.system
      )
    )
  }

  /**
   Creates a security provider with maximum security level.

   This provider offers the highest level of security for extremely sensitive
   data, with some performance tradeoff. It uses:
   - ChaCha20-Poly1305 for authenticated encryption
   - Argon2id with memory-hard parameters for key derivation
   - Hardware-backed secure random generation
   - Triple key derivation with domain separation
   - Comprehensive security event logging and auditing

   - Parameter logger: Optional logger for security events
   - Returns: A configured SecurityProviderProtocol instance
   */
  public static func createMaximumSecurityProvider(
    logger: LoggingInterfaces.LoggingProtocol?=nil
  ) async -> SecurityProviderProtocol {
    // Create max-security crypto service
    let _ = await CryptoServiceFactory
      .createMaxSecurityCryptoService(
        keySize: 512,
        hashAlgorithm: .sha512,
        saltSize: 32,
        iterations: 200_000,
        memorySize: 1024 * 1024 * 1024,
        parallelism: 4
      )
    let _ = KeyManagementFactory.createKeyManager(
      logger: logger as? LoggingServiceProtocol
    )

    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger {
      actualLogger=logger
    } else {
      // Create a development logger with appropriate settings
      let factory=LoggingServiceFactory.shared
      let developmentLogger=await factory.createDevelopmentLogger(
        minimumLevel: .debug,
        formatter: nil
      )
      // Convert the LoggingServiceActor to LoggingProtocol using a wrapper
      actualLogger=await SecurityLoggingUtilities.createLoggingWrapper(logger: developmentLogger)
    }

    // Create secure logger for privacy-aware logging
    let secureLogger=await SecurityLoggingUtilities.createSecureLogger(
      subsystem: "com.umbra.security",
      category: "SecurityService"
    )

    // Create security service with max security configuration
    return await SecurityServiceFactory.createWithLoggers(
      logger: actualLogger,
      secureLogger: secureLogger,
      configuration: CoreSecurityTypes.SecurityConfigDTO(
        encryptionAlgorithm: CoreSecurityTypes.EncryptionAlgorithm.chacha20Poly1305,
        hashAlgorithm: CoreSecurityTypes.HashAlgorithm.sha512,
        providerType: CoreSecurityTypes.SecurityProviderType.cryptoKit
      )
    )
  }
}

// CoreSecurityError extension has been moved to SecurityProvider+Validation.swift
