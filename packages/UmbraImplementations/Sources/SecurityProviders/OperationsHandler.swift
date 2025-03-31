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
    self.cryptoService = cryptoService
    self.keyManager = keyManager
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
        return await handleEncryption(config: config, operation: operation)
      case .decrypt:
        return await handleDecryption(config: config, operation: operation)
      case .hash:
        return await handleHashing(config: config, operation: operation)
      case .sign, .verify, .deriveKey, .generateRandom, .storeKey, .retrieveKey, .deleteKey:
        // Return error for unsupported operations
        return .failure(
          errorDetails: "Unsupported operation: \(operation.rawValue)",
          executionTimeMs: 0,
          metadata: ["operation": operation.rawValue]
        )
    }
  }

  // MARK: - Helper Methods

  /// Convert a Result type to a SecurityResultDTO
  /// - Parameters:
  ///   - result: The Result to convert
  ///   - operation: The original operation
  /// - Returns: A properly formatted SecurityResultDTO
  func resultToDTO(
    _ result: Result<[UInt8], SecurityProtocolError>,
    operation: SecurityOperation
  ) -> SecurityResultDTO {
    switch result {
      case let .success(data):
        return .success(
          resultData: Data(data),
          executionTimeMs: 0, // Should implement proper timing in production
          metadata: ["operation": operation.rawValue]
        )
      case let .failure(error):
        return .failure(
          errorDetails: error.localizedDescription,
          executionTimeMs: 0, // Should implement proper timing in production
          metadata: ["operation": operation.rawValue]
        )
    }
  }

  /// Retrieve a key for a cryptographic operation
  /// - Parameter config: Configuration to extract key information from
  /// - Returns: Result with the key bytes or an error
  private func retrieveKeyForOperation(_ config: SecurityConfigDTO) async -> Result<[UInt8], SecurityProtocolError> {
    // Check if a key is directly provided in options
    if let keyData = config.options?.metadata?["key"], let key = Data(base64Encoded: keyData) {
      return .success(Array(key))
    } else if config.options?.metadata?["key"] != nil {
      // Key is present but not valid base64
      return .failure(.invalidMessageFormat(details: "Invalid key format"))
    }

    // Check if a key identifier is provided
    if let keyID = config.options?.metadata?["keyIdentifier"] {
      // Retrieve the key from the key manager
      let keyResult = await keyManager.retrieveKey(withIdentifier: keyID)

      switch keyResult {
        case let .success(keyData):
          return .success(keyData)
        case .failure:
          // Key not found or other error
          // Fall through to the error case
          return .failure(
            .invalidMessageFormat(details: "Key not found: \(keyID)")
          )
      }
    }

    // No key provided or found
    return .failure(.invalidMessageFormat(details: "No key provided for operation"))
  }

  /// Handle encryption operations
  /// - Parameters:
  ///   - config: Configuration for the encryption
  ///   - operation: The operation being performed
  /// - Returns: Result with encrypted data or error
  private func handleEncryption(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // First check if we need to retrieve a key
    let keyResult = await retrieveKeyForOperation(config)

    switch keyResult {
      case let .success(key):
        // Now that we have the key, extract the data to encrypt
        guard
          let dataString = config.options?.metadata?["data"],
          let inputData = Data(base64Encoded: dataString)
        else {
          return .failure(
            errorDetails: "No input data provided for encryption",
            executionTimeMs: 0,
            metadata: ["operation": operation.rawValue]
          )
        }

        // Perform encryption with the key and data
        return resultToDTO(
          await cryptoService.encrypt(data: [UInt8](inputData), using: key), 
          operation: operation
        )
      case let .failure(error):
        return .failure(
          errorDetails: error.localizedDescription,
          executionTimeMs: 0,
          metadata: ["operation": operation.rawValue]
        )
    }
  }

  /// Handle decryption operations
  /// - Parameters:
  ///   - config: Configuration for the decryption
  ///   - operation: The operation being performed
  /// - Returns: Result with decrypted data or error
  private func handleDecryption(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // First check if we need to retrieve a key
    let keyResult = await retrieveKeyForOperation(config)

    switch keyResult {
      case let .success(key):
        // Now that we have the key, extract the data to decrypt
        guard
          let dataString = config.options?.metadata?["data"],
          let inputData = Data(base64Encoded: dataString)
        else {
          return .failure(
            errorDetails: "No ciphertext provided for decryption",
            executionTimeMs: 0,
            metadata: ["operation": operation.rawValue]
          )
        }

        // Perform decryption with the key and data
        return resultToDTO(
          await cryptoService.decrypt(data: [UInt8](inputData), using: key), 
          operation: operation
        )
      case let .failure(error):
        return .failure(
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
      let dataString = config.options?.metadata?["data"],
      let inputData = Data(base64Encoded: dataString)
    else {
      return .failure(
        errorDetails: "No data provided for hashing",
        executionTimeMs: 0,
        metadata: ["operation": operation.rawValue]
      )
    }

    // Perform hashing
    return resultToDTO(
      await cryptoService.hash(data: [UInt8](inputData)), 
      operation: operation
    )
  }
}
