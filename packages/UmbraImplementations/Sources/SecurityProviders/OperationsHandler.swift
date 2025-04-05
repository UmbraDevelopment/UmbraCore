/**
 # UmbraCore Security Operations Handler

 This file provides functionality for routing security operations to the appropriate
 specialised handlers and services within the UmbraCore security framework.

 ## Responsibilities

 * Route security operations to the appropriate service based on operation type
 * Retrieve keys when needed for cryptographic operations
 * Handle errors consistently across all operations
 * Enforce security policies for operations

 ## Design Pattern

 This class follows the Command pattern, encapsulating each security operation request
 as an object that contains all information needed to process the request. This allows
 for a clean separation of concerns between the client (SecurityProvider) and the
 services that perform the actual operations.

 ## Security Considerations

 * Centralised error handling ensures consistent security reporting
 * Key retrieval is handled consistently for all operations
 * Validation is performed before routing operations
 * Each operation type is handled by a specialised method for clarity and maintainability
 */

import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/// Handles routing of security operations to the appropriate services
///
/// OperationsHandler is responsible for taking security operation requests and
/// routing them to the appropriate service, handling key retrieval and error cases.
final class OperationsHandler {
  // MARK: - Properties

  /// The crypto service for cryptographic operations
  private let cryptoService: CryptoServiceProtocol

  /// The key manager for key operations
  private let keyManager: KeyManagementProtocol

  // MARK: - Initialisation

  /// Creates a new operations handler
  /// - Parameters:
  ///   - cryptoService: The crypto service to use
  ///   - keyManager: The key manager to use
  init(cryptoService: CryptoServiceProtocol, keyManager: KeyManagementProtocol) {
    self.cryptoService=cryptoService
    self.keyManager=keyManager
  }

  // MARK: - Operation Handling

