import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingServices

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
 ```
 */
public enum KeychainServiceFactory {
  /// Default service identifier for keychain entries
  public static let defaultServiceIdentifier="com.umbra.keychain"

  /**
   Creates a KeychainServiceProtocol implementation with default configuration.

   - Parameters:
      - serviceIdentifier: Custom service identifier, or default if not specified
      - logger: Optional custom logger

   - Returns: A configured KeychainServiceProtocol instance
   */
  public static func createService(
    serviceIdentifier: String=defaultServiceIdentifier,
    logger: LoggingServiceProtocol?=nil
  ) async -> KeychainServiceProtocol {
    // Use provided logger or create a default one with appropriate identifier
    let actualLogger: LoggingServiceProtocol = logger ?? DefaultLogger()
    // TODO: Configure minimum level if needed via DefaultLogger setup or alternative
    // For now, DefaultLogger likely has its own default level. Explicit setting here removed.
    // Create a LoggingProtocol adapter for the service
    let serviceLogger=LoggingAdapter(wrapping: actualLogger)

    // Create and return the keychain service
    return KeychainServiceImpl(
      serviceIdentifier: serviceIdentifier,
      logger: serviceLogger
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
    serviceIdentifier: String=defaultServiceIdentifier,
    logger: LoggingServiceProtocol?=nil
  ) async -> KeychainServiceProtocol {
    // Use provided logger or create a default one with appropriate identifier
    let actualLogger: LoggingServiceProtocol = logger ?? DefaultLogger()
    // TODO: Configure minimum level if needed via DefaultLogger setup or alternative
    // For now, DefaultLogger likely has its own default level. Explicit setting here removed.
    // Create a LoggingProtocol adapter for the service
    let serviceLogger=LoggingAdapter(wrapping: actualLogger)

    // Create and return the in-memory keychain service
    return InMemoryKeychainServiceImpl(
      serviceIdentifier: serviceIdentifier,
      logger: serviceLogger
    )
  }
}
