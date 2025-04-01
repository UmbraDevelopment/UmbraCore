/**
 # SecurityUtilsImpl

 Provides utility functions for common security operations such as secure string
 handling, data conversion, validation, and other helper functions that support
 the core security functionality.

 ## Responsibilities

 * Provide secure string handling utilities
 * Offer data conversion functions (hex, base64, etc.)
 * Validate security-related inputs and configurations
 * Support random data generation
 * Handle secure comparison of sensitive data
 */

import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import UmbraErrors

/// Implementation of security utilities that support the core security functionality
public final class SecurityUtilsImpl: Sendable {
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
  /// - Parameters:
  ///   - bytes: The binary data to convert
  ///   - uppercase: Whether to use uppercase letters (default: true)
  ///   - separator: Optional character to use as separator (default: none)
  /// - Returns: A hexadecimal string representation
  public func bytesToHexString(
    _ bytes: [UInt8],
    uppercase: Bool=true,
    separator: String?=nil
  ) -> String {
    let format=uppercase ? "%02X" : "%02x"

    // Convert bytes to hex chars
    let hexChars=bytes.map { String(format: format, $0) }

    if let separator {
      return hexChars.joined(separator: separator)
    } else {
      return hexChars.joined()
    }
  }

  /// Convert a hexadecimal string to binary data
  /// - Parameter hexString: The hex string to convert
  /// - Returns: The converted binary data as a byte array or nil if conversion fails
  public func hexStringToBytes(_ hexString: String) -> [UInt8]? {
    // Remove any spaces from the string
    let hex=hexString.replacingOccurrences(of: " ", with: "")

    // Check for even number of characters
    guard hex.count % 2 == 0 else {
      return nil
    }

    var bytes=[UInt8]()
    bytes.reserveCapacity(hex.count / 2)

    // Process two characters at a time (one byte)
    for i in stride(from: 0, to: hex.count, by: 2) {
      let start=hex.index(hex.startIndex, offsetBy: i)
      let end=hex.index(start, offsetBy: 2)
      let byteString=String(hex[start..<end])

      guard let byte=UInt8(byteString, radix: 16) else {
        return nil
      }

      bytes.append(byte)
    }

    return bytes
  }

  /// Convert binary data to a Base64-encoded string
  /// - Parameter bytes: The binary data to encode
  /// - Returns: A Base64-encoded string
  public func bytesToBase64String(_ bytes: [UInt8]) -> String {
    let data=Data(bytes)
    return data.base64EncodedString()
  }

  /// Convert a Base64 string to binary data
  /// - Parameter base64String: The Base64-encoded string
  /// - Returns: The decoded binary data as a byte array or nil if decoding fails
  public func base64StringToBytes(_ base64String: String) -> [UInt8]? {
    guard let data=Data(base64Encoded: base64String) else {
      return nil
    }
    return [UInt8](data)
  }

  // MARK: - Validation

  /// Validate that a key meets minimum security requirements
  /// - Parameters:
  ///   - key: The key to validate
  ///   - minimumBitLength: Minimum required bit length
  /// - Returns: True if the key meets requirements, false otherwise
  public func validateKeyStrength(key: [UInt8], minimumBitLength: Int) -> Bool {
    // Check key length
    key.count * 8 >= minimumBitLength
  }

  // MARK: - Random Data

  /// Generate a random string of specified length with given character set
  /// - Parameters:
  ///   - length: Length of the random string
  ///   - charset: Character set to use (default: alphanumeric)
  /// - Returns: Random string of specified length
  public func generateRandomString(
    length: Int,
    charset: String="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  ) -> String {
    let randomBytes=generateRandomBytes(count: length)
    let charsetLength=charset.count

    return randomBytes.enumerated().reduce(into: "") { result, element in
      let index=charset.index(charset.startIndex, offsetBy: Int(element.element) % charsetLength)
      result.append(charset[index])
    }
  }

  /// Generate random bytes of specified count
  /// - Parameter count: Number of random bytes to generate
  /// - Returns: Array of random bytes
  public func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes=[UInt8](repeating: 0, count: count)
    _=SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return bytes
  }

  // MARK: - Secure Comparison

  /// Securely compare two byte arrays for equality
  /// - Parameters:
  ///   - lhs: First byte array
  ///   - rhs: Second byte array
  /// - Returns: True if equal, false otherwise
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
