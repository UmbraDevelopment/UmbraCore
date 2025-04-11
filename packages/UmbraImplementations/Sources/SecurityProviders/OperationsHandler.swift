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
      case .sign:
        await processSigningOperation(config, operation: operation)
      case .verify:
        await processVerificationOperation(config, operation: operation)
      case .hash:
        await processHashingOperation(config, operation: operation)
      case .verifyHash:
        await processHashVerificationOperation(config, operation: operation)
      case .deriveKey, .generateRandom, .storeKey, .retrieveKey, .deleteKey:
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
              options: EncryptionOptions(algorithm: .aes256CBC, mode: .cbc, padding: .pkcs7)
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
              options: DecryptionOptions(algorithm: .aes256CBC, mode: .cbc, padding: .pkcs7)
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
        .operationFailed(reason: "Secure storage is not available")
      case .dataNotFound:
        .operationFailed(reason: "Data not found in secure storage")
      case .keyNotFound:
        .operationFailed(reason: "Key not found in secure storage")
      case .hashNotFound:
        .operationFailed(reason: "Hash not found in secure storage")
      case .encryptionFailed:
        .operationFailed(reason: "Encryption operation failed")
      case .decryptionFailed:
        .operationFailed(reason: "Decryption operation failed")
      case .hashingFailed:
        .operationFailed(reason: "Hash operation failed")
      case .hashVerificationFailed:
        .operationFailed(reason: "Hash verification failed")
      case .keyGenerationFailed:
        .operationFailed(reason: "Key generation failed")
      case let .invalidIdentifier(reason):
        .operationFailed(reason: "Invalid identifier: \(reason)")
      case let .identifierNotFound(identifier):
        .operationFailed(reason: "Identifier not found: \(identifier)")
      case let .storageFailure(reason):
        .operationFailed(reason: "Storage failure: \(reason)")
      case let .generalError(reason):
        .operationFailed(reason: "General error: \(reason)")
      case .unsupportedOperation:
        .operationFailed(reason: "The operation is not supported")
      case .implementationUnavailable:
        .operationFailed(reason: "The protocol implementation is not available")
      case let .operationFailed(message):
        .operationFailed(reason: message)
      case let .invalidInput(message):
        .inputError(message)
      case .operationRateLimited:
        .operationFailed(reason: "Operation was rate limited for security purposes")
      case .storageError:
        .operationFailed(reason: "Generic storage error occurred")
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

  /**
   Process a signing operation.

   - Parameters:
     - config: Configuration for the operation
     - operation: The security operation being performed
   - Returns: A result DTO with the operation result
   */
  private func processSigningOperation(
    _ config: SecurityConfigDTO,
    operation _: SecurityOperation
  ) async -> SecurityResultDTO {
    // Start timing the operation
    let startTime=Date().timeIntervalSince1970

    // Validate input
    guard let inputData=config.options?.metadata?["inputData"] else {
      return .failure(
        errorDetails: "Missing input data in configuration",
        executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
      )
    }

    // Import data to secure storage
    let importResult=await cryptoService.importData(
      Array(inputData.utf8),
      customIdentifier: nil
    )

    // Process import result
    switch importResult {
      case let .success(dataIdentifier):
        // Check if key identifier is provided
        guard let keyIdentifier=config.options?.metadata?["keyIdentifier"] else {
          return .failure(
            errorDetails: "Missing key identifier in configuration",
            executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
          )
        }

        // Create hash options
        let hashOptions=HashingOptions(
          algorithm: config.hashAlgorithm
        )

        // Attempt to generate hash (which serves as a signature in this case)
        let hashResult=await cryptoService.generateHash(
          dataIdentifier: dataIdentifier,
          options: hashOptions
        )

        switch hashResult {
          case let .success(hashIdentifier):
            // Get the signature data
            let signatureResult=await cryptoService.exportData(identifier: hashIdentifier)

            switch signatureResult {
              case let .success(signatureData):
                // Calculate operation time
                let executionTime=Date().timeIntervalSince1970 - startTime

                // Return success
                return .success(
                  resultData: Data(signatureData),
                  executionTimeMs: executionTime * 1000,
                  metadata: ["algorithm": config.hashAlgorithm.rawValue]
                )

              case let .failure(error):
                return .failure(
                  errorDetails: "Failed to export signature: \(error)",
                  executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
                )
            }

          case let .failure(error):
            return .failure(
              errorDetails: "Signature generation failed: \(error)",
              executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
            )
        }

      case let .failure(error):
        return .failure(
          errorDetails: "Failed to import data: \(error)",
          executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
        )
    }
  }

  /**
   Process a verification operation.

   - Parameters:
     - config: Configuration for the operation
     - operation: The security operation being performed
   - Returns: A result DTO with the operation result
   */
  private func processVerificationOperation(
    _ config: SecurityConfigDTO,
    operation _: SecurityOperation
  ) async -> SecurityResultDTO {
    // Start timing the operation
    let startTime=Date().timeIntervalSince1970

    // Validate inputs
    guard let inputData=config.options?.metadata?["inputData"] else {
      return .failure(
        errorDetails: "Missing input data in configuration",
        executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
      )
    }

    guard
      let signatureStr=config.options?.metadata?["signature"],
      let signatureData=signatureStr.data(using: .utf8)
    else {
      return .failure(
        errorDetails: "Missing or invalid signature in configuration",
        executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
      )
    }

    // Import data to secure storage
    let importDataResult=await cryptoService.importData(
      Array(inputData.utf8),
      customIdentifier: nil
    )

    // Process import result
    switch importDataResult {
      case let .success(dataIdentifier):
        // Import signature to secure storage
        let importSignatureResult=await cryptoService.importData(
          [UInt8](signatureData),
          customIdentifier: nil
        )

        switch importSignatureResult {
          case let .success(hashIdentifier):
            // Create hash options
            let hashOptions=HashingOptions(
              algorithm: config.hashAlgorithm
            )

            // Verify the hash
            let verifyResult=await cryptoService.verifyHash(
              dataIdentifier: dataIdentifier,
              hashIdentifier: hashIdentifier,
              options: hashOptions
            )

            switch verifyResult {
              case let .success(isValid):
                // Calculate operation time
                let executionTime=Date().timeIntervalSince1970 - startTime

                // Return success with verification result
                return .success(
                  resultData: Data([isValid ? 1 : 0]),
                  executionTimeMs: executionTime * 1000,
                  metadata: ["isValid": isValid ? "true" : "false"]
                )

              case let .failure(error):
                return .failure(
                  errorDetails: "Verification failed: \(error)",
                  executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
                )
            }

          case let .failure(error):
            return .failure(
              errorDetails: "Failed to import signature: \(error)",
              executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
            )
        }

      case let .failure(error):
        return .failure(
          errorDetails: "Failed to import data: \(error)",
          executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
        )
    }
  }

  /**
   Process a hashing operation.

   - Parameters:
     - config: Configuration for the operation
     - operation: The security operation being performed
   - Returns: A result DTO with the operation result
   */
  private func processHashingOperation(
    _ config: SecurityConfigDTO,
    operation _: SecurityOperation
  ) async -> SecurityResultDTO {
    // Start timing the operation
    let startTime=Date().timeIntervalSince1970

    // Validate input
    guard let inputData=config.options?.metadata?["inputData"] else {
      return .failure(
        errorDetails: "Missing input data in configuration",
        executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
      )
    }

    // Import data to secure storage
    let importResult=await cryptoService.importData(
      Array(inputData.utf8),
      customIdentifier: nil
    )

    // Process import result
    switch importResult {
      case let .success(dataIdentifier):
        // Create hash options
        let hashOptions=HashingOptions(
          algorithm: config.hashAlgorithm
        )

        // Generate hash
        let hashResult=await cryptoService.hash(
          dataIdentifier: dataIdentifier,
          options: hashOptions
        )

        switch hashResult {
          case let .success(hashIdentifier):
            // Get the hash data
            let exportResult=await cryptoService.exportData(identifier: hashIdentifier)

            switch exportResult {
              case let .success(hashData):
                // Calculate operation time
                let executionTime=Date().timeIntervalSince1970 - startTime

                // Return success
                return .success(
                  resultData: Data(hashData),
                  executionTimeMs: executionTime * 1000,
                  metadata: ["algorithm": config.hashAlgorithm.rawValue]
                )

              case let .failure(error):
                return .failure(
                  errorDetails: "Failed to export hash: \(error)",
                  executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
                )
            }

          case let .failure(error):
            return .failure(
              errorDetails: "Hashing failed: \(error)",
              executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
            )
        }

      case let .failure(error):
        return .failure(
          errorDetails: "Failed to import data: \(error)",
          executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
        )
    }
  }

  /**
   Process a hash verification operation.

   - Parameters:
     - config: Configuration for the operation
     - operation: The security operation being performed
   - Returns: A result DTO with the operation result
   */
  private func processHashVerificationOperation(
    _ config: SecurityConfigDTO,
    operation _: SecurityOperation
  ) async -> SecurityResultDTO {
    // Start timing the operation
    let startTime=Date().timeIntervalSince1970

    // Validate inputs
    guard let inputData=config.options?.metadata?["inputData"] else {
      return .failure(
        errorDetails: "Missing input data in configuration",
        executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
      )
    }

    guard
      let expectedHashStr=config.options?.metadata?["expectedHash"],
      let expectedHashData=expectedHashStr.data(using: .utf8)
    else {
      return .failure(
        errorDetails: "Missing or invalid expected hash in configuration",
        executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
      )
    }

    // Import data to secure storage
    let importDataResult=await cryptoService.importData(
      Array(inputData.utf8),
      customIdentifier: nil
    )

    // Process import result
    switch importDataResult {
      case let .success(dataIdentifier):
        // Import expected hash to secure storage
        let importHashResult=await cryptoService.importData(
          [UInt8](expectedHashData),
          customIdentifier: nil
        )

        switch importHashResult {
          case let .success(hashIdentifier):
            // Create hash options
            let hashOptions=HashingOptions(
              algorithm: config.hashAlgorithm
            )

            // Verify the hash
            let verifyResult=await cryptoService.verifyHash(
              dataIdentifier: dataIdentifier,
              hashIdentifier: hashIdentifier,
              options: hashOptions
            )

            switch verifyResult {
              case let .success(isValid):
                // Calculate operation time
                let executionTime=Date().timeIntervalSince1970 - startTime

                // Return success with verification result
                return .success(
                  resultData: Data([isValid ? 1 : 0]),
                  executionTimeMs: executionTime * 1000,
                  metadata: ["isValid": isValid ? "true" : "false"]
                )

              case let .failure(error):
                return .failure(
                  errorDetails: "Hash verification failed: \(error)",
                  executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
                )
            }

          case let .failure(error):
            return .failure(
              errorDetails: "Failed to import expected hash: \(error)",
              executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
            )
        }

      case let .failure(error):
        return .failure(
          errorDetails: "Failed to import data: \(error)",
          executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000
        )
    }
  }

  /**
   Handle an operation error.

   - Parameters:
     - error: The error that occurred
     - operationName: The name of the operation that failed
     - executionTimeMs: The execution time of the operation in milliseconds
   - Returns: A result DTO with the error details
   */
  private func handleOperationError(
    _ error: Error,
    operationName: String,
    executionTimeMs: TimeInterval
  ) -> SecurityResultDTO {
    .failure(
      errorDetails: "Operation '\(operationName)' failed: \(error.localizedDescription)",
      executionTimeMs: executionTimeMs,
      metadata: ["errorType": String(describing: error)]
    )
  }
}
