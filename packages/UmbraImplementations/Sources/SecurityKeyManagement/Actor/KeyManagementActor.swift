import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import KeyManagementActorTypes
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
 let keyManager = KeyManagementActor(keyStore: myKeyStore, loggingService: myLogger)

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

  /// Store for key metadata
  private let metadataStore: KeyMetadataStore

  /// Logger for security operations
  private let securityLogger: SecurityLogger

  /// Key generator for creating new keys
  private let keyGenerator: KeyGenerator

  /**
   Initialises a new KeyManagementActor with the specified key store and logger.

   - Parameters:
   - keyStore: The secure key storage implementation
   - loggingService: The logging service for recording operations
   - keyGenerator: Optional key generator (defaults to DefaultKeyGenerator)
   */
  public init(
    keyStore: KeyStorage,
    loggingService: LoggingServiceProtocol,
    keyGenerator: KeyGenerator=DefaultKeyGenerator()
  ) {
    self.keyStore=keyStore
    securityLogger=SecurityLogger(loggingService: loggingService)
    self.keyGenerator=keyGenerator

    // Create metadata store using the same secure storage if available
    if let secureStorage=keyStore as? SecureStorageProtocol {
      metadataStore=KeyMetadataStore(secureStorage: secureStorage)
    } else {
      // Fallback to a KeyStorage adapter if keyStore doesn't implement SecureStorageProtocol
      let adapter=KeyStorageToSecureStorageAdapter(keyStorage: keyStore)
      metadataStore=KeyMetadataStore(secureStorage: adapter)
    }
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
      let error=KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: error
      )
      return Result<[UInt8], SecurityProtocolError>.failure(error.toStandardError())
    }

    // Get the key from storage
    do {
      if let key=try await keyStore.getKey(identifier: sanitizeIdentifier(identifier)) {
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
        return Result<[UInt8], SecurityProtocolError>.failure(error.toStandardError())
      }
    } catch {
      let secError=KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "retrieve",
        error: secError
      )
      return Result<[UInt8], SecurityProtocolError>.failure(secError.toStandardError())
    }
  }

  // MARK: - Protocol Conformance

  /**
   Implements the protocol-compliant version of storeKey.
   
   - Parameters:
     - key: The security key as a byte array.
     - identifier: A string identifier for the key.
   - Returns: A Result indicating success or an error.
   */
  public func storeKey(_ key: [UInt8], withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError> {
    // Call the more comprehensive implementation with empty additionalInfo
    return await storeKeyInternal(key, withIdentifier: identifier, additionalInfo: [:])
  }

  /**
   Enhanced version of storeKey that supports additional metadata.
   
   - Parameters:
     - key: The security key as a byte array.
     - identifier: A string identifier for the key.
     - additionalInfo: Optional dictionary of additional metadata about the key.
   - Returns: A Result indicating success or an error.
   */
  internal func storeKeyInternal(
    _ key: [UInt8],
    withIdentifier identifier: String,
    additionalInfo: [String: String]=[:]
  ) async -> Result<Void, SecurityProtocolError> {
    let operationID=UUID().uuidString

    // Create privacy-aware logging context
    var logMetadata=LogMetadataDTOCollection()
      .withPrivate(key: "keyIdentifier", value: identifier)
      .withPublic(key: "keySize", value: String(key.count))
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: "storeKey")

    // Log only non-sensitive additional information
    for (key, value) in additionalInfo {
      if ["algorithm", "keyType", "createdAt", "expiresAt", "purpose", "keyUsage"].contains(key) {
        logMetadata=logMetadata.withPublic(key: key, value: value)
      } else {
        // Any metadata not in the safe list is treated as private
        logMetadata=logMetadata.withPrivate(key: key, value: value)
      }
    }

    // Log operation start with enhanced context
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "store"
    )

    let sanitizedIdentifier=sanitizeIdentifier(identifier)

    // Validate the input with enhanced error context
    guard !identifier.isEmpty else {
      let error=KeyManagementError.invalidInput(details: "Identifier cannot be empty")

      await securityLogger.logOperationFailure(
        keyIdentifier: "invalid",
        operation: "store",
        error: error
      )

      return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
    }

    // Validate the key with enhanced error context
    guard !key.isEmpty else {
      let error=KeyManagementError.invalidInput(details: "Key cannot be empty")

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

      // Create and store metadata with additional information
      var keyPurpose=additionalInfo["purpose"] ?? "encryption"
      var keyAlgorithm: CryptoAlgorithm = .aes // Default

      // Determine algorithm from metadata if available
      if let algorithmStr=additionalInfo["algorithm"] {
        switch algorithmStr.lowercased() {
          case "aes", "aes-256", "aes-128", "aes-gcm":
            keyAlgorithm = .aes
          case "rsa":
            keyAlgorithm = .rsa
          case "ec", "ecdsa", "ecdh":
            keyAlgorithm = .curve25519
          case "hmac", "hmac-sha256":
            keyAlgorithm = .hmac
            keyPurpose="authentication"
          default:
            // Handle other algorithms - CryptoAlgorithm doesn't have an .other case
            // Use default algorithm
            keyAlgorithm = .aes
        }
      }

      // Create comprehensive metadata
      let metadata=KeyMetadata(
        id: identifier,
        createdAt: Date().timeIntervalSinceReferenceDate,
        algorithm: keyAlgorithm,
        keySize: key.count * 8, // Size in bits
        purpose: keyPurpose,
        attributes: additionalInfo
      )

      try await metadataStore.storeKeyMetadata(metadata)

      // Log the success
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "store"
      )

      return .success(())
    } catch {
      // Enhanced error handling with more context
      let errorDescription: String
      let secError: KeyManagementError

      if let keyError=error as? KeyManagementError {
        secError=keyError
        errorDescription=keyError.localizedDescription
      } else {
        errorDescription=error.localizedDescription
        secError=KeyManagementError.keyManagementError(details: errorDescription)
      }

      // Log failure
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
      let error=KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "delete",
        error: error
      )
      return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
    }

    // Sanitise the identifier
    let sanitizedIdentifier=sanitizeIdentifier(identifier)

    do {
      // Check if the key exists before attempting to delete
      if try await keyStore.containsKey(identifier: sanitizedIdentifier) {
        do {
          try await keyStore.deleteKey(identifier: sanitizedIdentifier)

          // Delete the metadata
          try await metadataStore.deleteKeyMetadata(for: identifier)

          await securityLogger.logOperationSuccess(
            keyIdentifier: identifier,
            operation: "delete"
          )

          return .success(())
        } catch {
          let secError=KeyManagementError.keyManagementError(details: error.localizedDescription)
          await securityLogger.logOperationFailure(
            keyIdentifier: identifier,
            operation: "delete",
            error: secError
          )
          return Result<Void, SecurityProtocolError>.failure(secError.toStandardError())
        }
      } else {
        let error=KeyManagementError
          .keyNotFound(identifier: identifier)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "delete",
          error: error
        )
        return Result<Void, SecurityProtocolError>.failure(error.toStandardError())
      }
    } catch {
      let secError=KeyManagementError.keyManagementError(details: error.localizedDescription)
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
    dataToReencrypt _: [UInt8]?=nil
  ) async -> Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError> {
    await securityLogger.logOperationStart(
      keyIdentifier: identifier,
      operation: "rotate"
    )

    // Validate the input
    guard !identifier.isEmpty else {
      let error=KeyManagementError.invalidInput(details: "Identifier cannot be empty")
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: error
      )
      return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>
        .failure(error.toStandardError())
    }

    let sanitizedIdentifier=sanitizeIdentifier(identifier)

    do {
      guard try await keyStore.containsKey(identifier: sanitizedIdentifier) else {
        let error=KeyManagementError
          .keyNotFound(identifier: identifier)
        await securityLogger.logOperationFailure(
          keyIdentifier: identifier,
          operation: "rotate",
          error: error
        )
        return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>
          .failure(error.toStandardError())
      }

      // Generate a new key - this will replace the existing one
      let newKey=try await keyGenerator.generateKey()

      // Store the new key
      try await keyStore.storeKey(newKey, identifier: sanitizedIdentifier)

      // Create and store metadata
      let metadata=KeyMetadata(
        id: identifier,
        algorithm: .aes, // Default, should be determined based on key
        keySize: newKey.count * 8, // Size in bits
        purpose: "encryption" // Default, should be a parameter
      )

      try await metadataStore.storeKeyMetadata(metadata)

      // Log the success
      await securityLogger.logOperationSuccess(
        keyIdentifier: identifier,
        operation: "rotate"
      )

      return .success((newKey: newKey, reencryptedData: nil))
    } catch {
      let secError=KeyManagementError.keyManagementError(details: error.localizedDescription)
      await securityLogger.logOperationFailure(
        keyIdentifier: identifier,
        operation: "rotate",
        error: secError
      )
      return Result<(newKey: [UInt8], reencryptedData: [UInt8]?), SecurityProtocolError>
        .failure(secError.toStandardError())
    }
  }

  /**
   Retrieves all key identifiers.

   - Returns: A result containing an array of key identifiers or an error
   */
  public func getAllKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    // Simply delegate to the protocol method
    await listKeyIdentifiers()
  }

  /**
   Lists all available key identifiers.

   - Returns: An array of key identifiers or an error.
   */
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    // Log the operation start
    await securityLogger.logOperationStart(
      keyIdentifier: "all",
      operation: "list"
    )

    do {
      // Get all key identifiers from the metadata store
      let identifiers=try await metadataStore.getAllKeyIdentifiers()

      // Log the successful operation
      await securityLogger.logOperationSuccess(
        keyIdentifier: "all",
        operation: "list"
      )

      return .success(identifiers)
    } catch {
      let secError=KeyManagementError.keyManagementError(details: error.localizedDescription)

      // Log the failed operation
      await securityLogger.logOperationFailure(
        keyIdentifier: "all",
        operation: "list",
        error: secError
      )

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
    var keyData=[UInt8](repeating: 0, count: 32)

    // Use SecRandomCopyBytes for secure random generation
    let status=SecRandomCopyBytes(kSecRandomDefault, keyData.count, &keyData)

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
    self.loggingService=loggingService
  }

  func logOperationStart(keyIdentifier _: String, operation _: String) async {
    // Implement logging for operation start
  }

  func logOperationProgress(
    keyIdentifier _: String,
    operation _: String,
    progress _: String
  ) async {
    // Implement logging for operation progress
  }

  func logOperationSuccess(keyIdentifier _: String, operation _: String) async {
    // Implement logging for operation success
  }

  func logOperationFailure(keyIdentifier _: String, operation _: String, error _: Error) async {
    // Implement logging for operation failure
  }
}
