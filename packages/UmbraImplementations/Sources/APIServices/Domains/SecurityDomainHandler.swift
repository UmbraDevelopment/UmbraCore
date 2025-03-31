import APIInterfaces
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors
import CoreSecurityTypes
import DomainAPI
import SecurityUtils

/**
 # Security Domain Handler

 Handles security-related API operations by delegating to the underlying
 security and keychain services. This handler follows the Alpha Dot Five architecture
 with proper thread safety, structured error handling, and privacy-aware logging.

 ## Privacy-Enhanced Logging

 Operations are logged with appropriate privacy controls to ensure sensitive
 information is properly protected during logging.

 ## Operation Processing

 Each security operation is processed by mapping it to the appropriate
 security service methods, with proper error handling and result conversion.

 ## Memory Protection

 Sensitive cryptographic operations are protected with memory protection to prevent
 data leakage.
 */
public struct SecurityDomainHandler: DomainHandler {
  /// The security service for encryption/decryption operations
  private let securityService: SecurityServiceProtocol

  /// The logger for privacy-aware logging
  private let logger: LoggingProtocol?

  /**
   Initialises a new security domain handler.

   - Parameters:
      - service: The security service
      - logger: Optional logger for privacy-aware operation recording
   */
  public init(service: SecurityServiceProtocol, logger: LoggingProtocol?=nil) {
    securityService=service
    self.logger=logger
  }

  /**
   Executes a security operation and returns the result.

   - Parameter operation: The operation to execute

   - Returns: The result of the operation
   - Throws: Error if the operation fails
   */
  public func execute<T: APIOperation>(_ operation: T) async throws -> Any {
    // Log the operation start with appropriate privacy controls
    if let operationName=operation as? SecurityAPIOperation.Type {
      await logOperation(operationName, event: "start")
    } else {
      await logOperation(String(describing: T.self), event: "start")
    }

    do {
      // Handle specific security operations
      if let op=operation as? EncryptDataOperation {
        return try await handleEncryptData(op)
      } else if let op=operation as? DecryptDataOperation {
        return try await handleDecryptData(op)
      } else if let op=operation as? GenerateKeyOperation {
        return try await handleGenerateKey(op)
      } else if let op=operation as? RetrieveKeyOperation {
        return try await handleRetrieveKey(op)
      } else if let op=operation as? DeleteKeyOperation {
        return try await handleDeleteKey(op)
      } else if let op=operation as? HashDataOperation {
        return try await handleHashData(op)
      } else if let op=operation as? StoreSecretOperation {
        return try await handleStoreSecret(op)
      } else if let op=operation as? RetrieveSecretOperation {
        return try await handleRetrieveSecret(op)
      } else if let op=operation as? DeleteSecretOperation {
        return try await handleDeleteSecret(op)
      }

      // Unsupported operation
      throw APIError
        .operationNotSupported("Unsupported security operation: \(String(describing: T.self))")
    } catch {
      // Log the error with privacy controls
      await logError(error, for: String(describing: T.self))

      // Map to API error and rethrow
      throw mapToAPIError(error)
    }
  }

  /**
   Checks if this handler supports the given operation.

   - Parameter operation: The operation to check

   - Returns: True if the operation is supported, false otherwise
   */
  public func supports(_ operation: some APIOperation) -> Bool {
    operation is SecurityAPIOperation
  }

  // MARK: - Operation Handlers

