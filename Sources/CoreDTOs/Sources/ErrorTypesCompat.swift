import Foundation
import UmbraErrors
import UmbraErrorsCore

// This file provides compatibility functions to transition from legacy errors to ErrorHandling
// These bridge between the old API and the new API structure

/// Legacy security error type compatibility extension
extension ErrorHandlingCore.UmbraErrors.Security.Core {
  /// Compatibility method for old-style operation failures
  /// - Parameters:
  ///   - operation: The name of the operation that failed
  ///   - reason: The reason for the failure
  /// - Returns: A suitable Core error
  public static func operationFailed(operation: String, reason: String) -> Self {
    .operationFailed(reason: "\(operation): \(reason)")
  }

  /// Compatibility method for legacy internal errors
  /// - Parameter message: The error message
  /// - Returns: A suitable Core error
  public static func internalError(description message: String) -> Self {
    .internalError(description: message)
  }

  /// Compatibility method for legacy missing implementation errors
  /// - Parameter component: The component that is missing implementation
  /// - Returns: A suitable Core error
  public static func missingImplementation(component: String) -> Self {
    .internalError(description: "Missing implementation: \(component)")
  }
}
