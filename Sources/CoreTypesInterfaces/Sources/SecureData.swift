/// A secure container for sensitive binary data that automatically zeroes memory when deallocated
/// This provides a Foundation-free implementation that is Sendable-compliant
public struct SecureData: Sendable, Equatable {
  /// Internal storage using ByteArray
  private let storage: ByteArray

  /// Initialize with raw bytes
  /// - Parameter bytes: Array of bytes
  public init(bytes: [UInt8]) {
    storage = ByteArray(bytes: bytes)
  }

  /// Initialize with a ByteArray
  /// - Parameter byteArray: ByteArray to wrap
  public init(byteArray: ByteArray) {
    storage = byteArray
  }

  /// Access the raw bytes
  /// Note: This should be used carefully as it exposes the sensitive data
  public var rawBytes: [UInt8] {
    storage.rawBytes
  }

  /// The number of bytes in the secure data
  public var count: Int {
    storage.count
  }

  /// Get a slice of the data
  /// - Parameters:
  ///   - from: Starting index
  ///   - length: Number of bytes to include
  /// - Returns: A new SecureData containing the specified slice
  public func slice(from: Int, length: Int) -> SecureData {
    SecureData(byteArray: storage.slice(from: from, length: length))
  }

  /// Creates an empty SecureData instance
  public static var empty: SecureData {
    SecureData(bytes: [])
  }

  /// Check if the SecureData is empty
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Subscript access to individual bytes
  public subscript(index: Int) -> UInt8 {
    storage[index]
  }

  /// Subscript access to a range of bytes
  public subscript(range: Range<Int>) -> SecureData {
    SecureData(byteArray: storage[range])
  }
}

/// Extension to provide compatibility with existing BinaryData usage
extension SecureData {
  /// Convert to a ByteArray representation
  public var asByteArray: ByteArray {
    storage
  }
}
