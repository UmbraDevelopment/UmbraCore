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
/// - Implements privacy-aware logging with proper metadata classification
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

import CoreSecurityTypes
import LoggingServices

import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
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
    if let providedKeyManager=keyManager {
      actualKeyManager=providedKeyManager
    } else {
      // Use the shared factory instance with proper async/await handling
      @MainActor
      func getFactory() -> KeyManagerAsyncFactory {
        KeyManagerAsyncFactory.shared
      }

      let factory=await getFactory()
      if await factory.tryInitialize() {
        do {
          let createdKeyManager=try await factory.createKeyManager()
          actualKeyManager=createdKeyManager
        } catch {
          // Fall back to SimpleKeyManager if factory throws an error
          actualKeyManager=SimpleKeyManager(logger: logger ?? DefaultLogger())
        }
      } else {
        // Fall back to SimpleKeyManager if factory initialization fails
        actualKeyManager=SimpleKeyManager(logger: logger ?? DefaultLogger())
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
    self.logger=logger
  }

  // MARK: - Helper Methods

  /**
   Create a metadata collection with privacy controls.
   
   - Parameter dict: Dictionary of string key-value pairs to convert to metadata
   - Returns: A privacy-aware metadata collection
   */
  private func createMetadataCollection(from dict: [String: String]) -> LogMetadataDTOCollection {
    let collection = LogMetadataDTOCollection()
    
    for (key, value) in dict {
      // In KeychainServices, we treat all metadata as private by default
      collection.withPrivate(key: key, value: value)
    }
    
    return collection
  }

  /**
   Convert a dictionary to PrivacyMetadata (deprecated method).
   
   - Parameter dict: Dictionary of string key-value pairs to convert
   - Returns: Legacy privacy metadata object
   */
  @available(*, deprecated, message: "Use createMetadataCollection instead")
  private func createPrivacyMetadata(from dict: [String: String]) -> PrivacyMetadata? {
    guard !dict.isEmpty else {
      return nil
    }

    var result=PrivacyMetadata()
    for (key, value) in dict {
      // In KeychainServices, we treat all metadata as private by default
      result[key]=PrivacyMetadataValue(value: value, privacy: .private)
    }
    return result
  }

  // Implementation of generateKey method from KeyManagementProtocol
  public func generateKey(
    size: Int,
    type: KeyType,
    persistent _: Bool
  ) async throws -> String {
    await logger.warning(
      "Using simple key manager implementation for key generation - this is not secure for production",
      context: KeychainLogContext(
        account: "key_generation",
        operation: "generateKey",
        additionalContext: createMetadataCollection(from: ["keyType": "\(type.rawValue)", "size": "\(size)"])
      )
    )

    // Generate a simple UUID-based key identifier
    let keyIdentifier="generated-key-\(UUID().uuidString)"

    return keyIdentifier
  }

  public func retrieveKey(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityProtocolError> {
    await logger.warning(
      "Attempted to retrieve key with a simple key manager implementation",
      context: KeychainLogContext(
        account: identifier,
        operation: "retrieveKey"
      )
    )
    return .failure(
      .operationFailed(reason: "Simple implementation does not support key retrieval")
    )
  }

  public func storeKey(
    _: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    await logger.warning(
      "Attempted to store key with a simple key manager implementation",
      context: KeychainLogContext(
        account: identifier,
        operation: "storeKey"
      )
    )
    return .failure(
      .operationFailed(reason: "Simple implementation does not support key storage")
    )
  }

  public func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, SecurityProtocolError> {
    await logger.warning(
      "Attempted to delete key with a simple key manager implementation",
      context: KeychainLogContext(
        account: identifier,
        operation: "deleteKey"
      )
    )
    return .failure(
      .operationFailed(reason: "Simple implementation does not support key deletion")
    )
  }

  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt _: [UInt8]?
  ) async -> Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError> {
    await logger.warning(
      "Attempted to rotate key with a simple key manager implementation",
      context: KeychainLogContext(
        account: identifier,
        operation: "rotateKey"
      )
    )
    return .failure(
      .operationFailed(reason: "Simple implementation does not support key rotation")
    )
  }

  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    await logger.warning(
      "Attempted to list keys with a simple key manager implementation",
      context: KeychainLogContext(
        account: "all_keys",
        operation: "listKeyIdentifiers"
      )
    )
    return .failure(
      .operationFailed(reason: "Simple implementation does not support listing keys")
    )
  }
}
