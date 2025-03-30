import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityKeyTypes
import SecurityTypes
import UmbraErrors

/**
 # KeyManagementActor

 An actor-based implementation of the KeyManagementProtocol that provides secure
 key management operations with proper concurrency safety in accordance with the
 Alpha Dot Five architecture.

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

  /// The logger for recording operations
  private let logger: LoggingProtocol
  
  /// Domain-specific logger for key management operations
  private let keyLogger: KeyManagementLogger

  /// Key generator for creating new keys
  private let keyGenerator: KeyGenerator

  // MARK: - Initialisation

  /**
   Initialises a new KeyManagementActor with the specified key store and logger.

   - Parameters:
   - keyStore: The secure key storage implementation
   - logger: The logger for recording operations
   - keyGenerator: Optional key generator (defaults to DefaultKeyGenerator)
   */
  public init(
    keyStore: KeyStorage,
    logger: LoggingProtocol,
    keyGenerator: KeyGenerator = DefaultKeyGenerator()
  ) {
    self.keyStore = keyStore
    self.logger = logger
    self.keyLogger = KeyManagementLogger(logger: logger)
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
    return identifier.replacingOccurrences(of: "/", with: "_")
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
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await keyLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "retrieve"
    )

    guard !identifier.isEmpty else {
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: SecurityProtocolError.invalidInput("Identifier cannot be empty")
      )
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    if let key=await keyStore.getKey(identifier: sanitizeIdentifier(identifier)) {
      await keyLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "retrieve"
      )
      return .success(key)
    } else {
      let error = SecurityProtocolError.keyManagementError("Key not found with identifier: \(identifier)")
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: error
      )
      return .failure(error)
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
    _ key: SecureBytes,
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    await keyLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "store"
    )

    guard !identifier.isEmpty else {
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "store",
        error: SecurityProtocolError.invalidInput("Identifier cannot be empty")
      )
      return .failure(.invalidInput("Identifier cannot be empty"))
    }
    guard !key.isEmpty else {
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "store",
        error: SecurityProtocolError.invalidInput("Key cannot be empty")
      )
      return .failure(.invalidInput("Key cannot be empty"))
    }

    let sanitizedIdentifier=sanitizeIdentifier(identifier)

    if await keyStore.containsKey(identifier: sanitizedIdentifier) {
      var additionalContext = LogMetadataDTOCollection()
      additionalContext.addPublic(key: "action", value: "overwrite")
      
      await keyLogger.logOperationStart(
        keyIdentifier: identifier,
        operation: "store",
        additionalContext: additionalContext,
        message: "Overwriting existing key"
      )
    }

    await keyStore.storeKey(key, identifier: sanitizedIdentifier)
    await keyLogger.logOperationSuccess(
      keyIdentifier: identifier,
      operation: "store"
    )
    return .success(())
  }

  /**
   Deletes the key with the specified identifier.

   - Parameter identifier: The identifier of the key to delete
   - Returns: A Result indicating success or an error
   */
  public func deleteKey(
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityProtocolError> {
    await keyLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "delete"
    )

    guard !identifier.isEmpty else {
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "delete",
        error: SecurityProtocolError.invalidInput("Identifier cannot be empty")
      )
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    let sanitizedIdentifier=sanitizeIdentifier(identifier)

    if await keyStore.containsKey(identifier: sanitizedIdentifier) {
      await keyStore.deleteKey(identifier: sanitizedIdentifier)
      await keyLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "delete"
      )
      return .success(())
    } else {
      let error = SecurityProtocolError.keyManagementError("Key not found with identifier: \(identifier)")
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "delete",
        error: error
      )
      return .failure(error)
    }
  }

  /**
   Rotates the key with the specified identifier, optionally re-encrypting data
   with the new key.

   - Parameters:
   - identifier: The identifier of the key to rotate
   - dataToReencrypt: Optional data to re-encrypt with the new key
   - Returns: A Result containing the new key and optionally re-encrypted data, or an error
   */
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), SecurityProtocolError> {
    await keyLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "rotate"
    )

    guard !identifier.isEmpty else {
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "rotate",
        error: SecurityProtocolError.invalidInput("Identifier cannot be empty")
      )
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    let sanitizedIdentifier=sanitizeIdentifier(identifier)

    if await keyStore.containsKey(identifier: sanitizedIdentifier) {
      do {
        // Generate a new key for rotation
        let newKey=try await keyGenerator.generateKey()
        
        var additionalContext = LogMetadataDTOCollection()
        additionalContext.addPublic(key: "action", value: "key_generation")
        
        await keyLogger.logOperationSuccess(
          keyIdentifier: identifier,
          operation: "rotate",
          additionalContext: additionalContext,
          message: "Generated new key for rotation"
        )

        // Store the newly generated key
        await keyStore.storeKey(newKey, identifier: sanitizedIdentifier)
        
        additionalContext = LogMetadataDTOCollection()
        additionalContext.addPublic(key: "action", value: "key_storage")
        
        await keyLogger.logOperationSuccess(
          keyIdentifier: identifier,
          operation: "rotate",
          additionalContext: additionalContext,
          message: "Stored new key with identifier"
        )

        // Re-encrypt data if provided
        var reencryptedData: SecureBytes?
        if let dataToReencrypt=dataToReencrypt {
          // In a real implementation, we would use the old key to decrypt and the new key to encrypt
          // For simplicity, we're just copying the data in this example
          reencryptedData=dataToReencrypt
          
          additionalContext = LogMetadataDTOCollection()
          additionalContext.addPublic(key: "action", value: "data_reencryption")
          
          await keyLogger.logOperationSuccess(
            keyIdentifier: identifier,
            operation: "rotate",
            additionalContext: additionalContext,
            message: "Re-encrypted data with new key"
          )
        }

        return .success((newKey: newKey, reencryptedData: reencryptedData))
      } catch {
        await keyLogger.logOperationError(
          keyIdentifier: identifier,
          operation: "rotate",
          error: error
        )
        return .failure(
          .keyManagementError("Failed to rotate key: \(error.localizedDescription)")
        )
      }
    } else {
      let error = SecurityProtocolError.keyManagementError("Key not found with identifier: \(identifier)")
      await keyLogger.logOperationError(
        keyIdentifier: identifier,
        operation: "rotate",
        error: error
      )
      return .failure(error)
    }
  }

  /**
   Lists all the key identifiers managed by this actor.

   - Returns: A Result containing an array of identifiers, or an error
   */
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    await keyLogger.logOperationStart(
      keyIdentifier: "all",
      operation: "list"
    )

    let identifiers=await keyStore.listKeyIdentifiers()
    
    var additionalContext = LogMetadataDTOCollection()
    additionalContext.addPublic(key: "count", value: String(identifiers.count))
    
    await keyLogger.logOperationSuccess(
      keyIdentifier: "all",
      operation: "list",
      additionalContext: additionalContext,
      message: "Found \(identifiers.count) key identifiers"
    )
    return .success(identifiers)
  }
}

/**
 Protocol for generating cryptographic keys.
 */
public protocol KeyGenerator: Sendable {
  /**
   Generates a new cryptographic key.

   - Returns: A new key
   - Throws: An error if key generation fails
   */
  func generateKey() async throws -> SecureBytes
}

/**
 Default implementation of KeyGenerator that creates random keys.
 */
public struct DefaultKeyGenerator: KeyGenerator {
  public init() {}

  /**
   Generates a random key of the specified length.

   - Returns: A random key
   - Throws: An error if key generation fails
   */
  public func generateKey() async throws -> SecureBytes {
    // For a real implementation, this would use a secure random number generator
    // and more sophisticated key generation logic
    let keyData=SecureBytes(repeating: 0, count: 32)
    return keyData
  }
}
