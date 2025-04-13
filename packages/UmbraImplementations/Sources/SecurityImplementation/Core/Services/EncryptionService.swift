import CoreSecurityTypes
import CryptoServices
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 Creates a log context from a metadata dictionary.

 - Parameter metadata: Dictionary of metadata values
 - Parameter domain: Domain name for the log context
 - Parameter source: Source identifier for the log context
 - Returns: A BaseLogContextDTO with proper privacy tagging
 */
private func createLogContext(
  _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
  domain: String="SecurityServices",
  source: String="EncryptionService"
) -> BaseLogContextDTO {
  var collection=LogMetadataDTOCollection()

  for (key, data) in metadata {
    switch data.privacy {
      case .public:
        collection=collection.withPublic(key: key, value: data.value)
      case .private:
        collection=collection.withPrivate(key: key, value: data.value)
      case .sensitive:
        collection=collection.withSensitive(key: key, value: data.value)
      case .hash:
        // Using public for hash as withHash method is not available
        collection=collection.withPublic(key: key, value: data.value)
      case .auto:
        // For auto privacy level, use public as withAuto is not available
        collection=collection.withPublic(key: key, value: data.value)
      @unknown default:
        // Handle any future cases by defaulting to private
        collection=collection.withPrivate(key: key, value: data.value)
    }
  }

  return BaseLogContextDTO(
    domainName: domain,
    source: source,
    metadata: collection
  )
}

/**
 # Encryption Service

 Handles encryption and decryption operations for the security provider.
 This service encapsulates the logic specific to data encryption and decryption,
 reducing complexity in the main CoreSecurityProviderService.

 ## Responsibilities

 - Perform encryption operations
 - Perform decryption operations
 - Track performance and log operations
 - Handle encryption-specific errors

 ## Privacy-Aware Logging

 Uses privacy-aware logging to ensure all sensitive data is properly tagged with privacy
 levels in accordance with the Alpha Dot Five architecture principles.
 */
final class EncryptionService: SecurityServiceBase {
  // MARK: - Properties

  /**
   The crypto service used for cryptographic operations
   */
  private let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The logger instance for recording general operation details
   */
  let logger: LoggingInterfaces.LoggingProtocol

  /**
   The secure storage for handling sensitive data
   */
  private let secureStorage: SecureStorage

  // MARK: - Initialisation