  /**
   Handles the encrypt data operation.

   - Parameter operation: The encrypt data operation

   - Returns: Encryption result
   - Throws: Error if encryption fails
   */
  private func handleEncryptData(_ operation: EncryptDataOperation) async throws
  -> EncryptionResult {
    // Create encryption configuration
    var options=[String: String]()
    if let algorithm=operation.algorithm {
      options["algorithm"]=algorithm
    }

    // Add key identifier if storing the key
    var keyIdentifier: String?
    if operation.storeKey {
      keyIdentifier=operation.keyIdentifier ?? UUID().uuidString
      options["keyIdentifier"]=keyIdentifier
    }

    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "encryptData", privacy: .public)
    if let algorithm=operation.algorithm {
      metadata["algorithm"]=PrivacyMetadataValue(value: algorithm, privacy: .public)
    }
    if let keyID=keyIdentifier {
      metadata["keyIdentifier"]=PrivacyMetadataValue(value: keyID, privacy: .private)
    }
    await logger?.info(
      "Encrypting data",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create security config for the encryption
    let config=SecurityConfigDTO(
      algorithm: operation.algorithm ?? "AES256GCM",
      keySize: 256,
      options: options
    )

    // Use memory protection for encryption operation
    return try await MemoryProtection.withSecureOperation {
      // Perform the encryption
      let securityOperation: SecurityOperation=if let key=operation.key {
        .encrypt(data: operation.data, key: key)
      } else {
        .encrypt(data: operation.data, key: nil)
      }

      let result=try await securityService.performSecureOperation(
        securityOperation,
        config: config
      )

      // Store the key if requested
      if operation.storeKey, let key=result.key, let keyID=keyIdentifier {
        try await MemoryProtection.withSecureTemporaryData(key) { secureKey in
          try await securityService.storeKey(secureKey, withIdentifier: keyID)
        }

        // Log key storage with privacy controls
        var keyMetadata=PrivacyMetadata()
        keyMetadata["keyIdentifier"]=PrivacyMetadataValue(value: keyID, privacy: .private)
        keyMetadata["operation"]=PrivacyMetadataValue(value: "storeKey", privacy: .public)
        await logger?.info(
          "Stored encryption key",
          metadata: keyMetadata,
          source: "SecurityDomainHandler"
        )
      }

      // Return the encryption result
      return EncryptionResult(
        encryptedData: result.data ?? [], // Handle potential nil data
        keyIdentifier: keyIdentifier
      )
    }
  }

  /**
   Handles the decrypt data operation.

   - Parameter operation: The decrypt data operation

   - Returns: Decrypted data
   - Throws: Error if decryption fails
   */
  private func handleDecryptData(_ operation: DecryptDataOperation) async throws -> [UInt8] {
    // Create decryption configuration
    var options=[String: String]()

    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "decryptData", privacy: .public)

    // Get the key for decryption
    var decryptionKey=operation.key

    // If no key provided but key identifier is, retrieve the stored key
    if decryptionKey == nil, let keyID=operation.keyIdentifier {
      metadata["keyIdentifier"]=PrivacyMetadataValue(value: keyID, privacy: .private)
      options["keyIdentifier"]=keyID

      await logger?.info(
        "Retrieving stored key for decryption",
        metadata: metadata,
        source: "SecurityDomainHandler"
      )

      decryptionKey=try await securityService.retrieveKey(withIdentifier: keyID)
    }

    await logger?.info(
      "Decrypting data",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create security config for the decryption
    let config=SecurityConfigDTO(
      algorithm: "AES256GCM", // Default to AES-GCM
      keySize: 256,
      options: options
    )

    // Use memory protection for decryption operation
    return try await MemoryProtection.withSecureOperation {
      // Perform the decryption
      guard let key=decryptionKey else {
        throw SecurityProtocolError
          .invalidInput("No decryption key provided or found for the given key identifier")
      }

      // Use memory protection for both the key and encrypted data
      return try await MemoryProtection.withSecureTemporaryBatch([key, operation.encryptedData]) { secureBatch in
        let secureKey = secureBatch[0]
        let secureEncryptedData = secureBatch[1]

        let securityOperation: SecurityOperation = .decrypt(data: secureEncryptedData, key: secureKey)
        let result=try await securityService.performSecureOperation(securityOperation, config: config)

        // Return the decrypted data
        guard let decryptedData=result.data else {
          throw SecurityProtocolError.cryptographicError("Decryption failed to produce valid data")
        }

        await logger?.info(
          "Successfully decrypted data",
          metadata: metadata,
          source: "SecurityDomainHandler"
        )

        // Return a copy of the decrypted data to prevent sharing references
        return MemoryProtection.secureDataCopy(decryptedData)
      }
    }
  }

