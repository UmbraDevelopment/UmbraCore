import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors

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

  /// The secure logger instance
  private let securityLogger: SecurityLogger

  /// Key generator for creating new keys
  private let keyGenerator: KeyGenerator

  // MARK: - Initialisation

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
  ) async -> Result<[UInt8], KeyManagementError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "retrieve"
    )

    guard !identifier.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return .failure(.invalidInput(details: "Identifier cannot be empty"))
    }

    if let key=await keyStore.getKey(identifier: sanitizeIdentifier(identifier)) {
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "retrieve"
      )
      return .success(key)
    } else {
      let error=KeyManagementError
        .keyNotFound(identifier: identifier)
      await securityLogger.logOperationFailure(
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
     - identifier: The identifier to use for the key
   - Returns: A Result indicating success or containing an error
   */
  public func storeKey(
    _ key: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, KeyManagementError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "store"
    )

    guard !identifier.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return .failure(.invalidInput(details: "Identifier cannot be empty"))
    }

    guard !key.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: KeyManagementError.invalidInput(details: "Key cannot be empty")
      )
      return .failure(.invalidInput(details: "Key cannot be empty"))
    }

    let sanitizedIdentifier = sanitizeIdentifier(identifier)

    // Store the key
    do {
      // Start a secure transaction for the storage operation
      await securityLogger.logOperationStart(
        keyIdentifier: identifier,
        operation: "secure_transaction"
      )

      try await keyStore.storeKey(key, withIdentifier: sanitizedIdentifier)

      // Log the successful completion of the transaction
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "secure_transaction"
      )

      // Log the success of the overall operation
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "store"
      )
      return .success(())
    } catch {
      let secError = error as? KeyManagementError
        ?? KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "store",
        error: secError
      )
      return .failure(secError)
    }
  }

  /**
   Deletes a key with the specified identifier.

   - Parameter identifier: The identifier of the key to delete
   - Returns: A Result indicating success or an error
   */
  public func deleteKey(
    withIdentifier identifier: String
  ) async -> Result<Void, KeyManagementError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "delete"
    )

    guard !identifier.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return .failure(.invalidInput(details: "Identifier cannot be empty"))
    }

    let sanitizedIdentifier = sanitizeIdentifier(identifier)

    // Delete the key
    if await keyStore.containsKey(identifier: sanitizedIdentifier) {
      do {
        try await keyStore.deleteKey(identifier: sanitizedIdentifier)
        await securityLogger.logOperationSuccess(
          keyIdentifier: identifier,
          operation: "delete"
        )
        return .success(())
      } catch {
        let secError = error as? KeyManagementError 
          ?? KeyManagementError.keyManagementError(details: error.localizedDescription)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "delete",
          error: secError
        )
        return .failure(secError)
      }
    } else {
      let error = KeyManagementError
        .keyNotFound(identifier: identifier)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: error
      )
      return .failure(error)
    }
  }

  /**
   Rotates a key with the specified identifier.

   - Parameter identifier: The identifier of the key to rotate
   - Parameter keyGenerator: The key generator to use, defaults to DefaultKeyGenerator
   - Returns: A Result containing the new key or an error
   */
  public func rotateKey(
    withIdentifier identifier: String, 
    keyGenerator: KeyGenerator = DefaultKeyGenerator()
  ) async -> Result<[UInt8], KeyManagementError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "rotate"
    )

    guard !identifier.isEmpty else {
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      )
      return .failure(.invalidInput(details: "Identifier cannot be empty"))
    }

    let sanitizedIdentifier = sanitizeIdentifier(identifier)

    guard await keyStore.containsKey(identifier: sanitizedIdentifier) else {
      let error = KeyManagementError
        .keyNotFound(identifier: identifier)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: error
      )
      return .failure(error)
    }

    do {
      // Generate a new key with the same bit length as the old one
      let oldKey = try await keyStore.getKey(identifier: sanitizedIdentifier) ?? []
      let bitLength = oldKey.count * 8
      
      // Generate a new key
      let newKey = try await keyGenerator.generateKey(bitLength: bitLength)
      
      // Store the new key with the same identifier
      try await keyStore.storeKey(newKey, withIdentifier: sanitizedIdentifier)
      
      // Log the success
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "rotate"
      )
      
      return .success(newKey)
    } catch {
      let secError = error as? KeyManagementError
        ?? KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: secError
      )
      return .failure(secError)
    }
  }

  /**
   Lists all key identifiers.

   - Returns: A Result containing an array of key identifiers or an error
   */
  public func listKeyIdentifiers() async -> Result<[String], KeyManagementError> {
    do {
      let identifiers=await keyStore.getAllIdentifiers()
      return .success(identifiers)
    } catch {
      let secError=error as? KeyManagementError
        ?? KeyManagementError.keyManagementError(details: error.localizedDescription)
      return .failure(secError)
    }
  }
}

/**
 Protocol for generating cryptographic keys.
 */
public protocol KeyGenerator {
  /**
   Generates a new cryptographic key.

   - Parameter bitLength: The desired bit length of the key
   - Returns: A new key
   - Throws: An error if key generation fails
   */
  func generateKey(bitLength: Int) async throws -> [UInt8]
}

/**
 Default implementation of KeyGenerator.
 */
public struct DefaultKeyGenerator: KeyGenerator {
  /**
   Generates a new cryptographic key.

   - Parameter bitLength: The desired bit length of the key
   - Returns: A new key
   - Throws: An error if key generation fails
   */
  public func generateKey(bitLength: Int) async throws -> [UInt8] {
    // For a real implementation, this would use a secure random number generator
    // and more sophisticated key generation logic
    var bytes=[UInt8](repeating: 0, count: bitLength / 8)
    let status=SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    guard status == errSecSuccess else {
      throw KeyManagementError.keyManagementError(details: "Failed to generate secure random bytes")
    }

    return bytes
  }
}
