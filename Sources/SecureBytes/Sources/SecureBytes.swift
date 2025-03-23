/// A Foundation-free implementation of binary data storage
/// that conforms to all required concurrency and safety protocols.
@frozen
public struct SecureBytes: Sendable, Equatable, Hashable {
  // MARK: - Properties

  /// The underlying storage of bytes
  private let storage: [UInt8]

  /// The number of bytes in the data
  public var count: Int {
    storage.count
  }

  /// Returns whether the data is empty
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Access to the raw bytes array.
  /// Note: This is marked 'unsafe' because it provides direct access to the
  /// internal storage, which could potentially allow mutations that bypass the
  /// SecureBytes safety guarantees.
  public var unsafeBytes: [UInt8] {
    storage
  }

  // MARK: - Initialisation

  /// Creates a new instance from an array of bytes
  /// - Parameter bytes: The bytes to store
  public init(_ bytes: [UInt8]) {
    storage=bytes
  }

  /// Creates an empty instance
  public init() {
    storage=[]
  }

  /// Creates a new instance with the specified size, filled with zeros
  /// - Parameter count: The size in bytes
  public init(count: Int) {
    storage=[UInt8](repeating: 0, count: count)
  }

  /// Creates a new instance with the specified size, filled with the given value
  /// - Parameters:
  ///   - repeating: The value to fill the data with
  ///   - count: The number of bytes
  public init(repeating: UInt8, count: Int) {
    storage=[UInt8](repeating: repeating, count: count)
  }

  // MARK: - Subscript Access

  /// Access individual bytes by index
  public subscript(index: Int) -> UInt8 {
    precondition(index >= 0 && index < storage.count, "Index out of bounds")
    return storage[index]
  }

  /// Access a range of bytes
  public subscript(bounds: Range<Int>) -> SecureBytes {
    precondition(
      bounds.lowerBound >= 0 && bounds.upperBound <= storage.count,
      "Range out of bounds"
    )
    return SecureBytes(Array(storage[bounds]))
  }

  // MARK: - Methods

  /// Get the raw bytes as an array
  /// - Returns: Array of bytes
  public func bytes() -> [UInt8] {
    Array(storage)
  }

  /// Concatenate two SecureBytes instances
  /// - Parameter other: The instance to append
  /// - Returns: A new combined instance
  public func appending(_ other: SecureBytes) -> SecureBytes {
    var newBytes=bytes()
    newBytes.append(contentsOf: other.bytes())
    return SecureBytes(newBytes)
  }

  /// Combines two SecureBytes instances into one
  /// - Parameters:
  ///   - first: The first SecureBytes object
  ///   - second: The second SecureBytes object
  /// - Returns: A new SecureBytes instance containing both byte arrays
  public static func combine(_ first: SecureBytes, _ second: SecureBytes) -> SecureBytes {
    first.appending(second)
  }

  /// Splits this SecureBytes instance at the specified position
  /// - Parameter position: The position to split at
  /// - Returns: A tuple containing two SecureBytes instances
  /// - Throws: Error if the position is out of bounds
  public func split(at position: Int) throws -> (SecureBytes, SecureBytes) {
    guard position >= 0, position <= count else {
      throw SecureBytesError.invalidRange
    }

    let firstPart=self[0..<position]
    let secondPart=self[position..<count]

    return (firstPart, secondPart)
  }

  /// Returns a hex string representation of the bytes
  /// - Returns: Hexadecimal string
  public func hexString() -> String {
    storage.map { byteToHexString($0) }.joined()
  }

  /// Converts a single byte to its hexadecimal string representation
  /// - Parameter byte: The byte to convert
  /// - Returns: Two-character hex string
  private func byteToHexString(_ byte: UInt8) -> String {
    let digits=["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
    let highIndex=Int(byte >> 4)
    let lowIndex=Int(byte & 0x0F)
    return digits[highIndex] + digits[lowIndex]
  }

  /// Creates a SecureBytes instance from a hex string
  /// - Parameter hex: Hexadecimal string
  /// - Returns: New SecureBytes instance, or nil if invalid hex
  public static func fromHexString(_ hex: String) -> SecureBytes? {
    guard hex.count % 2 == 0 else { return nil }

    var bytes=[UInt8]()
    bytes.reserveCapacity(hex.count / 2)

    var index=hex.startIndex
    while index < hex.endIndex {
      let nextIndex=hex.index(index, offsetBy: 2)
      let byteString=hex[index..<nextIndex]

      guard let byte=UInt8(String(byteString), radix: 16) else { return nil }
      bytes.append(byte)

      index=nextIndex
    }

    return SecureBytes(bytes)
  }

  // MARK: - Equatable & Hashable

  public static func == (lhs: SecureBytes, rhs: SecureBytes) -> Bool {
    lhs.storage == rhs.storage
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(storage)
  }
}

// MARK: - Error Handling

/// Errors that can be thrown by SecureBytes operations
public enum SecureBytesError: Error {
  case invalidRange
  case invalidData
}

// MARK: - ExpressibleByArrayLiteral

extension SecureBytes: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement=UInt8

  public init(arrayLiteral elements: UInt8...) {
    self.init(elements)
  }
}

// MARK: - CustomStringConvertible

extension SecureBytes: CustomStringConvertible {
  public var description: String {
    "SecureBytes(\(count) bytes)"
  }
}

// MARK: - CustomDebugStringConvertible

extension SecureBytes: CustomDebugStringConvertible {
  public var debugDescription: String {
    let prefix=count <= 16 ? hexString() : hexString().prefix(32) + "..."
    return "SecureBytes(\(count) bytes: \(prefix))"
  }
}
