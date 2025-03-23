import Foundation

// MARK: - Error Mapping Functions

/// Maps from a UmbraCoreTypes error to a domain-agnostic error
///
/// This function centralises the mapping from domain-specific errors to generic errors.
/// Where possible, it maintains consistent error behaviours.
///
/// - Parameter error: The UmbraCoreTypes error to map
/// - Returns: Equivalent generic error
@Sendable
public func mapToDomainErrors(_ error: Error) -> Error {
  // For now, we'll just return the original error
  // This will be expanded in future implementations
  error
}

/// Maps from a generic error to a UmbraCoreTypes error
///
/// This function provides bidirectional mapping from generic errors back to domain-specific errors.
/// It complements the mapToDomainErrors function by providing the reverse mapping operation,
/// which is essential for error propagation across module boundaries.
///
/// - Parameter error: The generic error to map
/// - Returns: Equivalent UmbraCoreTypes error
@Sendable
public func mapFromDomainErrors(_ error: Error) -> Error {
  // For specific error types, we need to handle the translation explicitly
  if let resourceError = error as? ResourceError {
    return mapFromDomainResourceError(resourceError)
  }

  if let securityError = error as? SecurityError {
    return mapFromDomainSecurityError(securityError)
  }

  // Preserve the original behaviour of returning the error as-is
  return error
}

/// Maps a ResourceError to an appropriate UmbraCoreTypes error
///
/// This specialised mapping function handles the translation of resource errors
/// to domain-specific error types, ensuring proper error semantics are preserved.
///
/// - Parameter error: The ResourceError to map
/// - Returns: Equivalent UmbraCoreTypes error
private func mapFromDomainResourceError(_ error: ResourceError) -> Error {
  // Convert generic resource error to specific domain error
  ResourceLocatorError.generalError(error.description)
}

/// Maps a SecurityError to an appropriate UmbraCoreTypes error
///
/// This specialised mapping function handles the translation of security errors
/// to domain-specific error types, ensuring proper error semantics are preserved
/// across module boundaries.
///
/// - Parameter error: The SecurityError to map
/// - Returns: Equivalent UmbraCoreTypes error
private func mapFromDomainSecurityError(_ error: SecurityError) -> Error {
  // Convert generic security error to specific domain error
  ResourceLocatorError.generalError(error.description)
}

// MARK: - Error Container

/// A minimal error container for foundation-free error representation
public struct ErrorContainer: Error {
  public let domain: String
  public let code: Int
  public let userInfo: [String: Any]

  public init(domain: String, code: Int, userInfo: [String: Any]) {
    self.domain = domain
    self.code = code
    self.userInfo = userInfo
  }
}
