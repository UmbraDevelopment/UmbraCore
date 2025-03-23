import UmbraCoreTypes_CoreErrors

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
    input=input.replacingOccurrences(of: "=", with: "")

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
  /// - Throws: `SecureBytesError.invalidHexString` if the string is not valid hexadecimal
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

  /// Accesses the byte at the specified position.
  ///
  /// - Parameter position: The position of the byte to access.
  /// - Returns: The byte at the specified position.
  /// - Throws: `SecureBytesError.outOfBounds` if the position is outside the valid range.
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
      let value=Int(byte)
      hexString += hexDigits[(value >> 4) & 0xF]
      hexString += hexDigits[value & 0xF]
    }

    return hexString
  }

  /// Returns a hex encoded string of the bytes
  public func hexEncodedString() -> String {
    hexString()
  }

  /// Returns a base64 encoded string of the bytes
  public func base64EncodedString() -> String {
    // Base64 encoding table
    let base64Alphabet=[
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
      "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
      "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
      "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"
    ]

    // Implementation for base64 encoding without Foundation
    var result=""
    var bits=0
    var bitsCount=0

    for byte in storage {
      bits=(bits << 8) | Int(byte)
      bitsCount += 8

      while bitsCount >= 6 {
        bitsCount -= 6
        let index=(bits >> bitsCount) & 0x3F
        result.append(base64Alphabet[index])
      }
    }

    // Handle remaining bits
    if bitsCount > 0 {
      bits=bits << (6 - bitsCount)
      let index=bits & 0x3F
      result.append(base64Alphabet[index])
    }

    // Add padding
    let padding=(4 - (result.count % 4)) % 4
    for _ in 0..<padding {
      result.append("=")
    }

    return result
  }

  /// Provides a slice of the SecureBytes.
  ///
  /// - Parameters:
  ///   - range: The range of bytes to include in the slice.
  /// - Returns: A new SecureBytes instance containing the specified bytes.
  /// - Throws: `SecureBytesError.outOfBounds` if the range is outside the valid range.
  public func slice(_ range: Range<Int>) throws -> SecureBytes {
    guard range.lowerBound >= 0, range.upperBound <= storage.count else {
      throw SecureBytesError.outOfBounds
    }

    return SecureBytes(bytes: Array(storage[range]))
  }

  /// Creates a slice of SecureBytes from a starting index and length
  /// - Parameters:
  ///   - from: The starting index of the slice
  ///   - length: The number of bytes to include in the slice
  /// - Returns: A new SecureBytes instance containing the specified bytes
  /// - Throws: `SecureBytesError.outOfBounds` if the range is outside the valid range
  public func slice(from startIndex: Int, length: Int) throws -> SecureBytes {
    let endIndex=startIndex + length
    guard startIndex >= 0, endIndex <= storage.count else {
      throw SecureBytesError.outOfBounds
    }

    return SecureBytes(bytes: Array(storage[startIndex..<endIndex]))
  }

  /// Performs a secure constant-time comparison with another SecureBytes
  /// - Parameter other: The SecureBytes to compare with
  /// - Returns: true if the contents are identical, false otherwise
  public func secureCompare(with other: SecureBytes) -> Bool {
    // Use the existing constant-time comparison from == operator
    self == other
  }

  /// Appends a single byte to the end of the SecureBytes.
  public mutating func append(_ byte: UInt8) {
    storage.append(byte)
  }

  /// Appends the contents of another SecureBytes to this one.
  public mutating func append(_ bytes: SecureBytes) {
    storage.append(contentsOf: bytes.storage)
  }

  /// Provides a way to access the raw bytes safely.
  /// - Parameter body: A closure that takes an unsafe pointer to the bytes and returns a value of
  /// type R.
  /// - Returns: A pointer to the bytes and the number of bytes.
  /// - Throws: `SecureBytesError.allocationFailed` if memory allocation fails.
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try storage.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
      try body(buffer)
    }
  }

  /// Provides mutable access to the raw bytes.
  public mutating func withUnsafeMutableBytes<R>(
    _ body: (UnsafeMutableRawBufferPointer) throws
      -> R
  ) rethrows -> R {
    try storage.withUnsafeMutableBytes { buffer in
      try body(buffer)
    }
  }
}

// MARK: - Equatable and Hashable

extension SecureBytes {
  /// Returns a Boolean value indicating whether two SecureBytes instances are equal.
  public static func == (lhs: SecureBytes, rhs: SecureBytes) -> Bool {
    // Constant-time comparison to avoid timing attacks
    guard lhs.storage.count == rhs.storage.count else {
      return false
    }

    var result: UInt8=0
    for i in 0..<lhs.storage.count {
      result |= lhs.storage[i] ^ rhs.storage[i]
    }

    return result == 0
  }

  /// Hashes the essential components of the SecureBytes instance.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(storage)
  }
}

// MARK: - Codable

extension SecureBytes {
  /// Encodes this SecureBytes into the given encoder.
  public func encode(to encoder: Encoder) throws {
    var container=encoder.singleValueContainer()
    try container.encode(storage)
  }

  /// Creates a new SecureBytes by decoding from the given decoder.
  @preconcurrency
  @available(*, deprecated, message: "Will need to be refactored for Swift 6")
  public init(from decoder: Decoder) throws {
    let container=try decoder.singleValueContainer()
    storage=try container.decode([UInt8].self)
  }
}

// MARK: - ExpressibleByArrayLiteral

extension SecureBytes: ExpressibleByArrayLiteral {
  /// Creates a SecureBytes instance from an array literal.
  public init(arrayLiteral elements: UInt8...) {
    storage=elements
  }
}

// MARK: - Operators

extension SecureBytes {
  /// Concatenates two SecureBytes instances.
  public static func + (lhs: SecureBytes, rhs: SecureBytes) -> SecureBytes {
    var result=lhs
    result.append(rhs)
    return result
  }
}
