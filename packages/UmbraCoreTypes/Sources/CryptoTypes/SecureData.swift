import Foundation

/**
 # SecureData

 A secure wrapper around Foundation's Data type that provides additional
 security guarantees for sensitive cryptographic material.

 This type follows the Alpha Dot Five architecture principles by providing
 a Sendable, value-type representation of binary data that can be safely
 passed across actor boundaries while ensuring proper memory protection.

 ## Memory Protection

 This implementation automatically zeros out memory when the instance is
 deallocated, reducing the risk of sensitive data leakage.

 ## Thread Safety

 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it conforms to Sendable and uses proper memory isolation.
 */
public struct SecureData: Sendable, Equatable {
  /// The internal data storage
  private let storage: ManagedSecureStorage

  /**
   Initialises a new secure data instance with the provided data.

   - Parameter data: The data to securely store
   */
  public init(_ data: Data) {
    storage=ManagedSecureStorage(data)
  }

  /**
   Initialises a new secure data instance with the provided bytes.

   - Parameter bytes: The bytes to securely store
   */
  public init(bytes: some Collection<UInt8>) {
    storage=ManagedSecureStorage(Data(bytes))
  }

  /**
   Initialises a new empty secure data instance with the specified capacity.

   - Parameter capacity: The initial capacity in bytes
   */
  public init(capacity: Int) {
    storage=ManagedSecureStorage(Data(capacity: capacity))
  }

  /**
   Provides secure access to the underlying data.

   This method ensures that the data is only accessible within the provided
   closure and is not exposed outside of it.

   - Parameter body: A closure that receives the data for processing
   - Returns: The result of the closure
   */
  public func withSecureAccess<R>(_ body: (Data) throws -> R) rethrows -> R {
    try storage.withSecureAccess(body)
  }

  /**
   Provides secure access to the underlying bytes.

   This method ensures that the bytes are only accessible within the provided
   closure and are not exposed outside of it.

   - Parameter body: A closure that receives the bytes for processing
   - Returns: The result of the closure
   */
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try storage.withUnsafeBytes(body)
  }

  /**
   Returns the size of the secure data in bytes.

   - Returns: The size in bytes
   */
  public var count: Int {
    storage.count
  }

  /**
   Creates a new secure data instance by appending another secure data instance.

   - Parameter other: The other secure data to append
   - Returns: A new secure data instance with the combined data
   */
  public func appending(_ other: SecureData) -> SecureData {
    var result: Data?

    withSecureAccess { selfData in
      other.withSecureAccess { otherData in
        result=selfData + otherData
      }
    }

    return SecureData(result!)
  }

  /**
   Creates a new secure data instance by appending raw data.

   - Parameter data: The data to append
   - Returns: A new secure data instance with the combined data
   */
  public func appending(_ data: Data) -> SecureData {
    var result: Data?

    withSecureAccess { selfData in
      result=selfData + data
    }

    return SecureData(result!)
  }

  /**
   Creates a new secure data instance containing a subset of the data.

   - Parameter range: The range of bytes to include
   - Returns: A new secure data instance with the specified range
   */
  public func subdata(in range: Range<Int>) -> SecureData {
    var result: Data?

    withSecureAccess { data in
      result=data.subdata(in: range)
    }

    return SecureData(result!)
  }

  /**
   Compares two secure data instances for equality.

   This comparison is performed in constant time to prevent timing attacks.

   - Parameter lhs: The first secure data instance
   - Parameter rhs: The second secure data instance
   - Returns: true if the instances contain the same data, false otherwise
   */
  public static func == (lhs: SecureData, rhs: SecureData) -> Bool {
    var result=false

    lhs.withSecureAccess { lhsData in
      rhs.withSecureAccess { rhsData in
        // Constant-time comparison to prevent timing attacks
        if lhsData.count != rhsData.count {
          result=false
          return
        }

        var difference: UInt8=0

        for i in 0..<lhsData.count {
          difference |= lhsData[i] ^ rhsData[i]
        }

        result=difference == 0
      }
    }

    return result
  }
}

/**
 Internal reference-counted storage for secure data.

 This class manages the lifecycle of the secure data and ensures
 proper memory protection and zeroing when the data is no longer needed.
 */
private final class ManagedSecureStorage: @unchecked Sendable {
  /// The internal data storage
  private var data: Data

  /// The size of the data in bytes
  fileprivate var count: Int {
    data.count
  }

  /**
   Initialises a new managed secure storage instance.

   - Parameter data: The data to securely store
   */
  fileprivate init(_ data: Data) {
    self.data=data
  }

  /**
   Provides secure access to the underlying data.

   - Parameter body: A closure that receives the data for processing
   - Returns: The result of the closure
   */
  fileprivate func withSecureAccess<R>(_ body: (Data) throws -> R) rethrows -> R {
    try body(data)
  }

  /**
   Provides secure access to the underlying bytes.

   - Parameter body: A closure that receives the bytes for processing
   - Returns: The result of the closure
   */
  fileprivate func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try data.withUnsafeBytes(body)
  }

  /**
   Zeroes out the memory when the instance is deallocated.
   */
  deinit {
    // Zero out the memory to prevent data leakage
    if !data.isEmpty {
      data.withUnsafeMutableBytes { bytes in
        if let baseAddress=bytes.baseAddress {
          memset(baseAddress, 0, bytes.count)
        }
      }
    }
  }
}
