import Foundation
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
    storage = []
  }

  /// Create a SecureBytes instance with the specified size, filled with zeros
  /// - Parameter count: The number of bytes to allocate
  /// - Throws: `SecureBytesError.allocationFailed` if memory allocation fails
  public init(count: Int) throws {
    storage = [UInt8](repeating: 0, count: count)
    guard !storage.isEmpty else {
      throw SecureBytesError.allocationFailed
    }
  }

  /// Create a SecureBytes instance with the specified capacity, filled with zeros
  /// - Parameter capacity: The number of bytes to allocate
  public init(capacity: Int) {
    storage = [UInt8](repeating: 0, count: capacity)
  }

  /// Create a SecureBytes instance from raw bytes
  /// - Parameter bytes: The bytes to use
  public init(bytes: [UInt8]) {
    storage = bytes
  }

  /// Create a SecureBytes instance from a raw buffer pointer and count
  /// - Parameters:
  ///   - bytes: Pointer to the bytes
  ///   - count: Number of bytes to copy
  public init(bytes: UnsafeRawPointer, count: Int) {
    let buffer = UnsafeRawBufferPointer(start: bytes, count: count)
    storage = [UInt8](buffer)
  }

  // MARK: - Properties

  /// The number of bytes in the buffer
  public var count: Int {
    storage.count
  }

  /// Indicates whether the buffer is empty
  public var isEmpty: Bool {
    storage.isEmpty
  }

  // MARK: - Subscript Access

  /// Provides array-like access to the bytes in the buffer
  /// - Parameter position: The position to access
  /// - Returns: The byte at the specified position
  public subscript(position: Int) -> UInt8 {
    get {
      storage[position]
    }
    set {
      storage[position] = newValue
    }
  }

  // MARK: - Methods

  /// Securely zero the buffer contents
  public mutating func reset() {
    for i in 0..<storage.count {
      storage[i] = 0
    }
  }

  /// Get the byte at the specified position
  /// - Parameter position: The position to access
  /// - Returns: The byte at the specified position
  /// - Throws: `SecureBytesError.outOfBounds` if the position is outside the valid range
  public func byte(at position: Int) throws -> UInt8 {
    guard position >= 0, position < storage.count else {
      throw SecureBytesError.outOfBounds
    }
    return storage[position]
  }

  /// Append the contents of another SecureBytes instance
  /// - Parameter other: The instance to append
  public mutating func append(_ other: SecureBytes) {
    storage.append(contentsOf: other.storage)
  }

  /// Append a byte to the buffer
  /// - Parameter byte: The byte to append
  public mutating func append(_ byte: UInt8) {
    storage.append(byte)
  }

  /// Append bytes to the buffer
  /// - Parameter bytes: The bytes to append
  public mutating func append(contentsOf bytes: [UInt8]) {
    storage.append(contentsOf: bytes)
  }

  /// Append bytes from a raw buffer pointer
  /// - Parameters:
  ///   - bytes: Pointer to the bytes
  ///   - count: Number of bytes to append
  public mutating func append(bytes: UnsafeRawPointer, count: Int) {
    let buffer = UnsafeRawBufferPointer(start: bytes, count: count)
    storage.append(contentsOf: buffer)
  }

  /// Convert to a Data instance (requires Foundation)
  /// - Returns: A Data instance containing the same bytes
  public func toData() -> Data {
    Data(storage)
  }

  /// Execute a block with direct access to the raw bytes
  /// - Parameter body: A closure that takes a pointer to the bytes
  /// - Returns: The result of the closure
  /// - Throws: Rethrows any error thrown by the closure
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try storage.withUnsafeBytes(body)
  }
}

/// Errors that can occur when working with SecureBytes
public enum SecureBytesError: Error {
  /// Memory allocation failed
  case allocationFailed
  /// Index access was out of bounds
  case outOfBounds
  /// Generic operation failure
  case operationFailed
}
