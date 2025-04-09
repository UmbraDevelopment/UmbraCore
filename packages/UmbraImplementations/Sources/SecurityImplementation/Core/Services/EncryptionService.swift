import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/**
 Creates a log context from a metadata dictionary.
 
 - Parameter metadata: Dictionary of metadata values
 - Parameter domain: Domain name for the log context
 - Parameter source: Source identifier for the log context
 - Returns: A BaseLogContextDTO with proper privacy tagging
 */
private func createLogContext(
  _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
  domain: String = "SecurityServices",
  source: String = "EncryptionService"
) -> BaseLogContextDTO {
  var collection = LogMetadataDTOCollection()
  
  for (key, data) in metadata {
    switch data.privacy {
    case .public:
      collection = collection.withPublic(key: key, value: data.value)
    case .private:
      collection = collection.withPrivate(key: key, value: data.value)
    case .sensitive:
      collection = collection.withSensitive(key: key, value: data.value)
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
   Initialises a new encryption service with the specified dependencies

   - Parameters:
       - cryptoService: Service for cryptographic operations
       - logger: Logger for general operation details
   */
  init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService = cryptoService
    self.logger = logger
    secureStorage = SecureStorage()
  }

  // MARK: - Encryption Operations

  /**
   Encrypts data with the specified configuration

   - Parameter config: The configuration for encryption
   - Returns: The result of the encryption operation
   - Throws: SecurityError if encryption fails
   */
  func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.encrypt

    // Log start of operation
    let startContext = createLogContext([
      "operation": (value: operation.rawValue, privacy: .public),
      "operationID": (value: operationID, privacy: .public)
    ])
    
    await logger.debug(
      "Starting encryption operation",
      context: startContext
    )

    do {
      // Validate inputs
      guard let inputData = config.inputData else {
        throw SecurityError.invalidInput("No input data provided for encryption")
      }

      // Get or generate key
      let keyData = try await getKeyData(for: config)

      // Perform encryption
      let result = try await encryptData(
        data: inputData,
        key: keyData,
        options: config.options
      )

      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log success
      let successContext = createLogContext([
        "operationID": (value: operationID, privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "inputSize": (value: String(inputData.count), privacy: .public),
        "outputSize": (value: String(result.count), privacy: .public)
      ])
      
      await logger.debug(
        "Encryption completed successfully",
        context: successContext
      )

      // Return result
      return SecurityResultDTO(
        operationID: operationID,
        data: result,
        status: .success,
        metadata: nil
      )
    } catch {
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log failure
      let errorContext = createLogContext([
        "operationID": (value: operationID, privacy: .public),
        "error": (value: error.localizedDescription, privacy: .private),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public)
      ])
      
      await logger.error(
        "Encryption operation failed",
        context: errorContext
      )

      // Map to security error
      if let secError = error as? SecurityError {
        throw secError
      } else {
        throw SecurityError.encryptionError("Encryption failed: \(error.localizedDescription)")
      }
    }
  }

  /**
   Decrypts data with the specified configuration

   - Parameter config: The configuration for decryption
   - Returns: The result of the decryption operation
   - Throws: SecurityError if decryption fails
   */
  func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.decrypt

    // Log start of operation
    let startContext = createLogContext([
      "operation": (value: operation.rawValue, privacy: .public),
      "operationID": (value: operationID, privacy: .public)
    ])
    
    await logger.debug(
      "Starting decryption operation",
      context: startContext
    )

    do {
      // Validate inputs
      guard let inputData = config.inputData else {
        throw SecurityError.invalidInput("No input data provided for decryption")
      }

      // Get key
      let keyData = try await getKeyData(for: config)

      // Perform decryption
      let result = try await decryptData(
        data: inputData,
        key: keyData,
        options: config.options
      )

      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log success
      let successContext = createLogContext([
        "operationID": (value: operationID, privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "inputSize": (value: String(inputData.count), privacy: .public),
        "outputSize": (value: String(result.count), privacy: .public)
      ])
      
      await logger.debug(
        "Decryption completed successfully",
        context: successContext
      )

      // Return result
      return SecurityResultDTO(
        operationID: operationID,
        data: result,
        status: .success,
        metadata: nil
      )
    } catch {
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log failure with secure logger
      let errorContext = createLogContext([
        "operationID": (value: operationID, privacy: .public),
        "error": (value: error.localizedDescription, privacy: .private),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public)
      ])
      
      await logger.error(
        "Decryption operation failed",
        context: errorContext
      )

      // Map to security error
      if let secError = error as? SecurityError {
        throw secError
      } else {
        throw SecurityError.decryptionError("Decryption failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Private Methods

  /**
   Gets key data for a cryptographic operation

   - Parameter config: The operation configuration
   - Returns: The key data
   - Throws: SecurityError if key retrieval fails
   */
  private func getKeyData(for config: SecurityConfigDTO) async throws -> Data {
    // Implementation details...
    // This would retrieve key data from a keychain or other secure source
    // For now, just return empty data as a placeholder
    return Data()
  }

  /**
   Encrypts data with the provided key and options

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - options: Additional encryption options
   - Returns: Encrypted data
   - Throws: SecurityError if encryption fails
   */
  private func encryptData(
    data: Data,
    key: Data,
    options: SecurityOptionsDTO?
  ) async throws -> Data {
    // Implementation details...
    // This would perform the actual encryption using the cryptoService
    // For now, just return the input data as a placeholder
    return data
  }

  /**
   Decrypts data with the provided key and options

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - options: Additional decryption options
   - Returns: Decrypted data
   - Throws: SecurityError if decryption fails
   */
  private func decryptData(
    data: Data,
    key: Data,
    options: SecurityOptionsDTO?
  ) async throws -> Data {
    // Implementation details...
    // This would perform the actual decryption using the cryptoService
    // For now, just return the input data as a placeholder
    return data
  }
}

/**
 A secure storage actor for handling sensitive data in memory.
 This replaces the deprecated SecureBytes type with an actor-based approach
 for better memory safety and concurrency control.
 */
actor SecureStorage {
  private var storage: [String: Data]=[:]

  func store(data: Data, withIdentifier identifier: String) throws {
    storage[identifier]=data
  }

  func retrieve(withIdentifier identifier: String) throws -> Data {
    guard let data=storage[identifier] else {
      throw SecurityProtocolError.keyNotFound
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
