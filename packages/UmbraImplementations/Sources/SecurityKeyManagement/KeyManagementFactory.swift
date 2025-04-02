import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors

/**
 # KeyManagementFactory

 A factory for creating key management service components following the Alpha Dot Five 
 architecture principles with actor-based concurrency.

 This factory handles the proper instantiation of all key management services whilst
 providing a clean interface that uses protocol types rather than concrete implementations.
 All implementations returned by this factory are actor-based to ensure thread safety
 and proper state isolation.

 ## Usage

 ```swift
 // Create a key management service with a custom logger
 let logger = DefaultLogger()
 let keyManager = await KeyManagementFactory.createKeyManager(logger: logger)

 // Generate a new key - note the await keyword for actor method calls
 let key = try await keyManager.generateKey(ofType: .aes256)
 ```
 */
public enum KeyManagementFactory {
  /**
   Creates a new key management service with the specified logger.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new actor-based implementation of KeyManagementProtocol
   */
  public static func createKeyManager(
    logger: LoggingProtocol?=nil
  ) async -> any KeyManagementProtocol {
    // Get a key storage implementation
    let keyStore = createKeyStorage(logger: logger)

    // Create and return the actor implementation
    return await KeyManagementActor(
      keyStore: keyStore,
      logger: logger ?? DefaultLogger()
    )
  }

  /**
   Creates a key storage implementation suitable for the current environment.

   This factory method will select the appropriate storage implementation based on
   the current environment and security requirements.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeyStorage
   */
  public static func createKeyStorage(
    logger _: LoggingProtocol?=nil
  ) -> any KeyStorage {
    // Use in-memory implementation for now, but could be extended to use
    // other storage backends based on environment
    InMemoryKeyStore()
  }
}
