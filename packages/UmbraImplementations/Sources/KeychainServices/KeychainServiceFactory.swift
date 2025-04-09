import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # KeychainServiceFactory

 Factory for creating instances of KeychainServiceProtocol implementations.

 This factory follows the Alpha Dot Five architecture pattern, providing
 standardised methods for creating service instances with proper dependencies.

 ## Usage Example

 ```swift
 // Create a keychain service with default settings
 let keychainService = await KeychainServiceFactory.createService()

 // Create a keychain service with a custom service identifier
 let customService = await KeychainServiceFactory.createService(
     serviceIdentifier: "com.example.customService"
 )
 
 // Create a security service that integrates keychain and key management
 let securityService = await KeychainServiceFactory.createSecurityService()
 ```
 */
public enum KeychainServiceFactory {
  /// Default service identifier for keychain entries
  public static let defaultServiceIdentifier = "com.umbra.keychain"

  /**
   Creates a KeychainServiceProtocol implementation with default configuration.

   - Parameters:
      - serviceIdentifier: Custom service identifier, or default if not specified
      - logger: Optional custom logger

   - Returns: A configured KeychainServiceProtocol instance
   */
  public static func createService(
    serviceIdentifier: String = defaultServiceIdentifier,
    logger: LoggingProtocol? = nil
  ) async -> KeychainServiceProtocol {
    // Use provided logger or create a default one with appropriate identifier
    let actualLogger: LoggingProtocol = logger ?? DefaultLogger()
    
    // Create and return the keychain service
    return KeychainServiceImpl(
      serviceIdentifier: serviceIdentifier,
      logger: actualLogger
    )
  }
  
  /**
   Creates a new keychain service with the specified logger.
   This method provides compatibility with the KeychainServicesFactory API.

   - Parameters:
     - serviceIdentifier: An identifier for the keychain service (optional)
     - logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeychainServiceProtocol
   */
  public static func createKeychainService(
    serviceIdentifier: String? = nil,
    logger: LoggingProtocol? = nil
  ) async -> any KeychainServiceProtocol {
    await createService(
      serviceIdentifier: serviceIdentifier ?? defaultServiceIdentifier,
      logger: logger
    )
  }

  /**
   Creates an in-memory KeychainServiceProtocol implementation for testing.

   - Parameters:
      - serviceIdentifier: Custom service identifier, or default if not specified
      - logger: Optional custom logger

   - Returns: A configured in-memory KeychainServiceProtocol instance
   */
  public static func createInMemoryService(
    serviceIdentifier: String = defaultServiceIdentifier,
    logger: LoggingProtocol? = nil
  ) async -> KeychainServiceProtocol {
    // Use provided logger or create a default one with appropriate identifier
    let actualLogger: LoggingProtocol = logger ?? DefaultLogger()
    
    // Create and return the in-memory keychain service
    return InMemoryKeychainServiceImpl(
      serviceIdentifier: serviceIdentifier,
      logger: actualLogger
    )
  }
  
  /**
   Creates a KeychainSecurityActor that integrates keychain and key management services.

   This factory method provides a unified interface for operations that require both
   keychain storage and security key management, such as storing encrypted secrets.

   - Parameters:
      - keychainService: Optional custom keychain service (will create default if nil)
      - keyManager: Optional custom key manager (will load from SecurityKeyManagement if nil)
      - logger: Optional custom logger for operation logging

   - Returns: A configured KeychainSecurityActor
   */
  public static func createSecurityService(
    keychainService: KeychainServiceProtocol? = nil,
    keyManager: KeyManagementProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> any KeychainSecurityProtocol {
    // Determine which keychain service to use
    let actualKeychainService: KeychainServiceProtocol = if let keychainService {
      keychainService
    } else {
      await createService(logger: logger)
    }

    let actualLogger = logger ?? DefaultLogger()

    // For key manager, we need to dynamically load it from SecurityKeyManagement
    let actualKeyManager: (any KeyManagementProtocol)

    if let keyManager {
      actualKeyManager = keyManager
    } else {
      // Use a helper function to handle the async factory properly
      @MainActor
      func createKeyManager() async -> KeyManagementProtocol {
        let factory = KeyManagerAsyncFactory.shared
        if await factory.tryInitialize() {
          do {
            return try await factory.createKeyManager()
          } catch {
            // Fallback to a basic implementation on error
            return SimpleKeyManager(logger: actualLogger)
          }
        } else {
          // Fallback to a basic implementation if initialization fails
          return SimpleKeyManager(logger: actualLogger)
        }
      }
      
      actualKeyManager = await createKeyManager()
    }

    // Create the security actor with the configured dependencies
    return KeychainSecurityActor(
      keychainService: actualKeychainService,
      keyManager: actualKeyManager,
      logger: actualLogger
    )
  }
  
  /**
   Creates a secure keychain service with enhanced security features.
   
   This implementation uses additional security measures such as key rotation
   and secure memory handling for sensitive operations.

   - Parameters:
      - serviceIdentifier: Custom service identifier, or default if not specified
      - logger: Optional custom logger
      - securityLevel: The security level to apply (default: high)

   - Returns: A configured secure KeychainServiceProtocol instance
   */
  public static func createSecureService(
    serviceIdentifier: String = defaultServiceIdentifier,
    logger: LoggingProtocol? = nil,
    securityLevel: SecurityLevel = .high
  ) async -> KeychainServiceProtocol {
    // Use provided logger or create a default one with appropriate identifier
    let actualLogger: LoggingProtocol = logger ?? DefaultLogger()
    
    // Create the base service
    let baseService = KeychainServiceImpl(
      serviceIdentifier: serviceIdentifier,
      logger: actualLogger
    )
    
    // Apply security enhancements based on the requested security level
    switch securityLevel {
      case .standard:
        return baseService
        
      case .high:
        // Wrap with enhanced security features
        return SecureKeychainServiceDecorator(
          wrapping: baseService,
          logger: actualLogger
        )
    }
  }
}

/// Security levels for keychain services
public enum SecurityLevel {
  /// Standard security with basic protection
  case standard
  
  /// High security with additional protection measures
  case high
}
