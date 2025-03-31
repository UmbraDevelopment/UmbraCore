import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import SecurityCoreTypes
import UmbraErrors

/**
 # KeychainSecurityFactory

 Factory for creating instances of KeychainSecurityActor with appropriate dependencies.

 This factory follows the Alpha Dot Five architecture pattern, providing
 standardised methods for creating actors with proper dependency injection.

 ## Usage Example

 ```swift
 // Create a keychain security actor with default settings
 let securityActor = await KeychainSecurityFactory.createActor()

 // Create with custom configurations
 let customActor = await KeychainSecurityFactory.createActor(
     keychainServiceIdentifier: "com.example.customApp"
 )
 ```
 */
public enum KeychainSecurityFactory {
  /// Default service identifier for keychain entries
  public static let defaultServiceIdentifier="com.umbra.keychain"

  /**
   Creates a KeychainSecurityActor with default implementations of all dependencies.

   - Parameters:
      - keychainServiceIdentifier: Optional custom service identifier for the keychain
      - logger: Optional custom logger

   - Returns: A properly configured KeychainSecurityActor
   */
  public static func createActor(
    keychainServiceIdentifier: String=defaultServiceIdentifier,
    logger: LoggingServiceProtocol?=nil
  ) async -> KeychainSecurityActor {
    // Get the default keychain service
    let keychainService=await KeychainServiceFactory.createService(
      serviceIdentifier: keychainServiceIdentifier,
      logger: logger
    )

    // Get the default security provider
    let securityProvider=await SecurityProviderFactory.createSecurityProvider(
      logger: logger
    )

    // Create an adapter for the logger
    let loggerAdapter=logger.map { LoggingAdapter(wrapping: $0) } ?? DefaultLogger()

    // Create and return the actor
    return await KeychainSecurityActor(
      keychainService: keychainService,
      keyManager: securityProvider.keyManager(),
      logger: loggerAdapter
    )
  }

  /**
   Creates a KeychainSecurityActor with custom dependencies.

   - Parameters:
      - keychainService: Custom keychain service
      - securityProvider: Custom security provider
      - logger: Custom logger

   - Returns: A configured KeychainSecurityActor
   */
  public static func createActor(
    keychainService: KeychainServiceProtocol,
    securityProvider: SecurityProviderProtocol,
    logger: LoggingServiceProtocol
  ) -> KeychainSecurityActor {
    // Create an adapter for the logger
    let loggerAdapter=LoggingAdapter(wrapping: logger)

    return await KeychainSecurityActor(
      keychainService: keychainService,
      keyManager: securityProvider.keyManager(),
      logger: loggerAdapter
    )
  }

  /**
   Creates an in-memory keychain security actor for testing.

   - Parameters:
     - serviceIdentifier: Identifier for the keychain service
     - logger: Optional logging service

   - Returns: An initialised KeychainSecurityActor using in-memory storage
   */
  public static func createInMemoryActor(
    serviceIdentifier: String=defaultServiceIdentifier,
    logger: LoggingServiceProtocol?=nil
  ) async -> KeychainSecurityActor {
    // Get an in-memory keychain service
    let keychainService=await KeychainServiceFactory.createInMemoryService(
      serviceIdentifier: serviceIdentifier,
      logger: logger
    )

    // Create a mock security provider
    let securityProvider=await SecurityProviderFactory.createSecurityProvider(
      logger: logger
    )

    // Create an adapter for the logger
    let loggerAdapter: LoggingProtocol=logger
      .map { LoggingAdapter(wrapping: $0) } ?? DefaultLogger()

    // Create and return the actor with the proper initialization parameters
    return KeychainSecurityActor(
      keychainService: keychainService,
      securityProvider: securityProvider,
      logger: loggerAdapter
    )
  }
}
