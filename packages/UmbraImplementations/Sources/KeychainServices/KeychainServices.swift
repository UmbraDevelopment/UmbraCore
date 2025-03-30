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
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import UmbraErrors

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
    logger: LoggingProtocol?=nil
  ) async -> any KeychainServiceProtocol {
    await KeychainServicesFactory.createKeychainService(logger: logger)
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
    keychainService: KeychainServiceProtocol?=nil,
    keyManager: KeyManagementProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) async -> any KeychainSecurityProtocol {
    // Create a fallback key manager if none provided
    let actualKeyManager: KeyManagementProtocol
    if let providedKeyManager = keyManager {
      actualKeyManager = providedKeyManager
    } else {
      do {
        let factory = try KeyManagerAsyncFactory.createInstance()
        if let createdKeyManager = await factory.createKeyManager() {
          actualKeyManager = createdKeyManager
        } else {
          // Fall back to SimpleKeyManager if the factory failed to create a key manager
          actualKeyManager = SimpleKeyManager(logger: logger ?? DefaultLogger())
        }
      } catch {
        // Fall back to SimpleKeyManager if we can't create the proper key manager
        actualKeyManager = SimpleKeyManager(logger: logger ?? DefaultLogger())
      }
    }
    
    return await KeychainServicesFactory.createSecurityService(
      keychainService: keychainService,
      keyManager: actualKeyManager,
      logger: logger
    )
  }
}

/**
 Basic implementation of KeyManagementProtocol for when the real implementation
 cannot be loaded dynamically.

 This implementation simply returns error results for all operations, making it
 safe to use as a fallback but ensuring that users are aware of the limitation.
 */
public struct SimpleKeyManager: KeyManagementProtocol {
  // Logger instance
  private let logger: LoggingProtocol

  // Initialiser with logger
  public init(logger: LoggingProtocol) {
    self.logger = logger
  }

  public func retrieveKey(withIdentifier _: String) async -> Result<SecureBytes, SecurityProtocolError> {
    await logger.warning(
      "Attempted to retrieve key with a simple key manager implementation",
      metadata: nil,
      source: "SimpleKeyManager"
    )
    return .failure(
      .unsupportedOperation(name: "Simple implementation does not support key retrieval")
    )
  }

  public func storeKey(_: SecureBytes, withIdentifier _: String) async -> Result<Void, SecurityProtocolError> {
    await logger.warning(
      "Attempted to store key with a simple key manager implementation",
      metadata: nil,
      source: "SimpleKeyManager"
    )
    return .failure(
      .unsupportedOperation(name: "Simple implementation does not support key storage")
    )
  }

  public func deleteKey(withIdentifier _: String) async -> Result<Void, SecurityProtocolError> {
    await logger.warning(
      "Attempted to delete key with a simple key manager implementation",
      metadata: nil,
      source: "SimpleKeyManager"
    )
    return .failure(
      .unsupportedOperation(name: "Simple implementation does not support key deletion")
    )
  }

  public func rotateKey(
    withIdentifier _: String,
    dataToReencrypt _: SecureBytes?
  ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), SecurityProtocolError> {
    await logger.warning(
      "Attempted to rotate key with a simple key manager implementation",
      metadata: nil,
      source: "SimpleKeyManager"
    )
    return .failure(
      .unsupportedOperation(name: "Simple implementation does not support key rotation")
    )
  }

  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    await logger.warning(
      "Attempted to list keys with a simple key manager implementation",
      metadata: nil,
      source: "SimpleKeyManager"
    )
    return .failure(
      .unsupportedOperation(name: "Simple implementation does not support listing key identifiers")
    )
  }
}
