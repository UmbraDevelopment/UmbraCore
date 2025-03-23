import CoreErrors
import CoreTypesInterfaces
import ErrorHandlingDomains
import UmbraCoreTypes

// Since SecurityProtocolsCore and XPCProtocolsCore are namespaces rather than direct modules,
// we need to use the correct type paths to avoid ambiguity issues

/// Type alias for UmbraErrors.Security.Core - our target error type
public typealias CESecurityError=UmbraErrors.Security.Core

/// Create a local SecureBytesError enum that mirrors the one in UmbraCoreTypes.CoreErrors
public enum SecureBytesError: Error, Equatable {
  case invalidHexString
  case outOfBounds
  case allocationFailed
}

/// Define an ExternalError type for representing errors from external systems
public struct ExternalError: Error, Equatable {
  /// The reason for the error
  public let reason: String

  /// Initialize with a reason
  public init(reason: String) {
    self.reason=reason
  }
}

/// Maps errors from external domains to the UmbraErrors.Security.Core domain
///
/// This adapter function provides a standardised way to convert any error type
/// into the centralised UmbraErrors.Security.Core type. It delegates to the
/// centralised error mapper to ensure consistent error handling across the codebase.
///
/// - Parameter error: Any error from an external domain
/// - Returns: The equivalent UmbraErrors.Security.Core
public func mapExternalToCoreError(_ error: Error) -> CESecurityError {
  // If already the correct type, return as is
  if let securityError=error as? CESecurityError {
    return securityError
  }

  // Otherwise map to an appropriate security error
  return CESecurityError.internalError(reason: "Mapped from \(String(describing: error))")
}

/// Maps from CoreErrors.SecurityError to an appropriate external error type
///
/// This adapter function provides bidirectional conversion capability,
/// complementing the mapExternalToCoreError function. It delegates to the
/// centralised error mapper to ensure consistent error handling.
///
/// - Parameter error: A CoreErrors.SecurityError to convert
/// - Returns: An appropriate error in the external domain
public func mapCoreToExternalError(_ error: CESecurityError) -> Error {
  CoreErrors.SecurityErrorMapper.mapFromCoreError(error)
}

/// Maps from SecureBytesError to CoreErrors.SecurityError
///
/// This specialised mapping function handles SecureBytesError conversion,
/// delegating to the centralised error mapper to ensure consistent handling.
///
/// - Parameter error: The SecureBytesError to convert
/// - Returns: An equivalent CoreErrors.SecurityError
public func mapSecureBytesToCoreError(_ error: SecureBytesError) -> CESecurityError {
  CoreErrors.SecurityErrorMapper.mapToCoreError(error)
}

/// Maps any Result with Error to a Result with CoreErrors.SecurityError
///
/// This helper function simplifies error handling when working with Result types
/// by automatically mapping the error component to a standardised SecurityError.
///
/// - Parameter result: A Result with any Error type
/// - Returns: A Result with CoreErrors.SecurityError
public func mapToSecurityResult<T>(_ result: Result<T, Error>)
-> Result<T, CESecurityError> {
  switch result {
    case let .success(value):
      .success(value)
    case let .failure(error):
      .failure(CoreErrors.SecurityErrorMapper.mapToCoreError(error))
  }
}

/// Maps an external error to a CoreErrors.SecurityError
/// - Parameter error: The external error to map
/// - Returns: A CoreErrors.SecurityError
public func externalErrorToCoreError(_ error: Error) -> CESecurityError {
  if let securityError=error as? CESecurityError {
    return securityError
  }

  // Map based on error type
  if let externalError=error as? ExternalError {
    return CESecurityError.internalError(reason: externalError.reason)
  }

  // Default fallback
  return CESecurityError.internalError(reason: error.localizedDescription)
}
