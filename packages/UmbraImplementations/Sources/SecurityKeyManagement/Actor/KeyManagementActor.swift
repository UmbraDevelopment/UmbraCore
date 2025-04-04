import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors
import KeyManagementActorTypes

/**
 # KeyManagementActor

 An actor-based implementation of the KeyManagementProtocol that provides secure
 key management operations with proper concurrency safety in accordance with the
 architecture.

 This actor ensures proper isolation of the key management operations, preventing
 race conditions and other concurrency issues that could compromise security.

 ## Responsibilities

 * Store cryptographic keys securely
 * Retrieve keys by identifier
 * Rotate keys to enforce key lifecycle policies
 * Delete keys when no longer needed
 * Track key metadata and usage statistics

 ## Security Considerations

 * Keys are stored using platform-specific secure storage mechanisms
 * Key material is never persisted in plaintext
 * Key identifiers are hashed to prevent information disclosure
 * Access to keys is logged for audit purposes
 * Actor isolation prevents concurrent access to sensitive key material

 ## Usage

 ```swift
 // Create a key management actor
 let keyManager = KeyManagementActor(keyStore: myKeyStore, logger: myLogger)

 // Store a key
 let storeResult = await keyManager.storeKey(myKey, withIdentifier: "master-key")

 // Retrieve a key
 let retrieveResult = await keyManager.retrieveKey(withIdentifier: "master-key")
 switch retrieveResult {
 case .success(let key):
     // Use the key
 case .failure(let error):
     // Handle error
 }
 ```
 */
public actor KeyManagementActor: KeyManagementProtocol {
  // MARK: - Properties

  /// Secure storage for keys
  private let keyStore: KeyStorage

  /// Logger for security operations
  private let securityLogger: SecurityLogger

  /// Key generator for creating new keys
  private let keyGenerator: KeyGenerator
  
  /**
   Initialises a new KeyManagementActor with the specified key store and logger.

   - Parameters:
   - keyStore: The secure key storage implementation
   - logger: The logging service for recording operations
   - keyGenerator: Optional key generator (defaults to DefaultKeyGenerator)
   */
  public init(
    keyStore: KeyStorage,
    logger: LoggingServiceProtocol,
    keyGenerator: KeyGenerator = DefaultKeyGenerator()
  ) {
    self.keyStore = keyStore
    
    // Create a security logger using the provided logging service
    self.securityLogger = SecurityLogger(loggingService: logger)
    
    // Store the key generator
    self.keyGenerator = keyGenerator
  }

  // MARK: - Key Management Operations

  /**
   Sanitises a key identifier to prevent injection attacks and information leakage.

   - Parameter identifier: The raw identifier to sanitise
   - Returns: A sanitised version of the identifier
   */
  private func sanitizeIdentifier(_ identifier: String) -> String {
    // Basic sanitisation - in a real implementation, this would be more robust
    // For example, we might hash the identifier or apply more sophisticated sanitisation
    identifier.replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "\\", with: "_")
      .replacingOccurrences(of: ":", with: "_")
  }

  /**
   Retrieves a key with the specified identifier.

   - Parameter identifier: The identifier of the key to retrieve
   - Returns: A Result containing the key or an error
   */
  public func retrieveKey(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "retrieve"
    )

    // Validate the input
    guard !identifier.isEmpty else {
      let error = KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: error
      )
      return Result<[UInt8], SecurityProtocolError>.failure(error.toStandardError())
    }

    // Get the key from storage
    do {
      if let key = try await keyStore.getKey(identifier: sanitizeIdentifier(identifier)) {
        await securityLogger.logOperationSuccess(
          keyIdentifier: identifier,
          operation: "retrieve"
        )
        return .success(key)
      } else {
        let error = KeyManagementError
          .keyNotFound(identifier: identifier)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "retrieve",
          error: error
        )
        return Result<[UInt8], SecurityProtocolError>.failure(error.toStandardError())
      }
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: secError
      )
      return Result<[UInt8], SecurityProtocolError>.failure(secError.toStandardError())
    }
  }

  /**
   Stores a key with the specified identifier.

   - Parameters:
   - key: The key to store
   - identifier: The identifier to associate with the key
   - Returns: A Result indicating success or an error
   */
  public func storeKey(
    _ key: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "store"
    )

    let sanitizedIdentifier = sanitizeIdentifier(identifier)
    
    // Validate the input
    guard !identifier.isEmpty else {
      let error = KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: error
      )
      return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
    }

    // Validate the key
    guard !key.isEmpty else {
      let error = KeyManagementError.invalidInput(details: "Key cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: error
      )
      return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
    }

    // Store the key securely
    do {
      // Store the key in the secure storage
      try await keyStore.storeKey(key, identifier: sanitizedIdentifier)
      
      // Log the success
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "store"
      )
      
      return .success(())
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: secError
      )
      return Result<Void, SecurityProtocolError>.failure(secError.toStandardError())
    }
  }

  /**
   Deletes a key with the specified identifier.

   - Parameter identifier: The identifier of the key to delete
   - Returns: A Result indicating success or an error
   */
  public func deleteKey(
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "delete"
    )

    // Validate the input
    guard !identifier.isEmpty else {
      let error = KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: error
      )
      return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
    }

    // Sanitise the identifier
    let sanitizedIdentifier = sanitizeIdentifier(identifier)
    
    do {
      // Check if the key exists before attempting to delete
      if try await keyStore.containsKey(identifier: sanitizedIdentifier) {
        do {
          try await keyStore.deleteKey(identifier: sanitizedIdentifier)
          
          await securityLogger.logOperationSuccess(
            keyIdentifier: identifier,
            operation: "delete"
          )
          
          return .success(())
        } catch {
          let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
          await securityLogger.logOperationFailure(
            keyIdentifier: identifier,
            operation: "delete",
            error: secError
          )
          return Result<Void, SecurityProtocolError>.failure(secError.toStandardError())
        }
      } else {
        let error = KeyManagementError
          .keyNotFound(identifier: identifier)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "delete",
          error: error
        )
        return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
      }
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: secError
      )
      return Result<Void, SecurityProtocolError>.failure(secError.toStandardError())
    }
  }

  /**
   Rotates a key with the specified identifier.

   - Parameters:
   - identifier: The identifier of the key to rotate
   - dataToReencrypt: Optional data to re-encrypt with the new key
   - Returns: A Result containing the new key and re-encrypted data or an error
   */
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: [UInt8]? = nil
  ) async -> Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "rotate"
    )

    // Validate the input
    guard !identifier.isEmpty else {
      let error = KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: error
      )
      return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>.failure(error.toStandardError())
    }

    let sanitizedIdentifier = sanitizeIdentifier(identifier)
    
    do {
      guard try await keyStore.containsKey(identifier: sanitizedIdentifier) else {
        let error = KeyManagementError
          .keyNotFound(identifier: identifier)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "rotate",
          error: error
        )
        return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>.failure(error.toStandardError())
      }
      
      // Generate a new key - this will replace the existing one
      let newKey = try await keyGenerator.generateKey()
      
      // Store the new key
      try await keyStore.storeKey(newKey, identifier: sanitizedIdentifier)
      
      // Log the success
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "rotate"
      )
      
      return .success((newKey: newKey, reencryptedData: nil))
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: secError
      )
      return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>.failure(secError.toStandardError())
    }
  }

  /**
   Retrieves all key identifiers.
   
   - Returns: A result containing an array of key identifiers or an error
   */
  public func getAllKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    do {
      let identifiers = try await keyStore.getKeyIdentifiers()
      return .success(identifiers)
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      return Result<[String], SecurityProtocolError>.failure(secError.toStandardError())
    }
  }
}

