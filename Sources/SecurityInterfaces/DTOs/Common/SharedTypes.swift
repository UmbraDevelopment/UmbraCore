import Foundation
import UmbraCoreTypes

/// Common types and utilities shared across DTO implementations
/// This file provides shared types and utilities used by multiple DTOs
/// to ensure consistency and avoid duplication.
public enum SecurityDTOSharedTypes {
  /// Common key status values
  public enum KeyStatus: String, Sendable, Codable {
    /// Key is active and valid for use
    case active
    /// Key has been revoked and should not be used
    case revoked
    /// Key has expired and is no longer valid
    case expired
    /// Key is suspected to be compromised and should not be used
    case compromised
    /// Key is pending deletion
    case pendingDeletion
    /// Key generation is in progress
    case generating
  }

  /// Common key algorithm categories
  public enum AlgorithmCategory: String, Sendable, Codable {
    /// Symmetric encryption algorithms (e.g., AES)
    case symmetric
    /// Asymmetric encryption algorithms (e.g., RSA, ECC)
    case asymmetric
    /// Hash algorithms (e.g., SHA-256)
    case hash
    /// Key derivation functions (e.g., PBKDF2)
    case keyDerivation
    /// Digital signature algorithms
    case signature
  }
  
  /// Convert SecureBytes to/from other binary representations
  public enum SecureBytesConverter {
    /// Convert from binary data to SecureBytes
    /// - Parameter data: Binary data to convert
    /// - Returns: Secure bytes representation
    public static func fromData(_ data: Data) -> SecureBytes {
      SecureBytes(Array(data))
    }
    
    /// Convert from SecureBytes to binary data
    /// - Parameter secureBytes: Secure bytes to convert
    /// - Returns: Data representation
    public static func toData(_ secureBytes: SecureBytes) -> Data {
      Data(secureBytes)
    }
  }
}
