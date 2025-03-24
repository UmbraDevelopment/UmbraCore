

import UmbraErrors
import UmbraErrorsCore
import Foundation

/// Result of an operation that can succeed or fail
public enum OperationResultDTO<T> {
  /// Operation succeeded with a value
  case success(T)
  /// Operation failed with an error
  case failure(ErrorHandlingCore.Error)

  /// Returns true if the operation succeeded
  public var succeeded: Bool {
    switch self {
      case .success:
        true
      case .failure:
        false
    }
  }

  /// Returns the success value or throws the error
  /// - Throws: The failure error if the operation failed
  /// - Returns: The success value if the operation succeeded
  public func get() throws -> T {
    switch self {
      case let .success(value):
        return value
      case let .failure(error):
        throw error
    }
  }

  /// Maps the success value to a new value
  /// - Parameter transform: Transformation function
  /// - Returns: A new OperationResultDTO with the transformed value
  public func map<U>(_ transform: (T) -> U) -> OperationResultDTO<U> {
    switch self {
      case let .success(value):
        .success(transform(value))
      case let .failure(error):
        .failure(error)
    }
  }

  /// Creates a new OperationResultDTO from a throwing function
  /// - Parameter body: Function that can throw
  /// - Returns: OperationResultDTO with the result or error
  public static func from(body: () throws -> T) -> OperationResultDTO<T> {
    do {
      return try .success(body())
    } catch {
      return .failure(ErrorHandlingCore.Error(error))
    }
  }
}
