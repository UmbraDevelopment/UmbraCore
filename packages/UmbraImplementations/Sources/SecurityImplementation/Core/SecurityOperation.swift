import Foundation

/**
 # SecurityOperation

 Represents the various security operations that can be performed by the security provider.

 ## Associated Values

 Some operations include associated values that provide additional parameters required
 for that specific operation. For example, the `generateRandom` operation includes a length
 parameter that determines how many bytes of random data should be generated.

 ## Descriptions

 Each operation includes a human-readable description, which is useful for logging throughout
 the system, ensuring proper monitoring and diagnostics.
 */
public enum SecurityOperation: CustomStringConvertible, Equatable {
  /// Encryption of data
  case encrypt
  
  /// Decryption of data
  case decrypt
  
  /// Generation of a cryptographic key
  case generateKey
  
  /// Secure storage of data
  case secureStore
  
  /// Secure retrieval of data
  case secureRetrieve
  
  /// Secure deletion of data
  case secureDelete
  
  /// Signing of data
  case sign
  
  /// Verification of signed data
  case verify
  
  /// Generation of random secure data
  case generateRandom(length: Int)
  
  /**
   The string representation of the operation.
   
   - Returns: A string representation suitable for use in logs and identifiers
   */
  public var rawValue: String {
    switch self {
    case .encrypt:
      return "encrypt"
    case .decrypt:
      return "decrypt"
    case .generateKey:
      return "generateKey"
    case .secureStore:
      return "secureStore"
    case .secureRetrieve:
      return "secureRetrieve"
    case .secureDelete:
      return "secureDelete"
    case .sign:
      return "sign"
    case .verify:
      return "verify"
    case .generateRandom:
      return "generateRandom"
    }
  }
  
  /**
   Creates a new SecurityOperation from a raw string value.
   This is used mainly for serialization and deserialization.
   Note that for `generateRandom`, this will create an instance with a default length of 32.
   
   - Parameter rawValue: The string representation
   - Returns: The matching operation or nil if no match
   */
  public init?(rawValue: String) {
    switch rawValue {
    case "encrypt":
      self = .encrypt
    case "decrypt":
      self = .decrypt
    case "generateKey":
      self = .generateKey
    case "secureStore":
      self = .secureStore
    case "secureRetrieve":
      self = .secureRetrieve
    case "secureDelete":
      self = .secureDelete
    case "sign":
      self = .sign
    case "verify":
      self = .verify
    case "generateRandom":
      self = .generateRandom(length: 32) // Default length
    default:
      return nil
    }
  }
  
  /**
   A human-readable description of the operation.
   
   - Returns: A description suitable for display and logging
   */
  public var description: String {
    switch self {
    case .encrypt:
      return "Encrypt Data"
    case .decrypt:
      return "Decrypt Data"
    case .generateKey:
      return "Generate Cryptographic Key"
    case .secureStore:
      return "Securely Store Data"
    case .secureRetrieve:
      return "Securely Retrieve Data"
    case .secureDelete:
      return "Securely Delete Data"
    case .sign:
      return "Sign Data"
    case .verify:
      return "Verify Signature"
    case .generateRandom(let length):
      return "Generate \(length) Bytes of Random Data"
    }
  }
}