  /// Handle a security operation request with the provided configuration
  /// - Parameters:
  ///   - operation: The security operation to perform
  ///   - config: Configuration parameters for the operation
  /// - Returns: The result of the operation with appropriate status and data
  func handleOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    switch operation {
      case .encrypt:
        await processEncryptionOperation(config, operation: operation)
      case .decrypt:
        await processDecryptionOperation(config, operation: operation)
      case .hash:
        await handleHashing(config: config, operation: operation)
      case .sign, .verify, .deriveKey, .generateRandom, .storeKey, .retrieveKey, .deleteKey:
        // Return error for unsupported operations
        .failure(
          errorDetails: "Unsupported operation: \(operation.rawValue)",
          executionTimeMs: 0,
          metadata: ["operation": operation.rawValue]
        )
    }
  }

  // MARK: - Helper Methods

  /// Imports data for an operation into secure storage and returns the identifier
  /// - Parameter data: The binary data to import
  /// - Returns: A string identifier for retrieving the data
  private func importDataForOperation(_ data: [UInt8]) async -> String {
    // Generate a unique identifier
    let identifier=UUID().uuidString

    // Store the data using the crypto service's secure storage
    let result=await cryptoService.secureStorage.storeData(data, withIdentifier: identifier)

    // Handle the result
    switch result {
      case .success:
        return identifier
      case let .failure(error):
        // Log error if possible, but return the identifier anyway
        print("Warning: Failed to import data: \(error.localizedDescription)")
        return identifier
    }
  }

  /// Retrieves data using an identifier from secure storage
  /// - Parameter identifier: The identifier for the stored data
  /// - Returns: The retrieved binary data or nil if retrieval failed
  private func retrieveDataForOperation(withIdentifier identifier: String) async -> [UInt8]? {
    let result=await cryptoService.secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(data):
        return data
      case let .failure(error):
        // Log error if possible
        print("Warning: Failed to retrieve data: \(error.localizedDescription)")
        return nil
    }
  }

  /// Converts a Result from a cryptographic operation to a SecurityResultDTO
  /// - Parameters:
  ///   - result: The cryptographic operation result
  ///   - operation: The security operation type
  /// - Returns: A SecurityResultDTO representing the result
  private func resultToDTO(
    _ result: Result<some Any, CoreSecurityTypes.SecurityProtocolError>,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // NOTE: In a production implementation, we would measure execution time
    // by capturing start/end times and calculating the difference

    switch result {
      case let .success(value):
        if let identifier=value as? String {
          // For cryptographic operations that return identifiers, retrieve the actual data
          if let data=await retrieveDataForOperation(withIdentifier: identifier) {
            return SecurityResultDTO.success(
              resultData: Data(data),
              executionTimeMs: 0, // Would calculate from start/end time in a full implementation
              metadata: ["operation": operation.rawValue]
            )
          } else {
            return SecurityResultDTO.failure(
              errorDetails: "Failed to retrieve data for identifier: \(identifier)",
              executionTimeMs: 0,
              metadata: ["operation": operation.rawValue]
            )
          }
        } else if let boolValue=value as? Bool {
          // For verification operations that return a boolean
          return SecurityResultDTO.success(
            resultData: Data(boolValue ? [1] : [0]), // Simple representation of boolean as a byte
            executionTimeMs: 0,
            metadata: ["operation": operation.rawValue]
          )
        } else {
          // This branch should not be reached with the current implementation
          return SecurityResultDTO.failure(
            errorDetails: "Unexpected result type",
            executionTimeMs: 0,
            metadata: ["operation": operation.rawValue]
          )
        }
      case let .failure(error):
        return SecurityResultDTO.failure(
          errorDetails: error.localizedDescription,
          executionTimeMs: 0,
          metadata: ["operation": operation.rawValue, "errorType": String(describing: error)]
        )
    }
  }

  /// Process an encryption operation with the provided configuration
  /// - Parameters:
  ///   - config: Configuration for the encryption operation
  ///   - operation: The security operation type
  /// - Returns: Result of the encryption operation
  private func processEncryptionOperation(
    _ config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // First check if we need to retrieve a key
    let keyResult=await retrieveKeyForOperation(config)

    switch keyResult {
      case let .success(key):
        // Extract input data from config
        guard
          let dataString=config.options?.metadata?["data"],
          let inputData=Data(base64Encoded: dataString)
        else {
          return SecurityResultDTO.failure(
            errorDetails: "Missing input data",
            executionTimeMs: 0,
            metadata: ["operation": operation.rawValue]
          )
        }

        // Perform encryption with the key and data
        return await resultToDTO(
          convertStorageResult(
            cryptoService.encrypt(
              dataIdentifier: importDataForOperation([UInt8](inputData)),
              keyIdentifier: importDataForOperation(key),
              options: EncryptionOptions(algorithm: .aes128CBC)
            )
          ),
          operation: operation
        )
      case let .failure(error):
        return SecurityResultDTO.failure(
          errorDetails: error.localizedDescription,
          executionTimeMs: 0,
          metadata: ["operation": operation.rawValue]
        )
    }
  }

  /// Process a decryption operation with the provided configuration
  /// - Parameters:
  ///   - config: Configuration for the decryption operation
  ///   - operation: The security operation type
  /// - Returns: Result of the decryption operation
  private func processDecryptionOperation(
    _ config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // First check if we need to retrieve a key
    let keyResult=await retrieveKeyForOperation(config)

    switch keyResult {
      case let .success(key):
        // Extract input data from config
        guard
          let dataString=config.options?.metadata?["data"],
          let inputData=Data(base64Encoded: dataString)
        else {
          return SecurityResultDTO.failure(
            errorDetails: "Missing input data",
            executionTimeMs: 0,
            metadata: ["operation": operation.rawValue]
          )
        }

        // Perform decryption with the key and data
        return await resultToDTO(
          convertStorageResult(
            cryptoService.decrypt(
              encryptedDataIdentifier: importDataForOperation([UInt8](inputData)),
              keyIdentifier: importDataForOperation(key),
              options: DecryptionOptions(algorithm: .aes128CBC)
            )
          ),
          operation: operation
        )
      case let .failure(error):
        return SecurityResultDTO.failure(
          errorDetails: error.localizedDescription,
          executionTimeMs: 0,
          metadata: ["operation": operation.rawValue]
        )
    }
  }

  /// Handle hashing operations
  /// - Parameters:
  ///   - config: Configuration for the hashing
  ///   - operation: The operation being performed
  /// - Returns: Result with hash value or error
  private func handleHashing(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // Extract data to hash
    guard
      let dataString=config.options?.metadata?["data"],
      let inputData=Data(base64Encoded: dataString)
    else {
      return SecurityResultDTO.failure(
        errorDetails: "No data provided for hashing",
        executionTimeMs: 0,
        metadata: ["operation": operation.rawValue]
      )
    }

    // Perform hashing
    return await resultToDTO(
      convertStorageResult(
        cryptoService.hash(
          dataIdentifier: importDataForOperation([UInt8](inputData)),
          options: HashingOptions(algorithm: .sha256)
        )
      ),
      operation: operation
    )
  }

  /// Retrieve a key for a cryptographic operation
  /// - Parameter config: Configuration to extract key information from
  /// - Returns: Result with the key bytes or an error
  private func retrieveKeyForOperation(_ config: SecurityConfigDTO) async
  -> Result<[UInt8], CoreSecurityTypes.SecurityProtocolError> {
    // Check if a key is directly provided in options
    if let keyData=config.options?.metadata?["key"], let key=Data(base64Encoded: keyData) {
      return .success(Array(key))
    } else if config.options?.metadata?["key"] != nil {
      // Key is present but not valid base64
      return .failure(
        CoreSecurityTypes.SecurityProtocolError
          .invalidMessageFormat(details: "Invalid key format")
      )
    }

    // Check if a key identifier is provided
    if let keyID=config.options?.metadata?["keyIdentifier"] {
      // Retrieve the key from the key manager
      let keyResult=await keyManager.retrieveKey(withIdentifier: keyID)

      switch keyResult {
        case let .success(keyData):
          return .success(keyData)
        case .failure:
          // Key not found or other error
          // Fall through to the error case
          return .failure(
            CoreSecurityTypes.SecurityProtocolError
              .invalidMessageFormat(details: "Key not found: \(keyID)")
          )
      }
    }

    // No key provided or found
    return .failure(
      CoreSecurityTypes.SecurityProtocolError
        .invalidMessageFormat(details: "No key provided for operation")
    )
  }

  /**
   Converts a SecurityStorageError to a SecurityProtocolError.
   This is needed because the CryptoServiceProtocol now uses SecurityStorageError.

   - Parameter storageError: The storage error to convert
   - Returns: An equivalent protocol error
   */
  private func convertStorageErrorToProtocolError(_ storageError: SecurityStorageError)
  -> CoreSecurityTypes.SecurityProtocolError {
    switch storageError {
      case .storageUnavailable:
        .operationFailed("Secure storage is not available")
      case .dataNotFound:
        .operationFailed("Data not found in secure storage")
      case .keyNotFound:
        .operationFailed("Key not found in secure storage")
      case .hashNotFound:
        .operationFailed("Hash not found in secure storage")
      case .encryptionFailed:
        .operationFailed("Encryption operation failed")
      case .decryptionFailed:
        .operationFailed("Decryption operation failed")
      case .hashingFailed:
        .operationFailed("Hashing operation failed")
      case .hashVerificationFailed:
        .operationFailed("Hash verification failed")
      case .keyGenerationFailed:
        .operationFailed("Key generation failed")
      case .unsupportedOperation:
        .operationFailed("The operation is not supported")
      case .implementationUnavailable:
        .operationFailed("The protocol implementation is not available")
      case let .operationFailed(message):
        .operationFailed(reason: message)
    }
  }

  /**
   Converts a Result with SecurityStorageError to a Result with SecurityProtocolError.

   - Parameter result: The storage result to convert
   - Returns: An equivalent result with protocol error
   */
  private func convertStorageResult<T>(_ result: Result<T, SecurityStorageError>)
  -> Result<T, CoreSecurityTypes.SecurityProtocolError> {
    switch result {
      case let .success(value):
        .success(value)
      case let .failure(error):
        .failure(convertStorageErrorToProtocolError(error))
    }
  }
}
