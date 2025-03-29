/// # KeychainServices Module
///
/// Provides concrete implementations of the keychain system, following the Alpha Dot Five
/// architecture principle of separation between types, interfaces, and implementations.
///
/// This module contains:
/// - Default keychain service implementation
/// - In-memory implementation for testing
/// - Factory for service creation
/// - KeychainSecurityActor for integrated keychain and key management
///
/// Following Alpha Dot Five principles, this module:
/// - Contains only implementation code
/// - Implements interfaces defined in KeychainInterfaces
/// - Uses types defined in KeychainTypes
/// - Uses actor-based concurrency for thread safety
/// - Follows the Swift Concurrency model
///
/// ## Main Components
///
/// ```swift
/// KeychainServiceImpl
/// InMemoryKeychainServiceImpl
/// KeychainServiceFactory
/// KeychainSecurityActor
/// ```
///
/// ## Factory Usage
///
/// ```swift
/// // Create with default settings
/// let keychainService = await KeychainServices.createService()
///
/// // Create with custom logger
/// let customService = await KeychainServices.createService(logger: CustomLogger())
///
/// // Create integrated security actor
/// let securityActor = await KeychainServices.createSecurityService()
/// ```
///
/// ## Thread Safety
///
/// All implementations use Swift actors to ensure thread safety and proper
/// isolation of state.

import Foundation
import KeychainInterfaces
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors
import LoggingTypes
import SecurityCoreTypes

/// Convenience access to KeychainServiceFactory
public enum KeychainServices {
  /**
   Creates a default keychain service with optional custom logger.
   
   This method provides a standard implementation of the KeychainServiceProtocol
   that works with the system keychain.
   
   - Parameter logger: Optional custom logger for operation logging
   - Returns: A configured keychain service
   */
  public static func createService(
    logger: LoggingProtocol? = nil
  ) async -> any KeychainServiceProtocol {
    return await KeychainServicesFactory.createKeychainService(logger: logger)
  }
  
  /**
   Creates a KeychainSecurityActor that integrates keychain and key management services.
   
   This service provides a unified interface for operations that require both 
   keychain storage and security key management, such as storing encrypted secrets.
   
   - Parameters:
      - keychainService: Optional custom keychain service (will create default if nil)
      - keyManager: Optional custom key manager (will load from SecurityKeyManagement if nil)
      - logger: Optional custom logger for operation logging
   
   - Returns: A configured security service implementation
   */
  public static func createSecurityService(
    keychainService: KeychainServiceProtocol? = nil,
    keyManager: KeyManagementProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> any KeychainSecurityProtocol {
    return await KeychainServicesFactory.createSecurityService(
      keychainService: keychainService,
      keyManager: keyManager,
      logger: logger
    )
  }
}

// Helper class for dynamic loading of KeyManagementProtocol
private final class KeyManagerAsyncFactory: NSObject {
  typealias AsyncKeyManagerFactory = @Sendable () async -> KeyManagementProtocol
  
  private var asyncFactory: AsyncKeyManagerFactory?
  
  // Static factory method to create an instance if possible
  static func createInstance() -> KeyManagerAsyncFactory? {
    let instance = KeyManagerAsyncFactory()
    
    // Try to dynamically load the module and set up the async factory
    if
      let securityKeyManagementClass = NSClassFromString("SecurityKeyManagement.SecurityKeyManagement"),
      securityKeyManagementClass.responds(to: NSSelectorFromString("createKeyManager"))
    {
      // This is a simplified approach - in a real implementation,
      // we would need more complex bridging to properly handle Swift async methods
      instance.asyncFactory = {
        // Return a basic implementation for now - the actual implementation
        // would need to properly bridge to Swift's concurrency
        return SimpleKeyManager(logger: DefaultLogger())
      }
      return instance
    } else {
      return nil
    }
  }
  
  func createKeyManager() async -> KeyManagementProtocol {
    if let factory = asyncFactory {
      return await factory()
    }
    return SimpleKeyManager(logger: DefaultLogger())
  }
}

/**
 Basic implementation of KeyManagementProtocol for when the real implementation
 cannot be loaded dynamically.
 
 This implementation simply returns error results for all operations, making it
 safe to use as a fallback but ensuring that users are aware of the limitation.
 */
private struct SimpleKeyManager: KeyManagementProtocol {
  // Logger instance
  private let logger: LoggingProtocol
  
  // Initialiser with logger
  init(logger: LoggingProtocol) {
    self.logger = logger
  }
  
  func retrieveKey(withIdentifier identifier: String) async -> Result<SecureBytes, SecurityProtocolError> {
    await logger.warning("Attempted to retrieve key with a simple key manager implementation", metadata: nil)
    return .failure(.unsupportedOperation(name: "Simple implementation does not support key retrieval"))
  }
  
  func storeKey(_ key: SecureBytes, withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
    await logger.warning("Attempted to store key with a simple key manager implementation", metadata: nil)
    return .failure(.unsupportedOperation(name: "Simple implementation does not support key storage"))
  }
  
  func deleteKey(withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
    await logger.warning("Attempted to delete key with a simple key manager implementation", metadata: nil)
    return .failure(.unsupportedOperation(name: "Simple implementation does not support key deletion"))
  }
  
  func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), SecurityProtocolError> {
    await logger.warning("Attempted to rotate key with a simple key manager implementation", metadata: nil)
    return .failure(.unsupportedOperation(name: "Simple implementation does not support key rotation"))
  }
  
  func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    await logger.warning("Attempted to list keys with a simple key manager implementation", metadata: nil)
    return .failure(.unsupportedOperation(name: "Simple implementation does not support listing key identifiers"))
  }
}
