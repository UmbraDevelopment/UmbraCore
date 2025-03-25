import Foundation
import UmbraErrorsCore

/// Domain for ResourceLocator-related errors
public enum ResourceLocatorErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="UmbraErrors.ResourceLocator"

  /// Path is invalid
  case invalidPath="INVALID_PATH"

  /// Resource not found
  case resourceNotFound="RESOURCE_NOT_FOUND"

  /// Access denied to resource
  case accessDenied="ACCESS_DENIED"

  /// Unsupported scheme
  case unsupportedScheme="UNSUPPORTED_SCHEME"

  /// General error
  case generalError="GENERAL_ERROR"
}

/// Error types specific to UmbraCore ResourceLocator operations
public enum ResourceLocatorError: Error, Equatable, Sendable {
  /// The path is invalid or empty
  case invalidPath

  /// The requested resource does not exist
  case resourceNotFound

  /// Access to the resource is denied
  case accessDenied

  /// The scheme is not supported
  case unsupportedScheme

  /// General error with message
  case generalError(String)

  /// Get the equivalent UmbraError for this error type
  public func toUmbraError() -> UmbraError {
    switch self {
      case .invalidPath:
        ResourceLocatorErrorDomain.makeInvalidPathError()
      case .resourceNotFound:
        ResourceLocatorErrorDomain.makeResourceNotFoundError()
      case .accessDenied:
        ResourceLocatorErrorDomain.makeAccessDeniedError()
      case .unsupportedScheme:
        ResourceLocatorErrorDomain.makeUnsupportedSchemeError()
      case let .generalError(message):
        ResourceLocatorErrorDomain.makeGeneralError(description: message)
    }
  }
}

/// Factory methods for ResourceLocator-related errors
extension ResourceLocatorErrorDomain {
  /// Creates an error for invalid path
  ///
  /// - Parameters:
  ///   - description: Optional custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeInvalidPathError(
    description: String="The provided path is invalid or empty",
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .invalidResource,
      code: ResourceLocatorErrorDomain.invalidPath.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates an error for resource not found
  ///
  /// - Parameters:
  ///   - description: Optional custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeResourceNotFoundError(
    description: String="The requested resource could not be found",
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .notFound,
      code: ResourceLocatorErrorDomain.resourceNotFound.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates an error for access denied
  ///
  /// - Parameters:
  ///   - description: Optional custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeAccessDeniedError(
    description: String="Access to the requested resource is denied",
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .notAvailable,
      code: ResourceLocatorErrorDomain.accessDenied.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates an error for unsupported scheme
  ///
  /// - Parameters:
  ///   - description: Optional custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeUnsupportedSchemeError(
    description: String="The scheme specified is not supported",
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .invalidResource,
      code: ResourceLocatorErrorDomain.unsupportedScheme.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates a general error
  ///
  /// - Parameters:
  ///   - description: Custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeGeneralError(
    description: String,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .general,
      code: ResourceLocatorErrorDomain.generalError.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }
}
