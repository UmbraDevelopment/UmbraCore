/**
 # SecureBytes Extensions

 This file provides extensions to SecureBytes for handling common encoding/decoding operations
 in a Foundation-independent way.

 ## Features

 * Foundation-independent string conversions
 * Utility methods for working with passwords and text
 * Compatible with the XPC DTO-based protocols
 */

import UmbraCoreTypes

/// Extensions to SecureBytes for handling text encoding/decoding
extension SecureBytes {
  /// ASCII encoding table for converting between bytes and ASCII characters
  private static let asciiTable: [UInt8: Character]={
    var table: [UInt8: Character]=[:]
    // ASCII printable characters (32-126)
    for byte in 32...126 {
      if let scalar=UnicodeScalar(byte) {
        table[UInt8(byte)]=Character(scalar)
      }
    }
    return table
  }()

  /// Convert SecureBytes to a string using ASCII encoding
  /// - Returns: ASCII string representation or nil if data contains non-ASCII bytes
  public func toASCIIString() -> String? {
    var result=""
    for byte in self {
      guard let char=Self.asciiTable[byte] else {
        return nil // Non-ASCII byte found
      }
      result.append(char)
    }
    return result
  }

  /// Create SecureBytes from an ASCII string
  /// - Parameter string: ASCII string to convert
  /// - Returns: New SecureBytes containing the encoded string data
  public static func fromASCIIString(_ string: String) -> SecureBytes? {
    var bytes: [UInt8]=[]
    for char in string {
      guard
        let scalar=char.unicodeScalars.first,
        scalar.value <= 127, // ASCII range
        let byte=UInt8(exactly: scalar.value)
      else {
        return nil // Non-ASCII character found
      }
      bytes.append(byte)
    }
    return SecureBytes(bytes: bytes)
  }

  /// Get a substring as SecureBytes
  /// - Parameters:
  ///   - start: Start index
  ///   - length: Length of substring
  /// - Returns: New SecureBytes containing the substring
  public func substring(start: Int, length: Int) -> SecureBytes {
    guard start >= 0, length > 0, start + length <= count else {
      return SecureBytes()
    }
    var result=[UInt8]()
    for i in start..<(start + length) {
      result.append(self[i])
    }
    return SecureBytes(bytes: result)
  }

  /// Determine if SecureBytes is valid ASCII text
  /// - Returns: True if all bytes are valid ASCII
  public func isASCIIText() -> Bool {
    for byte in self {
      if byte > 127 {
        return false
      }
    }
    return true
  }
}
