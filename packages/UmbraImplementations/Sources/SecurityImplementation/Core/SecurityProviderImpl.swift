import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # Core Security Provider Service

 Actor-based implementation of the SecurityProviderProtocol, providing
 a secure interface to all cryptographic and key management services at the core infrastructure level.

 ## Concurrency

 Uses Swift's actor model to ensure thread safety for all security operations,
 preventing data races and ensuring security invariants are maintained.

 ## Security

 Centralises access control, encryption, signing, and key management through
 a unified interface with comprehensive logging and error handling.
 */
// Using @preconcurrency to resolve protocol conformance issues with isolated methods
@preconcurrency
public actor CoreSecurityProviderService: SecurityProviderProtocol {
  // MARK: - Dependencies

  /**
   The cryptographic service used for operations

   Required by the SecurityProviderProtocol
   */
  public let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The key management service used for key operations

   Required by the SecurityProviderProtocol
   */
  public let keyManager: KeyManagementProtocol

  /**
   The logger instance for recording operation details
   */
  let logger: LoggingInterfaces.LoggingProtocol

  // MARK: - Service Components

  /**
   The encryption service for handling encryption/decryption operations
   */
  private let encryptionService: EncryptionService

  /**
   The signature service for handling sign/verify operations
   */
  private let signatureService: SignatureService

  /**
   The secure storage service for handling key persistence
   */
  private let storageService: SecureStorageService

  /**
   Initializes the security provider with all required services.

   - Parameters:
     - cryptoService: Service for cryptographic operations
     - keyManager: Service for key management operations
     - logger: Service for logging operations
   */
  public init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    self.keyManager=keyManager
    self.logger=logger

    // Initialize component services
    encryptionService=EncryptionService(
      keyManager: keyManager,
      cryptoService: cryptoService,
      logger: logger
    )

    signatureService=SignatureService(
      keyManager: keyManager,
      cryptoService: cryptoService,
      logger: logger
    )

    storageService=SecureStorageService(
      keyManager: keyManager,
      cryptoService: cryptoService,
      logger: logger
    )
  }

  // MARK: - SecurityProviderProtocol Implementation

  /**
   Provides access to the cryptographic service.

   - Returns: The cryptographic service instance
   */
  public func cryptoService() async -> SecurityCoreInterfaces.CryptoServiceProtocol {
    cryptoService
  }

  /**
   Provides access to the key management service.

   - Returns: The key management service instance
   */
  public func keyManager() async -> KeyManagementProtocol {
    keyManager
  }

  /**
   Encrypts data with the specified configuration.

   Delegates to the encryption service for implementation.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await encryptionService.encrypt(config: config)
  }

  /**
   Decrypts data with the specified configuration.

   Delegates to the encryption service for implementation.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await encryptionService.decrypt(config: config)
  }

  /**
   Generates a cryptographic key with the specified configuration.

   Delegates to the key management service for implementation.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Log the operation
    await logger.info(
      "Generating cryptographic key",
      metadata: ["keyType": config.keyType.rawValue],
      source: "CoreSecurityProvider"
    )

    // Process the request through the key management service
    let result=try await keyManager.generateKey(
      type: config.keyType,
      size: config.keySize,
      metadata: config.metadata
    )

    // Create result data
    let resultDTO=SecurityResultDTO(
      status: .success,
      data: Data(result.identifier.utf8),
      metadata: ["keyType": config.keyType.rawValue, "keySize": String(config.keySize)]
    )

    // Log completion
    await logger.info(
      "Key generation completed successfully",
      metadata: ["keyType": config.keyType.rawValue],
      source: "CoreSecurityProvider"
    )

    return resultDTO
  }

  /**
   Signs data with the specified configuration

   Delegates to the signature service for implementation.

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing signature or error
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await signatureService.sign(config: config)
  }

  /**
   Verifies a signature with the specified configuration

   Delegates to the signature service for implementation.

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await signatureService.verify(config: config)
  }

  /**
   Stores data securely with the specified configuration

   Delegates to the secure storage service for implementation.

   - Parameter config: Configuration for the storage operation
   - Returns: Result containing operation status or error
   */
  public func store(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await storageService.store(config: config)
  }

  /**
   Retrieves data securely with the specified configuration

   Delegates to the secure storage service for implementation.

   - Parameter config: Configuration for the retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func retrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await storageService.retrieve(config: config)
  }

  /**
   Processes a security operation based on the provided configuration.

   This is a unified entry point for all security operations, handling common
   aspects like logging, error mapping, and result formatting.

   - Parameters:
     - operation: The security operation to perform
     - metadata: Additional metadata for the operation
   - Returns: The result of the operation
   */
  public func processSecurityOperation(
    operation: SecurityOperation,
    metadata: [String: String]
  ) async -> SecurityCoreTypes.SecurityResultDTO {
    // Process the operation using actor-isolated state
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create base metadata
    var operationMetadata=metadata
    operationMetadata["operationID"]=operationID
    operationMetadata["operation"]=String(describing: operation)

    // Log operation start
    await logger.info(
      "Starting security operation: \(operation)",
      metadata: operationMetadata,
      source: "CoreSecurityProvider"
    )

    do {
      // Process the operation based on type
      let result: SecurityResultDTO=try await {
        switch operation {
          case let .encrypt(data, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .encrypt,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await encrypt(config: config)

          case let .decrypt(data, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .decrypt,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await decrypt(config: config)

          case let .generateKey(type, size):
            let config=SecurityConfigDTO(
              operationType: .generateKey,
              keyType: type,
              keySize: size,
              metadata: metadata
            )
            return try await generateKey(config: config)

          case let .sign(data, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .sign,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await sign(config: config)

          case let .verify(data, signature, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .verify,
              data: data,
              signature: signature,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await verify(config: config)

          case let .store(data, identifier):
            let config=SecurityConfigDTO(
              operationType: .store,
              data: data,
              identifier: identifier,
              metadata: metadata
            )
            return try await store(config: config)

          case let .retrieve(identifier):
            let config=SecurityConfigDTO(
              operationType: .retrieve,
              identifier: identifier,
              metadata: metadata
            )
            return try await retrieve(config: config)
        }
      }()

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log operation completion
      var resultMetadata=operationMetadata
      resultMetadata["duration"]=String(format: "%.3f", duration)
      resultMetadata["status"]="success"

      await logger.info(
        "Completed security operation: \(operation)",
        metadata: resultMetadata,
        source: "CoreSecurityProvider"
      )

      return result
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log operation failure
      var errorMetadata=operationMetadata
      errorMetadata["duration"]=String(format: "%.3f", duration)
      errorMetadata["status"]="error"
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Failed security operation: \(operation)",
        metadata: errorMetadata,
        source: "CoreSecurityProvider"
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: error.localizedDescription,
        metadata: errorMetadata
      )
    }
  }
}
