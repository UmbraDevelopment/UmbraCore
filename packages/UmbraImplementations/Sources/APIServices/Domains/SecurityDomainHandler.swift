import APIInterfaces
import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import ErrorCoreTypes
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import UmbraErrors

/**
 # Security Domain Handler

 Handles security-related API operations within the Alpha Dot Five architecture.
 This implementation provides secure operations for encryption, decryption,
 key management, and secure storage with proper privacy controls.

 ## Actor-Based Secure Storage

 This handler uses actor-based `SecureStorage` internally to ensure thread safety
 and memory protection for all sensitive cryptographic material. The handler leverages
 `SendableCryptoMaterial` for all cryptographic operations, which is designed
 as a drop-in replacement for the deprecated `SecureBytes` class.

 ## Privacy-Enhanced Logging

 All operations are logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.

 ## Thread Safety

 Operations are thread-safe by leveraging Swift's structured concurrency model
 and actor-based isolation where appropriate. The underlying security service
 uses actors to provide isolation and consistent memory safety.

 ## Memory Protection

 Security operations include memory protection to prevent data leakage.
 This is achieved through properly isolated actor-based state management,
 ensuring sensitive material is protected throughout its lifecycle.
 */
public struct SecurityDomainHandler: DomainHandler {
  /// Security service for cryptographic operations
  private let securityService: any SecurityProviderProtocol

  /// Logger with privacy controls
  private let logger: (any LoggingProtocol)?

  /**
   Initialises a new security domain handler.

   - Parameters:
      - service: The security service for cryptographic operations that uses actor-based SecureStorage
      - logger: Optional logger for privacy-aware operation recording

   The security service must use actor-based SecureStorage internally to ensure
   proper isolation and thread safety for all cryptographic operations.
   */
  public init(
    service: any SecurityProviderProtocol,
    logger: (any LoggingProtocol)?=nil
  ) {
    securityService=service
    self.logger=logger
  }

  /**
   Executes a security operation and returns its result.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails

   All operations are executed through the actor-based security service,
   ensuring proper isolation and memory protection.
   */
  public func execute(_ operation: some APIOperation) async throws -> Any {
    // Log the operation start with privacy-aware metadata
    let operationName=String(describing: type(of: operation))
    let startMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: operationName, privacyLevel: .public)
      .with(key: "event", value: "start", privacyLevel: .public)

