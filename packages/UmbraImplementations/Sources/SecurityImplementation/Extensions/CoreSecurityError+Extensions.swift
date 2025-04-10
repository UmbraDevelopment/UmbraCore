import CoreSecurityTypes
import Foundation

/**
 # CoreSecurityTypes Extensions

 Extension methods for CoreSecurityTypes to provide mapping between legacy CoreSecurityError
 and the type-safe SecurityError enum used in the Alpha Dot Five architecture.

 This extension allows for seamless integration between existing code that uses CoreSecurityError
 and the new standardised error handling approach using SecurityError.
 */

// MARK: - CoreSecurityError to SecurityError Mapping

extension CoreSecurityError {
  /**
   Maps a CoreSecurityError to its equivalent SecurityError type

   - Returns: The corresponding SecurityError type
   */
  public func toSecurityError() -> CoreSecurityTypes.SecurityError {
    switch self {
      case let .invalidInput(message):
        .invalidInputData(reason: message)
      case let .cryptoError(message):
        if message.lowercased().contains("encrypt") {
          .encryptionFailed(reason: message)
        } else if message.lowercased().contains("decrypt") {
          .decryptionFailed(reason: message)
        } else if message.lowercased().contains("sign") {
          .signingFailed(reason: message)
        } else if message.lowercased().contains("verif") {
          .verificationFailed(reason: message)
        } else if message.lowercased().contains("hash") {
          .hashingFailed(reason: message)
        } else {
          .unknownError(message)
        }
      case let .configurationError(message):
        .invalidConfiguration(reason: message)
      case let .unsupportedOperation(message):
        .unsupportedOperation(operation: message)
      case let .unsupportedPlatform(message):
        .platformNotSupported(reason: message)
      case let .hardwareUnavailable(message):
        .secureEnclaveUnavailable(reason: message)
      case let .resourceError(message):
        .resourceError(reason: message)
    }
  }

  /**
   Creates an invalid verification context error with the specified reason

   - Parameter reason: The reason for the error
   - Returns: A CoreSecurityError with the appropriate error code
   */
  public static func invalidVerificationContext(reason: String) -> CoreSecurityError {
    .invalidInput("Invalid verification context: \(reason)")
  }

  /**
   Creates a decryption failed error with the specified reason

   - Parameter reason: The reason for the error
   - Returns: A CoreSecurityError with the appropriate error code
   */
  public static func decryptionFailed(reason: String) -> CoreSecurityError {
    .cryptoError("Decryption failed: \(reason)")
  }

  /**
   Creates an encryption failed error with the specified reason

   - Parameter reason: The reason for the error
   - Returns: A CoreSecurityError with the appropriate error code
   */
  public static func encryptionFailed(reason: String) -> CoreSecurityError {
    .cryptoError("Encryption failed: \(reason)")
  }

  /**
   Creates an invalid operation error with the specified reason

   - Parameter reason: The reason for the error
   - Returns: A CoreSecurityError with the appropriate error code
   */
  public static func invalidOperation(reason: String) -> CoreSecurityError {
    .unsupportedOperation("Invalid operation: \(reason)")
  }

  /**
   Creates a not initialised error

   - Returns: A CoreSecurityError with the appropriate error code
   */
  public static func notInitialised() -> CoreSecurityError {
    .configurationError("Security service not initialised")
  }
}

// MARK: - SecurityError Extensions

extension CoreSecurityTypes.SecurityError {
  /**
   Maps a SecurityError to its equivalent CoreSecurityError type

   - Returns: The corresponding CoreSecurityError type
   */
  public func toCoreSecurityError() -> CoreSecurityError {
    switch self {
      case let .encryptionFailed(reason):
        .cryptoError("Encryption failed: \(reason ?? "Unknown reason")")
      case let .decryptionFailed(reason):
        .cryptoError("Decryption failed: \(reason ?? "Unknown reason")")
      case let .hashingFailed(reason):
        .cryptoError("Hashing failed: \(reason ?? "Unknown reason")")
      case let .keyGenerationFailed(reason):
        .cryptoError("Key generation failed: \(reason ?? "Unknown reason")")
      case let .keyStorageFailed(reason):
        .cryptoError("Key storage failed: \(reason ?? "Unknown reason")")
      case let .keyRetrievalFailed(reason):
        .cryptoError("Key retrieval failed: \(reason ?? "Unknown reason")")
      case let .keyDeletionFailed(reason):
        .cryptoError("Key deletion failed: \(reason ?? "Unknown reason")")
      case let .signingFailed(reason):
        .cryptoError("Signing failed: \(reason ?? "Unknown reason")")
      case let .verificationFailed(reason):
        .cryptoError("Verification failed: \(reason ?? "Unknown reason")")
      case let .invalidInputData(reason):
        .invalidInput(reason ?? "Invalid input data")
      case let .invalidConfiguration(reason):
        .configurationError(reason ?? "Invalid configuration")
      case let .algorithmNotSupported(reason):
        .unsupportedOperation(reason ?? "Algorithm not supported")
      case let .secureEnclaveUnavailable(reason):
        .hardwareUnavailable(reason ?? "Secure Enclave unavailable")
      case .operationCancelled:
        .resourceError("Operation cancelled")
      case let .unsupportedOperation(operation):
        .unsupportedOperation("Unsupported operation: \(operation)")
      case let .platformNotSupported(reason):
        .unsupportedPlatform(reason ?? "Platform not supported")
      case let .storageOperationFailed(reason):
        .resourceError("Storage operation failed: \(reason)")
      case let .retrievalOperationFailed(reason):
        .resourceError("Retrieval operation failed: \(reason)")
      case let .deletionOperationFailed(reason):
        .resourceError("Deletion operation failed: \(reason)")
      case let .dataNotFound(reason):
        .resourceError("Data not found: \(reason)")
      case let .resourceError(reason):
        .resourceError(reason)
      case let .generalError(reason):
        .cryptoError(reason)
      case let .underlyingError(error):
        .cryptoError("Underlying error: \(error.localizedDescription)")
      case let .unknownError(reason):
        .cryptoError(reason ?? "Unknown error")
    }
  }
}
