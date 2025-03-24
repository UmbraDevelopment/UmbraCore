import Foundation
import UmbraErrorsDomains

/// Generic security error protocol for use in error mappers
/// This allows us to decouple from specific implementations
public protocol SecurityErrorType: Error, CustomStringConvertible {
  var description: String { get }
  init(description: String)
}

/// Mapper from the enhanced SecurityError to a basic security error
public struct EnhancedToBasicSecurityErrorMapper<T: SecurityErrorType>: ErrorMapper {
  public typealias SourceError = UmbraErrorsDomains.SecurityError
  public typealias TargetError = T

  public init() {}

  /// Maps from enhanced SecurityError to a basic security error
  /// - Parameter error: The enhanced SecurityError to map
  /// - Returns: The equivalent basic security error
  public func map(_ error: UmbraErrorsDomains.SecurityError) -> T {
    // Create a SecurityError with an appropriate description based on the error code
    return T(description: error.errorDescription)
  }
}

/// Mapper from a basic security error to the enhanced SecurityError
public struct BasicToEnhancedSecurityErrorMapper<S: SecurityErrorType>: ErrorMapper {
  public typealias SourceError = S
  public typealias TargetError = UmbraErrorsDomains.SecurityError

  public init() {}

  /// Maps from a basic security error to enhanced SecurityError
  /// - Parameter error: The basic security error to map
  /// - Returns: The equivalent enhanced SecurityError
  public func map(_ error: S) -> UmbraErrorsDomains.SecurityError {
    // Since basic security errors only have a description, we need to infer the error code
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

/// Simple error type that can be used as a bridge
/// This avoids having to reference specific types from other modules
public struct GenericSecurityError: SecurityErrorType {
  public let description: String
  
  public init(description: String) {
    self.description = description
  }
}

/// Function to register the SecurityError mapper with the ErrorRegistry
public func registerSecurityErrorMappers() {
  let registry = ErrorRegistry.shared
  
  // Register mappers using string-based domain identifiers to avoid direct type references
  // This allows us to break circular dependencies while maintaining proper error mapping
  registry.register(
    targetDomain: "Security.Core",
    mapper: EnhancedToBasicSecurityErrorMapper<GenericSecurityError>()
  )
  
  registry.register(
    targetDomain: "UmbraErrorsDomains.SecurityError", 
    mapper: BasicToEnhancedSecurityErrorMapper<GenericSecurityError>()
  )
}
