import CoreSecurityTypes
import Foundation
import KeyManagementActor // Import the actor module directly
import KeyStorage // Import the KeyStorage module with InMemoryKeyStore
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyTypes // Import the module containing KeyStorage protocol
import UmbraErrors

/**
 # KeyManagementFactory

 A factory for creating key management service components that hides implementation details
 and avoids naming conflicts with Swift keywords.

 This factory handles the proper instantiation of all key management services whilst
 providing a clean interface that uses protocol types rather than concrete implementations.

 ## Usage

 ```swift
 // Create a key management service with a custom logger
 let logger = DefaultLogger()
 let keyManager = KeyManagementFactory.createKeyManager(logger: logger)

 // Generate a new key
 let key = try await keyManager.generateKey(ofType: .aes256)
 ```
 */
public enum KeyManagementFactory {
  /**
   Creates a new key management service with the specified logger.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeyManagementProtocol
   */
  public static func createKeyManager(
    logger: LoggingProtocol?=nil
  ) async -> any KeyManagementProtocol {
    // Get a key storage implementation
    let keyStore=createKeyStorage(logger: logger)

    // Use ActorTypes implementation but return as protocol type
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
