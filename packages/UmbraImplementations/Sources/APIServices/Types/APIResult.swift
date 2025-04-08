import Foundation
import UmbraErrors

/**
 * Result type for API operations
 *
 * Provides a type-safe way to handle success and failure cases for API operations,
 * following the Alpha Dot Five architecture principles.
 */
public enum APIResult<Value: Sendable>: Sendable {
  /// Successful operation with associated value
  case success(Value)

  /// Failed operation with associated error
  case failure(APIError)

  /**
   * Returns the success value or throws the failure error
   *
   * - Returns: The success value
   * - Throws: The wrapped error if this is a failure case
   */
  public func get() throws -> Value {
    switch self {
      case let .success(value):
        return value
      case let .failure(error):
        throw error
    }
  }

  /**
   * Maps a successful result to a new value using the provided transform function
   *
   * - Parameter transform: Function to transform the successful value
   * - Returns: A new result with the transformed value or the same error
   */
  public func map<NewValue: Sendable>(_ transform: (Value) -> NewValue) -> APIResult<NewValue> {
    switch self {
      case let .success(value):
        .success(transform(value))
      case let .failure(error):
        .failure(error)
    }
  }

  /// Whether this result represents a success
  public var isSuccess: Bool {
    if case .success=self {
      return true
    }
    return false
  }

  /// Whether this result represents a failure
  public var isFailure: Bool {
    if case .failure=self {
      return true
    }
    return false
  }
}
