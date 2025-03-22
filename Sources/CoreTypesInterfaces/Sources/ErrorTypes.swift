import CoreErrors
import ErrorHandlingDomains

/// Protocol for error types that can be converted to SecurityError
///
/// Implementations of this protocol should consider using
/// `CoreErrors.SecurityErrorMapper.mapToCoreError`
/// in their implementations to ensure consistent error handling across the codebase.
public protocol SecurityErrorConvertible: Error, Sendable {
  /// Convert this error to a SecurityError
  ///
  /// When implementing this method, consider delegating to
  /// `CoreErrors.SecurityErrorMapper.mapToCoreError`
  /// to ensure consistent error mapping behaviour throughout the application.
  func toSecurityError() -> CoreErrors.SecurityError

  /// Create an instance of this error type from a SecurityError
  ///
  /// When implementing this method, consider using standardised error mapping patterns
  /// to ensure consistent behaviour across the codebase.
  static func fromSecurityError(_ error: CoreErrors.SecurityError) -> Self
}

/// Protocol for error types that can be serialized for XPC transport
///
/// Implementations of this protocol should consider using
/// `CoreErrors.SecurityErrorMapper.mapToXPCError`
/// in their implementations to ensure consistent error handling across the codebase.
public protocol XPCTransportableError: Error, Sendable {
  /// Convert to a standard error representation for XPC transport
  ///
  /// When implementing this method, consider delegating to
  /// `CoreErrors.SecurityErrorMapper.mapToXPCError`
  /// to ensure consistent error mapping behaviour throughout the application.
  func toTransportableError() -> CoreErrors.SecurityError

  /// Create from a standard error representation received via XPC
  ///
  /// When implementing this method, consider using standardised error mapping patterns
  /// to ensure consistent behaviour across the codebase.
  static func fromTransportableError(_ error: CoreErrors.SecurityError) -> Self
}

/// Type alias for clarity when working with SecurityError from CoreErrors
public typealias CoreSecurityError = CoreErrors.SecurityError

/// Custom result type with standard error handling
public typealias SecurityResult<Success> = Result<Success, CoreSecurityError>

/// Error domain identifier for core security errors
public let coreSecurityErrorDomain = "com.umbra.core.security"

/// Base protocol for all security-related errors
public protocol SecurityError: Error, Sendable, CustomStringConvertible {
  /// A descriptive error code
  var errorCode: Int { get }

  /// The error domain
  var errorDomain: String { get }

  /// Human-readable error description
  var errorDescription: String { get }
}

/// Extension providing default implementation for SecurityError
extension SecurityError {
  public var errorDomain: String {
    coreSecurityErrorDomain
  }

  public var description: String {
    errorDescription
  }
}
