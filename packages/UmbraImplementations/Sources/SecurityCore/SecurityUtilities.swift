import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import UmbraErrors

/**
 # SecurityUtilities

 Provides essential utility functions for common security operations such as secure string
 handling, data conversion, validation, and other helper functions that support
 the core security functionality.

 This implementation follows the Alpha Dot Five architecture principles for
 security components but does not use actors as it is stateless and thread-safe.

 ## Responsibilities

 * Provide secure string handling utilities
 * Offer data conversion functions (hex, base64, etc.)
 * Validate security-related inputs and configurations
 * Support random data generation
 * Handle secure comparison of sensitive data
 */

/// Implementation of security utilities that support the core security functionality
public struct SecurityUtilities: Sendable {
  // MARK: - Initialisation

  /// Creates a new security utilities instance
  public init() {
    // No initialisation needed - stateless service
  }

  // MARK: - String Handling

  /// Securely convert a string to a byte array
  /// - Parameter string: String to convert
  /// - Returns: Byte array representation of the string
  public func secureStringToBytes(_ string: String) -> [UInt8] {
    let data=Data(string.utf8)
    return [UInt8](data)
  }

  /// Securely convert a byte array to a string
  /// - Parameter bytes: Byte array to convert
  /// - Returns: String representation of the bytes
  public func bytesToSecureString(_ bytes: [UInt8]) -> String? {
    let data=Data(bytes)
    return String(data: data, encoding: .utf8)
  }

  // MARK: - Data Conversion

  /// Convert binary data to a hexadecimal string
  /// - Parameter bytes: Binary data to convert
  /// - Returns: Hexadecimal string representation
  public func bytesToHexString(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined()
  }

  /// Convert a hexadecimal string to binary data
  /// - Parameter hexString: Hexadecimal string to convert
  /// - Returns: Binary data if valid, nil if invalid hexadecimal
  public func hexStringToBytes(_ hexString: String) -> [UInt8]? {
    let cleanString=hexString.replacingOccurrences(of: " ", with: "")

    // Validate string is even length and contains only hex characters
    guard
      cleanString.count % 2 == 0,
      cleanString.allSatisfy({ character in
        character.isHexDigit
      })
    else {
      return nil
    }

    // Convert pairs of characters to bytes
    var bytes=[UInt8]()
    for i in stride(from: 0, to: cleanString.count, by: 2) {
      let startIndex=cleanString.index(cleanString.startIndex, offsetBy: i)
      let endIndex=cleanString.index(startIndex, offsetBy: 2)
      let byteString=cleanString[startIndex..<endIndex]

      if let byte=UInt8(byteString, radix: 16) {
        bytes.append(byte)
      } else {
        return nil
      }
    }

    return bytes
  }

  /// Convert binary data to a Base64 string
  /// - Parameter bytes: Binary data to convert
  /// - Returns: Base64 string representation
  public func bytesToBase64(_ bytes: [UInt8]) -> String {
    Data(bytes).base64EncodedString()
  }

  /// Convert a Base64 string to binary data
  /// - Parameter base64String: Base64 string to convert
  /// - Returns: Binary data if valid, nil if invalid Base64
  public func base64ToBytes(_ base64String: String) -> [UInt8]? {
    guard let data=Data(base64Encoded: base64String) else {
      return nil
    }
    return [UInt8](data)
  }

  // MARK: - Security Validation

  /// Validate a security key has the expected length
  /// - Parameters:
  ///   - key: Key to validate
  ///   - expectedLength: Expected length in bytes
  /// - Returns: True if valid, false otherwise
  public func validateKeyLength(_ key: [UInt8], expectedLength: Int) -> Bool {
    key.count == expectedLength
  }

  /// Generate a secure random string of the specified length
  /// - Parameter length: Length of the string to generate
  /// - Returns: Random string suitable for tokens, etc.
  public func generateRandomString(length: Int) -> String {
    do {
      let randomBytes=try MemoryProtection.secureRandomBytes(length)
      return bytesToBase64(randomBytes).prefix(length).replacingOccurrences(of: "/", with: "A")
        .replacingOccurrences(of: "+", with: "B")
    } catch {
      // Fallback if secure random generation fails
      let characters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in characters.randomElement()! })
    }
  }

  // MARK: - Secure Comparison

  /// Perform a constant-time comparison of two byte arrays to prevent timing attacks
  /// - Parameters:
  ///   - lhs: First byte array to compare
  ///   - rhs: Second byte array to compare
  /// - Returns: True if arrays are equal, false otherwise
  public func secureCompare(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
    // Constant-time comparison to prevent timing attacks
    guard lhs.count == rhs.count else {
      return false
    }

    var result: UInt8=0
    for i in 0..<lhs.count {
      result |= lhs[i] ^ rhs[i]
    }

    return result == 0
  }
}