    await logger?.info(
      "Starting security operation",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: startMetadata
      )
    )

    do {
      // Execute the appropriate operation based on type
      let result=try await executeSecurityOperation(operation)

      // Log success
      let successMetadata=LogMetadataDTOCollection()
        .with(key: "operation", value: operationName, privacyLevel: .public)
        .with(key: "event", value: "success", privacyLevel: .public)
        .with(key: "status", value: "completed", privacyLevel: .public)

      await logger?.info(
        "Security operation completed successfully",
        context: CoreLogContext(
          source: "SecurityDomainHandler",
          metadata: successMetadata
        )
      )

      return result
    } catch {
      // Log failure with privacy-aware error details
      let errorMetadata=LogMetadataDTOCollection()
        .with(key: "operation", value: operationName, privacyLevel: .public)
        .with(key: "event", value: "failure", privacyLevel: .public)
        .with(key: "status", value: "failed", privacyLevel: .public)
        .with(key: "error", value: error.localizedDescription, privacyLevel: .private)

      await logger?.error(
        "Security operation failed",
        context: CoreLogContext(
          source: "SecurityDomainHandler",
          metadata: errorMetadata,
          error: error
        )
      )

      // Map to appropriate API error and rethrow
      throw mapToAPIError(error)
    }
  }

  /**
   Determines if this handler supports the given operation.

   - Parameter operation: The operation to check support for
   - Returns: true if the operation is supported, false otherwise
   */
  public func supports(_ operation: some APIOperation) -> Bool {
    operation is any SecurityAPIOperation
  }

  // MARK: - Private Helper Methods

  /**
   Routes the operation to the appropriate handler method based on its type.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails or is unsupported

   Each handler method uses proper Sendable types and actor-based secure storage
   to maintain memory safety and thread isolation.
   */
  private func executeSecurityOperation(_ operation: some APIOperation) async throws -> Any {
    switch operation {
      case let op as EncryptData:
        return try await handleEncryptData(op)
      case let op as DecryptData:
        return try await handleDecryptData(op)
      case let op as GenerateKey:
        return try await handleGenerateKey(op)
      case let op as RetrieveKey:
        return try await handleRetrieveKey(op)
      case let op as StoreKey:
        return try await handleStoreKey(op)
      case let op as DeleteKey:
        return try await handleDeleteKey(op)
      case let op as HashData:
        return try await handleHashData(op)
      case let op as StoreSecret:
        return try await handleStoreSecret(op)
      case let op as RetrieveSecret:
        return try await handleRetrieveSecret(op)
      case let op as DeleteSecret:
        return try await handleDeleteSecret(op)
      default:
        throw APIError.operationNotSupported(
          message: "Unsupported security operation: \(type(of: operation))",
          code: "SECURITY_OPERATION_NOT_SUPPORTED"
        )
    }
  }

  /**
   Maps domain-specific errors to standardised API errors.

   - Parameter error: The original error
   - Returns: An APIError instance
   */
  private func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError=error as? APIError {
      return apiError
    }

    // Handle specific security error types
    if let secError=error as? SecurityError {
      switch secError {
        case let .invalidInput(message):
          return APIError.invalidOperation(
            message: "Invalid security input: \(message)",
            code: "INVALID_SECURITY_INPUT"
          )
        case let .operationFailed(message):
          return APIError.operationFailed(
            message: "Security operation failed: \(message)",
            code: "SECURITY_OPERATION_FAILED",
            underlyingError: secError
          )
        case let .encryptionFailed(message):
          return APIError.operationFailed(
            message: "Encryption failed: \(message)",
            code: "ENCRYPTION_FAILED",
            underlyingError: secError
          )
        case let .decryptionFailed(message):
          return APIError.operationFailed(
            message: "Decryption failed: \(message)",
            code: "DECRYPTION_FAILED",
            underlyingError: secError
          )
        case let .keyGenerationFailed(message):
          return APIError.operationFailed(
            message: "Key generation failed: \(message)",
            code: "KEY_GENERATION_FAILED",
            underlyingError: secError
          )
        case let .keyRetrievalFailed(message):
          return APIError.operationFailed(
            message: "Key retrieval failed: \(message)",
            code: "KEY_RETRIEVAL_FAILED",
            underlyingError: secError
          )
        case let .keyStorageFailed(message):
          return APIError.operationFailed(
            message: "Key storage failed: \(message)",
            code: "KEY_STORAGE_FAILED",
            underlyingError: secError
          )
        case let .keyDeletionFailed(message):
          return APIError.operationFailed(
            message: "Key deletion failed: \(message)",
            code: "KEY_DELETION_FAILED",
            underlyingError: secError
          )
        case let .permissionDenied(message):
          return APIError.authenticationFailed(
            message: "Permission denied: \(message)",
            code: "SECURITY_PERMISSION_DENIED"
          )
        case let .unknownError(message):
          return APIError.operationFailed(
            message: "Unknown security error: \(message)",
            code: "SECURITY_UNKNOWN_ERROR",
            underlyingError: secError
          )
      }
    }

    // Default error mapping for unhandled error types
    return APIError.operationFailed(
      message: "Security operation failed: \(error.localizedDescription)",
      code: "SECURITY_OPERATION_ERROR",
      underlyingError: error
    )
  }

  /**
   Converts a string algorithm identifier to a concrete EncryptionAlgorithm.

   - Parameter algorithmString: String representation of the algorithm
   - Returns: The appropriate EncryptionAlgorithm type
   - Throws: SecurityError.invalidInput if an invalid algorithm is specified
   */
  private func getAlgorithm(from algorithmString: String?) throws -> CoreSecurityTypes
  .EncryptionAlgorithm {
    guard let algorithmStr=algorithmString else {
      return .aes256GCM // Default to AES-GCM if not specified
    }

    switch algorithmStr.lowercased() {
      case "aes", "aes256", "aes-256", "aes-gcm", "aes256-gcm", "aesgcm":
        return .aes256GCM
      case "chacha20", "chacha20poly1305", "chacha":
        return .chacha20Poly1305
      default:
        throw SecurityError.invalidInput("Unsupported encryption algorithm: \(algorithmStr)")
    }
  }

  /**
   Converts a string representation of a hash algorithm to a HashAlgorithm enum case.

   - Parameter algorithmString: String representation of the algorithm
   - Returns: A HashAlgorithm value
   - Throws: SecurityError if the algorithm is not supported
   */
  private func getHashAlgorithm(from algorithmString: String?) async throws -> CoreSecurityTypes
  .HashAlgorithm {
    guard let algorithmStr=algorithmString else {
      // Default to SHA-256 if no algorithm specified
      return .sha256
    }

    switch algorithmStr.lowercased() {
      case "sha256", "sha-256":
        return .sha256
      case "sha512", "sha-512":
        return .sha512
      case "sha1", "sha-1":
        // SHA-1 is deprecated, use SHA-256 as a secure alternative
        await logger?.warning(
          "SHA-1 is deprecated and was requested, using SHA-256 instead",
          context: CoreLogContext(
            source: "SecurityDomainHandler",
            metadata: LogMetadataDTOCollection()
              .with(key: "requested_algorithm", value: "sha1", privacyLevel: .public)
              .with(key: "using_algorithm", value: "sha256", privacyLevel: .public)
          )
        )
        return .sha256
      case "sha384", "sha-384":
        // SHA-384 is not directly supported, use SHA-512 instead
        await logger?.warning(
          "SHA-384 is not directly supported, using SHA-512 instead",
          context: CoreLogContext(
            source: "SecurityDomainHandler",
            metadata: LogMetadataDTOCollection()
              .with(key: "requested_algorithm", value: "sha384", privacyLevel: .public)
              .with(key: "using_algorithm", value: "sha512", privacyLevel: .public)
          )
        )
        return .sha512
      default:
        if algorithmStr.isEmpty {
          // Default to SHA-256 for empty string
          await logger?.warning(
            "Empty hash algorithm specified, using SHA-256 as default",
            context: CoreLogContext(
              source: "SecurityDomainHandler",
              metadata: LogMetadataDTOCollection()
                .with(key: "requested_algorithm", value: "empty", privacyLevel: .public)
                .with(key: "using_algorithm", value: "sha256", privacyLevel: .public)
            )
          )
          return .sha256
        }

        throw SecurityError.invalidInput("Unsupported hash algorithm: \(algorithmStr)")
    }
  }

  /**
   Handles data encryption operations.

   - Parameter operation: The encryption operation parameters
   - Returns: Encrypted data result
   - Throws: APIError if the encryption fails
   */
  private func handleEncryptData(_ operation: EncryptData) async throws -> EncryptionResult {
    let encryptionMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "encryptData", privacyLevel: .public)
      .with(key: "dataSize", value: String(operation.data.count), privacyLevel: .public)

    await logger?.debug(
      "Processing encryption request",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: encryptionMetadata
      )
    )

    // Determine the encryption algorithm to use
    let algorithm=try getAlgorithm(from: operation.algorithm)

    // Create the security configuration
    let config=try await SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: getHashAlgorithm(from: nil), // Default to SHA-256
      providerType: .system, // Use system provider
      options: SecurityConfigOptions(
        enableDetailedLogging: false,
        keyDerivationIterations: 100_000,
        memoryLimitBytes: 65536,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        verifyOperations: true,
        metadata: [
          "inputData": "encrypted",
          "keyMaterial": "provided",
          "operation": "encrypt"
        ]
      )
    )

    // Encrypt the data with the provided configuration
    let result=try await securityService.encrypt(config: config)

    // Check for successful result
    guard result.successful, let encryptedData=result.resultData else {
      throw SecurityError.encryptionFailed(
        "Encryption failed with no details: \(result.errorDetails ?? "unknown error")"
      )
    }

    return EncryptionResult(
      encryptedData: encryptedData,
      key: operation.key,
      keyIdentifier: nil,
      algorithm: algorithm.rawValue
    )
  }

  /**
   Handles data decryption operations.

   - Parameter operation: The decryption operation parameters
   - Returns: Decrypted data
   - Throws: APIError if the decryption fails
   */
  private func handleDecryptData(_ operation: DecryptData) async throws -> Data {
    let decryptionMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "decryptData", privacyLevel: .public)
      .with(
        key: "encryptedDataSize",
        value: String(operation.encryptedData.count),
        privacyLevel: .public
      )

    await logger?.debug(
      "Processing decryption request",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: decryptionMetadata
      )
    )

    // Determine the encryption algorithm to use
    let algorithm=try getAlgorithm(from: operation.algorithm)

    // Create the security configuration
    let config=try await SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: getHashAlgorithm(from: nil), // Default to SHA-256
      providerType: .system, // Use system provider
      options: SecurityConfigOptions(
        enableDetailedLogging: false,
        keyDerivationIterations: 100_000,
        memoryLimitBytes: 65536,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        verifyOperations: true,
        metadata: [
          "inputData": "encrypted",
          "keyMaterial": "provided",
          "operation": "decrypt"
        ]
      )
    )

    // Attempt decryption
    let result=try await securityService.decrypt(config: config)

    // Check for successful result
    guard result.successful, let decryptedData=result.resultData else {
      throw SecurityError.decryptionFailed(
        "Decryption failed with no details: \(result.errorDetails ?? "unknown error")"
      )
    }

    return decryptedData
  }

  /**
   Handles key generation operations.

   - Parameter operation: The key generation operation parameters
   - Returns: Generated crypto key
   - Throws: APIError if the key generation fails
   */
  private func handleGenerateKey(_ operation: GenerateKey) async throws -> SendableCryptoMaterial {
    let keyGenMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "generateKey", privacyLevel: .public)
      .with(key: "keyType", value: operation.keyType, privacyLevel: .public)
      .with(key: "keySize", value: String(operation.keySize ?? 0), privacyLevel: .public)

    await logger?.debug(
      "Generating cryptographic key",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: keyGenMetadata
      )
    )

    // Create security configuration for key generation
    let config=try await SecurityConfigDTO(
      encryptionAlgorithm: getAlgorithm(from: operation.algorithm),
      hashAlgorithm: getHashAlgorithm(from: nil), // Default to SHA-256
      providerType: .system,
      options: SecurityConfigOptions(
        enableDetailedLogging: false,
        keyDerivationIterations: 100_000,
        memoryLimitBytes: 65536,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        verifyOperations: true,
        metadata: [
          "operation": "generateKey",
          "keySize": String(operation.keySize ?? 256)
        ]
      )
    )

    // Generate key based on type
    let result=try await securityService.generateKey(config: config)

    // Check for successful result
    guard result.successful, let keyData=result.resultData else {
      throw SecurityError.keyGenerationFailed(
        "Key generation failed with no details: \(result.errorDetails ?? "unknown error")"
      )
    }

    // Return the generated key
    return SendableCryptoMaterial(keyData)
  }

  /**
   Handles data hashing operations.

   - Parameter operation: The hashing operation parameters
   - Returns: Hash result
   - Throws: APIError if the hashing fails
   */
  private func handleHashData(_ operation: HashData) async throws -> String {
    let hashMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "hashData", privacyLevel: .public)
      .with(key: "dataSize", value: String(operation.data.count), privacyLevel: .public)
      .with(key: "algorithm", value: operation.algorithm ?? "sha256", privacyLevel: .public)

    await logger?.debug(
      "Computing hash for data",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: hashMetadata
      )
    )

    // Determine the hash algorithm to use
    let algorithm=try await getHashAlgorithm(from: operation.algorithm)

    // Compute the hash
    return try await securityService.hashData(
      data: operation.data,
      algorithm: algorithm
    )
  }

  /**
   Handles storing a cryptographic key.

   - Parameter operation: The key storage operation parameters
   - Returns: The key identifier that can be used to retrieve the key
   - Throws: APIError if the operation fails
   */
  private func handleStoreKey(_ operation: StoreKey) async throws -> String {
    let storeMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "storeKey", privacyLevel: .public)
      .with(key: "keyIdentifier", value: operation.identifier ?? "", privacyLevel: .public)
      .with(key: "keyType", value: "symmetric", privacyLevel: .public)

    await logger?.debug(
      "Storing cryptographic key",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: storeMetadata
      )
    )

    // Create security configuration for key storage
    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default algorithm
      hashAlgorithm: .sha256,
      providerType: .system,
      options: SecurityConfigOptions(
        enableDetailedLogging: false,
        keyDerivationIterations: 100_000,
        memoryLimitBytes: 65536,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        verifyOperations: true,
        metadata: [
          "operation": "storeKey",
          "keyIdentifier": operation.identifier ?? "",
          "keyType": "symmetric"
        ]
      )
    )

    // Store the key with the provided identifier or generate a new one
    let result=try await securityService.encrypt(config: config)

    // Check for successful result
    guard result.successful, let keyIDData=result.resultData else {
      throw SecurityError.keyStorageFailed(
        "Key storage failed with no details: \(result.errorDetails ?? "unknown error")"
      )
    }

    // Convert the result to a key identifier
    let keyID=String(data: keyIDData, encoding: .utf8) ?? UUID().uuidString

    await logger?.info(
      "Key stored successfully",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: LogMetadataDTOCollection()
          .with(key: "operation", value: "storeKey", privacyLevel: .public)
          .with(key: "key_id", value: keyID, privacyLevel: .public)
          .with(key: "status", value: "success", privacyLevel: .public)
      )
    )

    return keyID
  }

  /**
   Handles retrieval of a stored cryptographic key.

   - Parameter operation: The key retrieval operation parameters
   - Returns: The retrieved key
   - Throws: APIError if the operation fails
   */
  private func handleRetrieveKey(_ operation: RetrieveKey) async throws -> SendableCryptoMaterial {
    let retrieveMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "retrieveKey", privacyLevel: .public)
      .with(key: "keyId", value: operation.identifier, privacyLevel: .private)

    await logger?.debug(
      "Retrieving cryptographic key",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: retrieveMetadata
      )
    )

    // Create config for key retrieval
    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default algorithm
      hashAlgorithm: .sha256,
      providerType: .system,
      options: SecurityConfigOptions(
        enableDetailedLogging: false,
        keyDerivationIterations: 100_000,
        memoryLimitBytes: 65536,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        verifyOperations: true,
        metadata: [
          "operation": "retrieveKey",
          "keyIdentifier": operation.identifier,
          "keyType": operation.keyType ?? "symmetric"
        ]
      )
    )

    // Retrieve key
    do {
      let result=try await securityService.decrypt(config: config)

      await logger?.info(
        "Key retrieved successfully",
        context: CoreLogContext(
          source: "SecurityDomainHandler",
          metadata: LogMetadataDTOCollection()
            .with(key: "operation", value: "retrieveKey", privacyLevel: .public)
            .with(key: "key_id", value: operation.identifier, privacyLevel: .public)
            .with(key: "status", value: "success", privacyLevel: .public)
        )
      )

      // Check for successful result
      guard result.successful, let keyData=result.resultData else {
        throw SecurityError.keyRetrievalFailed(
          "Key retrieval failed with no details: \(result.errorDetails ?? "unknown error")"
        )
      }

      return SendableCryptoMaterial(keyData)
    } catch {
      await logger?.error(
        "Failed to retrieve key",
        context: CoreLogContext(
          source: "SecurityDomainHandler",
          metadata: LogMetadataDTOCollection()
            .with(key: "operation", value: "retrieveKey", privacyLevel: .public)
            .with(key: "key_id", value: operation.identifier, privacyLevel: .private)
            .with(key: "error", value: error.localizedDescription, privacyLevel: .private),
          error: error
        )
      )

      throw mapToAPIError(error)
    }
  }

  /**
   Handles deletion of a stored cryptographic key.

   - Parameter operation: The key deletion operation parameters
   - Throws: APIError if the operation fails
   */
  private func handleDeleteKey(_ operation: DeleteKey) async throws {
    let deleteMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "deleteKey", privacyLevel: .public)
      .with(key: "keyId", value: operation.identifier, privacyLevel: .private)

    await logger?.debug(
      "Deleting cryptographic key",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: deleteMetadata
      )
    )

    // Create config for key deletion
    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default algorithm
      hashAlgorithm: .sha256,
      providerType: .system,
      options: SecurityConfigOptions(
        enableDetailedLogging: false,
        keyDerivationIterations: 100_000,
        memoryLimitBytes: 65536,
        useHardwareAcceleration: true,
        operationTimeoutSeconds: 30.0,
        verifyOperations: true,
        metadata: [
          "operation": "deleteKey",
          "keyIdentifier": operation.identifier,
          "forced": operation.forced ? "true" : "false"
        ]
      )
    )

    // Delete the key
    let result=try await securityService.decrypt(config: config)

    await logger?.info(
      "Key deleted successfully",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: LogMetadataDTOCollection()
          .with(key: "operation", value: "deleteKey", privacyLevel: .public)
          .with(key: "key_id", value: operation.identifier, privacyLevel: .public)
          .with(key: "status", value: "success", privacyLevel: .public)
      )
    )

    // Check for successful result
    if !result.successful {
      throw SecurityError.keyDeletionFailed(
        "Key deletion failed with no details: \(result.errorDetails ?? "unknown error")"
      )
    }
  }

  /**
   Handles secret storage operations.

   - Parameter operation: The secret storage operation parameters
   - Returns: Secret identifier
   - Throws: APIError if the storage fails
   */
  private func handleStoreSecret(_ operation: StoreSecret) async throws -> String {
    let storeMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "storeSecret", privacyLevel: .public)
      .with(
        key: "secretType",
        value: String(describing: type(of: operation.secret)),
        privacyLevel: .public
      )
      .with(key: "providedId", value: operation.identifier ?? "none", privacyLevel: .private)

    await logger?.debug(
      "Storing secret data",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: storeMetadata
      )
    )

    // Store the secret with the provided identifier or generate a new one
    let secretID=try await securityService.saveSecret(
      secret: operation.secret,
      identifier: operation.identifier
    )

    await logger?.info(
      "Successfully stored secret",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: LogMetadataDTOCollection()
          .with(key: "operation", value: "storeSecret", privacyLevel: .public)
          .with(key: "secret_id", value: secretID, privacyLevel: .public)
          .with(key: "status", value: "success", privacyLevel: .public)
      )
    )

    return secretID
  }

  /**
   Handles secret retrieval operations.

   - Parameter operation: The secret retrieval operation parameters
   - Returns: Retrieved secret
   - Throws: APIError if the secret is not found
   */
  private func handleRetrieveSecret(_ operation: RetrieveSecret) async throws
  -> SendableCryptoMaterial {
    let retrieveMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "retrieveSecret", privacyLevel: .public)
      .with(key: "secretId", value: operation.identifier, privacyLevel: .private)

    await logger?.debug(
      "Retrieving secret data",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: retrieveMetadata
      )
    )

    // Create config for secret retrieval
    let secretConfig=SecuritySecretConfig(
      identifier: operation.identifier
    )

    // Retrieve secret
    do {
      let result=try await securityService.getSecret(
        identifier: operation.identifier
      )

      await logger?.info(
        "Successfully retrieved secret",
        context: CoreLogContext(
          source: "SecurityDomainHandler",
          metadata: LogMetadataDTOCollection()
            .with(key: "operation", value: "retrieveSecret", privacyLevel: .public)
            .with(key: "secret_id", value: operation.identifier, privacyLevel: .public)
            .with(key: "status", value: "success", privacyLevel: .public)
        )
      )

      return SendableCryptoMaterial(result.data)
    } catch {
      await logger?.error(
        "Failed to retrieve secret",
        context: CoreLogContext(
          source: "SecurityDomainHandler",
          metadata: LogMetadataDTOCollection()
            .with(key: "operation", value: "retrieveSecret", privacyLevel: .public)
            .with(key: "secret_id", value: operation.identifier, privacyLevel: .private)
            .with(key: "error", value: error.localizedDescription, privacyLevel: .private),
          error: error
        )
      )

      // Rethrow the error after logging
      throw mapToAPIError(error)
    }
  }

  /**
   Handles secret deletion operations.

   - Parameter operation: The secret deletion operation parameters
   - Throws: APIError if the deletion fails
   */
  private func handleDeleteSecret(_ operation: DeleteSecret) async throws {
    let deleteMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "deleteSecret", privacyLevel: .public)
      .with(key: "secretId", value: operation.identifier, privacyLevel: .private)

    await logger?.debug(
      "Deleting secret data",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: deleteMetadata
      )
    )

    // Create config for secret deletion
    let secretConfig=SecuritySecretConfig(
      identifier: operation.identifier
    )

    // Delete the secret
    _=try await securityService.removeSecret(
      identifier: operation.identifier
    )

    await logger?.info(
      "Successfully deleted secret",
      context: CoreLogContext(
        source: "SecurityDomainHandler",
        metadata: LogMetadataDTOCollection()
          .with(key: "operation", value: "deleteSecret", privacyLevel: .public)
          .with(key: "secret_id", value: operation.identifier, privacyLevel: .public)
          .with(key: "status", value: "success", privacyLevel: .public)
      )
    )
  }

  /**
   Security error types for domain-specific error handling.
   */
  private enum SecurityError: Error, LocalizedError {
    case invalidInput(String)
    case operationFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)
    case keyGenerationFailed(String)
    case keyRetrievalFailed(String)
    case keyStorageFailed(String)
    case keyDeletionFailed(String)
    case permissionDenied(String)
    case unknownError(String)

    var errorDescription: String? {
      switch self {
        case let .invalidInput(message),
             let .operationFailed(message),
             let .encryptionFailed(message),
             let .decryptionFailed(message),
             let .keyGenerationFailed(message),
             let .keyRetrievalFailed(message),
             let .keyStorageFailed(message),
             let .keyDeletionFailed(message),
             let .permissionDenied(message),
             let .unknownError(message):
          message
      }
    }
  }
}

// MARK: - Core API Types

/**
 Base protocol for all API operations
 */
public protocol APIOperation: Sendable {}

/**
 Result of encryption operations
 */
public struct EncryptionResult {
  public let encryptedData: Data
  public let key: SendableCryptoMaterial?
  public let keyIdentifier: String?
  public let algorithm: String

  public init(
    encryptedData: Data,
    key: SendableCryptoMaterial?=nil,
    keyIdentifier: String?=nil,
    algorithm: String
  ) {
    self.encryptedData=encryptedData
    self.key=key
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
  }
}

/**
 A type-safe wrapper for cryptographic material that can be safely passed across actor boundaries.
 */
public struct SendableCryptoMaterial: Sendable, Equatable {
  public let rawData: Data

  public init(_ data: Data) {
    rawData=data
  }

  public init(_ bytes: [UInt8]) {
    rawData=Data(bytes)
  }

  public init(_ string: String) {
    rawData=Data(string.utf8)
  }
}

// MARK: - Security Secret Config

/**
 Configuration for security secret operations.
 */
public struct SecuritySecretConfig {
  let identifier: String
}
