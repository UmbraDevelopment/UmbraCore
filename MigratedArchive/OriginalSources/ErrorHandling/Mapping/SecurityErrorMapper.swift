import Foundation
import MappingCommon

// MARK: - Security Error Mapper Implementation

/// A bidirectional mapper for converting between `SecurityError` and
/// `UmbraErrors.GeneralSecurity.Core` error types.
///
/// # Overview
/// This mapper provides functionality to convert between the flat `SecurityError` type and the
/// hierarchical `UmbraErrors.GeneralSecurity.Core` error type. This allows different parts of the
/// system to work with the error type that best suits their needs while maintaining compatibility.
///
/// # Usage
/// ```swift
/// // Map from SecurityError to UmbraErrors.GeneralSecurity.Core
/// let securityError = SecurityError.invalidKey(reason: "Key too short")
/// let coreError = SecurityErrorMapper.mapAtoB(securityError)
///
/// // Map from UmbraErrors.GeneralSecurity.Core to SecurityError
/// let coreError = UmbraErrors.GeneralSecurity.Core.invalidKey(reason: "Key too short")
/// let securityError = SecurityErrorMapper.mapBtoA(coreError)
/// ```
///
/// # Important Notes
/// - All error cases must be handled in the mapping functions
/// - Always include `@unknown default` cases for Swift 6 compatibility
/// - When adding new error cases, update both mapping functions
/// - Use descriptive reasons when mapping to provide context for the error
public struct SecurityErrorMapper: ErrorMapper {
  /// Initialises a new mapper
  public init() {}

  /// Maps from source error type to target error type
  /// - Parameter error: The source error
  /// - Returns: The mapped target error
  public func mapError(_ error: UmbraErrors.GeneralSecurity.Core) -> ErrorHandlingTypes
  .SecurityError {
    .domainCoreError(error)
  }

  /// Maps from any error to the consolidated SecurityError
  /// - Parameter error: The source error
  /// - Returns: The mapped SecurityError if applicable, or nil if not mappable
  public func mapToSecurityError(_ error: Error) -> ErrorHandlingTypes.SecurityError? {
    if let securityCoreError=error as? UmbraErrors.GeneralSecurity.Core {
      return .domainCoreError(securityCoreError)
    }

    if let protocolsError=error as? UmbraErrors.Security.Protocols {
      return .domainProtocolError(protocolsError)
    }

    if let xpcError=error as? UmbraErrors.Security.XPC {
      return .domainXPCError(xpcError)
    }

    // Attempt to map special cases based on error description
    let errorDescription=String(describing: error)

    if errorDescription.contains("authentication") {
      return .authenticationFailed(reason: "Authentication failed: \(errorDescription)")
    } else if errorDescription.contains("permission") {
      return .permissionDenied(reason: "Permission denied: \(errorDescription)")
    } else if
      errorDescription.contains("unauthorized") || errorDescription
        .contains("unauthorised")
    {
      return .unauthorizedAccess(reason: "Unauthorized access: \(errorDescription)")
    } else if errorDescription.contains("encrypt") {
      return .encryptionFailed(reason: "Encryption failed: \(errorDescription)")
    } else if errorDescription.contains("decrypt") {
      return .decryptionFailed(reason: "Decryption failed: \(errorDescription)")
    } else if errorDescription.contains("key") {
      return .keyGenerationFailed(reason: "Key error: \(errorDescription)")
    } else if errorDescription.contains("hash") {
      return .hashingFailed(reason: "Hashing failed: \(errorDescription)")
    }

    // Default fallback for unmappable errors
    return .internalError(reason: "Unmapped error: \(errorDescription)")
  }

