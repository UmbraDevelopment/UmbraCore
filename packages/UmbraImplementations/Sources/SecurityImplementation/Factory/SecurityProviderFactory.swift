import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import CoreSecurityTypes
import CryptoServices
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
    let cryptoService: any CryptoServiceProtocol = await CryptoServiceFactory.createStandardCryptoService()
    let keyManager = await KeyManagementFactory.createKeyManager(logger: logger)
    
    // Use the provided logger or create a default one
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger = logger {
      actualLogger = logger
    } else {
      let developmentLogger = LoggingServiceFactory.createDevelopmentLogger(
        minimumLevel: .info,
        formatter: nil
      )
      actualLogger = developmentLogger
    }
    
    // Create the security service actor
    let securityService = SecurityServiceActor(
      cryptoService: cryptoService,
      logger: actualLogger
    )
    
    // Initialize the service
    try? await securityService.initialize()
    
    return securityService
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
    let cryptoService: any CryptoServiceProtocol = await CryptoServiceFactory.createHighSecurityCryptoService()
    let keyManager = await KeyManagementFactory.createKeyManager(logger: logger)
    
    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger = logger {
      actualLogger = logger
    } else {
      let developmentLogger = LoggingServiceFactory.createDevelopmentLogger(
        minimumLevel: .debug,
        formatter: nil
      )
      actualLogger = developmentLogger
    }
    
    // Create the security service actor
    let securityService = SecurityServiceActor(
      cryptoService: cryptoService,
      logger: actualLogger
    )
    
    // Initialize the service
    try? await securityService.initialize()
    
    return securityService
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
    logger: LoggingInterfaces.LoggingProtocol? = nil
  ) async -> SecurityProviderProtocol {
    // Create max-security crypto service
    let cryptoService: any CryptoServiceProtocol = await CryptoServiceFactory.createMaxSecurityCryptoService()
    let keyManager = await KeyManagementFactory.createKeyManager(logger: logger)
    
    // Use the provided logger or create a default one with debug level logging
    let actualLogger: LoggingInterfaces.LoggingProtocol
    if let logger = logger {
      actualLogger = logger
    } else {
      let developmentLogger = LoggingServiceFactory.createDevelopmentLogger(
        minimumLevel: .debug,
        formatter: nil
      )
      actualLogger = developmentLogger
    }
    
    // Create the security service actor
    let securityService = SecurityServiceActor(
      cryptoService: cryptoService,
      logger: actualLogger
    )
    
    // Initialize the service
    try? await securityService.initialize()
    
    return securityService
  }
}