  /**
   Handles the generate key operation.

   - Parameter operation: The generate key operation

   - Returns: Key generation result
   - Throws: Error if key generation fails
   */
  private func handleGenerateKey(_ operation: GenerateKeyOperation) async throws
  -> KeyGenerationResult {
    // Create key generation configuration
    var options=[String: String]()
    options["keyType"]=operation.keyType.rawValue

    // Configure size based on key type
    let keySize: Int
    switch operation.keyType {
    case .symmetric:
      keySize=operation.size ?? 256
    case .asymmetric:
      keySize=operation.size ?? 2048
    }

    // Generate a key identifier if needed
    let keyIdentifier=operation.keyIdentifier ?? UUID().uuidString

    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "generateKey", privacy: .public)
    metadata["keyType"]=PrivacyMetadataValue(value: operation.keyType.rawValue, privacy: .public)
    metadata["keySize"]=PrivacyMetadataValue(value: "\(keySize)", privacy: .public)
    metadata["keyIdentifier"]=PrivacyMetadataValue(value: keyIdentifier, privacy: .private)
    await logger?.info(
      "Generating key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create security config for the key generation
    let config=SecurityConfigDTO(
      algorithm: operation.algorithm ?? "AES",
      keySize: keySize,
      options: options
    )

    // Use memory protection for key generation
    return try await MemoryProtection.withSecureOperation {
      // Generate the key
      let securityOperation: SecurityOperation = .generateKey(
        type: operation.keyType,
        size: keySize
      )
      let result=try await securityService.performSecureOperation(securityOperation, config: config)

      // Store the key if requested
      if operation.storeKey, let key=result.key {
        try await MemoryProtection.withSecureTemporaryData(key) { secureKey in
          try await securityService.storeKey(secureKey, withIdentifier: keyIdentifier)
        }

        var storeMetadata=PrivacyMetadata()
        storeMetadata["operation"]=PrivacyMetadataValue(value: "storeKey", privacy: .public)
        storeMetadata["keyIdentifier"]=PrivacyMetadataValue(value: keyIdentifier, privacy: .private)
        await logger?.info(
          "Stored generated key",
          metadata: storeMetadata,
          source: "SecurityDomainHandler"
        )
      }

      // Return the result, making a secured copy if needed
      let resultKey = operation.includeKeyInResponse ? 
        (result.key != nil ? MemoryProtection.secureDataCopy(result.key!) : nil) : nil

      return KeyGenerationResult(
        key: resultKey,
        keyIdentifier: keyIdentifier
      )
    }
  }

