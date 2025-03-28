import Foundation
import SecurityCoreTypes

/**
 # SecureBytes Extensions

 This file provides essential extensions to facilitate safe and efficient conversions
 between `SecureBytes` and Foundation data types. These extensions are critical for
 integrating the security module with Foundation-based APIs while maintaining
 the security guarantees provided by `SecureBytes`.

 ## Security Considerations

 - When converting between `SecureBytes` and `Data`, be aware that `Data` is not
   designed for secure storage of sensitive information and may persist in memory.
 - Always limit the scope of any `Data` objects created from `SecureBytes` and
   consider manually zeroing `Data` objects after use.
 - These conversions should only be used at integration boundaries where
   interaction with non-security-focused APIs is necessary.
 */

/// Extensions for SecureBytes to facilitate data conversion while maintaining
/// security best practices.
extension SecureBytes {
  /**
   Converts SecureBytes to Data efficiently.

   This method provides a direct conversion from SecureBytes to Foundation's Data type.
   It's primarily intended for integration with APIs that require Data objects.

   ## Security Warning

   The returned Data object does not provide the same memory protection guarantees
   as SecureBytes. The caller is responsible for:

   1. Limiting the scope of the returned Data object
   2. Not persisting the Data object longer than necessary
   3. Not writing the Data to disk without encryption

   - Returns: A new Data object containing a copy of the bytes in this SecureBytes instance
   */
  public func toDataEfficient() -> Data {
    var bytes=[UInt8]()
    for i in 0..<count {
      bytes.append(self[i])
    }
    return Data(bytes)
  }

  /**
   Creates SecureBytes from a string using the specified encoding.

   This is useful for converting password strings, configuration values, or other
   text-based secrets into securely managed byte arrays.

   ## Usage Example

   ```swift
   // Convert a password to SecureBytes
   let passwordString = "my-secure-password"
   guard let passwordBytes = SecureBytes.from(string: passwordString) else {
       // Handle conversion failure
       return
   }

   // Use passwordBytes for cryptographic operations
   // ...

   // Optionally, zero out the original string memory
   // Note: This is not guaranteed in Swift, but helps reduce exposure
   var mutablePassword = passwordString
   mutablePassword = String(repeating: "0", count: mutablePassword.count)
   ```

   - Parameters:
      - string: The string to convert to SecureBytes
      - encoding: The string encoding to use (defaults to UTF-8)

   - Returns: A new SecureBytes instance containing the encoded string data,
             or nil if the string cannot be encoded using the specified encoding
   */
  public static func from(string: String, using encoding: String.Encoding = .utf8) -> SecureBytes? {
    guard let data=string.data(using: encoding) else { return nil }
    return SecureBytes(bytes: [UInt8](data))
  }

  /**
   Creates a hexadecimal string representation of the secure bytes.

   This method is useful for logging, debugging, or displaying non-sensitive
   cryptographic values like hashes or public identifiers.

   ## Security Consideration

   Do not use this method to convert sensitive data (like private keys or
   passwords) to strings for display or storage purposes.

   - Returns: A hexadecimal string representation of the bytes
   */
  public func toHexString() -> String {
    var hexString=""
    for i in 0..<count {
      hexString += String(format: "%02x", self[i])
    }
    return hexString
  }
}

/// Extensions for Data to facilitate conversion to SecureBytes
extension Data {
  /**
   Converts Data to SecureBytes efficiently.

   This method provides a direct way to secure data that was previously
   managed by Foundation's Data type. It's especially useful when receiving
   data from external APIs or storage that needs to be handled securely.

   ## Use Cases

   - Converting data received from network calls to secure storage
   - Converting user input captured as Data to a secure format for cryptographic operations
   - Transitioning legacy code from Data to SecureBytes

   ## Example

   ```swift
   // Fetch data from a network request
   let fetchedData: Data = // ... data from network

   // Convert to SecureBytes for secure processing
   let secureData = fetchedData.toSecureBytes()

   // Process with security operations
   // ...

   // Clear the original Data from memory when no longer needed
   // (note: not guaranteed in Swift but reduces exposure)
   var mutableData = fetchedData
   mutableData.resetBytes(in: 0..<mutableData.count)
   ```

   - Returns: A new SecureBytes instance containing a copy of this Data's bytes
   */
  public func toSecureBytes() -> SecureBytes {
    SecureBytes(bytes: [UInt8](self))
  }
}
