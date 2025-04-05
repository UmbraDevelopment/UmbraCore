import Foundation
import LoggingServices

import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # KeychainServicesFactory

 A factory for creating keychain service components that hides implementation details
 and avoids naming conflicts with Swift keywords.

 This factory handles the proper instantiation of all keychain services whilst
 providing a clean interface that uses protocol types rather than concrete implementations.

 ## Usage

 ```swift
 // Create a keychain service with a custom logger
 let logger = YourLoggerImplementation()
 let keychainService = await KeychainServicesFactory.createKeychainService(logger: logger)

 // Store a value in the keychain
 try await keychainService.storeValue("MyPassword", forKey: "MyApp.password")
 ```
 */
public enum KeychainServicesFactory {
  // Default service identifier for the keychain
  private static let defaultServiceIdentifier="com.umbra.keychainservice"

  /**
   Creates a new keychain service with the specified logger.

   - Parameters:
     - serviceIdentifier: An identifier for the keychain service (optional)
     - logger: Logger for recording operations (optional)
   - Returns: A new implementation of KeychainServiceProtocol
   */
  public static func createKeychainService(
    serviceIdentifier: String?=nil,
    logger: LoggingProtocol?=nil
  ) async -> any KeychainServiceProtocol {
    // Use the standard implementation but return as protocol type
    let actualLogger=logger ?? DefaultLogger()

    return KeychainServiceImpl(
      serviceIdentifier: serviceIdentifier ?? defaultServiceIdentifier,
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
    keychainService: KeychainServiceProtocol?=nil,
    keyManager _: KeyManagementProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> any KeychainSecurityProtocol {
    // Determine which keychain service to use
    let actualKeychainService: KeychainServiceProtocol=if let keychainService {
      keychainService
    } else {
      await createKeychainService(logger: logger)
    }

    let actualLogger=logger ?? DefaultLogger()

    // For key manager, we need to dynamically load it from SecurityKeyManagement
    let actualKeyManager: (any KeyManagementProtocol)

    // Use a helper function to handle the async factory properly
    @MainActor
    func createKeyManager() async -> KeyManagementProtocol {
      let factory=KeyManagerAsyncFactory.shared
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

    // Await the key manager creation
    actualKeyManager=await createKeyManager()

    // Create and return the security implementation
    return KeychainSecurityImpl(
      keychainService: actualKeychainService,
      keyManager: actualKeyManager,
      logger: actualLogger
    )
  }
}
