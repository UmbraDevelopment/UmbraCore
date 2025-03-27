import Domains
import Foundation
import UmbraErrorsCore

/// Generic security error protocol for use in error mappers
/// This allows us to decouple from specific implementations
public protocol SecurityErrorType: Error, CustomStringConvertible {
  var description: String { get }
  init(description: String)
}

/// Mapper from the enhanced SecurityError to a basic security error
public struct EnhancedToBasicSecurityErrorMapper<T: SecurityErrorType>: ErrorMapper {
  public typealias SourceError=Domains.SecurityError
  public typealias TargetError=T

  public init() {}

  /// Maps from enhanced SecurityError to a basic security error
  /// - Parameter error: The enhanced SecurityError to map
  /// - Returns: The equivalent basic security error
  public func map(_ error: Domains.SecurityError) -> T {
    // Create a SecurityError with an appropriate description based on the error code
    T(description: error.localizedDescription)
  }
}

/// Mapper from a basic security error to the enhanced SecurityError
public struct BasicToEnhancedSecurityErrorMapper<S: SecurityErrorType>: ErrorMapper {
  public typealias SourceError=S
  public typealias TargetError=Domains.SecurityError

  public init() {}

  /// Maps from a basic security error to enhanced SecurityError
  /// - Parameter error: The basic security error to map
  /// - Returns: The equivalent enhanced SecurityError
  public func map(_ error: S) -> Domains.SecurityError {
    // Since basic security errors only have a description, we need to infer the error code
    // This is a best-effort mapping based on the description
    let description=error.description.lowercased()

    if description.contains("bookmark") {
      return Domains.SecurityError(
        code: .bookmarkError,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("access") {
      return Domains.SecurityError(
        code: .accessError,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("encrypt") {
      return Domains.SecurityError(
        code: .encryptionFailed,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("decrypt") {
      return Domains.SecurityError(
        code: .decryptionFailed,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("key") {
      return Domains.SecurityError(
        code: .invalidKey,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("certificate") {
      return Domains.SecurityError(
        code: .certificateInvalid,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("unauthorised") || description.contains("unauthorized") {
      return Domains.SecurityError(
        code: .unauthorisedAccess,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("storage") {
      return Domains.SecurityError(
        code: .secureStorageFailure,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else {
      // Default fallback for unknown descriptions
      return Domains.SecurityError(
        code: .accessError,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    }
  }
}

/// Simple error type that can be used as a bridge
/// This avoids having to reference specific types from other modules
public struct GenericSecurityError: SecurityErrorType {
  public let description: String

  public init(description: String) {
    self.description=description
  }
}

/// Function to register the SecurityError mapper with the ErrorRegistry
public func registerSecurityErrorMappers() {
  let registry=ErrorRegistry.shared

  // Register mappers using string-based domain identifiers to avoid direct type references
  // This allows us to break circular dependencies while maintaining proper error mapping
  registry.register(
    targetDomain: "Security.Core",
    mapper: EnhancedToBasicSecurityErrorMapper<GenericSecurityError>()
  )

  registry.register(
    targetDomain: "SecurityError",
    mapper: BasicToEnhancedSecurityErrorMapper<GenericSecurityError>()
  )
}
