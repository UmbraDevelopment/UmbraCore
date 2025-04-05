import CoreSecurityTypes
import LoggingServices

import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors
import LoggingAdapters // For SecurityLogger
import DomainSecurityTypes

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
 let key = try await keyManager.generateKey(ofType: .aes128)
 ```
 */
public enum KeyManagementFactory {
  /**
   Creates a new key management service with the specified logger.

   - Parameter logger: Logger for recording operations (optional)
   - Returns: A new actor-based implementation of KeyManagementProtocol
   */
  public static func createKeyManager(
    logger: LoggingServiceProtocol?=nil
  ) -> any KeyManagementProtocol {
    // Get a key storage implementation
    let keyStore = createKeyStorage(logger: logger)
    
    // Use default logging service if none provided
    let loggingService = logger ?? createDefaultLoggingService()

    // Create and return our actor implementation
    return SimpleKeyManagementActor(
      keyStore: keyStore,
      logger: loggingService
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
    logger _: LoggingServiceProtocol?=nil
  ) -> any KeyStorage {
    // Use in-memory implementation for now, but could be extended to use
    // other storage backends based on environment
    return SimpleInMemoryKeyStore()
  }
  
  /**
   Creates a default logging service when none is provided.
   
   - Returns: A basic implementation of LoggingServiceProtocol
   */
  private static func createDefaultLoggingService() -> LoggingServiceProtocol {
    return DefaultLoggingService()
  }
}

/**
 Default implementation of logging service for use when none is provided.
 */
private struct DefaultLoggingService: LoggingServiceProtocol {
  func verbose(_ message: String, metadata: LogMetadata?, source: String?) async {}
  func debug(_ message: String, metadata: LogMetadata?, source: String?) async {}
  func info(_ message: String, metadata: LogMetadata?, source: String?) async {}
  func warning(_ message: String, metadata: LogMetadata?, source: String?) async {}
  func error(_ message: String, metadata: LogMetadata?, source: String?) async {}
  func critical(_ message: String, metadata: LogMetadata?, source: String?) async {}
  
  // Implementation of required LoggingServiceProtocol methods
  func addDestination(_ destination: any LoggingTypes.LogDestination) async throws {}
  func removeDestination(withIdentifier identifier: String) async -> Bool { return false }
  func setMinimumLogLevel(_ level: LoggingTypes.UmbraLogLevel) async {}
  func getMinimumLogLevel() async -> LoggingTypes.UmbraLogLevel { return .info }
  func flushAllDestinations() async throws {}
}

/**
 Simple implementation of KeyStorage that stores keys in memory.
 This is mainly for testing and should not be used in production.
 */
public final class SimpleInMemoryKeyStore: KeyStorage {
  // Thread-safe storage for keys
  private let storage = StorageActor()
  
  // Actor to provide thread-safe access to the keys
  private actor StorageActor {
    // Dictionary to store keys by their identifier
    var keys: [String: [UInt8]] = [:]
    
    func storeKey(_ key: [UInt8], identifier: String) {
      keys[identifier] = key
    }
    
    func getKey(identifier: String) -> [UInt8]? {
      return keys[identifier]
    }
    
    func deleteKey(identifier: String) {
      keys.removeValue(forKey: identifier)
    }
    
    func containsKey(identifier: String) -> Bool {
      return keys.keys.contains(identifier)
    }
    
    func getAllKeys() -> [String] {
      return Array(keys.keys)
    }
  }
  
  public init() {}
  
  public func storeKey(_ key: [UInt8], identifier: String) async throws {
    await storage.storeKey(key, identifier: identifier)
  }
  
  public func getKey(identifier: String) async throws -> [UInt8]? {
    return await storage.getKey(identifier: identifier)
  }
  
  public func containsKey(identifier: String) async throws -> Bool {
    return await storage.containsKey(identifier: identifier)
  }
  
  public func deleteKey(identifier: String) async throws {
    await storage.deleteKey(identifier: identifier)
  }
  
  public func listKeyIdentifiers() async throws -> [String] {
    return await storage.getAllKeys()
  }
}

/**
 A simple actor-based implementation of KeyManagementProtocol.
 */
public actor SimpleKeyManagementActor: KeyManagementProtocol {
  // MARK: - Properties
  
  /// Secure storage for keys
  private let keyStore: KeyStorage
  
  /// Security logger
  private let securityLogger: SecurityLogger
  
  // MARK: - Initialisation
  
  public init(keyStore: KeyStorage, logger: LoggingServiceProtocol) {
    self.keyStore = keyStore
    self.securityLogger = SecurityLogger(loggingService: logger)
  }
  
  // MARK: - Key Management Methods
  
  public func retrieveKey(withIdentifier identifier: String) async
    -> Result<[UInt8], SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "retrieve"
    )
    
    guard !identifier.isEmpty else {
      let error = SecurityProtocolError.inputError("Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: error
      )
      return .failure(error)
    }
    
    do {
      if let key = try await keyStore.getKey(identifier: sanitizeIdentifier(identifier)) {
        await securityLogger.logOperationSuccess(
          keyIdentifier: identifier,
          operation: "retrieve"
        )
        return .success(key)
      } else {
        let error = SecurityProtocolError.operationFailed("Key not found: \(identifier)")
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "retrieve",
          error: error
        )
        return .failure(error)
      }
    } catch {
      let secError = SecurityProtocolError.operationFailed(reason: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: secError
      )
      return .failure(secError)
    }
  }
  
  public func storeKey(_ key: [UInt8], withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "store"
    )
    
    guard !identifier.isEmpty else {
      let error = SecurityProtocolError.inputError("Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: error
      )
      return .failure(error)
    }
    
    guard !key.isEmpty else {
      let error = SecurityProtocolError.inputError("Key cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: error
      )
      return .failure(error)
    }
    
    do {
      try await keyStore.storeKey(key, identifier: sanitizeIdentifier(identifier))
      
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "store"
      )
      return .success(())
    } catch {
      let secError = SecurityProtocolError.operationFailed(reason: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: secError
      )
      return .failure(secError)
    }
  }
  
  public func deleteKey(withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "delete"
    )
    
    guard !identifier.isEmpty else {
      let error = SecurityProtocolError.inputError("Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: error
      )
      return .failure(error)
    }
    
    let sanitizedIdentifier = sanitizeIdentifier(identifier)
    
    do {
      if try await keyStore.containsKey(identifier: sanitizedIdentifier) {
        try await keyStore.deleteKey(identifier: sanitizedIdentifier)
        await securityLogger.logOperationSuccess(
          keyIdentifier: identifier,
          operation: "delete"
        )
        return .success(())
      } else {
        let error = SecurityProtocolError.operationFailed("Key not found: \(identifier)")
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "delete",
          error: error
        )
        return .failure(error)
      }
    } catch {
      let secError = SecurityProtocolError.operationFailed(reason: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: secError
      )
      return .failure(secError)
    }
  }
  
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: [UInt8]?
  ) async -> Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "rotate"
    )
    
    guard !identifier.isEmpty else {
      let error = SecurityProtocolError.inputError("Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: error
      )
      return .failure(error)
    }
    
    // Simple implementation - generate new random key
    // In a real implementation, this would use proper key derivation
    let newKey = generateRandomKey(length: 32) // 256 bits
    
    do {
      // Store the new key
      try await keyStore.storeKey(newKey, identifier: sanitizeIdentifier(identifier))
      
      // Re-encrypt data if provided
      var reencryptedData: [UInt8]? = nil
      if let dataToReencrypt = dataToReencrypt {
        // Simple implementation - in a real system, this would use proper encryption
        // with the new key
        reencryptedData = dataToReencrypt
      }
      
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "rotate"
      )
      
      return .success((newKey: newKey, reencryptedData: reencryptedData))
    } catch {
      let secError = SecurityProtocolError.operationFailed(reason: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: secError
      )
      return .failure(secError)
    }
  }
  
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    do {
      let identifiers = try await keyStore.listKeyIdentifiers()
      return .success(identifiers)
    } catch {
      let secError = SecurityProtocolError.operationFailed(reason: error.localizedDescription)
      return .failure(secError)
    }
  }
  
  // MARK: - Helper Methods
  
  private func sanitizeIdentifier(_ identifier: String) -> String {
    // Basic sanitisation - in a real implementation, this would be more robust
    return identifier.replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "\\", with: "_")
      .replacingOccurrences(of: ":", with: "_")
  }
  
  private func generateRandomKey(length: Int) -> [UInt8] {
    var randomBytes = [UInt8](repeating: 0, count: length)
    // In a real implementation, this would use a secure random number generator
    for i in 0..<length {
      randomBytes[i] = UInt8.random(in: 0...255)
    }
    return randomBytes
  }
}