  /**
   Initialises the service with all required dependencies

   - Parameters:
     - cryptoService: Service for performing cryptographic operations
     - logger: Service for logging operations
   */
  init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    self.logger=logger
    secureStorage=SecureStorage()
  }

  /**
   Initialises the service with just a logger

   This initializer is required to conform to SecurityServiceBase protocol,
   but it's not intended for direct use.

   - Parameter logger: The logging service to use
   */
  init(logger: LoggingInterfaces.LoggingProtocol) {
    self.logger=logger

    // Initialize secureStorage first since it's needed for cryptoService
    secureStorage=SecureStorage()

    // Correctly initialize cryptoService with the required secureStorage parameter
    cryptoService=DefaultCryptoServiceImpl(secureStorage: secureStorage, logger: logger)

    // Log warning that this initializer shouldn't be used directly
    Task {
      let warningContext=createLogContext([
        "component": (value: "SecurityImplementation", privacy: .public)
      ])

      await logger.warning(
        "EncryptionService initialized with minimal dependencies, consider using the full initializer",
        context: warningContext
      )
    }
  }

  // MARK: - Encryption Operations

  /**
   Encrypts data with the specified configuration

   - Parameter config: The configuration for encryption
   - Returns: The result of the encryption operation
   - Throws: CoreSecurityError if encryption fails
   */
  func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=CoreSecurityTypes.SecurityOperation.encrypt

    // Log start of operation
    let startContext=createLogContext([
      "operation": (value: operation.rawValue, privacy: .public),
      "operationID": (value: operationID, privacy: .public)
    ])

    await logger.debug(
      "Starting encryption operation",
      context: startContext
    )

    let result=try await encryptData(
      data: extractInputData(from: config),
      key: getKeyData(for: config),
      options: config.options
    )

    // Process encryption result
    switch result {
      case let .success(encryptedData):
        // Calculate duration for metrics
        let duration=Date().timeIntervalSince(startTime)

        // Log success with secure logger
        let successContext=createLogContext([
          "operationID": (value: operationID, privacy: .public),
          "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
          "inputSize": (value: String(extractInputData(from: config).count), privacy: .public),
          "outputSize": (value: String(encryptedData.count), privacy: .public)
        ])

        await logger.debug(
          "Encryption completed successfully",
          context: successContext
        )

        // Return result
        return SecurityResultDTO.success(
          resultData: encryptedData,
          executionTimeMs: duration * 1000,
          metadata: nil
        )

      case let .failure(error):
        // Calculate duration for metrics
        let duration=Date().timeIntervalSince(startTime)

        // Log failure
        let errorContext=createLogContext([
          "operationID": (value: operationID, privacy: .public),
          "error": (value: error.localizedDescription, privacy: .private),
          "durationMs": (value: String(Int(duration * 1000)), privacy: .public)
        ])

        await logger.error(
          "Encryption operation failed",
          context: errorContext
        )

        // Map to security error
        if let secError=error as? CoreSecurityError {
          throw secError
        } else {
          throw CoreSecurityError
            .encryptionFailed(reason: "Encryption failed: \(error.localizedDescription)")
        }
    }
  }

  /**
   Decrypts data with the specified configuration

   - Parameter config: The configuration for decryption
   - Returns: The result of the decryption operation
   - Throws: CoreSecurityError if decryption fails
   */
  func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=CoreSecurityTypes.SecurityOperation.decrypt

    // Log start of operation
    let startContext=createLogContext([
      "operation": (value: operation.rawValue, privacy: .public),
      "operationID": (value: operationID, privacy: .public)
    ])

    await logger.debug(
      "Starting decryption operation",
      context: startContext
    )

    let result=try await decryptData(
      data: extractInputData(from: config),
      key: getKeyData(for: config),
      options: config.options
    )

    // Process decryption result
    switch result {
      case let .success(decryptedData):
        // Calculate duration for metrics
        let duration=Date().timeIntervalSince(startTime)

        // Log success with secure logger
        let successContext=createLogContext([
          "operationID": (value: operationID, privacy: .public),
          "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
          "inputSize": (value: String(config.options?.metadata?["inputData"]?.count ?? 0),
                        privacy: .public),
          "outputSize": (value: String(decryptedData.count), privacy: .public)
        ])

        await logger.debug(
          "Decryption completed successfully",
          context: successContext
        )

        // Return result
        return SecurityResultDTO.success(
          resultData: decryptedData,
          executionTimeMs: duration * 1000,
          metadata: nil
        )

      case let .failure(error):
        // Calculate duration for metrics
        let duration=Date().timeIntervalSince(startTime)

        // Log failure
        let errorContext=createLogContext([
          "operationID": (value: operationID, privacy: .public),
          "error": (value: error.localizedDescription, privacy: .private),
          "durationMs": (value: String(Int(duration * 1000)), privacy: .public)
        ])

        await logger.error(
          "Decryption operation failed",
          context: errorContext
        )

        // Map to security error
        if let secError=error as? CoreSecurityError {
          throw secError
        } else {
          throw CoreSecurityError
            .decryptionFailed(reason: "Decryption failed: \(error.localizedDescription)")
        }
    }
  }

  // MARK: - Private Methods

  /**
   Gets key data for a cryptographic operation

   - Parameter config: The operation configuration
   - Returns: The key data
   - Throws: CoreSecurityError if key retrieval fails
   */
  private func getKeyData(for _: SecurityConfigDTO) async throws -> Data {
    // Implementation details...
    // This would retrieve key data from a keychain or other secure source
    // For now, just return empty data as a placeholder
    Data()
  }

  /**
   Encrypts data with the provided key and options

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - options: Additional encryption options
   - Returns: Encrypted data
   - Throws: CoreSecurityError if encryption fails
   */
  private func encryptData(
    data: Data,
    key _: Data,
    options _: SecurityConfigOptions?
  ) async throws -> Result<Data, Error> {
    // Implementation details...
    // This would perform the actual encryption using the cryptoService
    // For now, just return the input data as a placeholder
    .success(data)
  }

  /**
   Decrypts data with the provided key and options

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - options: Additional decryption options
   - Returns: Decrypted data
   - Throws: CoreSecurityError if decryption fails
   */
  private func decryptData(
    data: Data,
    key _: Data,
    options _: SecurityConfigOptions?
  ) async throws -> Result<Data, Error> {
    // Implementation details...
    // This would perform the actual decryption using the cryptoService
    // For now, just return the input data as a placeholder
    .success(data)
  }

  private func extractInputData(from config: SecurityConfigDTO) -> Data {
    guard
      let options=config.options,
      let metadata=options.metadata,
      let inputDataString=metadata["inputData"]
    else {
      return Data()
    }

    // Attempt to convert from Base64 if the data is Base64-encoded
    if let decodedData=Data(base64Encoded: inputDataString) {
      return decodedData
    }

    // If not Base64, try using the string data directly
    return inputDataString.data(using: .utf8) ?? Data()
  }
}

/**
 A secure storage actor for handling sensitive data in memory.
 This replaces the deprecated SecureBytes type with an actor-based approach
 for better memory safety and concurrency control.
 */
actor SecureStorage: SecureStorageProtocol {
  private var storage: [String: Data]=[:]

  /// Stores data securely with the given identifier.
  /// - Parameters:
  ///   - data: The data to store as a byte array.
  ///   - identifier: A string identifier for the stored data.
  /// - Returns: Success or an error.
  func storeData(_ data: [UInt8], withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    storage[identifier]=Data(data)
    return .success(())
  }

  /// Retrieves data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to retrieve.
  /// - Returns: The retrieved data as a byte array or an error.
  func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    guard let data=storage[identifier] else {
      return .failure(.keyNotFound)
    }
    return .success([UInt8](data))
  }

  /// Deletes data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to delete.
  /// - Returns: Success or an error.
  func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    storage.removeValue(forKey: identifier)
    return .success(())
  }

  /// Lists all available data identifiers.
  /// - Returns: An array of data identifiers or an error.
  func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    .success(Array(storage.keys))
  }

  // Legacy methods for internal use
  func store(data: Data, withIdentifier identifier: String) throws {
    storage[identifier]=data
  }

  func retrieve(withIdentifier identifier: String) throws -> Data {
    guard let data=storage[identifier] else {
      throw CoreSecurityError.storageError("Key not found: \(identifier)")
    }
    return data
  }

  func remove(withIdentifier identifier: String) {
    storage.removeValue(forKey: identifier)
  }
}

/**
 Security-specific errors for encryption operations
 */
enum EncryptionServiceError: Error {
  case invalidInput(String)
  case operationFailed(String)
  case encryptionFailed(String)
  case decryptionFailed(String)
  case algorithmNotSupported(String)
  case cryptoError(String)
}
