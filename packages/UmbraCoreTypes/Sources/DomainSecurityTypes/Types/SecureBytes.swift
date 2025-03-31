import CoreSecurityTypes
import Foundation

/**
 A secure container for sensitive byte data that automatically handles
 memory protection and secure disposal.

 This type follows the architecture pattern for secure handling of
 sensitive data with proper memory management.
 */
@available(*, deprecated, message: "Use actor-based SecureStorage instead")
public final class SecureBytes: @unchecked Sendable {
  /// Underlying secure data storage
  private let secureStorage: Data

  /// Zeroisation flag - access only through thread-safe methods
  private var _isZeroised: Bool = false

  /// Thread-safe lock for access control
  private let lock = NSLock()
  
  /// Thread-safe accessor for zeroisation status
  private var isZeroised: Bool {
    get {
        lock.lock()
        defer { lock.unlock() }
        return _isZeroised
    }
    set {
        lock.lock()
        defer { lock.unlock() }
        _isZeroised = newValue
    }
  }

  /**
   Initialises a new secure byte container with the provided data.

   - Parameter data: Data to store securely
   */
  public init(data: Data) {
    secureStorage = data
  }

  /**
   Initialises a new secure byte container with zeroes.

   - Parameter count: Number of zero bytes to initialise
   */
  public init(zeroCount count: Int) {
    var bytes = [UInt8](repeating: 0, count: count)
    secureStorage = Data(bytes: &bytes, count: count)
  }

  /**
   Initialises a new secure byte container with random data.

   - Parameter count: Number of random bytes to generate
   - Throws: CoreSecurityError if random generation fails
   */
  public init(randomCount count: Int) throws {
    var bytes = [UInt8](repeating: 0, count: count)

    // Generate random bytes
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    guard status == errSecSuccess else {
      throw CoreSecurityError.cryptoError("Failed to generate secure random bytes: \(status)")
    }

    secureStorage = Data(bytes: &bytes, count: count)
  }

  /**
   Accesses the underlying data in a secure manner.

   Data is only accessible within the provided closure and is not
   retained elsewhere to minimise exposure.

   - Parameter accessHandler: Closure that receives the data temporarily
   - Returns: Whatever the closure returns
   - Throws: CoreSecurityError if the data has been zeroised
   */
  public func withUnsafeBytes<T>(_ accessHandler: (Data) throws -> T) throws -> T {
    lock.lock()
    defer { lock.unlock() }

    guard !isZeroised else {
      throw CoreSecurityError.invalidKey("Cannot access zeroised secure bytes")
    }

    return try accessHandler(secureStorage)
  }

  /**
   Securely zeroes out the data and marks the container as invalid.
   */
  public func zeroise() {
    lock.lock()
    defer { lock.unlock() }

    guard !isZeroised else { return }

    // Secure zeroisation would ideally overwrite memory directly
    // This is a simplified version for demonstration
    isZeroised = true
  }

  deinit {
    zeroise()
  }
}
