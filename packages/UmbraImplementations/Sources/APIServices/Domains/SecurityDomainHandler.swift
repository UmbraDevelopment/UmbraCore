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
  private let logger: LoggingProtocol?

  /**
   Initialises a new security domain handler.

   - Parameters:
      - service: The security service for cryptographic operations that uses actor-based SecureStorage
      - logger: Optional logger for privacy-aware operation recording

   The security service must use actor-based SecureStorage internally to ensure
   proper isolation and thread safety for all cryptographic operations.
   */
  public init(service: any SecurityProviderProtocol, logger: LoggingProtocol?=nil) {
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
    let startMetadata=PrivacyMetadata([
      "operation": PrivacyMetadataValue(value: operationName, privacy: .public),
      "event": PrivacyMetadataValue(value: "start", privacy: .public)
    ])

    await logger?.info(
      "Starting security operation",
      metadata: startMetadata,
      source: "SecurityDomainHandler"
    )

    do {
      // Execute the appropriate operation based on type
      let result=try await executeSecurityOperation(operation)

      // Log success
      let successMetadata=PrivacyMetadata([
        "operation": PrivacyMetadataValue(value: operationName, privacy: .public),
        "event": PrivacyMetadataValue(value: "success", privacy: .public),
        "status": PrivacyMetadataValue(value: "completed", privacy: .public)
      ])

      await logger?.info(
        "Security operation completed successfully",
        metadata: successMetadata,
        source: "SecurityDomainHandler"
      )

      return result
    } catch {
      // Log failure with privacy-aware error details
      let errorMetadata=PrivacyMetadata([
        "operation": PrivacyMetadataValue(value: operationName, privacy: .public),
        "event": PrivacyMetadataValue(value: "failure", privacy: .public),
        "status": PrivacyMetadataValue(value: "failed", privacy: .public),
        "error": PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)
      ])

      await logger?.error(
        "Security operation failed",
        metadata: errorMetadata,
        source: "SecurityDomainHandler"
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
        case let .cryptographicError(message):
          return APIError.operationFailed(
            message: "Cryptographic operation failed: \(message)",
            code: "CRYPTO_ERROR"
          )
        case let .keyNotFound(message):
          return APIError.resourceNotFound(
            message: "Security key not found: \(message)",
            identifier: "unknown_key"
          )
        case let .permissionDenied(message):
          return APIError.authenticationFailed(
            "Access denied to security resource: \(message)"
          )
        case let .operationFailed(message):
          return APIError.operationFailed(
            message: "Security operation failed: \(message)",
            code: "SECURITY_OPERATION_FAILED"
          )
        case let .secretNotFound(message):
          return APIError.resourceNotFound(
            message: "Security secret not found: \(message)",
            identifier: "unknown_secret"
          )
        case let .keyStorageError(message):
          return APIError.operationFailed(
            message: "Key storage failed: \(message)",
            code: "KEY_STORAGE_ERROR"
          )
        case let .secureStorageError(message):
          return APIError.operationFailed(
            message: "Secure storage operation failed: \(message)",
            code: "SECURE_STORAGE_ERROR"
          )
        case let .actorIsolationError(message):
          return APIError.operationFailed(
            message: "Actor isolation violation: \(message)",
            code: "ACTOR_ISOLATION_ERROR"
          )
      }
    }

    // Default to a generic operation failed error
    return APIError.operationFailed(
      message: error.localizedDescription,
      code: "SECURITY_ERROR",
      underlyingError: error
    )
  }

  /**
   Converts a string algorithm identifier to a concrete EncryptionAlgorithm.

   - Parameter algorithmString: String representation of the algorithm
   - Returns: The appropriate EncryptionAlgorithm type
   - Throws: SecurityError.invalidInput if an invalid algorithm is specified
   */
  private func getAlgorithm(from algorithmString: String?) throws -> EncryptionAlgorithm {
    guard let algorithmStr=algorithmString else {
      return .aes128GCM // Default to AES-GCM if not specified
    }

    switch algorithmStr.lowercased() {
      case "aes", "aes256", "aes-256", "aes-gcm", "aes256-gcm", "aesgcm":
        return .aes128GCM
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
  private func getHashAlgorithm(from algorithmString: String?) throws -> HashAlgorithm {
    guard let algorithmStr=algorithmString else {
      // Default to SHA-256 if no algorithm specified
      return .sha256
    }

    switch algorithmStr.lowercased() {
      case "sha1", "sha-1":
        // SHA-1 is deprecated, use SHA-256 as a secure alternative
        await logger?.warning(
          "SHA-1 is deprecated and was requested, using SHA-256 instead",
          metadata: PrivacyMetadata([
            "requestedAlgorithm": PrivacyMetadataValue(value: "SHA-1", privacy: .public),
            "usingAlgorithm": PrivacyMetadataValue(value: "SHA-256", privacy: .public)
          ]),
          source: "SecurityDomainHandler"
        )
        return .sha256
      case "sha256", "sha-256":
        return .sha256
      case "sha384", "sha-384":
        // SHA-384 is not directly supported, use SHA-512 instead
        await logger?.warning(
          "SHA-384 is not directly supported, using SHA-512 instead",
          metadata: PrivacyMetadata([
            "requestedAlgorithm": PrivacyMetadataValue(value: "SHA-384", privacy: .public),
            "usingAlgorithm": PrivacyMetadataValue(value: "SHA-512", privacy: .public)
          ]),
          source: "SecurityDomainHandler"
        )
        return .sha512
      case "sha512", "sha-512":
        return .sha512
      case "blake2b", "blake2":
        return .blake2b
      case _:
        if algorithmStr.isEmpty {
          // Default to SHA-256 for empty string
          await logger?.warning(
            "Empty hash algorithm specified, using SHA-256 as default",
            metadata: PrivacyMetadata(),
            source: "SecurityDomainHandler"
          )
          return .sha256
        }
        throw SecurityError.invalidInput("Unsupported hash algorithm: \(algorithmString ?? "nil")")
    }
  }

  /**
   Security error types for domain-specific error handling.
   */
  private enum SecurityError: Error, LocalizedError {
    case invalidInput(String)
    case cryptographicError(String)
    case keyNotFound(String)
    case permissionDenied(String)
    case operationFailed(String)
    case secretNotFound(String)
    case keyStorageError(String)
    case hashOperationFailed(String)
    case secureStorageError(String)
    case actorIsolationError(String)

    var errorDescription: String? {
      switch self {
        case let .invalidInput(message),
             let .cryptographicError(message),
             let .keyNotFound(message),
             let .permissionDenied(message),
             let .operationFailed(message),
             let .secretNotFound(message),
             let .keyStorageError(message),
             let .hashOperationFailed(message),
             let .secureStorageError(message),
             let .actorIsolationError(message):
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
 API error type for standardised error handling across the API service
 */
public enum APIError: Error, Sendable {
  case operationNotSupported(message: String, code: String)
  case invalidOperation(message: String, code: String)
  case operationFailed(error: Error, code: String)
  case authenticationFailed(message: String, code: String)
  case resourceNotFound(message: String, identifier: String)
  case operationCancelled(message: String, code: String)
  case operationTimedOut(message: String, timeoutSeconds: Int, code: String)
  case serviceUnavailable(message: String, code: String)
  case invalidState(message: String, details: String, code: String)
  case conflict(message: String, details: String, code: String)
  case rateLimitExceeded(message: String, resetTime: String?, code: String)
}

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

// MARK: - Protocol Conformance

/**
 Protocol defining a security-related API operation
 */
public protocol SecurityAPIOperation: APIOperation {}

/**
 Operation for encrypting data
 */
public struct EncryptData: SecurityAPIOperation {
  public let data: Data
  public let key: SendableCryptoMaterial?
  public let keyIdentifier: String?
  public let algorithm: String?
  public let options: [String: String]?
  public let storeKey: Bool

  public init(
    data: Data,
    key: SendableCryptoMaterial?=nil,
    keyIdentifier: String?=nil,
    algorithm: String?=nil,
    options: [String: String]?=nil,
    storeKey: Bool=false
  ) {
    self.data=data
    self.key=key
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
    self.options=options
    self.storeKey=storeKey
  }
}

/**
 Operation for decrypting data
 */
public struct DecryptData: SecurityAPIOperation {
  public let encryptedData: SendableCryptoMaterial
  public let key: SendableCryptoMaterial?
  public let keyIdentifier: String?
  public let algorithm: String?
  public let options: [String: String]?

  public init(
    encryptedData: SendableCryptoMaterial,
    key: SendableCryptoMaterial?=nil,
    keyIdentifier: String?=nil,
    algorithm: String?=nil,
    options: [String: String]?=nil
  ) {
    self.encryptedData=encryptedData
    self.key=key
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
    self.options=options
  }
}

/**
 Operation for generating a cryptographic key
 */
public struct GenerateKey: SecurityAPIOperation {
  public let keyLength: Int?
  public let keyType: String?
  public let algorithm: String?
  public let options: [String: String]?

  public init(
    keyLength: Int?=nil,
    keyType: String?=nil,
    algorithm: String?=nil,
    options: [String: String]?=nil
  ) {
    self.keyLength=keyLength
    self.keyType=keyType
    self.algorithm=algorithm
    self.options=options
  }
}

/**
 Operation for retrieving a stored key
 */
public struct RetrieveKey: SecurityAPIOperation {
  public let keyIdentifier: String

  public init(keyIdentifier: String) {
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation for storing a cryptographic key
 */
public struct StoreKey: SecurityAPIOperation {
  public let key: SendableCryptoMaterial
  public let keyIdentifier: String?
  public let attributes: [String: String]?

  public init(
    key: SendableCryptoMaterial,
    keyIdentifier: String?=nil,
    attributes: [String: String]?=nil
  ) {
    self.key=key
    self.keyIdentifier=keyIdentifier
    self.attributes=attributes
  }
}

/**
 Operation for deleting a stored key
 */
public struct DeleteKey: SecurityAPIOperation {
  public let keyIdentifier: String

  public init(keyIdentifier: String) {
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation for hashing data
 */
public struct HashData: SecurityAPIOperation {
  public let data: SendableCryptoMaterial
  public let algorithm: String?
  public let options: [String: String]?

  public init(
    data: SendableCryptoMaterial,
    algorithm: String?=nil,
    options: [String: String]?=nil
  ) {
    self.data=data
    self.algorithm=algorithm
    self.options=options
  }
}

/**
 Operation for storing a secret
 */
public struct StoreSecret: SecurityAPIOperation {
  public let secret: SendableCryptoMaterial
  public let identifier: String?
  public let service: String
  public let attributes: [String: String]?

  public init(
    secret: SendableCryptoMaterial,
    identifier: String?=nil,
    service: String,
    attributes: [String: String]?=nil
  ) {
    self.secret=secret
    self.identifier=identifier
    self.service=service
    self.attributes=attributes
  }
}

/**
 Operation for retrieving a stored secret
 */
public struct RetrieveSecret: SecurityAPIOperation {
  public let identifier: String
  public let service: String

  public init(identifier: String, service: String) {
    self.identifier=identifier
    self.service=service
  }
}

/**
 Operation for deleting a stored secret
 */
public struct DeleteSecret: SecurityAPIOperation {
  public let identifier: String
  public let service: String

  public init(identifier: String, service: String) {
    self.identifier=identifier
    self.service=service
  }
}

/**
 Result type for key generation operations
 */
public struct KeyGenerationResult {
  public let key: SendableCryptoMaterial
  public let keyIdentifier: String?
  public let keyType: String

  public init(
    key: SendableCryptoMaterial,
    keyIdentifier: String?=nil,
    keyType: String="symmetric"
  ) {
    self.key=key
    self.keyIdentifier=keyIdentifier
    self.keyType=keyType
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
