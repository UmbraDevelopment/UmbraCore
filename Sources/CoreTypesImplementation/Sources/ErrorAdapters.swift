import CoreTypesInterfaces
import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping
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

/// Maps errors from external domains to the UmbraErrors.Security.Core domain
///
/// This adapter function provides a standardised way to convert any error type
/// into the centralised UmbraErrors.Security.Core type. It delegates to the
/// centralised error mapper to ensure consistent error handling across the codebase.
///
/// - Parameter error: Any error from an external domain
/// - Returns: The equivalent UmbraErrors.Security.Core
public func mapExternalToCoreError(_ error: Error) -> UmbraErrors.Security.Core {
  // If already the correct type, return as is
  if let securityError=error as? UmbraErrors.Security.Core {
    return securityError
  }

  // Otherwise map to an appropriate security error
  return UmbraErrors.Security.Core.internalError(reason: "Mapped from \(String(describing: error))")
}

/// Maps from ErrorHandlingDomains.UmbraErrors.Security.Core to an appropriate external error type
///
/// This adapter function provides bidirectional conversion capability,
/// complementing the mapExternalToCoreError function. It delegates to the
/// centralised error mapper for consistent mapping behaviour.
///
/// - Parameter error: Error of type UmbraErrors.Security.Core
/// - Returns: An appropriate external error
public func mapCoreToExternalError(_ error: UmbraErrors.Security.Core) -> Error {
  // For now, simply wrap in the ExternalError type
  ExternalError(reason: "Core error: \(error)")
}

/// Maps from SecureBytesError to ErrorHandlingDomains.UmbraErrors.Security.Core
///
/// This specialised mapping function handles SecureBytesError conversion,
/// delegating to the centralised error mapper to ensure consistent handling.
///
/// - Parameter error: The SecureBytesError to convert
/// - Returns: An equivalent ErrorHandlingDomains.UmbraErrors.Security.Core
public func mapSecureBytesToCoreError(_ error: SecureBytesError) -> UmbraErrors.Security.Core {
  // For now, simply map to an internal error
  UmbraErrors.Security.Core.internalError(reason: "SecureBytesError: \(error)")
}

/// Maps any Result with Error to a Result with ErrorHandlingDomains.UmbraErrors.Security.Core
///
/// This helper function simplifies error handling when working with Result types
/// by automatically mapping the error component to a standardised SecurityError.
///
/// - Parameter result: A Result with any Error type
/// - Returns: A Result with ErrorHandlingDomains.UmbraErrors.Security.Core
public func mapToSecurityResult<T>(_ result: Result<T, Error>)
-> Result<T, UmbraErrors.Security.Core> {
  switch result {
    case let .success(value):
      .success(value)
    case let .failure(error):
      .failure(mapExternalToCoreError(error))
  }
}

/// Maps an external error to a ErrorHandlingDomains.UmbraErrors.Security.Core
/// - Parameter error: The external error to map
/// - Returns: A ErrorHandlingDomains.UmbraErrors.Security.Core
public func externalErrorToCoreError(_ error: Error) -> UmbraErrors.Security.Core {
  if let securityError=error as? UmbraErrors.Security.Core {
    return securityError
  }

  // Map based on error type
  if let externalError=error as? ExternalError {
    return UmbraErrors.Security.Core.internalError(reason: externalError.reason)
  }

  // Default fallback
  return UmbraErrors.Security.Core.internalError(reason: error.localizedDescription)
}

/// Maps from an Error to the error type expected by the caller
///
/// This is a convenience function that determines the appropriate error mapping
/// based on the context.
///
/// - Parameters:
///   - error: The error to map
///   - context: The context in which the error occurred
/// - Returns: The mapped error
public func adaptErrorForContext(_ error: Error, context _: String) -> Error {
  // Currently this is a simplified implementation
  // In a more complex system, we might use context to determine the mapping strategy
  mapExternalToCoreError(error)
}