  /// Maps from any error to a core security error
  /// - Parameter error: The source error
  /// - Returns: The mapped core error if applicable, or nil if not mappable
  public func mapToCoreError(_ error: Error) -> UmbraErrors.GeneralSecurity.Core? {
    // Direct mapping if already a core error
    if let coreError=error as? UmbraErrors.GeneralSecurity.Core {
      return coreError
    }

    // Map via SecurityError if possible
    if let securityError=mapToSecurityError(error) {
      switch securityError {
        case let .domainCoreError(coreError):
          return coreError
        case let .authenticationFailed(reason):
          return .invalidInput(reason: reason)
        case let .permissionDenied(reason):
          return .invalidInput(reason: reason)
        case let .unauthorizedAccess(reason):
          return .invalidInput(reason: reason)
        case let .encryptionFailed(reason):
          return .encryptionFailed(reason: reason)
        case let .decryptionFailed(reason):
          return .decryptionFailed(reason: reason)
        case let .keyGenerationFailed(reason):
          return .keyGenerationFailed(reason: reason)
        case let .hashingFailed(reason):
          return .hashVerificationFailed(reason: reason)
        case let .signatureInvalid(reason):
          return .hashVerificationFailed(reason: reason)
        case .domainProtocolError, .domainXPCError:
          return .serviceError(code: 1001, reason: "Protocol or XPC error: \(securityError)")
        case let .internalError(reason):
          return .internalError(reason)
        default:
          // Handle other cases generically
          return .internalError("Unmapped security error: \(securityError)")
      }
    }

    // Attempt to map based on error description
    let errorDescription=String(describing: error)

    if errorDescription.contains("authentication") || errorDescription.contains("login") {
      return .invalidInput(reason: "Authentication failed: \(errorDescription)")
    } else if errorDescription.contains("timeout") {
      return .timeout(operation: "Operation timed out: \(errorDescription)")
    } else if errorDescription.contains("key") {
      return .invalidKey(reason: "Invalid key: \(errorDescription)")
    } else if errorDescription.contains("encrypt") {
      return .encryptionFailed(reason: "Encryption failed: \(errorDescription)")
    } else if errorDescription.contains("decrypt") {
      return .decryptionFailed(reason: "Decryption failed: \(errorDescription)")
    } else if errorDescription.contains("hash") || errorDescription.contains("integrity") {
      return .hashVerificationFailed(reason: "Hash verification failed: \(errorDescription)")
    }

    // Default fallback for unmappable errors
    return nil
  }
}

extension SecurityErrorMapper: BidirectionalErrorMapper {
  /// Maps from source to target error type
  /// - Parameter error: The source error
  /// - Returns: The mapped error
  public func mapAtoB(_ error: UmbraErrors.GeneralSecurity.Core) -> ErrorHandlingTypes
  .SecurityError {
    mapError(error)
  }

  /// Maps from target error type to source error type
  /// - Parameter error: The target error
  /// - Returns: The mapped source error
  public func mapBtoA(_ error: ErrorHandlingTypes.SecurityError) -> UmbraErrors.GeneralSecurity
  .Core {
    switch error {
      case let .domainCoreError(coreError):
        return coreError
      case let .authenticationFailed(reason):
        return .invalidInput(reason: reason)
      case let .permissionDenied(reason):
        return .invalidInput(reason: reason)
      case let .unauthorizedAccess(reason):
        return .invalidInput(reason: reason)
      case let .encryptionFailed(reason):
        return .encryptionFailed(reason: reason)
      case let .decryptionFailed(reason):
        return .decryptionFailed(reason: reason)
      case let .keyGenerationFailed(reason):
        return .keyGenerationFailed(reason: reason)
      case let .hashingFailed(reason):
        return .hashVerificationFailed(reason: reason)
      case let .signatureInvalid(reason):
        return .hashVerificationFailed(reason: reason)
      case .domainProtocolError:
        return .serviceError(code: 1002, reason: "Protocol error")
      case .domainXPCError:
        return .serviceError(code: 1003, reason: "XPC error")
      case let .internalError(reason):
        return .internalError(reason)
      @unknown default:
        return .internalError("Unknown error type: \(error)")
    }
  }
}
