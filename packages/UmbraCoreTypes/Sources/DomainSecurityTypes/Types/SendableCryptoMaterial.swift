import Darwin

/**
 # SendableCryptoMaterial

 A Swift 6 compatible, value-type, Sendable data container specifically designed
 for handling sensitive cryptographic material in accordance with the Alpha Dot Five
 architecture principles.

 This type serves as the recommended replacement for the deprecated `SecureBytes` class,
 providing a seamless interface for working with the actor-based `SecureStorage` system.

 ## Thread Safety

 Unlike the previous `SecureBytes` class which required manual thread-safety handling,
 `SendableCryptoMaterial` is a pure value type and automatically `Sendable`. This makes it safe
 to use across actor boundaries without additional synchronisation.

 ## Memory Protection

 While `SendableCryptoMaterial` provides a value-type interface for sensitive data, actual secure
 memory handling is delegated to the `SecureStorage` actor to ensure proper isolation
 of mutable state and memory protection.

 ## Usage

 ```swift
 // Create secure data with bytes
 let material = SendableCryptoMaterial(bytes: [1, 2, 3, 4])

 // Create secure data with random bytes
 let randomMaterial = try SendableCryptoMaterial.randomBytes(count: 32)

 // Use with actor-based SecureStorage
 let encryptedMaterial = try await secureStorageActor.encrypt(material)
 ```
 */
public struct SendableCryptoMaterial: Sendable, Equatable {
  /// The underlying bytes
  private let bytes: [UInt8]

  /// Length of the secure data in bytes
  public var count: Int {
    bytes.count
  }

  /**
   Initialises a new secure data instance with the given bytes.

   - Parameter bytes: The bytes to store
   */
  public init(bytes: [UInt8]) {
    self.bytes = bytes
  }

  /**
   Creates a secure data instance with zeroes.

   - Parameter count: Number of zero bytes
   - Returns: A secure data instance filled with zeroes
   */
  public static func zeroes(count: Int) -> SendableCryptoMaterial {
    SendableCryptoMaterial(bytes: [UInt8](repeating: 0, count: count))
  }

  /**
   Creates a secure data instance with random bytes.

   - Parameter count: Number of random bytes
   - Returns: A secure data instance with cryptographically secure random bytes
   - Throws: Error if secure random generation fails
   */
  public static func randomBytes(count: Int) throws -> SendableCryptoMaterial {
    var bytes = [UInt8](repeating: 0, count: count)
    
    // Generate random bytes using system crypto
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    guard status == errSecSuccess else {
      throw SendableCryptoMaterialError.randomGenerationFailed
    }
    
    return SendableCryptoMaterial(bytes: bytes)
  }

  /**
   Exposes the bytes for processing in a controlled manner.

   - Parameter accessor: A closure that receives the bytes for processing
   - Returns: The result of the accessor closure
   */
  public func withUnsafeBytes<T>(_ accessor: ([UInt8]) throws -> T) rethrows -> T {
    try accessor(bytes)
  }

  /**
   Creates a copy of the secure data.

   - Returns: A new instance with the same bytes
   */
  public func copy() -> SendableCryptoMaterial {
    // Since this is a value type, a direct copy is safe
    self
  }
}

/**
 Errors related to secure data operations.
 */
public enum SendableCryptoMaterialError: Error, Sendable {
  /// Failed to generate random bytes
  case randomGenerationFailed
  /// Invalid hexadecimal string
  case invalidHexString
}

/**
 Compatibility extension for working with hexadecimal representations.
 */
extension SendableCryptoMaterial {
  /**
   Initialises secure data from a hexadecimal string.

   - Parameter hexString: The hexadecimal string
   - Throws: SendableCryptoMaterialError if the string is invalid
   */
  public init(hexString: String) throws {
    let hexString = hexString.replacingOccurrences(of: " ", with: "")
    
    // Validate string length
    guard hexString.count % 2 == 0 else {
      throw SendableCryptoMaterialError.invalidHexString
    }
    
    // Convert hex string to bytes
    var bytes = [UInt8]()
    var index = hexString.startIndex
    
    while index < hexString.endIndex {
      let nextIndex = hexString.index(index, offsetBy: 2)
      let byteString = hexString[index..<nextIndex]
      
      guard let byte = UInt8(byteString, radix: 16) else {
        throw SendableCryptoMaterialError.invalidHexString
      }
      
      bytes.append(byte)
      index = nextIndex
    }
    
    self.init(bytes: bytes)
  }
  
  /**
   Converts the secure data to a hexadecimal string.

   - Parameter uppercase: Whether to use uppercase letters
   - Returns: Hexadecimal string representation
   */
  public func toHexString(uppercase: Bool = false) -> String {
    withUnsafeBytes { bytes in
      let format = uppercase ? "%02X" : "%02x"
      return bytes.map { String(format: format, $0) }.joined()
    }
  }
}

/**
 Extension for compatibility with the actor-based API.
 */
extension SendableCryptoMaterial {
  /**
   Converts to a byte array for use with actor-based APIs.
   
   - Note: This method should generally only be called by actor implementations
     to minimize exposure of the raw bytes outside of isolated contexts.
   
   - Returns: Array of bytes
   */
  public func toByteArray() -> [UInt8] {
    withUnsafeBytes { $0 }
  }
}
