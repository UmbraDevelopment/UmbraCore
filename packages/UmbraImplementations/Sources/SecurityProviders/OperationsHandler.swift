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

import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
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
      case .verify, .generateKey, .sign, .deriveKey, .store, .retrieve, .delete, .custom:
        // Return error for unsupported operations
        return SecurityResultDTO(
          status: .failure,
          error: SecurityProtocolError.unsupportedOperation(name: operation.operationType)
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
    _ result: Result<SecureBytes, SecurityProtocolError>,
    operation: SecurityOperation
  ) -> SecurityResultDTO {
    switch result {
      case let .success(data):
        return SecurityResultDTO(
          status: .success,
          data: data
        )
      case let .failure(error):
        return SecurityResultDTO(
          status: .failure,
          error: error
        )
    }
  }

  /// Attempt to retrieve a key for an operation
  /// - Parameter config: The security configuration
  /// - Returns: Retrieved key or error
  private func retrieveKeyForOperation(
    _ config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    // Check if the key is directly provided in the options
    if let key = config.options["key"] {
      if let keyData = Utilities.base64StringToData(key) {
        return .success(SecureBytes(bytes: keyData))
      } else {
        return .failure(.invalidInput("Invalid key format"))
      }
    }

    // Check if a key identifier is provided
    if let keyID = config.options["keyIdentifier"] {
      // Retrieve the key from the key manager
      let keyResult = await keyManager.retrieveKey(withIdentifier: keyID)
      
      switch keyResult {
        case let .success(key):
          return .success(key)
        case .failure:
          // Fall through to the error case
          return .failure(
            .serviceError(code: 100, message: "Key not found: \(keyID)")
          )
      }
    }
    
    // No key provided or found
    return .failure(.invalidInput("No key provided for operation"))
  }

  /// Handle encryption operations
  /// - Parameters:
  ///   - config: Configuration for the encryption
  ///   - operation: The original operation
  /// - Returns: Result of the encryption
  private func handleEncryption(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // First check if we need to retrieve a key
    let keyResult = await retrieveKeyForOperation(config)

    switch keyResult {
      case let .success(key):
        // Check if we have input data
        guard let inputData = config.inputData else {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.invalidInput("No input data provided for encryption")
          )
        }

        // Perform the encryption with the key
        let result = await cryptoService.encrypt(data: inputData, using: key)
        return resultToDTO(result, operation: operation)

      case let .failure(error):
        return SecurityResultDTO(
          status: .failure,
          error: error
        )
    }
  }

  /// Handle decryption operations
  /// - Parameters:
  ///   - config: Configuration for the decryption
  ///   - operation: The original operation
  /// - Returns: Result of the decryption
  private func handleDecryption(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // First check if we need to retrieve a key
    let keyResult = await retrieveKeyForOperation(config)

    switch keyResult {
      case let .success(key):
        // Check if we have input data
        guard let inputData = config.inputData else {
          return SecurityResultDTO(
            status: .failure,
            error: SecurityProtocolError.invalidInput("No input data provided for decryption")
          )
        }

        // Perform the decryption with the key
        let result = await cryptoService.decrypt(data: inputData, using: key)
        return resultToDTO(result, operation: operation)

      case let .failure(error):
        return SecurityResultDTO(
          status: .failure,
          error: error
        )
    }
  }

  /// Handle hashing operations
  /// - Parameters:
  ///   - config: Configuration for the hashing
  ///   - operation: The original operation
  /// - Returns: Result of the hashing
  private func handleHashing(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async -> SecurityResultDTO {
    // Check if we have input data
    guard let inputData = config.inputData else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityProtocolError.invalidInput("No input data provided for hashing")
      )
    }

    // Perform the hashing
    let result = await cryptoService.hash(data: inputData)
    return resultToDTO(result, operation: operation)
  }
}
