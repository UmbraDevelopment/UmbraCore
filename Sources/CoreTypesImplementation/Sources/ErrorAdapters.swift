import CoreTypesInterfaces
import UmbraErrors
import UmbraErrorsCore

import UmbraCoreTypes

// Since SecurityProtocolsCore and XPCProtocolsCore are namespaces rather than direct modules,
// we need to use the correct type paths to avoid ambiguity issues

// MARK: - Error Types and Adapters

/// Create a local SecureBytesError enum that mirrors the one in ErrorHandlingDomains
public enum SecureBytesError: Error, Equatable {
  case invalidHexString
  case outOfBounds
  case allocationFailed
}

/// Define an ExternalError type for representing errors from external systems
public struct ExternalError: Error, Equatable {
  /// The reason for the error
  public let reason: String

  /// Initialise with a reason
  public init(reason: String) {
    self.reason=reason
  }
}

/// Maps errors from external domains to the SecurityError domain
///
/// This adapter function provides a standardised way to convert any error type
/// into the centralised SecurityError type. It delegates to the
/// centralised error mapper to ensure consistent error handling across the codebase.
///
/// - Parameter error: Any error from an external domain
/// - Returns: The equivalent SecurityError
public func mapExternalToCoreError(_ error: Error) -> SecurityError {
  // If already the correct type, return as is
  if let securityError=error as? SecurityError {
    return securityError
  }

  // Otherwise map to an appropriate security error
  return SecurityError.internalError(reason: "Mapped from \(String(describing: error))")
}

/// Maps from SecurityError to an appropriate external error type
///
/// This adapter function provides bidirectional conversion capability,
/// complementing the mapExternalToCoreError function. It delegates to the
/// centralised error mapper for consistent mapping behaviour.
///
/// - Parameter error: Error of type SecurityError
/// - Returns: An appropriate external error
public func mapCoreToExternalError(_ error: SecurityError) -> Error {
  // For now, simply wrap in the ExternalError type
  ExternalError(reason: "Core error: \(error)")
}

/// Maps from SecureBytesError to SecurityError
///
/// This specialised mapping function handles SecureBytesError conversion,
/// delegating to the centralised error mapper to ensure consistent handling.
///
/// - Parameter error: The SecureBytesError to convert
/// - Returns: An equivalent SecurityError
public func mapSecureBytesToCoreError(_ error: SecureBytesError) -> SecurityError {
  // For now, simply map to an internal error
  SecurityError.internalError(reason: "SecureBytesError: \(error)")
}

/// Maps any Result with Error to a Result with SecurityError
///
/// This helper function simplifies error handling when working with Result types
/// by automatically mapping the error component to a standardised SecurityError.
///
/// - Parameter result: A Result with any Error type
/// - Returns: A Result with SecurityError
public func mapToSecurityResult<T>(_ result: Result<T, Error>)
-> Result<T, SecurityError> {
  switch result {
    case let .success(value):
      .success(value)
    case let .failure(error):
      .failure(mapExternalToCoreError(error))
  }
}

/// Maps an external error to a SecurityError
/// - Parameter error: The external error to map
/// - Returns: A SecurityError
public func externalErrorToCoreError(_ error: Error) -> SecurityError {
  if let securityError=error as? SecurityError {
    return securityError
  }

  // Map based on error type
  if let externalError=error as? ExternalError {
    return SecurityError.internalError(reason: externalError.reason)
  }

  // For any other error type, create a generic internal error
  return SecurityError.internalError(reason: "External error: \(String(describing: error))")
}
