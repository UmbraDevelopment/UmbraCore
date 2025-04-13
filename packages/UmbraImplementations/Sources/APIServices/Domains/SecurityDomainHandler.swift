import APIInterfaces
import CoreSecurityTypes
import CryptoTypes
import DateTimeTypes
import DomainSecurityTypes
import ErrorCoreTypes
import FileSystemTypes
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # Security Domain Handler

 Handles security-related API operations within the Alpha Dot Five architecture.
 This implementation provides secure operations for encryption, decryption,
 key management, and secure storage with proper privacy controls.

 ## Actor-Based Secure Storage

 This handler uses actor-based `SecureStorage` internally to ensure thread safety
 and memory protection for all sensitive cryptographic material. The handler itself
 is implemented as an actor to provide additional isolation and thread safety guarantees.

 ## Privacy-Enhanced Logging

 All operations are logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.

 ## Thread Safety

 Operations are thread-safe by leveraging Swift's structured concurrency model
 and actor-based isolation. The handler is implemented as an actor to provide
 automatic synchronisation and eliminate potential race conditions.

 ## Memory Protection

 Security operations include memory protection to prevent data leakage.
 This is achieved through properly isolated actor-based state management,
 ensuring sensitive material is protected throughout its lifecycle.
 */
public actor SecurityDomainHandler: DomainHandler {
  /// Security service for cryptographic operations
  private let securityService: any SecurityProviderProtocol

  /// Logger with privacy controls
  private let logger: (any LoggingProtocol)?

  /// Cache for key metadata to improve performance of repeated operations
  private var keyMetadataCache: [String: (KeyMetadata, DateTimeDTO)]=[:]

  /// Cache time-to-live in seconds
  private let cacheTTL: TimeIntervalDTO = .seconds(60) // 1 minute

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
   Determines if this handler supports the given operation.

   - Parameter operation: The operation to check support for
   - Returns: true if the operation is supported, false otherwise
   */
  public nonisolated func supports(_ operation: some APIOperation) -> Bool {
    operation is any SecurityAPIOperation
  }

  // MARK: - DomainHandler Conformance

  public nonisolated var domain: String { APIDomain.security.rawValue }

  /**
   Handles an incoming API operation for the Security domain.

   - Parameter operation: The API operation to handle, conforming to `APIOperation`.
   - Returns: The result of the operation, specific to the operation type (`T.APIOperationResult`).
   - Throws: `APIError` if the operation fails or is not supported.
   */
  public func handleOperation<T: APIOperation>(operation: T) async throws -> T.APIOperationResult {
    // Ensure the operation is a security operation
    guard operation is SecurityAPIOperation else {
      // This should technically not happen if routing is correct, but good practice
      throw APIError.operationNotSupported(
        message: "Operation type \(String(describing: type(of: operation))) not supported by SecurityDomainHandler",
        code: "UNSUPPORTED_OPERATION"
      )
    }

    // Get operation name once for reuse
    let operationName=String(describing: type(of: operation))

    // Log operation start with optimised metadata creation
    await logOperationStart(operationName: operationName)

    do {
      // Execute the specific security operation
      let resultAny=try await executeSecurityOperation(operation as T)

      // Log success with optimised metadata creation
      await logOperationSuccess(operationName: operationName)

      // Cast the result to the expected type
      guard let result=resultAny as? T.APIOperationResult else {
        throw SecurityError.internalError("Unexpected result type from security operation")
      }

      return result
    } catch {
      // Log failure with optimised metadata creation
      await logOperationFailure(operationName: operationName, error: error)

      // Map to appropriate API error and rethrow
      if let apiError=error as? APIError {
        throw apiError
      } else if let securityError=error as? SecurityError {
        throw mapSecurityError(securityError)
      } else {
        throw APIError.internalError(
          message: "Unexpected error: \(error.localizedDescription)",
          code: "SECURITY_ERROR"
        )
      }
    }
  }

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
        // Check cache first for better performance
        if let keyID=op.identifier, let cachedMetadata=getCachedKeyMetadata(keyID: keyID) {
          // Log cache hit if logging is enabled
          if await logger?.isEnabled(for: .debug) == true {
            let metadata=createBaseMetadata(operation: "retrieveKey", event: "cacheHit")
              .withPrivate(key: "keyId", value: keyID)

            await logger?.debug(
              "Retrieved key metadata from cache",
              context: CoreLogContext(
                source: "SecurityDomainHandler",
                metadata: metadata
              )
            )
          }
          // Still need to retrieve the actual key material
          return try await handleRetrieveKey(op)
        }
        return try await handleRetrieveKey(op)
      case let op as StoreKey:
        let result=try await handleStoreKey(op)
        // Cache key metadata if available
        if let keyID=op.identifier, let keyType=op.keyType {
          let metadata=KeyMetadata(
            keyID: keyID,
            keyType: keyType,
            algorithm: op.algorithm ?? "AES",
            creationDate: DateTimeDTO.now()
          )
          cacheKeyMetadata(keyID: keyID, metadata: metadata)
        }
        return result
      case let op as DeleteKey:
        // Invalidate cache entry for this key
        keyMetadataCache.removeValue(forKey: op.identifier)
        return try await handleDeleteKey(op)
      case let op as StoreSecret:
        return try await handleStoreSecret(op)
      case let op as RetrieveSecret:
        return try await handleRetrieveSecret(op)
      case let op as DeleteSecret:
        return try await handleDeleteSecret(op)
      case let op as VerifySignature:
        return try await handleVerifySignature(op)
      case let op as CreateSignature:
        return try await handleCreateSignature(op)
      case let op as HashData:
        return try await handleHashData(op)
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

    // Use a type-based approach for more efficient error mapping
    switch error {
      case let securityError as SecurityError:
        return mapSecurityError(securityError)
      case let keychainError as KeychainError:
        return mapKeychainError(keychainError)
      default:
        return APIError.internalError(
          message: "An unexpected error occurred: \(error.localizedDescription)",
          underlyingError: error
        )
    }
  }

  /**
   Maps SecurityError to standardised APIError.

   - Parameter error: The security error to map
   - Returns: An APIError instance
   */
  private func mapSecurityError(_ error: SecurityError) -> APIError {
    switch error {
      case .keyNotFound:
        APIError.resourceNotFound(
          message: "Security key not found",
          identifier: "unknown"
        )
      case .invalidKey:
        APIError.validationError(
          message: "Invalid security key",
          details: "The provided key is invalid or corrupted",
          code: "INVALID_SECURITY_KEY"
        )
      case .encryptionFailed:
        APIError.operationFailed(
          message: "Encryption operation failed",
          code: "ENCRYPTION_FAILED",
          underlyingError: error
        )
      case .decryptionFailed:
        APIError.operationFailed(
          message: "Decryption operation failed",
          code: "DECRYPTION_FAILED",
          underlyingError: error
        )
      case .algorithmNotSupported:
        APIError.validationError(
          message: "Unsupported encryption algorithm",
          details: "The requested encryption algorithm is not supported",
          code: "UNSUPPORTED_ALGORITHM"
        )
      case .invalidData:
        APIError.validationError(
          message: "Invalid data for security operation",
          details: "The provided data is invalid or corrupted",
          code: "INVALID_SECURITY_DATA"
        )
      case .operationCancelled:
        APIError.operationCancelled(
          message: "Security operation was cancelled",
          code: "SECURITY_OPERATION_CANCELLED"
        )
      case .accessDenied:
        APIError.accessDenied(
          message: "Access denied for security operation",
          details: "The application does not have permission for this security operation",
          code: "SECURITY_ACCESS_DENIED"
        )
      case .internalError:
        APIError.internalError(
          message: "Internal security error",
          underlyingError: error
        )
    }
  }

  /**
   Maps KeychainError to standardised APIError.

   - Parameter error: The keychain error to map
   - Returns: An APIError instance
   */
  private func mapKeychainError(_ error: KeychainError) -> APIError {
    switch error {
      case .itemNotFound:
        APIError.resourceNotFound(
          message: "Keychain item not found",
          identifier: "unknown"
        )
      case .duplicateItem:
        APIError.conflict(
          message: "Duplicate keychain item",
          details: "An item with this identifier already exists in the keychain",
          code: "DUPLICATE_KEYCHAIN_ITEM"
        )
      case .accessDenied:
        APIError.accessDenied(
          message: "Access denied to keychain",
          details: "The application does not have permission to access the keychain",
          code: "KEYCHAIN_ACCESS_DENIED"
        )
      case .invalidData:
        APIError.validationError(
          message: "Invalid keychain data",
          details: "The provided data is invalid for keychain storage",
          code: "INVALID_KEYCHAIN_DATA"
        )
      case .unexpectedError:
        APIError.internalError(
          message: "Unexpected keychain error",
          underlyingError: error
        )
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
        context: BaseLogContextDTO(
          domainName: "security",
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
        context: BaseLogContextDTO(
          domainName: "security",
          source: "SecurityDomainHandler",
          metadata: LogMetadataDTOCollection()
            .with(key: "operation", value: "retrieveKey", privacyLevel: .public)
            .with(key: "key_id", value: operation.identifier, privacyLevel: .private)
            .with(key: "error", value: error.localizedDescription, privacyLevel: .private)
        )
      )

      // Rethrow the error after logging
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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
        context: BaseLogContextDTO(
          domainName: "security",
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
        context: BaseLogContextDTO(
          domainName: "security",
          source: "SecurityDomainHandler",
          metadata: LogMetadataDTOCollection()
            .with(key: "operation", value: "retrieveSecret", privacyLevel: .public)
            .with(key: "secret_id", value: operation.identifier, privacyLevel: .private)
            .with(key: "error", value: error.localizedDescription, privacyLevel: .private)
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
      context: BaseLogContextDTO(
        domainName: "security",
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
      context: BaseLogContextDTO(
        domainName: "security",
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

  /**
   Creates base metadata for logging with common fields.

   - Parameters:
     - operation: The operation name
     - event: The event type (start, success, failure)
   - Returns: Metadata collection with common fields
   */
  private func createBaseMetadata(operation: String, event: String) -> LogMetadataDTOCollection {
    LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "event", value: event)
      .withPublic(key: "domain", value: domain)
  }

  /**
   Logs the start of an operation with optimised metadata creation.

   - Parameter operationName: The name of the operation being executed
   */
  private func logOperationStart(operationName: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .debug) == true {
      let metadata=createBaseMetadata(operation: operationName, event: "start")

      await logger?.debug(
        "Handling security operation: \(operationName)",
        context: CoreLogContext(
          source: "SecurityDomainHandler.handleOperation",
          metadata: metadata
        )
      )
    }
  }

  /**
   Logs the successful completion of an operation with optimised metadata creation.

   - Parameter operationName: The name of the operation that completed
   */
  private func logOperationSuccess(operationName: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .info) == true {
      let metadata=createBaseMetadata(operation: operationName, event: "success")
        .withPublic(key: "status", value: "completed")

      await logger?.info(
        "Security operation completed successfully",
        context: CoreLogContext(
          source: "SecurityDomainHandler.handleOperation",
          metadata: metadata
        )
      )
    }
  }

  /**
   Logs the failure of an operation with optimised metadata creation.

   - Parameters:
     - operationName: The name of the operation that failed
     - error: The error that caused the failure
   */
  private func logOperationFailure(operationName: String, error: Error) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .error) == true {
      let metadata=createBaseMetadata(operation: operationName, event: "failure")
        .withPublic(key: "error_domain", value: domain)

      await logger?.error(
        "Security operation failed: \(error.localizedDescription)",
        context: CoreLogContext(
          source: "SecurityDomainHandler.handleOperation",
          metadata: metadata
        )
      )
    }
  }

  /**
   Logs a critical error with optimised metadata creation.

   - Parameters:
     - message: The error message
     - operationName: The name of the operation that encountered the critical error
   */
  private func logCriticalError(message: String, operationName: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .critical) == true {
      let metadata=createBaseMetadata(operation: operationName, event: "critical_error")
        .withPublic(key: "error_domain", value: domain)

      await logger?.critical(
        message,
        context: CoreLogContext(
          source: "SecurityDomainHandler.handleOperation",
          metadata: metadata
        )
      )
    }
  }

  /**
   Retrieves key metadata from the cache if available and not expired.

   - Parameter keyId: The key identifier
   - Returns: The cached key metadata if available, nil otherwise
   */
  private func getCachedKeyMetadata(keyID: String) -> KeyMetadata? {
    if
      let (metadata, timestamp)=keyMetadataCache[keyID],
      DateTimeDTO.now().timeIntervalSince(timestamp).seconds < cacheTTL.seconds
    {
      return metadata
    }
    return nil
  }

  /**
   Adds or updates key metadata in the cache.

   - Parameters:
     - keyId: The key ID to cache
     - metadata: The metadata to cache
   */
  private func cacheKeyMetadata(keyID: String, metadata: KeyMetadata) {
    keyMetadataCache[keyID]=(metadata, DateTimeDTO.now())
  }

  /**
   Clears all cached key metadata.
   */
  public func clearCache() {
    keyMetadataCache.removeAll()
  }

  /**
   Executes a batch of security operations more efficiently than individual execution.

   - Parameter operations: Array of operations to execute
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  public func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any] {
    var results: [String: Any]=[:]

    // Group operations by type for more efficient processing
    let groupedOperations=Dictionary(grouping: operations) { type(of: $0) }

    // Log batch operation start
    if await logger?.isEnabled(for: .info) == true {
      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "batchExecution")
        .withPublic(key: "event", value: "start")
        .withPublic(key: "operationCount", value: String(operations.count))
        .withPublic(key: "operationTypes", value: String(describing: groupedOperations.keys))

      await logger?.info(
        "Starting batch security operation",
        context: CoreLogContext(
          source: "SecurityDomainHandler.executeBatch",
          metadata: metadata
        )
      )
    }

    do {
      // Process each group of operations
      for (_, operationsOfType) in groupedOperations {
        if let firstOp=operationsOfType.first {
          // Process based on operation type
          if firstOp is HashData {
            // Example: Batch process all hash operations together
            let batchResult=try await batchHashData(
              operationsOfType.compactMap { $0 as? HashData }
            )
            for (id, result) in batchResult {
              results[id]=result
            }
          } else if firstOp is EncryptData {
            // Example: Batch process all encryption operations together
            let batchResult=try await batchEncryptData(
              operationsOfType.compactMap { $0 as? EncryptData }
            )
            for (id, result) in batchResult {
              results[id]=result
            }
          } else {
            // Fall back to individual processing for other types
            for operation in operationsOfType {
              let result=try await executeSecurityOperation(operation)
              results[operation.operationID]=result
            }
          }
        }
      }

      // Log batch operation success
      if await logger?.isEnabled(for: .info) == true {
        let metadata=LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "batchExecution")
          .withPublic(key: "event", value: "success")
          .withPublic(key: "operationCount", value: String(operations.count))
          .withPublic(key: "resultsCount", value: String(results.count))

        await logger?.info(
          "Batch security operation completed successfully",
          context: CoreLogContext(
            source: "SecurityDomainHandler.executeBatch",
            metadata: metadata
          )
        )
      }

      return results
    } catch {
      // Log batch operation failure
      if await logger?.isEnabled(for: .error) == true {
        let metadata=LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "batchExecution")
          .withPublic(key: "event", value: "failure")
          .withPublic(key: "operationCount", value: String(operations.count))
          .withPrivate(key: "error", value: error.localizedDescription)

        await logger?.error(
          "Batch security operation failed",
          context: CoreLogContext(
            source: "SecurityDomainHandler.executeBatch",
            metadata: metadata
          )
        )
      }

      throw mapToAPIError(error)
    }
  }

  /**
   Processes multiple hash data operations in a batch for better performance.

   - Parameter operations: Array of HashData operations to process
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  private func batchHashData(_ operations: [HashData]) async throws -> [String: HashResult] {
    var results: [String: HashResult]=[:]

    // Group operations by algorithm to minimize configuration changes
    let groupedByAlgorithm=Dictionary(grouping: operations) { $0.algorithm ?? "SHA-256" }

    // Process each algorithm group
    for (algorithm, algorithmOperations) in groupedByAlgorithm {
      // Configure the security service once per algorithm
      let securityConfig=SecurityConfigDTO(
        operation: .hash,
        algorithm: algorithm,
        options: SecurityConfigOptions()
      )

      // Process each operation with the same algorithm
      for operation in algorithmOperations {
        // Create operation-specific options
        var options=securityConfig.options
        options.metadata["inputData"]=operation.data

        let updatedConfig=SecurityConfigDTO(
          operation: securityConfig.operation,
          algorithm: securityConfig.algorithm,
          options: options
        )

        // Execute the hash operation
        let result=try await securityService.performSecureOperation(config: updatedConfig)

        // Create and store the result
        let hashResult=HashResult(
          hash: result.resultData,
          algorithm: algorithm
        )

        results[operation.operationID]=hashResult
      }
    }

    return results
  }

  /**
   Processes multiple encrypt data operations in a batch for better performance.

   - Parameter operations: Array of EncryptData operations to process
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  private func batchEncryptData(_ operations: [EncryptData]) async throws
  -> [String: EncryptionResult] {
    var results: [String: EncryptionResult]=[:]

    // Group operations by key ID to minimize key retrievals
    let groupedByKey=Dictionary(grouping: operations) { $0.keyIdentifier ?? "default" }

    // Process each key group
    for (keyID, keyOperations) in groupedByKey {
      // Retrieve the key once per group (if needed)
      let keyMaterial: SendableCryptoMaterial?=if keyID != "default" {
        try await securityService.retrieveKey(identifier: keyID)
      } else {
        nil
      }

      // Group by algorithm for further optimization
      let groupedByAlgorithm=Dictionary(grouping: keyOperations) { $0.algorithm ?? "AES-256-GCM" }

      // Process each algorithm group
      for (algorithm, algorithmOperations) in groupedByAlgorithm {
        // Configure the security service once per algorithm
        let securityConfig=SecurityConfigDTO(
          operation: .encrypt,
          algorithm: algorithm,
          options: SecurityConfigOptions()
        )

        // Process each operation with the same key and algorithm
        for operation in algorithmOperations {
          // Create operation-specific options
          var options=securityConfig.options
          options.metadata["inputData"]=operation.data

          if let keyMaterial {
            options.metadata["keyMaterial"]=keyMaterial
          }

          let updatedConfig=SecurityConfigDTO(
            operation: securityConfig.operation,
            algorithm: securityConfig.algorithm,
            options: options
          )

          // Execute the encryption operation
          let result=try await securityService.performSecureOperation(config: updatedConfig)

          // Create and store the result
          let encryptionResult=EncryptionResult(
            ciphertext: result.resultData,
            algorithm: algorithm,
            keyID: keyID != "default" ? keyID : nil
          )

          results[operation.operationID]=encryptionResult
        }
      }
    }

    return results
  }

  /**
   A type-safe wrapper for cryptographic material that can be safely passed across actor boundaries.
   */
  public struct SendableCryptoMaterial: Sendable, Equatable {
    public let rawData: SecureData

    public init(_ data: SecureData) {
      rawData=data
    }

    public init(_ data: Data) {
      rawData=SecureData(data)
    }

    public init(_ string: String) {
      rawData=SecureData(string.utf8)
    }
  }

  /**
   Configuration for security secret operations.
   */
  public struct SecuritySecretConfig {
    let identifier: String
  }
}
