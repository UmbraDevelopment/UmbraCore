import CryptoTypes
import Foundation

/**
 # SecureDataFactory

 Factory for creating SecureData instances with various security guarantees.
 This factory follows the Alpha Dot Five architecture pattern of providing
 factory methods that create properly configured instances.

 ## Usage Examples

 ```swift
 // Create from raw data
 let secureData = SecureDataFactory.createFromData(myData)

 // Create from string
 let securePassword = SecureDataFactory.createFromString("my-secure-password")

 // Create random data
 let randomBytes = await SecureDataFactory.createRandom(length: 32)
 ```
 */
public enum SecureDataFactory {
  /**
   Creates a SecureData instance from raw data.

   - Parameter data: The data to secure
   - Returns: A SecureData instance containing the data
   */
  public static func createFromData(_ data: Data) -> SecureData {
    SecureData(data)
  }

  /**
   Creates a SecureData instance from a string using the specified encoding.

   - Parameters:
      - string: The string to secure
      - encoding: The string encoding to use, defaults to UTF-8
   - Returns: A SecureData instance containing the encoded string
   */
  public static func createFromString(
    _ string: String,
    encoding: String.Encoding = .utf8
  ) -> SecureData? {
    guard let data=string.data(using: encoding) else {
      return nil
    }

    return SecureData(data)
  }

  /**
   Creates a SecureData instance from a hexadecimal string.

   - Parameter hexString: The hexadecimal string to convert
   - Returns: A SecureData instance containing the decoded hex data
   */
  public static func createFromHexString(_ hexString: String) -> SecureData? {
    // Remove any spaces or other formatting characters
    let hex=hexString.replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "<", with: "")
      .replacingOccurrences(of: ">", with: "")
      .replacingOccurrences(of: "0x", with: "")

    // Check for valid hex string (must be even length)
    guard hex.count % 2 == 0 else {
      return nil
    }

    var bytes=[UInt8]()
    bytes.reserveCapacity(hex.count / 2)

    // Convert pairs of hex characters to bytes
    var index=hex.startIndex
    while index < hex.endIndex {
      let nextIndex=hex.index(index, offsetBy: 2)
      let byteString=hex[index..<nextIndex]

      guard let byte=UInt8(byteString, radix: 16) else {
        return nil
      }

      bytes.append(byte)
      index=nextIndex
    }

    return SecureData(bytes: bytes)
  }

  /**
   Creates a SecureData instance containing random data.

   - Parameter length: The number of random bytes to generate
   - Returns: A SecureData instance containing random data
   */
  public static func createRandom(length: Int) async -> SecureData {
    // Use a cryptographically secure random number generator
    var bytes=[UInt8](repeating: 0, count: length)

    // Fill with random bytes
    let status=SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

    // Verify the operation succeeded
    guard status == errSecSuccess else {
      // Fallback to less secure but still usable random generation
      for i in 0..<length {
        bytes[i]=UInt8.random(in: 0...255)
      }
    }

    return SecureData(bytes: bytes)
  }

  /**
   Creates a SecureData instance by concatenating multiple SecureData instances.

   - Parameter dataPieces: The SecureData instances to concatenate
   - Returns: A SecureData instance containing all the data
   */
  public static func createByConcatenating(_ dataPieces: [SecureData]) -> SecureData {
    guard !dataPieces.isEmpty else {
      return SecureData(capacity: 0)
    }

    var result=dataPieces[0]

    for i in 1..<dataPieces.count {
      result=result.appending(dataPieces[i])
    }

    return result
  }

  /**
   Creates a SecureData instance from a base64-encoded string.

   - Parameter base64String: The base64 string to decode
   - Returns: A SecureData instance containing the decoded data
   */
  public static func createFromBase64(_ base64String: String) -> SecureData? {
    guard let data=Data(base64Encoded: base64String) else {
      return nil
    }

    return SecureData(data)
  }

  /**
   Creates an empty SecureData instance with the specified capacity.

   - Parameter capacity: The initial capacity in bytes
   - Returns: An empty SecureData instance
   */
  public static func createEmpty(capacity: Int=0) -> SecureData {
    SecureData(capacity: capacity)
  }
}
