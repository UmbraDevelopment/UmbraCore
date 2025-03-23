import CoreErrors
import ErrorHandlingDomains
import Foundation

/// Mapper from the enhanced SecurityError to CoreErrors.SecurityError
public struct EnhancedToCoreSecurityErrorMapper: ErrorMapper {
  public typealias SourceError = SecurityError
  public typealias TargetError = CoreErrors.SecurityError

  public init() {}

  /// Maps from enhanced SecurityError to CoreErrors.SecurityError
  /// - Parameter error: The enhanced SecurityError to map
  /// - Returns: The equivalent CoreErrors.SecurityError
  public func map(_ error: SecurityError) -> CoreErrors.SecurityError {
    switch error.errorCode {
      case .bookmarkError:
        .bookmarkError
      case .accessError:
        .accessError
      case .encryptionFailed:
        .encryptionFailed
      case .decryptionFailed:
        .decryptionFailed
      // Map additional cases to their closest equivalents in CoreErrors
      case .invalidKey, .keyGenerationFailed:
        // Since CoreErrors doesn't have these specific cases,
        // map them to the closest conceptual match
        .encryptionFailed
      case .certificateInvalid:
        .accessError
      case .unauthorisedAccess:
        .accessError
      case .secureStorageFailure:
        .bookmarkError
    }
  }
}

/// Mapper from CoreErrors.SecurityError to the enhanced SecurityError
public struct CoreToEnhancedSecurityErrorMapper: ErrorMapper {
  public typealias SourceError = CoreErrors.SecurityError
  public typealias TargetError = SecurityError

  public init() {}

  /// Maps from CoreErrors.SecurityError to enhanced SecurityError
  /// - Parameter error: The CoreErrors.SecurityError to map
  /// - Returns: The equivalent enhanced SecurityError
  public func map(_ error: CoreErrors.SecurityError) -> SecurityError {
    switch error {
      case .bookmarkError:
        SecurityError(code: .bookmarkError)
      case .accessError:
        SecurityError(code: .accessError)
      case .encryptionFailed:
        SecurityError(code: .encryptionFailed)
      case .decryptionFailed:
        SecurityError(code: .decryptionFailed)
    }
  }
}

/// Bidirectional mapper between enhanced SecurityError and CoreErrors.SecurityError
public let securityErrorMapper = BidirectionalErrorMapper<SecurityError, CoreErrors.SecurityError>(
  forwardMap: { EnhancedToCoreSecurityErrorMapper().map($0) },
  reverseMap: { CoreToEnhancedSecurityErrorMapper().map($0) }
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
