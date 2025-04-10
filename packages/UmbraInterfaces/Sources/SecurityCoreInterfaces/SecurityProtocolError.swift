import Foundation

/// Errors that can occur during security storage operations
public enum SecurityStorageError: Error, Sendable {
  /// The secure storage is not available
  case storageUnavailable

  /// The data was not found in secure storage
  case dataNotFound

  /// The key was not found in secure storage
  case keyNotFound

  /// The hash was not found in secure storage
  case hashNotFound

  /// Encryption operation failed
  case encryptionFailed

  /// Decryption operation failed
  case decryptionFailed

  /// Hashing operation failed
  case hashingFailed

  /// Hash verification failed
  case hashVerificationFailed

  /// Key generation failed
  case keyGenerationFailed

  /// The operation is not supported
  case unsupportedOperation

  /// The protocol implementation is not available
  case implementationUnavailable

  /// The identifier is invalid (empty or malformed)
  case invalidIdentifier(reason: String)

  /// The specified identifier does not exist in storage
  case identifierNotFound(identifier: String)

  /// General storage operation failure
  case storageFailure(reason: String)

  /// Generic error with reason
  case generalError(reason: String)

  /// Generic operation failure with optional message
  case operationFailed(String)

  /// Invalid input provided to the operation
  case invalidInput(String)

  /// Operation was rate limited for security purposes
  case operationRateLimited

  /// Generic storage error
  case storageError

  /// Description of the error for logging and debugging
  public var description: String {
    switch self {
      case .storageUnavailable:
        "Secure storage is not available"
      case .dataNotFound:
        "Data not found in secure storage"
      case .keyNotFound:
        "Key not found in secure storage"
      case .hashNotFound:
        "Hash not found in secure storage"
      case .encryptionFailed:
        "Encryption operation failed"
      case .decryptionFailed:
        "Decryption operation failed"
      case .hashingFailed:
        "Hashing operation failed"
      case .hashVerificationFailed:
        "Hash verification failed"
      case .keyGenerationFailed:
        "Key generation failed"
      case .unsupportedOperation:
        "The operation is not supported"
      case .implementationUnavailable:
        "The protocol implementation is not available"
      case let .operationFailed(message):
        "Operation failed: \(message)"
      case let .invalidInput(message):
        "Invalid input: \(message)"
      case .operationRateLimited:
        "Operation was rate limited for security purposes"
      case .storageError:
        "Generic storage error"
      case let .invalidIdentifier(reason):
        "Invalid identifier: \(reason)"
      case let .identifierNotFound(identifier):
        "Identifier not found: \(identifier)"
      case let .storageFailure(reason):
        "Storage failure: \(reason)"
      case let .generalError(reason):
        "General error: \(reason)"
    }
  }
}
