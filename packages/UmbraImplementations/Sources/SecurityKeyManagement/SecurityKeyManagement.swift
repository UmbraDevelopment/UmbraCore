import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityKeyTypes // Import SecurityKeyTypes module for KeyStorage protocol

/**
 # SecurityKeyManagement

 Main entry point for key management services in UmbraCore.
 This provides factory methods to access various key management operations
 through a clean interface that avoids implementation details.

 ## Usage

 ```swift
 // Create a key manager with a logger
 let logger = YourLoggerImplementation()
 let keyManager = await SecurityKeyManagement.createKeyManager(
     logger: logger
 )

 // Generate a key
 let key = try await keyManager.generateKey(ofType: .aes256)
 ```
 */
public enum SecurityKeyManagement {
  /**
   Creates a new key management service with the specified logger.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeyManagementProtocol
   */
  public static func createKeyManager(
    logger: LoggingProtocol?=nil
  ) async -> any KeyManagementProtocol {
    await KeyManagementFactory.createKeyManager(logger: logger)
  }

  /**
   Creates a key storage implementation suitable for the current environment.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeyStorage
   */
  public static func createKeyStorage(
    logger: LoggingProtocol?=nil
  ) -> any KeyStorage {
    KeyManagementFactory.createKeyStorage(logger: logger)
  }
}
