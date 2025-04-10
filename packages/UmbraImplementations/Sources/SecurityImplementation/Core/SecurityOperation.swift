import CoreSecurityTypes
import Foundation
import LoggingTypes

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

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
        "encrypt"
      case .decrypt:
        "decrypt"
      case .generateKey:
        "generateKey"
      case .secureStore:
        "secureStore"
      case .secureRetrieve:
        "secureRetrieve"
      case .secureDelete:
        "secureDelete"
      case .sign:
        "sign"
      case .verify:
        "verify"
      case .generateRandom:
        "generateRandom"
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
        "Encrypt Data"
      case .decrypt:
        "Decrypt Data"
      case .generateKey:
        "Generate Cryptographic Key"
      case .secureStore:
        "Securely Store Data"
      case .secureRetrieve:
        "Securely Retrieve Data"
      case .secureDelete:
        "Securely Delete Data"
      case .sign:
        "Sign Data"
      case .verify:
        "Verify Signature"
      case let .generateRandom(length):
        "Generate \(length) Bytes of Random Data"
    }
  }
}

// CoreSecurityError extension has been moved to CoreSecurityError+Extensions.swift
