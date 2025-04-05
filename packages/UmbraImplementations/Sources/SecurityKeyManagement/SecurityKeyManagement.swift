import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityKeyTypes

/**
 # SecurityKeyManagement

 Main entry point for key management services in UmbraCore following the
 Alpha Dot Five architecture principles with actor-based concurrency.

 This provides factory methods to access various key management operations
 through a clean interface that avoids implementation details.

 ## Usage

 ```swift
 // Create a key manager with a logger
 let logger = YourLoggerImplementation()
 let keyManager = SecurityKeyManagement.createKeyManager(
     logger: logger
 )

 // Generate a key - note the await keyword for actor method calls
 let key = try await keyManager.generateKey(ofType: .aes128)
 ```
 */
public enum SecurityKeyManagement {
  /**
   Creates a new key management service with the specified logger.
   The implementation follows the actor-based concurrency model of the
   Alpha Dot Five architecture.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new actor-based implementation of KeyManagementProtocol
   */
  public static func createKeyManager(
    logger: LoggingServiceProtocol?=nil
  ) -> any KeyManagementProtocol {
    KeyManagementFactory.createKeyManager(logger: logger)
  }

  /**
   Creates a key storage implementation suitable for the current environment.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeyStorage
   */
  public static func createKeyStorage(
    logger: LoggingServiceProtocol?=nil
  ) -> any KeyStorage {
    KeyManagementFactory.createKeyStorage(logger: logger)
  }
}
