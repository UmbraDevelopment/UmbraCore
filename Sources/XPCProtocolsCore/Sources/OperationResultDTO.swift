import Foundation
import UmbraErrors

/// Generic operation result with success or failure
///
/// This type provides a standardized way to return either a successful result
/// or an error from asynchronous operations.
public enum OperationResultDTO<T: Sendable>: Sendable {
    /// Operation succeeded with a result
    case success(T)
    
    /// Operation failed with an error
    case failure(UmbraErrors.SecurityError)
    
    /// Get the success value if available
    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// Get the error if available
    public var error: UmbraErrors.SecurityError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// Whether the operation was successful
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Whether the operation failed
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /// Map the success value to another type
    /// - Parameter transform: Function to transform the success value
    /// - Returns: New operation result with transformed value
    public func map<U: Sendable>(_ transform: (T) -> U) -> OperationResultDTO<U> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Flat map the success value to another operation result
    /// - Parameter transform: Function to transform the success value to another operation result
    /// - Returns: New operation result
    public func flatMap<U: Sendable>(_ transform: (T) -> OperationResultDTO<U>) -> OperationResultDTO<U> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
