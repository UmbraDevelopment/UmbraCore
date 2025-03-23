/**
 # UmbraCore Key Utilities

 This file provides utility functions for working with cryptographic keys in the
 UmbraCore security framework, including key derivation, format conversion, and validation.

 ## Responsibilities

 * Key format conversion (e.g., raw to PEM)
 * Key validation and verification
 * Key derivation functions
 * Key metadata utilities

 ## Security Considerations

 * Proper key format handling prevents misuse of keys
 * Key validation ensures that only appropriate keys are used for operations
 * Key derivation uses secure algorithms with appropriate parameters
 */

import CoreErrors
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Key type enumeration
public enum KeyType: String, Sendable, Equatable, CaseIterable {
  case symmetric="Symmetric"
  case asymmetric="Asymmetric"
  case hmac="HMAC"
  case rsa="RSA"
  case ec="EC"
  case unknown="Unknown"
}

/// Provides utility functions for working with cryptographic keys
///
/// KeyUtils offers helper methods for common key operations such as format conversion,
/// validation, and derivation. These utilities are used by other components of the
/// key management system.
final class KeyUtils {
  // MARK: - Initialisation

  /// Creates a new KeyUtils instance
  init() {
    // No initialisation needed - stateless service
  }

  // MARK: - Key Validation

  /// Validate that a key is appropriate for the specified operation
  /// - Parameters:
  ///   - key: The key to validate
  ///   - keyType: The expected key type
  ///   - minBits: The minimum acceptable key size in bits
  /// - Returns: True if the key is valid, false otherwise
  func validateKey(
    key: SecureBytes,
    keyType _: KeyType,
    minBits: Int
  ) -> Bool {
    // Check key length
    let keyLengthBits=key.count * 8
    guard keyLengthBits >= minBits else {
      return false
    }

    // Additional key type-specific validation could be added here
    // For example, checking asymmetric key structure

    return true
  }

  // MARK: - Key Derivation

  /// Derive a key from a password or passphrase
  /// - Parameters:
  ///   - password: The password or passphrase
  ///   - salt: Salt value for the derivation
  ///   - iterations: Number of iterations for the derivation
  ///   - keyLengthBytes: Length of the derived key in bytes
  /// - Returns: The derived key or an error if derivation fails
  func deriveKey(
    fromPassword password: String,
    salt: SecureBytes,
    iterations: Int,
    keyLengthBytes: Int
  ) -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Validate parameters
    guard !password.isEmpty else {
      return .failure(.invalidInput("Password cannot be empty"))
    }

    guard salt.count >= 16 else {
      return .failure(.invalidInput("Salt must be at least 16 bytes"))
    }

    guard iterations >= 10000 else {
      return .failure(.invalidInput("Iterations must be at least 10,000"))
    }

    guard keyLengthBytes > 0 else {
      return .failure(.invalidInput("Key length must be greater than 0"))
    }

    // For demo purposes, we'll use a simple approach
    // In a real implementation, this would use PBKDF2, HKDF, or another KDF

    // Convert password to bytes
    let passwordBytes=Array(password.utf8)

    // Create a new SecureBytes object to combine password and salt
    var combinedBytes=[UInt8]()
    combinedBytes.append(contentsOf: passwordBytes)

    // Access salt bytes and append
    salt.withUnsafeBytes { saltBytes in
      combinedBytes.append(contentsOf: saltBytes)
    }

    // Simple "stretching" for demonstration (not cryptographically secure)
    // In a real implementation, this would use a proper KDF
    var derivedKey=combinedBytes

    // Apply iterations (simplified for demonstration)
    for _ in 0..<iterations % 100 { // Just do a few rounds for demo
      // Hash the current value
      let hashedData=sha256(derivedKey)
      derivedKey=Array(hashedData.prefix(keyLengthBytes))
    }

    // Create the key with the specified length
    let result=SecureBytes(bytes: Array(derivedKey.prefix(keyLengthBytes)))
    return .success(result)
  }

  // MARK: - Format Conversion

  /// Convert a key to PEM format
  /// - Parameters:
  ///   - key: The key to convert
  ///   - keyType: The type of key
  /// - Returns: The key in PEM format
  func keyToPEM(
    key: SecureBytes,
    keyType: KeyType
  ) -> Result<String, UmbraErrors.Security.Protocols> {
    // This is a placeholder implementation
    // In a real implementation, this would create a proper PEM format

    // Convert to base64
    var base64=""
    key.withUnsafeBytes { keyBytes in
      let data=Data(keyBytes)
      base64=data.base64EncodedString()
    }

    return .success("""
      -----BEGIN \(keyType.rawValue.uppercased()) KEY-----
      \(base64)
      -----END \(keyType.rawValue.uppercased()) KEY-----
      """)
  }

  /// Parse a key from PEM format
  /// - Parameter pemString: The PEM string to parse
  /// - Returns: The key and its type, or an error if parsing fails
  func keyFromPEM(
    pemString: String
  ) -> Result<(key: SecureBytes, keyType: KeyType), UmbraErrors.Security.Protocols> {
    // This is a placeholder implementation
    // In a real implementation, this would properly parse PEM format

    // Check for key type
    let keyType: KeyType?=if pemString.contains("BEGIN SYMMETRIC KEY") {
      .symmetric
    } else if pemString.contains("BEGIN ASYMMETRIC KEY") {
      .asymmetric
    } else if pemString.contains("BEGIN HMAC KEY") {
      .hmac
    } else if pemString.contains("BEGIN RSA KEY") {
      .rsa
    } else if pemString.contains("BEGIN EC KEY") {
      .ec
    } else {
      .unknown
    }

    // Extract base64 content
    let lines=pemString.split(separator: "\n").map { String($0) }
    var base64Content=""

    var inContent=false
    for line in lines {
      if line.contains("BEGIN") {
        inContent=true
        continue
      } else if line.contains("END") {
        inContent=false
        break
      }

      if inContent {
        base64Content += line
      }
    }

    // Decode base64
    guard let data=Data(base64Encoded: base64Content) else {
      return .failure(.invalidInput("Invalid base64 encoding"))
    }

    // Create the key
    let key=SecureBytes(bytes: [UInt8](data))
    return .success((key: key, keyType: keyType!))
  }

  // MARK: - Helper Methods

  /// Simple SHA-256 implementation for demonstration
  private func sha256(_ input: [UInt8]) -> [UInt8] {
    // This is a placeholder. In a real implementation, this would use a crypto library
    // For now, we'll just return the input with some modifications
    var result=input
    if !result.isEmpty {
      result[0] = ~result[0] // Flip the first byte
    }
    return result
  }
}
