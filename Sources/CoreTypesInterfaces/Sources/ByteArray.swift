/// A simple Foundation-free representation of a byte array
/// Provides a clean, Sendable-compatible way to handle binary data
public struct ByteArray: Sendable, Equatable, Hashable {
  /// The raw bytes
  private let bytes: [UInt8]

  /// Initialize with raw bytes
  /// - Parameter bytes: Array of bytes
  public init(bytes: [UInt8]) {
    self.bytes = bytes
  }

  /// Access the raw bytes
  public var rawBytes: [UInt8] {
    bytes
  }

  /// The number of bytes in the array
  public var count: Int {
    bytes.count
  }

  /// Creates a ByteArray from a slice of another ByteArray
  public init(slice: ArraySlice<UInt8>) {
    bytes = Array(slice)
  }

  /// Subscript access to individual bytes
  public subscript(index: Int) -> UInt8 {
    bytes[index]
  }

  /// Subscript access to a range of bytes
  public subscript(range: Range<Int>) -> ByteArray {
    ByteArray(bytes: Array(bytes[range]))
  }

  /// Get a slice of the data
  public func slice(from: Int, length: Int) -> ByteArray {
    let end = Swift.min(from + length, count)
    return self[from..<end]
  }

  /// Create an empty ByteArray
  public static var empty: ByteArray {
    ByteArray(bytes: [])
  }

  /// Check if the ByteArray is empty
  public var isEmpty: Bool {
    bytes.isEmpty
  }
}
