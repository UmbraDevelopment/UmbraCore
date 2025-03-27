/**
 # UmbraCore Security Utilities

 This file provides general utility functions that are used throughout
 the SecurityProviders module. It defines reusable helper methods for
 common operations like data conversion and format handling.

 ## Responsibilities

 * Provide data conversion utilities (hex, base64, etc.)
 * Support reuse of common functionality across the module
 * Encapsulate implementation details of helper methods
 */

import Foundation
import SecurityCoreTypes
import SecurityTypes

/// Helper functions for security configuration and operations
enum Utilities {
  /// Convert hex string to Data
  /// - Parameter hexString: Hexadecimal string
  /// - Returns: Data representation or nil if invalid hex
  static func hexStringToData(_ hexString: String) -> [UInt8]? {
    // Remove any spaces from the string
    let hex = hexString.replacingOccurrences(of: " ", with: "")
    
    // Check for even number of characters
    guard hex.count % 2 == 0 else {
      return nil
    }
    
    var bytes = [UInt8]()
    bytes.reserveCapacity(hex.count / 2)
    
    // Process two characters at a time (one byte)
    for i in stride(from: 0, to: hex.count, by: 2) {
      let start = hex.index(hex.startIndex, offsetBy: i)
      let end = hex.index(start, offsetBy: 2)
      let byteString = String(hex[start..<end])
      
      guard let byte = UInt8(byteString, radix: 16) else {
        return nil
      }
      
      bytes.append(byte)
    }
    
    return bytes
  }
  
  /// Convert Base64 string to Data bytes
  /// - Parameter base64String: Base64-encoded string
  /// - Returns: Data bytes or nil if invalid Base64
  static func base64StringToData(_ base64String: String) -> [UInt8]? {
    guard let data = Data(base64Encoded: base64String) else {
      return nil
    }
    
    return [UInt8](data)
  }
  
  /**
   Convert binary data to a hexadecimal string.

   - Parameters:
   ///   - data: The binary data to convert
   ///   - uppercase: Whether to use uppercase letters (default: true)
   ///   - separator: Optional character to use as separator (default: none)
   - Returns: A hexadecimal string representation of the data

   ## Examples

   ```swift
   let hex = Utilities.dataToHexString([0xDE, 0xAD, 0xBE, 0xEF])
   // Returns: "DEADBEEF"

   let hexWithSeparator = Utilities.dataToHexString([0xDE, 0xAD, 0xBE, 0xEF], separator: " ")
   // Returns: "DE AD BE EF"
   ```
   */
  static func dataToHexString(
    _ data: [UInt8],
    uppercase: Bool = true,
    separator: String? = nil
  ) -> String {
    let format = uppercase ? "%02X" : "%02x"
    let hexChars = data.map { String(format: format, $0) }

    if let separator {
      return hexChars.joined(separator: separator)
    } else {
      return hexChars.joined()
    }
  }

  /**
   Convert binary data to a Base64-encoded string.

   - Parameters:
   ///   - data: The binary data to encode
   ///   - options: Base64 encoding options (default: none)
   - Returns: A Base64-encoded string

   ## Examples

   ```swift
   let base64 = Utilities.dataToBase64String([0x48, 0x65, 0x6C, 0x6C, 0x6F])
   // Returns: "SGVsbG8="
   ```
   */
  static func dataToBase64String(
    _ data: [UInt8],
    options: Data.Base64EncodingOptions = []
  ) -> String {
    let data = Data(data)
    return data.base64EncodedString(options: options)
  }
}
