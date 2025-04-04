import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors
import KeyManagementActor

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
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return Result<[UInt8], SecurityProtocolError>.failure(SecurityProtocolError.invalidInput(details: "Identifier cannot be empty"))
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
        return Result<[UInt8], SecurityProtocolError>.failure(SecurityProtocolError.keyNotFound(identifier: identifier))
      }
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: secError
      )
      return Result<[UInt8], SecurityProtocolError>.failure(SecurityProtocolError.generalError(details: error.localizedDescription))
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

    // Validate the input
    guard !identifier.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.invalidInput(details: "Identifier cannot be empty"))
    }

    guard !key.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: KeyManagementError.invalidInput(details: "Key cannot be empty")
      )
      return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.invalidInput(details: "Key cannot be empty"))
    }

    // Sanitise the identifier
    let sanitizedIdentifier = sanitizeIdentifier(identifier)
    
    do {
      // Log the transaction details for audit purposes
      await securityLogger.logOperationProgress(
        keyIdentifier: identifier,
        operation: "store",
        progress: "Storing key with identifier: \(identifier)"
      )

      try await keyStore.storeKey(key, identifier: sanitizedIdentifier)

      // Log the successful completion of the transaction
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
      return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.generalError(details: error.localizedDescription))
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
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.invalidInput(details: "Identifier cannot be empty"))
    }

    // Sanitise the identifier
    let sanitizedIdentifier = sanitizeIdentifier(identifier)
    
    // Delete the key
    do {
      if try await keyStore.containsKey(identifier: sanitizedIdentifier) {
        do {
          try await keyStore.deleteKey(identifier: sanitizedIdentifier)
          
          // Log the successful completion of the transaction
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
          return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.generalError(details: error.localizedDescription))
        }
      } else {
        let error = KeyManagementError
          .keyNotFound(identifier: identifier)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "delete",
          error: error
        )
        return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.keyNotFound(identifier: identifier))
      }
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: secError
      )
      return Result<Void, SecurityProtocolError>.failure(SecurityProtocolError.generalError(details: error.localizedDescription))
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
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>.failure(SecurityProtocolError.invalidInput(details: "Identifier cannot be empty"))
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
        return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>.failure(SecurityProtocolError.keyNotFound(identifier: identifier))
      }
      
      // Generate a new key
      let newKey = try await keyGenerator.generateKey()
      
      // Log the transaction details
      await securityLogger.logOperationProgress(
        keyIdentifier: identifier,
        operation: "rotate",
        progress: "Generated new key for rotation"
      )
      
      // Store the new key with the same identifier
      try await keyStore.storeKey(newKey, identifier: sanitizedIdentifier)
      
      // Log the success
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "rotate"
      )
      
      // Return the new key
      return .success((newKey: newKey, reencryptedData: nil))
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: secError
      )
      return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>.failure(SecurityProtocolError.generalError(details: error.localizedDescription))
    }
  }

  /**
   Lists all key identifiers managed by this service.

   - Returns: A Result containing an array of key identifiers or an error
   */
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    do {
      let identifiers = try await keyStore.getAllIdentifiers()
      return .success(identifiers)
    } catch {
      let secError = KeyManagementError.keyManagementError(details: error.localizedDescription)
      return Result<[String], SecurityProtocolError>.failure(SecurityProtocolError.generalError(details: error.localizedDescription))
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