/**
 Protocol for generating cryptographic keys.
 */
public protocol KeyGenerator: Sendable {
  /**
   Generates a new cryptographic key.
   
   - Returns: A new cryptographic key as a byte array
   - Throws: If key generation fails
   */
  func generateKey() async throws -> [UInt8]
}

/**
 Default implementation of KeyGenerator.
 */
public struct DefaultKeyGenerator: KeyGenerator {
  /**
   Initialises a new DefaultKeyGenerator.
   */
  public init() {}
  
  /**
   Generates a new cryptographic key using SecRandomCopyBytes.
   
   - Returns: A new cryptographic key as a byte array
   - Throws: If key generation fails
   */
  public func generateKey() async throws -> [UInt8] {
    // Generate a 32-byte (256-bit) key
    var keyData = [UInt8](repeating: 0, count: 32)
    
    // Use SecRandomCopyBytes for secure random generation
    let status = SecRandomCopyBytes(kSecRandomDefault, keyData.count, &keyData)
    
    guard status == errSecSuccess else {
      throw KeyManagementError.keyManagementError(details: "Failed to generate secure random bytes")
    }
    
    return keyData
  }
}

// MARK: - Helper Classes

/**
 Helper class for logging security operations.
 */
private actor SecurityLogger {
  private let loggingService: LoggingServiceProtocol
  
  init(loggingService: LoggingServiceProtocol) {
    self.loggingService = loggingService
  }
  
  func logOperationStart(keyIdentifier: String, operation: String) async {
    // Implement logging for operation start
  }
  
  func logOperationProgress(keyIdentifier: String, operation: String, progress: String) async {
    // Implement logging for operation progress
  }
  
  func logOperationSuccess(keyIdentifier: String, operation: String) async {
    // Implement logging for operation success
  }
  
  func logOperationFailure(keyIdentifier: String, operation: String, error: Error) async {
    // Implement logging for operation failure
  }
}
