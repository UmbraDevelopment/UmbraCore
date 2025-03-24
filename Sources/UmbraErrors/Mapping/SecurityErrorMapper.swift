import CoreErrors
import Foundation
import UmbraErrorsDomains

/// Mapper from the enhanced SecurityError to CoreErrors.Security
public struct EnhancedToCoreSecurityErrorMapper: ErrorMapper {
  public typealias SourceError = UmbraErrorsDomains.SecurityError
  public typealias TargetError = CoreErrors.Security

  public init() {}

  /// Maps from enhanced SecurityError to CoreErrors.Security
  /// - Parameter error: The enhanced SecurityError to map
  /// - Returns: The equivalent CoreErrors.Security
  public func map(_ error: UmbraErrorsDomains.SecurityError) -> CoreErrors.Security {
    // Create a SecurityError with an appropriate description based on the error code
    return CoreErrors.Security(description: error.errorDescription)
  }
}

/// Mapper from CoreErrors.Security to the enhanced SecurityError
public struct CoreToEnhancedSecurityErrorMapper: ErrorMapper {
  public typealias SourceError = CoreErrors.Security
  public typealias TargetError = UmbraErrorsDomains.SecurityError

  public init() {}

  /// Maps from CoreErrors.Security to enhanced SecurityError
  /// - Parameter error: The CoreErrors.Security to map
  /// - Returns: The equivalent enhanced SecurityError
  public func map(_ error: CoreErrors.Security) -> UmbraErrorsDomains.SecurityError {
    // Since CoreErrors.Security only has a description, we need to infer the error code
    // This is a best-effort mapping based on the description
    let description = error.description.lowercased()
    
    if description.contains("bookmark") {
      return UmbraErrorsDomains.SecurityError(code: .bookmarkError)
    } else if description.contains("access") {
      return UmbraErrorsDomains.SecurityError(code: .accessError)
    } else if description.contains("encrypt") {
      return UmbraErrorsDomains.SecurityError(code: .encryptionFailed)
    } else if description.contains("decrypt") {
      return UmbraErrorsDomains.SecurityError(code: .decryptionFailed)
    } else if description.contains("key") {
      return UmbraErrorsDomains.SecurityError(code: .invalidKey)
    } else if description.contains("certificate") {
      return UmbraErrorsDomains.SecurityError(code: .certificateInvalid)
    } else if description.contains("unauthorised") || description.contains("unauthorized") {
      return UmbraErrorsDomains.SecurityError(code: .unauthorisedAccess)
    } else if description.contains("storage") {
      return UmbraErrorsDomains.SecurityError(code: .secureStorageFailure)
    } else {
      // Default fallback for unknown descriptions
      return UmbraErrorsDomains.SecurityError(code: .accessError)
    }
  }
}

/// Bidirectional mapper between enhanced SecurityError and CoreErrors.Security
public let securityErrorMapper = BidirectionalErrorMapper<UmbraErrorsDomains.SecurityError, CoreErrors.Security>(
  forwardMap: { (error: UmbraErrorsDomains.SecurityError) -> CoreErrors.Security in
    EnhancedToCoreSecurityErrorMapper().map(error)
  },
  reverseMap: { (error: CoreErrors.Security) -> UmbraErrorsDomains.SecurityError in 
    CoreToEnhancedSecurityErrorMapper().map(error)
  }
)

/// Function to register the SecurityError mapper with the ErrorRegistry
public func registerSecurityErrorMappers() {
  let registry = ErrorRegistry.shared

  // Register mapper from enhanced to CoreErrors
  registry.register(
    targetDomain: "CoreErrors.Security",
    mapper: EnhancedToCoreSecurityErrorMapper()
  )

  // Register mapper from CoreErrors to enhanced
  registry.register(targetDomain: "Security", mapper: CoreToEnhancedSecurityErrorMapper())
}
