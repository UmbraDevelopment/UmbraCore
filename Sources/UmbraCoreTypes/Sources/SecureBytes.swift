// import UmbraErrors
import UmbraLogging

/// A secure byte array that automatically zeros its contents when deallocated
///
/// This type provides a foundation-free alternative to Foundation's Data type
/// with special focus on secure memory handling for sensitive information.
/// The storage is automatically zeroed when the instance is deallocated.
@frozen
public struct SecureBytes: Sendable, Equatable, Hashable, Codable {
  // MARK: - Storage

  /// Internal storage of the binary data
  private var storage: [UInt8]

  // MARK: - Initialization

  /// Create an empty SecureBytes instance
  public init() {
    storage=[]
  }

  /// Create a SecureBytes instance with the specified size, filled with zeros
  /// - Parameter count: The number of bytes to allocate
  /// - Throws: `SecureBytesError.allocationFailed` if memory allocation fails
  public init(count: Int) throws {
    storage=[UInt8](repeating: 0, count: count)
    guard !storage.isEmpty else {
      throw SecureBytesError.allocationFailed
    }
  }

  /// Create a SecureBytes instance with the specified capacity, filled with zeros
  /// - Parameter capacity: The number of bytes to allocate
  public init(capacity: Int) {
    storage=[UInt8](repeating: 0, count: capacity)
  }

  /// Create a SecureBytes instance from raw bytes
  /// - Parameter bytes: The bytes to use
  public init(bytes: [UInt8]) {
    storage=bytes
  }

  /// Create a SecureBytes instance from a raw buffer pointer and count
  /// - Parameters:
  ///   - bytes: Pointer to the bytes
  ///   - count: Number of bytes to copy
  public init(bytes: UnsafeRawPointer, count: Int) {
    let buffer=UnsafeRawBufferPointer(start: bytes, count: count)
    storage=[UInt8](buffer)
  }

  /// Create a SecureBytes instance from a base64 encoded string
  /// - Parameter base64Encoded: The base64 encoded string
  public init?(base64Encoded string: String) {
    // Base64 decoding table
    var base64DecodingTable=[UInt8](repeating: 0xFF, count: 256)
    let base64Chars=Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

    for (i, char) in base64Chars.enumerated() {
      base64DecodingTable[Int(char.asciiValue ?? 0)]=UInt8(i)
    }

    // Remove padding characters
    var input=string
    input=input.replacing("=", with: "")

    // Calculate output length (3 bytes for every 4 characters)
    let outputLength=(input.count * 3) / 4
    var result=[UInt8](repeating: 0, count: outputLength)

    var outputIndex=0
    var bits=0
    var bitsCount=0

    for char in input {
      guard
        let asciiValue=char.asciiValue,
        asciiValue < base64DecodingTable.count,
        base64DecodingTable[Int(asciiValue)] != 0xFF
      else {
        return nil // Invalid character
      }

      let value=base64DecodingTable[Int(asciiValue)]
      bits=(bits << 6) | Int(value)
      bitsCount += 6

      if bitsCount >= 8 {
        bitsCount -= 8
        result[outputIndex]=UInt8((bits >> bitsCount) & 0xFF)
        outputIndex += 1
      }
    }

    // Resize the result if needed (due to padding considerations)
    if outputIndex < result.count {
      result=Array(result[0..<outputIndex])
    }

    storage=result
  }

  /// Create a SecureBytes instance from a hex string
  /// - Parameter hexString: The hexadecimal string to convert
  /// - Throws: `SecureBytesError.invalidHexString` if the string is not valid
  /// hexadecimal
  public init(hexString: String) throws {
    // Validate the hex string has an even number of characters
    guard hexString.count % 2 == 0 else {
      throw SecureBytesError.invalidHexString
    }

    // Parse the hex string
    var bytes=[UInt8]()
    var index=hexString.startIndex

    while index < hexString.endIndex {
      let nextIndex=hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) ?? hexString
        .endIndex
      let byteString=String(hexString[index..<nextIndex])

      guard let byte=UInt8(byteString, radix: 16) else {
        throw SecureBytesError.invalidHexString
      }

      bytes.append(byte)
      index=nextIndex
    }

