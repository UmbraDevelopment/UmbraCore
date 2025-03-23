/**
 # UmbraCore Security Provider Utilities

 This file provides utility functions used by the security provider components
 for common tasks such as data conversion, validation, and formatting.

 ## Functionality

 * Conversion between hexadecimal strings and binary data
 * Conversion between Base64 strings and binary data
 * Data format validation and normalisation

 ## Design Considerations

 These utilities are designed to be pure functions with no side effects or state,
 making them easily testable and reusable across different components of the
 security implementation.
 */

import Foundation

/// Utility functions for the security provider
///
/// Provides helper methods for common tasks such as data conversion,
/// validation, and formatting that are used across various security components.
enum Utilities {
  // MARK: - Data Conversion

  /**
   Convert a hexadecimal string to binary data.

   - Parameter hexString: The hex string to convert (e.g., "DEADBEEF")
   - Returns: The converted binary data or nil if conversion fails

   This method handles hex strings with or without spaces and ensures the
   string has an even number of characters for proper byte conversion.

   ## Examples

   ```swift
   let data = Utilities.hexStringToData("DEADBEEF")
   let dataWithSpaces = Utilities.hexStringToData("DE AD BE EF")
   ```
   */
  static func hexStringToData(_ hexString: String) -> [UInt8]? {
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

  /**
   Convert a Base64 string to binary data.

   - Parameter base64String: The Base64-encoded string
   - Returns: The decoded binary data or nil if decoding fails

   This method handles standard Base64 encoding as well as URL-safe Base64
   encoding with or without padding.

   ## Examples

   ```swift
   let data = Utilities.base64StringToData("SGVsbG8gV29ybGQh")
   ```
   */
  static func base64StringToData(_ base64String: String) -> [UInt8]? {
    // Convert to Data then to [UInt8]
    guard let data=Data(base64Encoded: base64String) else {
      return nil
    }

    // Convert Data to [UInt8]
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
    uppercase: Bool=true,
    separator: String?=nil
  ) -> String {
    let format=uppercase ? "%02X" : "%02x"
    let hexChars=data.map { String(format: format, $0) }

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
    options: Data.Base64EncodingOptions=[]
  ) -> String {
    let data=Data(data)
    return data.base64EncodedString(options: options)
  }
}
