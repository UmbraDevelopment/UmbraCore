import Foundation
import UmbraCoreTypes

/// Defines security operations that can be performed by the security provider
/// This type allows for a unified interface for different security operations
public enum SecurityOperation: Sendable, Equatable {
  /// Encrypt data using the specified parameters
  case encrypt(data: SecureBytes, key: SecureBytes?)

  /// Decrypt data using the specified parameters
  case decrypt(data: SecureBytes, key: SecureBytes?)

  /// Generate a secure cryptographic key
  case generateKey(size: Int?)

  /// Compute a cryptographic hash
  case hash(data: SecureBytes, algorithm: HashAlgorithm?)

  /// Sign data using a private key
  case sign(data: SecureBytes, key: SecureBytes?)

  /// Verify a signature using a public key
  case verify(data: SecureBytes, signature: SecureBytes, key: SecureBytes?)

  /// Derive a key from a password or other input
  case deriveKey(input: SecureBytes, salt: SecureBytes?)

  /// Securely store data
  case store(data: SecureBytes, identifier: String)

  /// Retrieve securely stored data
  case retrieve(identifier: String)

  /// Delete securely stored data
  case delete(identifier: String)

  /// Custom operation with parameters
  case custom(operationName: String, parameters: [String: SecureBytes])

  /// Returns a string representation of the operation type
  /// suitable for logging and debugging (without sensitive data)
  public var operationType: String {
    switch self {
      case .encrypt:
        "encrypt"
      case .decrypt:
        "decrypt"
      case .generateKey:
        "generateKey"
      case .hash:
        "hash"
      case .sign:
        "sign"
      case .verify:
        "verify"
      case .deriveKey:
        "deriveKey"
      case .store:
        "store"
      case .retrieve:
        "retrieve"
      case .delete:
        "delete"
      case let .custom(operationName, _):
        "custom(\(operationName))"
    }
  }
}
