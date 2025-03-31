import Foundation
import UmbraErrorsCore

/// Protocol for service-specific errors that provide detailed context
public protocol ServiceErrorProtocol: LocalizedError {
  /// The source service that generated this error
  var serviceName: String { get }

  /// The operation that was being performed
  var operation: String { get }

  /// Additional details about what went wrong
  var details: String? { get }

  /// The underlying error that caused this error, if any
  var underlyingError: Error? { get }

  /// Whether this error can potentially be recovered from
  var isRecoverable: Bool { get }

  /// Steps that might help recover from this error
  var recoverySteps: [String]? { get }

  /// Creates an error context from this service error
  var context: UmbraErrorsCore.ErrorContext { get }
}

extension ServiceErrorProtocol {
  /// Default implementation assuming errors are not recoverable
  public var isRecoverable: Bool { false }

  /// Default implementation providing no recovery steps
  public var recoverySteps: [String]? { nil }

  /// Default implementation creating an error context
  public var context: UmbraErrorsCore.ErrorContext {
    // Create the error context with the required parameters
    UmbraErrorsCore.ErrorContext.create(
      domain: serviceName,
      code: 0,
      description: details ?? "Unknown error in \(operation)",
      underlyingError: underlyingError
    )
  }
}