  /**
   Handles the retrieve key operation.

   - Parameter operation: The retrieve key operation

   - Returns: The retrieved key
   - Throws: Error if key retrieval fails
   */
  private func handleRetrieveKey(_ operation: RetrieveKeyOperation) async throws -> [UInt8] {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "retrieveKey", privacy: .public)
    metadata["keyIdentifier"]=PrivacyMetadataValue(value: operation.keyIdentifier, privacy: .private)
    await logger?.info(
      "Retrieving key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Retrieve the key
    let key=try await securityService.retrieveKey(withIdentifier: operation.keyIdentifier)

    await logger?.info(
      "Successfully retrieved key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create a secure copy of the key to prevent sharing references
    return MemoryProtection.secureDataCopy(key)
  }

  /**
   Handles the delete key operation.

   - Parameter operation: The delete key operation

   - Returns: Result indicating success
   - Throws: Error if key deletion fails
   */
  private func handleDeleteKey(_ operation: DeleteKeyOperation) async throws -> DeleteKeyResult {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "deleteKey", privacy: .public)
    metadata["keyIdentifier"]=PrivacyMetadataValue(value: operation.keyIdentifier, privacy: .private)
    await logger?.info(
      "Deleting key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Delete the key
    let success=try await securityService.deleteKey(withIdentifier: operation.keyIdentifier)

    if success {
      await logger?.info(
        "Successfully deleted key",
        metadata: metadata,
        source: "SecurityDomainHandler"
      )
    } else {
      await logger?.warning(
        "Failed to delete key",
        metadata: metadata,
        source: "SecurityDomainHandler"
      )
    }

    return DeleteKeyResult(success: success)
  }

  /**
   Handles the hash data operation.

   - Parameter operation: The hash data operation

   - Returns: Hash result
   - Throws: Error if hashing fails
   */
  private func handleHashData(_ operation: HashDataOperation) async throws -> [UInt8] {
    // Configure hashing options
    var options=[String: String]()
    options["algorithm"]=operation.algorithm.rawValue

    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "hashData", privacy: .public)
    metadata["algorithm"]=PrivacyMetadataValue(value: operation.algorithm.rawValue, privacy: .public)

    await logger?.info(
      "Hashing data",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create security config for the hash operation
    let config=SecurityConfigDTO(
      algorithm: operation.algorithm.rawValue,
      options: options
    )

    // Use memory protection for the data to be hashed
    return try await MemoryProtection.withSecureTemporaryData(operation.data) { secureData in
      // Perform the hashing operation
      let securityOperation: SecurityOperation = .hash(data: secureData)
      let result = try await self.securityService.performSecureOperation(securityOperation, config: config)

      // Return the hash result
      guard let hashData = result.data else {
        throw SecurityProtocolError.cryptographicError("Hashing failed to produce valid data")
      }

      await self.logger?.info(
        "Successfully hashed data",
        metadata: metadata,
        source: "SecurityDomainHandler"
      )

      return hashData
    }
  }

  /**
   Handles the store secret operation.

   - Parameter operation: The store secret operation

   - Returns: Result indicating success
   - Throws: Error if secret storage fails
   */
  private func handleStoreSecret(_ operation: StoreSecretOperation) async throws
  -> StoreSecretResult {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "storeSecret", privacy: .public)
    metadata["key"]=PrivacyMetadataValue(value: operation.key, privacy: .private)
    await logger?.info(
      "Storing secret",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Store the secret
    try await securityService.storeKeychainItem(
      operation.value,
      forKey: operation.key,
      service: operation.service
    )

    await logger?.info(
      "Successfully stored secret",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    return StoreSecretResult(success: true)
  }

  /**
   Handles the retrieve secret operation.

   - Parameter operation: The retrieve secret operation

   - Returns: The retrieved secret
   - Throws: Error if secret retrieval fails
   */
  private func handleRetrieveSecret(_ operation: RetrieveSecretOperation) async throws
  -> [UInt8] {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "retrieveSecret", privacy: .public)
    metadata["key"]=PrivacyMetadataValue(value: operation.key, privacy: .private)
    await logger?.info(
      "Retrieving secret",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Retrieve the secret
    let value=try await securityService.retrieveKeychainItem(
      forKey: operation.key,
      service: operation.service
    )

    await logger?.info(
      "Successfully retrieved secret",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    return value
  }

  /**
   Handles the delete secret operation.

   - Parameter operation: The delete secret operation

   - Returns: Result indicating success
   - Throws: Error if secret deletion fails
   */
  private func handleDeleteSecret(_ operation: DeleteSecretOperation) async throws
  -> DeleteSecretResult {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "deleteSecret", privacy: .public)
    metadata["key"]=PrivacyMetadataValue(value: operation.key, privacy: .private)
    await logger?.info(
      "Deleting secret",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Delete the secret
    let success=try await securityService.deleteKeychainItem(
      forKey: operation.key,
      service: operation.service
    )

    await logger?.info(
      "Secret deletion " + (success ? "successful" : "failed"),
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    return DeleteSecretResult(success: success)
  }

  // MARK: - Helper Methods

  /**
   Logs an operation with appropriate privacy controls.

   - Parameters:
      - operation: The operation being performed
      - event: The event type (start, end, etc.)
   */
  private func logOperation(_ operation: Any, event: String) async {
    let operationName=String(describing: operation)

    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operationName, privacy: .public)
    metadata["event"]=PrivacyMetadataValue(value: event, privacy: .public)

    await logger?.debug(
      "Security operation \(event): \(operationName)",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )
  }

  /**
   Logs an error with appropriate privacy controls.

   - Parameters:
      - error: The error that occurred
      - operation: The operation that failed
   */
  private func logError(_ error: Error, for operation: String) async {
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)

    // Add appropriate error details with privacy controls
    if let secError=error as? SecurityProtocolError {
      metadata["errorType"]=PrivacyMetadataValue(value: "SecurityProtocolError", privacy: .public)
      metadata["errorDetails"]=PrivacyMetadataValue(value: "\(secError)", privacy: .private)
    } else {
      metadata["errorType"]=PrivacyMetadataValue(value: "\(type(of: error))", privacy: .public)
      metadata["errorDetails"]=PrivacyMetadataValue(value: "\(error.localizedDescription)", privacy: .private)
    }

    await logger?.error(
      "Security operation failed: \(operation)",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )
  }

  /**
   Maps internal errors to API errors.

   - Parameter error: The internal error

   - Returns: The mapped API error
   */
  private func mapToAPIError(_ error: Error) -> Error {
    // If it's already an API error, return it as is
    if let apiError=error as? APIError {
      return apiError
    }

    // Map security protocol errors to API errors
    if let secError=error as? SecurityProtocolError {
      switch secError {
      case .invalidInput:
        return APIError.invalidInput(secError.localizedDescription)
      case .cryptographicError:
        return APIError.securityError(secError.localizedDescription)
      case .unsupportedOperation:
        return APIError.operationNotSupported(secError.localizedDescription)
      }
    }

    // Default to internal error for other types
    return APIError.internalError(error.localizedDescription)
  }
}
