import APIInterfaces
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

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
      try await securityService.storeKey(key, withIdentifier: keyID)

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
      encryptedData: result.data ?? SecureBytes(), // Handle potential nil data
      keyIdentifier: keyIdentifier
    )
  }

  /**
   Handles the decrypt data operation.

   - Parameter operation: The decrypt data operation

   - Returns: Decrypted data
   - Throws: Error if decryption fails
   */
  private func handleDecryptData(_ operation: DecryptDataOperation) async throws -> SecureBytes {
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

    // Perform the decryption
    let securityOperation=SecurityOperation.decrypt(
      data: operation.data,
      key: decryptionKey
    )

    let result=try await securityService.performSecureOperation(
      securityOperation,
      config: config
    )

    // Return the decrypted data
    guard let decryptedData=result.data else {
      throw APIError.operationFailed(
        UmbraErrors.Common.invalidData("Decryption completed but no data was returned")
      )
    }

    return decryptedData
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

    // Add key identifier if storing the key
    var keyIdentifier: String?
    if operation.storeKey {
      keyIdentifier=operation.keyIdentifier ?? UUID().uuidString
      options["keyIdentifier"]=keyIdentifier
    }

    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "generateKey", privacy: .public)
    metadata["keyType"]=PrivacyMetadataValue(value: operation.keyType.rawValue, privacy: .public)
    metadata["keySize"]=PrivacyMetadataValue(value: String(operation.keySizeInBits),
                                             privacy: .public)
    if let keyID=keyIdentifier {
      metadata["keyIdentifier"]=PrivacyMetadataValue(value: keyID, privacy: .private)
    }

    await logger?.info(
      "Generating cryptographic key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create security config for the key generation
    let config=SecurityConfigDTO(
      algorithm: nil,
      keySize: operation.keySizeInBits,
      options: options
    )

    // Perform the key generation
    let securityOperation=SecurityOperation.generateKey(size: operation.keySizeInBits)
    let result=try await securityService.performSecureOperation(
      securityOperation,
      config: config
    )

    // Store the key if requested
    if operation.storeKey, let key=result.key, let keyID=keyIdentifier {
      try await securityService.storeKey(key, withIdentifier: keyID)

      // Log key storage with privacy controls
      var keyMetadata=PrivacyMetadata()
      keyMetadata["keyIdentifier"]=PrivacyMetadataValue(value: keyID, privacy: .private)
      keyMetadata["operation"]=PrivacyMetadataValue(value: "storeKey", privacy: .public)
      await logger?.info(
        "Stored generated key",
        metadata: keyMetadata,
        source: "SecurityDomainHandler"
      )
    }

    // Return the key generation result
    guard let generatedKey=result.key else {
      throw APIError.operationFailed(
        UmbraErrors.Common.invalidData("Key generation completed but no key was returned")
      )
    }

    return KeyGenerationResult(
      key: generatedKey,
      keyIdentifier: keyIdentifier
    )
  }

  /**
   Handles the retrieve key operation.

   - Parameter operation: The retrieve key operation

   - Returns: Retrieved key
   - Throws: Error if key retrieval fails
   */
  private func handleRetrieveKey(_ operation: RetrieveKeyOperation) async throws -> SecureBytes {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "retrieveKey", privacy: .public)
    metadata["keyIdentifier"]=PrivacyMetadataValue(value: operation.keyIdentifier,
                                                   privacy: .private)

    await logger?.info(
      "Retrieving stored key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Retrieve the key
    return try await securityService.retrieveKey(withIdentifier: operation.keyIdentifier)
  }

  /**
   Handles the delete key operation.

   - Parameter operation: The delete key operation

   - Throws: Error if key deletion fails
   */
  private func handleDeleteKey(_ operation: DeleteKeyOperation) async throws {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "deleteKey", privacy: .public)
    metadata["keyIdentifier"]=PrivacyMetadataValue(value: operation.keyIdentifier,
                                                   privacy: .private)

    await logger?.info(
      "Deleting stored key",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Delete the key
    try await securityService.deleteKey(withIdentifier: operation.keyIdentifier)
  }

  /**
   Handles the hash data operation.

   - Parameter operation: The hash data operation

   - Returns: Hash result
   - Throws: Error if hashing fails
   */
  private func handleHashData(_ operation: HashDataOperation) async throws -> SecureBytes {
    // Create hashing configuration
    var options=[String: String]()
    options["algorithm"]=operation.algorithm.rawValue

    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "hashData", privacy: .public)
    metadata["algorithm"]=PrivacyMetadataValue(value: operation.algorithm.rawValue,
                                               privacy: .public)

    await logger?.info(
      "Computing hash of data",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Create security config for the hashing
    let config=SecurityConfigDTO(
      algorithm: operation.algorithm.rawValue,
      keySize: nil,
      options: options
    )

    // Perform the hashing
    let securityOperation=SecurityOperation.hash(
      data: operation.data,
      algorithm: operation.algorithm.rawValue
    )

    let result=try await securityService.performSecureOperation(
      securityOperation,
      config: config
    )

    // Return the hash result
    guard let hashResult=result.data else {
      throw APIError.operationFailed(
        UmbraErrors.Common.invalidData("Hashing completed but no data was returned")
      )
    }

    return hashResult
  }

  /**
   Handles the store secret operation.

   - Parameter operation: The store secret operation

   - Returns: Store secret result
   - Throws: Error if secret storage fails
   */
  private func handleStoreSecret(_ operation: StoreSecretOperation) async throws
  -> StoreSecretResult {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "storeSecret", privacy: .public)
    metadata["account"]=PrivacyMetadataValue(value: operation.account, privacy: .private)
    metadata["encrypted"]=PrivacyMetadataValue(value: String(operation.encrypt), privacy: .public)

    await logger?.info(
      "Storing secret for account",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    var keyIdentifier: String?

    if operation.encrypt {
      // Generate a key identifier
      keyIdentifier=UUID().uuidString

      // Store encrypted secret
      keyIdentifier=try await securityService.storeEncryptedSecret(
        secret: operation.secret,
        forAccount: operation.account,
        keyIdentifier: keyIdentifier
      )
    } else {
      // Store unencrypted secret
      try await securityService.storeSecret(
        secret: operation.secret,
        forAccount: operation.account
      )
    }

    // Return the store secret result
    return StoreSecretResult(
      account: operation.account,
      keyIdentifier: keyIdentifier
    )
  }

  /**
   Handles the retrieve secret operation.

   - Parameter operation: The retrieve secret operation

   - Returns: Retrieved secret
   - Throws: Error if secret retrieval fails
   */
  private func handleRetrieveSecret(_ operation: RetrieveSecretOperation) async throws
  -> SecureBytes {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "retrieveSecret", privacy: .public)
    metadata["account"]=PrivacyMetadataValue(value: operation.account, privacy: .private)
    metadata["encrypted"]=PrivacyMetadataValue(value: String(operation.encrypted), privacy: .public)

    await logger?.info(
      "Retrieving secret for account",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    if operation.encrypted {
      // Retrieve encrypted secret
      return try await securityService.retrieveEncryptedSecret(
        forAccount: operation.account
      )
    } else {
      // Retrieve unencrypted secret
      return try await securityService.retrieveSecret(
        forAccount: operation.account
      )
    }
  }

  /**
   Handles the delete secret operation.

   - Parameter operation: The delete secret operation

   - Throws: Error if secret deletion fails
   */
  private func handleDeleteSecret(_ operation: DeleteSecretOperation) async throws {
    // Log with privacy controls
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "deleteSecret", privacy: .public)
    metadata["account"]=PrivacyMetadataValue(value: operation.account, privacy: .private)

    await logger?.info(
      "Deleting secret for account",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )

    // Delete the secret
    try await securityService.deleteSecret(
      forAccount: operation.account
    )
  }

  // MARK: - Helper Methods

  /**
   Logs an operation with privacy controls.

   - Parameters:
      - operation: The operation name
      - event: The event type
   */
  private func logOperation(_ operation: Any, event: String) async {
    let operationName=String(describing: operation)

    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operationName, privacy: .public)
    metadata["event"]=PrivacyMetadataValue(value: event, privacy: .public)

    await logger?.debug(
      "\(event.capitalized) operation: \(operationName)",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )
  }

  /**
   Logs an error with privacy controls.

   - Parameters:
      - error: The error
      - operation: The operation name
   */
  private func logError(_ error: Error, for operation: String) async {
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)
    metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .public)

    await logger?.error(
      "Security operation error: \(error.localizedDescription)",
      metadata: metadata,
      source: "SecurityDomainHandler"
    )
  }

  /**
   Maps an error to an APIError.

   - Parameter error: The original error

   - Returns: An APIError
   */
  private func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError=error as? APIError {
      return apiError
    }

    // Map known security errors to APIError types
    if let securityError=error as? SecurityCoreTypes.SecurityError {
      switch securityError {
        case .keyNotFound:
          return APIError.resourceNotFound("Security key not found", identifier: nil)

        case .invalidKey:
          return APIError.validationError("Invalid security key", fieldName: "key")

        case .encryptionFailed:
          return APIError.operationFailed(error)

        case .decryptionFailed:
          return APIError.operationFailed(error)

        case .operationNotSupported:
          return APIError.operationNotSupported(error.localizedDescription)

        default:
          return APIError.operationFailed(error)
      }
    }

    // Map keychain errors
    if let keychainError=error as? KeychainInterfaces.KeychainError {
      switch keychainError {
        case .itemNotFound:
          return APIError.resourceNotFound("Keychain item not found", identifier: nil)

        case .duplicateItem:
          return APIError.resourceConflict("Duplicate keychain item")

        case .accessDenied:
          return APIError.unauthorised("Access denied to keychain item")

        default:
          return APIError.operationFailed(error)
      }
    }

    // Default to operation failed
    return APIError.operationFailed(error)
  }
}
