import ErrorCoreTypes
import ErrorHandlingInterfaces
import Foundation

/**
 # SecurityErrorDomain

 Domain-specific error type for security-related errors.

 This implementation follows the Alpha Dot Five architecture by providing
 a concrete implementation of the ErrorDomainProtocol for security-related
 errors, with proper British spelling in documentation.
 */
public enum SecurityErrorDomain: ErrorDomainProtocol {
  // MARK: - Error Cases

  /// Authentication failed (incorrect credentials, etc.)
  case authenticationFailed(reason: String, context: ErrorContext?=nil)

  /// Authorisation failed (insufficient permissions, etc.)
  case authorisationFailed(reason: String, context: ErrorContext?=nil)

  /// Encryption operation failed
  case encryptionFailed(reason: String, context: ErrorContext?=nil)

  /// Decryption operation failed
  case decryptionFailed(reason: String, context: ErrorContext?=nil)

  /// Key management operation failed
  case keyManagementFailed(reason: String, context: ErrorContext?=nil)

  /// Invalid input provided to security operation
  case invalidInput(reason: String, context: ErrorContext?=nil)

  /// Security operation not supported
  case unsupportedOperation(name: String, context: ErrorContext?=nil)

  /// General security error that doesn't fit other categories
  case generalSecurityError(reason: String, context: ErrorContext?=nil)

  // MARK: - ErrorDomainProtocol Implementation

  /// The error domain identifier
  public static var domain: ErrorDomainType {
    .security
  }

  /// The error code within this domain
  public var code: Int {
    switch self {
      case .authenticationFailed: 1001
      case .authorisationFailed: 1002
      case .encryptionFailed: 1003
      case .decryptionFailed: 1004
      case .keyManagementFailed: 1005
      case .invalidInput: 1006
      case .unsupportedOperation: 1007
      case .generalSecurityError: 1099
    }
  }

  /// Human-readable description of the error
  public var localizedDescription: String {
    switch self {
      case let .authenticationFailed(reason, _):
        "Authentication failed: \(reason)"
      case let .authorisationFailed(reason, _):
        "Authorisation failed: \(reason)"
      case let .encryptionFailed(reason, _):
        "Encryption failed: \(reason)"
      case let .decryptionFailed(reason, _):
        "Decryption failed: \(reason)"
      case let .keyManagementFailed(reason, _):
        "Key management failed: \(reason)"
      case let .invalidInput(reason, _):
        "Invalid input: \(reason)"
      case let .unsupportedOperation(name, _):
        "Unsupported operation: \(name)"
      case let .generalSecurityError(reason, _):
        "Security error: \(reason)"
    }
  }

  /// Optional context providing additional information about the error
  public var context: ErrorContext? {
    switch self {
      case let .authenticationFailed(_, context),
           let .authorisationFailed(_, context),
           let .encryptionFailed(_, context),
           let .decryptionFailed(_, context),
           let .keyManagementFailed(_, context),
           let .invalidInput(_, context),
           let .unsupportedOperation(_, context),
           let .generalSecurityError(_, context):
        context
    }
  }

  /**
   Creates an error with additional context information.

   - Parameter context: The context to associate with this error
   - Returns: A new error instance with the provided context
   */
  public func withContext(_ context: ErrorContext) -> SecurityErrorDomain {
    switch self {
      case let .authenticationFailed(reason, _):
        .authenticationFailed(reason: reason, context: context)
      case let .authorisationFailed(reason, _):
        .authorisationFailed(reason: reason, context: context)
      case let .encryptionFailed(reason, _):
        .encryptionFailed(reason: reason, context: context)
      case let .decryptionFailed(reason, _):
        .decryptionFailed(reason: reason, context: context)
      case let .keyManagementFailed(reason, _):
        .keyManagementFailed(reason: reason, context: context)
      case let .invalidInput(reason, _):
        .invalidInput(reason: reason, context: context)
      case let .unsupportedOperation(name, _):
        .unsupportedOperation(name: name, context: context)
      case let .generalSecurityError(reason, _):
        .generalSecurityError(reason: reason, context: context)
    }
  }
}
