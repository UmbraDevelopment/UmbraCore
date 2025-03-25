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
      return "encrypt"
    case .decrypt:
      return "decrypt"
    case .generateKey:
      return "generateKey"
    case .hash:
      return "hash"
    case .sign:
      return "sign"
    case .verify:
      return "verify"
    case .deriveKey:
      return "deriveKey"
    case .store:
      return "store"
    case .retrieve:
      return "retrieve"
    case .delete:
      return "delete"
    case .custom(let operationName, _):
      return "custom(\(operationName))"
    }
  }
}
