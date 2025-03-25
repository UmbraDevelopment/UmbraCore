import Foundation
import UmbraErrorsCore

/// Error source information
public struct ErrorSource: Codable, Equatable, Hashable {
  /// Source identifier
  public let identifier: String
  /// Source location
  public let location: String?

  /// Create a new error source
  /// - Parameters:
  ///   - identifier: The source identifier
  ///   - location: Optional location information
  public init(identifier: String, location: String? = nil) {
    self.identifier = identifier
    self.location = location
  }
}

// MARK: - UmbraErrorsCore Integration

// This file previously contained a typealias to UmbraErrorsCore.ErrorContext.
// Instead of using a typealias, code should directly import UmbraErrorsCore
// and use UmbraErrorsCore.ErrorContext.

// Extension to bridge between the old and new ErrorContext formats if needed
extension UmbraErrorsCore.ErrorContext {
  /// Create a new error context with parameters matching the old interface
  /// - Parameters:
  ///   - source: Source of the error
  ///   - operation: Operation that was being performed
  ///   - details: Additional details
  public init(source: String, operation: String, details: String) {
    self.init(
      [:],
      source: source,
      operation: operation,
      details: details
    )
  }
}

/// Error context protocol
public protocol ErrorContextProvider {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: String { get }
  /// Description of the error
  var description: String { get }
}

/// Error handler protocol
public protocol ErrorHandler {
  /// Handle an error
  /// - Parameter error: The error to handle
  /// - Returns: Whether the error was handled
  func handle(error: Error) -> Bool
}

/// Protocol for all Umbra-specific errors
public protocol UmbraError: Error, CustomStringConvertible {
  /// The domain of the error
  var domain: String { get }

  /// The error code
  var code: String { get }

  /// Human-readable description of the error
  var errorDescription: String { get }

  /// The source of the error, if known
  var source: ErrorSource? { get }

  /// The underlying error that caused this error, if any
  var underlyingError: Error? { get }

  /// Additional context associated with this error
  var context: UmbraErrorsCore.ErrorContext { get }

  /// Creates a new error with the given context
  /// - Parameter context: The context to associate with the error
  /// - Returns: A new error with the given context
  func with(context: UmbraErrorsCore.ErrorContext) -> Self

  /// Creates a new error with the given underlying error
  /// - Parameter underlyingError: The underlying error
  /// - Returns: A new error with the given underlying error
  func with(underlyingError: Error) -> Self

  /// Creates a new error with the given source
  /// - Parameter source: The source to associate with the error
  /// - Returns: A new error with the given source
  func with(source: ErrorSource) -> Self
}

/// Protocol for standard error capabilities
public protocol StandardErrorCapabilities: UmbraError {
  /// Checks if this error is equal to another error
  /// - Parameter other: The other error to compare against
  /// - Returns: Whether the errors are equal
  func isEqual(to other: Error) -> Bool
}

/// Root namespace for all UmbraErrors
public enum UmbraErrors {
  // This is just a namespace, actual error types are defined in submodules
}
