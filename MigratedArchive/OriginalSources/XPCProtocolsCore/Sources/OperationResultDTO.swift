import Foundation
import UmbraErrors

/// Generic operation result with success or failure
///
/// This type provides a standardized way to return either a successful result
/// or an error from asynchronous operations.
import CoreDTOs

public enum OperationResultDTO<T: Sendable>: Sendable {
  /// Operation succeeded with a result
  case success(T)

  /// Operation failed with an error
  case failure(UmbraErrors.SecurityError)

  /// Get the success value if available
  public var value: T? {
    switch self {
      case let .success(value):
        value
      case .failure:
        nil
    }
  }

  /// Get the error if available
  public var error: UmbraErrors.SecurityError? {
    switch self {
      case .success:
        nil
      case let .failure(error):
        error
    }
  }

  /// Whether the operation was successful
  public var isSuccess: Bool {
    switch self {
      case .success:
        true
      case .failure:
        false
    }
  }

  /// Whether the operation failed
  public var isFailure: Bool {
    !isSuccess
  }

  /// Map the success value to another type
  /// - Parameter transform: Function to transform the success value
  /// - Returns: New operation result with transformed value
  public func map<U: Sendable>(_ transform: (T) -> U) -> OperationResultDTO<U> {
    switch self {
      case let .success(value):
        .success(transform(value))
      case let .failure(error):
        .failure(error)
    }
  }

  /// Flat map the success value to another operation result
  /// - Parameter transform: Function to transform the success value to another operation result
  /// - Returns: New operation result
  public func flatMap<U: Sendable>(_ transform: (T) -> OperationResultDTO<U>)
  -> OperationResultDTO<U> {
    switch self {
      case let .success(value):
        transform(value)
      case let .failure(error):
        .failure(error)
    }
  }
}