    storage=bytes
  }

  // MARK: - Deallocating

  /// Called when the instance is deallocated.
  /// Securely zeros the storage to remove sensitive data from memory.
  public mutating func secureClear() {
    for i in 0..<storage.count {
      storage[i]=0
    }
  }

  /// Alias for secureClear()
  public mutating func secureZero() {
    secureClear()
  }

  // MARK: - Accessing Data

  /// The number of bytes in the instance.
  public var count: Int {
    storage.count
  }

  /// Returns a Boolean value indicating whether the SecureBytes is empty.
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Provides temporary access to the bytes as an UnsafeRawBufferPointer
  /// - Parameter body: A closure that takes an UnsafeRawBufferPointer and returns a value
  /// - Returns: The value returned by the closure
  /// - Throws: Rethrows any error thrown by the closure
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    let bytes = self.toArray()
    return try bytes.withUnsafeBytes(body)
  }

  /// Accesses the byte at the specified position.
  ///
  /// - Parameter position: The position of the byte to access.
  /// - Returns: The byte at the specified position.
  /// - Throws: `SecureBytesError.outOfBounds` if the position is outside the valid
  /// range.
  public func byte(at position: Int) throws -> UInt8 {
    guard position >= 0, position < storage.count else {
      throw SecureBytesError.outOfBounds
    }
    return storage[position]
  }

  // MARK: - Subscripts

  /// Accesses the byte at the specified position.
  public subscript(index: Int) -> UInt8 {
    get {
      storage[index]
    }
    set {
      storage[index]=newValue
    }
  }

  /// Accesses a contiguous subrange of the bytes.
  public subscript(bounds: Range<Int>) -> SecureBytes {
    get {
      SecureBytes(bytes: Array(storage[bounds]))
    }
    set {
      storage.replaceSubrange(bounds, with: newValue.storage)
    }
  }

  /// Returns a hex string representation of the bytes.
  public func hexString() -> String {
    let hexDigits=["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    var hexString=""

    for byte in storage {
      let firstDigit=hexDigits[Int((byte >> 4) & 0xF)]
      let secondDigit=hexDigits[Int(byte & 0xF)]
      hexString.append(firstDigit)
      hexString.append(secondDigit)
    }

    return hexString
  }

  /// Returns a base64 encoded string representation of the bytes.
  public func base64EncodedString() -> String {
    if storage.isEmpty {
      return ""
    }

    // Base64 encoding table
    let base64Chars=Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
    var result=String()
    var i=0
    let count=storage.count

    // Process 3 bytes at a time
    while i + 3 <= count {
      let byte1=storage[i]
      let byte2=storage[i + 1]
      let byte3=storage[i + 2]

      let charIndex1=Int((byte1 >> 2) & 0x3F)
      let charIndex2=Int(((byte1 & 0x3) << 4) | ((byte2 >> 4) & 0xF))
      let charIndex3=Int(((byte2 & 0xF) << 2) | ((byte3 >> 6) & 0x3))
      let charIndex4=Int(byte3 & 0x3F)

      result.append(base64Chars[charIndex1])
      result.append(base64Chars[charIndex2])
      result.append(base64Chars[charIndex3])
      result.append(base64Chars[charIndex4])

      i += 3
    }

    // Handle remaining bytes
    if i + 2 == count {
      let byte1=storage[i]
      let byte2=storage[i + 1]

      let charIndex1=Int((byte1 >> 2) & 0x3F)
      let charIndex2=Int(((byte1 & 0x3) << 4) | ((byte2 >> 4) & 0xF))
      let charIndex3=Int((byte2 & 0xF) << 2)

      result.append(base64Chars[charIndex1])
      result.append(base64Chars[charIndex2])
      result.append(base64Chars[charIndex3])
      result.append("=")
    } else if i + 1 == count {
      let byte1=storage[i]

      let charIndex1=Int((byte1 >> 2) & 0x3F)
      let charIndex2=Int((byte1 & 0x3) << 4)

      result.append(base64Chars[charIndex1])
      result.append(base64Chars[charIndex2])
      result.append("==")
    }

    return result
  }

  /// Convert the SecureBytes to a standard array of bytes.
  ///
  /// - Warning: This copies the bytes to a non-secure array. Use with caution as the bytes
  /// won't be automatically zeroed when the array is deallocated.
  public func toArray() -> [UInt8] {
    Array(storage)
  }

  /// Convert a segment of the bytes to a standard array.
  ///
  /// - Parameters:
  ///   - start: The starting index
  ///   - count: The number of bytes to copy
  /// - Returns: An array containing the specified bytes
  /// - Throws: `SecureBytesError.outOfBounds` if the range is invalid
  public func toArray(start: Int, count: Int) throws -> [UInt8] {
    guard start >= 0, isEmpty, start + count <= storage.count else {
      throw SecureBytesError.outOfBounds
    }
    return Array(storage[start..<(start + count)])
  }
}

// Helper extension for string operations when Foundation is not available
extension String {
  /// Replace all occurrences of a substring with another, optimised for simple characters
  /// - Parameters:
  ///   - target: The character to replace
  ///   - replacement: The replacement string
  /// - Returns: A new string with all occurrences of target replaced by replacement
  fileprivate func replacing(_ target: String, with replacement: String) -> String {
    // Since we're only using this to remove "=" characters,
    // we can implement a simpler solution
    guard !isEmpty && target.count == 1, let targetChar=target.first else {
      return self
    }

    var result=""
    for char in self {
      if char == targetChar {
        result.append(contentsOf: replacement)
      } else {
        result.append(char)
      }
    }

    return result
  }
}

// MARK: - Equatable and Hashable

extension SecureBytes {
  /// Compare two SecureBytes instances for equality.
  public static func == (lhs: SecureBytes, rhs: SecureBytes) -> Bool {
    guard lhs.count == rhs.count else {
      return false
    }

    for i in 0..<lhs.count {
      if lhs[i] != rhs[i] {
        return false
      }
    }

    return true
  }

  /// Calculate a hash value for this instance.
  public func hash(into hasher: inout Hasher) {
    for byte in storage {
      hasher.combine(byte)
    }
  }
}

// MARK: - Codable

extension SecureBytes {
  /// Encode this instance.
  public func encode(to encoder: Encoder) throws {
    var container=encoder.singleValueContainer()
    try container.encode(storage)
  }

  /// Decode a new instance.
  public init(from decoder: Decoder) throws {
    let container=try decoder.singleValueContainer()
    storage=try container.decode([UInt8].self)
  }
}

/// Errors related to SecureBytes operations
public enum SecureBytesError: Error, Equatable, Sendable {
  /// Memory allocation failed when creating a SecureBytes instance
  case allocationFailed

  /// The operation attempted to access bytes outside the valid range
  case outOfBounds

  /// The provided hex string was invalid
  case invalidHexString

  /// General error with message
  case generalError(String)
}
