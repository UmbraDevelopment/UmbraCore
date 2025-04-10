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
    case .invalidInput(let message):
      return .invalidInputData(reason: message)
    case .cryptoError(let message):
      if message.lowercased().contains("encrypt") {
        return .encryptionFailed(reason: message)
      } else if message.lowercased().contains("decrypt") {
        return .decryptionFailed(reason: message)
      } else if message.lowercased().contains("sign") {
        return .signingFailed(reason: message)
      } else if message.lowercased().contains("verif") {
        return .verificationFailed(reason: message)
      } else if message.lowercased().contains("hash") {
        return .hashingFailed(reason: message)
      } else {
        return .unknownError(message)
      }
    case .configurationError(let message):
      return .invalidConfiguration(reason: message)
    case .unsupportedOperation(let message):
      return .unsupportedOperation(operation: message)
    case .unsupportedPlatform(let message):
      return .platformNotSupported(reason: message)
    case .hardwareUnavailable(let message):
      return .secureEnclaveUnavailable(reason: message)
    case .resourceError(let message):
      return .resourceError(reason: message)
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
    case .encryptionFailed(let reason):
      return .cryptoError("Encryption failed: \(reason ?? "Unknown reason")")
    case .decryptionFailed(let reason):
      return .cryptoError("Decryption failed: \(reason ?? "Unknown reason")")
    case .hashingFailed(let reason):
      return .cryptoError("Hashing failed: \(reason ?? "Unknown reason")")
    case .keyGenerationFailed(let reason):
      return .cryptoError("Key generation failed: \(reason ?? "Unknown reason")")
    case .keyStorageFailed(let reason):
      return .cryptoError("Key storage failed: \(reason ?? "Unknown reason")")
    case .keyRetrievalFailed(let reason):
      return .cryptoError("Key retrieval failed: \(reason ?? "Unknown reason")")
    case .keyDeletionFailed(let reason):
      return .cryptoError("Key deletion failed: \(reason ?? "Unknown reason")")
    case .signingFailed(let reason):
      return .cryptoError("Signing failed: \(reason ?? "Unknown reason")")
    case .verificationFailed(let reason):
      return .cryptoError("Verification failed: \(reason ?? "Unknown reason")")
    case .invalidInputData(let reason):
      return .invalidInput(reason ?? "Invalid input data")
    case .invalidConfiguration(let reason):
      return .configurationError(reason ?? "Invalid configuration")
    case .algorithmNotSupported(let reason):
      return .unsupportedOperation(reason ?? "Algorithm not supported")
    case .secureEnclaveUnavailable(let reason):
      return .hardwareUnavailable(reason ?? "Secure Enclave unavailable")
    case .operationCancelled:
      return .resourceError("Operation cancelled")
    case .unsupportedOperation(let operation):
      return .unsupportedOperation("Unsupported operation: \(operation)")
    case .platformNotSupported(let reason):
      return .unsupportedPlatform(reason ?? "Platform not supported")
    case .storageOperationFailed(let reason):
      return .resourceError("Storage operation failed: \(reason)")
    case .retrievalOperationFailed(let reason):
      return .resourceError("Retrieval operation failed: \(reason)")
    case .deletionOperationFailed(let reason):
      return .resourceError("Deletion operation failed: \(reason)")
    case .dataNotFound(let reason):
      return .resourceError("Data not found: \(reason)")
    case .resourceError(let reason):
      return .resourceError(reason)
    case .generalError(let reason):
      return .cryptoError(reason)
    case .underlyingError(let error):
      return .cryptoError("Underlying error: \(error.localizedDescription)")
    case .unknownError(let reason):
      return .cryptoError(reason ?? "Unknown error")
    }
  }
}
