import Darwin

/// A secure string container that keeps string data encrypted in memory when not in use
/// and provides secure string operations without Foundation dependencies.
@frozen
public struct SecureString: @unchecked Sendable {
  /// Module version
  public static let version = "1.0.0"

  // Internal storage - we use a byte array to avoid String memory management
  private var _storage: [UInt8]
  private let _lock: Lock

  /// Creates a new secure string from a regular Swift string.
  /// The input string is securely converted to bytes and then encrypted.
  ///
  /// - Parameter string: The string to secure
  public init(_ string: String) {
    // Convert the string to UTF-8 bytes
    let bytes = Array(string.utf8)

    // Store the bytes
    _storage = SecureString.scramble(bytes: bytes)
    _lock = Lock()

    // Overwrite the incoming string memory if possible
    _ = string
  }

  /// Creates a secure string from raw UTF-8 bytes
  ///
  /// - Parameter bytes: The UTF-8 bytes to store securely
  public init(bytes: [UInt8]) {
    _storage = SecureString.scramble(bytes: bytes)
    _lock = Lock()
  }

  /// Access the string value in a secure manner by providing a closure that receives
  /// the temporary decrypted string value.
  ///
  /// - Parameter accessor: The closure to execute with the temporary decrypted string
  /// - Returns: The result of the accessor closure
  public func access<T>(_ accessor: (String) throws -> T) rethrows -> T {
    try _lock.withLock {
      // Decrypt the bytes
      let decryptedBytes = SecureString.unscramble(bytes: _storage)

      // Create a temporary string
      let tempString = String(decoding: decryptedBytes, as: UTF8.self)

      // Execute the accessor and return the result
      return try accessor(tempString)
    }
  }

  /// Returns the length of the secured string
  public var length: Int {
    _storage.count
  }

  /// Returns true if the secure string is empty
  public var isEmpty: Bool {
    _storage.isEmpty
  }

  /// Compares this secure string with another secure string for equality
  /// without decrypting either to a regular String
  ///
  /// - Parameter other: The other secure string to compare
  /// - Returns: True if the strings are equal
  public func isEqual(to other: SecureString) -> Bool {
    guard length == other.length else {
      return false
    }

    return _lock.withLock {
      let selfBytes = SecureString.unscramble(bytes: _storage)
      let otherBytes = SecureString.unscramble(bytes: other._storage)

      // Constant-time comparison to avoid timing attacks
      var result: UInt8 = 0
      for i in 0..<selfBytes.count {
        result |= selfBytes[i] ^ otherBytes[i]
      }

      return result == 0
    }
  }

  /// Simple XOR scrambling for memory protection
  /// Note: This is a basic implementation - a real implementation would use
  /// a more sophisticated encryption approach
  private static func scramble(bytes: [UInt8]) -> [UInt8] {
    let key: [UInt8] = [0x82, 0x45, 0x7D, 0x39, 0xF2, 0x67, 0x9B, 0x25]
    var result = [UInt8](repeating: 0, count: bytes.count)

    for i in 0..<bytes.count {
      result[i] = bytes[i] ^ key[i % key.count]
    }

    return result
  }

  /// Unscramble the bytes back to their original form
  private static func unscramble(bytes: [UInt8]) -> [UInt8] {
    // XOR is its own inverse, so we use the same operation for decryption
    scramble(bytes: bytes)
  }
}

// MARK: - Equatable

extension SecureString: Equatable {
  public static func == (lhs: SecureString, rhs: SecureString) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Hashable

extension SecureString: Hashable {
  public func hash(into hasher: inout Hasher) {
    access { string in
      hasher.combine(string)
    }
  }
}

// MARK: - Custom String Convertible

extension SecureString: CustomStringConvertible {
  public var description: String {
    "<SecureString: length=\(length)>"
  }
}

// MARK: - CustomDebugStringConvertible

extension SecureString: CustomDebugStringConvertible {
  public var debugDescription: String {
    "<SecureString: length=\(length), content=REDACTED>"
  }
}

// MARK: - Foundation-free lock implementation

/// A simple lock implementation that doesn't rely on Foundation
@usableFromInline
final class Lock {
  @usableFromInline
  var _mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

  @usableFromInline
  init() {
    let err = pthread_mutex_init(_mutex, nil)
    precondition(err == 0, "Failed to initialize mutex with error \(err)")
  }

  deinit {
    pthread_mutex_destroy(_mutex)
    _mutex.deallocate()
  }

  func lock() {
    let err = pthread_mutex_lock(_mutex)
    precondition(err == 0, "Failed to lock mutex with error \(err)")
  }

  func unlock() {
    let err = pthread_mutex_unlock(_mutex)
    precondition(err == 0, "Failed to unlock mutex with error \(err)")
  }

  func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}
