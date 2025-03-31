import Foundation
import UmbraErrorsCore

/// Security error protocol for use in error mappers
/// This protocol provides a standardised interface for security errors
/// across different implementation contexts.
public protocol SecurityErrorType: Error, CustomStringConvertible, Sendable {
  var description: String { get }
  init(description: String)
}

/// Maps enhanced security errors to basic security errors
/// Follows Alpha Dot Five architecture with proper Swift 6 Sendable compliance
public struct EnhancedToBasicSecurityErrorMapper<T: SecurityErrorType>: ErrorMapper {
  public init() {}

  /// Maps from enhanced SecurityError to a basic security error
  /// - Parameter error: The enhanced SecurityError to map
  /// - Returns: The equivalent basic security error
  public func map(_ error: SecurityError) -> T {
    // Create a SecurityError with an appropriate description based on the error code
    T(description: error.localizedDescription)
  }
}

/// Enhanced SecurityError type for internal reference
/// This provides a proper Swift 6 Sendable-compliant error type
/// with comprehensive error codes and descriptive properties
public struct SecurityError: Error, CustomStringConvertible, Sendable {
  /// Security error code with specific categorisation
  public enum SecurityErrorCode: String, Sendable {
    case bookmarkError
    case accessError
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    case certificateInvalid
    case unauthorisedAccess
    case secureStorageFailure
  }

  /// The categorised error code
  public let errorCode: SecurityErrorCode

  /// Human-readable description with British spelling
  public let description: String

  /// Source information for error tracing
  public let errorSource: ErrorSource?

  /// Underlying error
  public let underlyingError: Error?

  /// Localised description
  public var localizedDescription: String {
    description
  }

  /// Creates a new SecurityError with the specified parameters
  ///
  /// - Parameters:
  ///   - code: The error classification
  ///   - description: Human-readable error message
  ///   - source: Optional error source information
  ///   - underlyingError: Optional underlying error
  public init(
    code: SecurityErrorCode,
    description: String,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil
  ) {
    errorCode=code
    self.description=description
    errorSource=source
    self.underlyingError=underlyingError
  }

  /// Creates a new SecurityError representing an encryption failure
  ///
  /// - Parameters:
  ///   - reason: The specific reason for encryption failure
  ///   - source: Optional error source information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured SecurityError
  public static func encryptionFailed(
    reason: String,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil
  ) -> SecurityError {
    SecurityError(
      code: .encryptionFailed,
      description: "Encryption failed: \(reason)",
      source: source,
      underlyingError: underlyingError
    )
  }

  /// Creates a new SecurityError representing a decryption failure
  ///
  /// - Parameters:
  ///   - reason: The specific reason for decryption failure
  ///   - source: Optional error source information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured SecurityError
  public static func decryptionFailed(
    reason: String,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil
  ) -> SecurityError {
    SecurityError(
      code: .decryptionFailed,
      description: "Decryption failed: \(reason)",
      source: source,
      underlyingError: underlyingError
    )
  }

  /// Creates a new SecurityError representing an invalid key
  ///
  /// - Parameters:
  ///   - reason: The specific key validation error
  ///   - source: Optional error source information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured SecurityError
  public static func invalidKey(
    reason: String,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil
  ) -> SecurityError {
    SecurityError(
      code: .invalidKey,
      description: "Invalid key: \(reason)",
      source: source,
      underlyingError: underlyingError
    )
  }

  /// Creates a new SecurityError representing unauthorized access
  ///
  /// - Parameters:
  ///   - reason: The specific reason for access denial
  ///   - source: Optional error source information
  ///   - underlyingError: Optional underlying error
  /// - Returns: A fully configured SecurityError
  public static func unauthorisedAccess(
    reason: String,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil
  ) -> SecurityError {
    SecurityError(
      code: .unauthorisedAccess,
      description: "Unauthorised access: \(reason)",
      source: source,
      underlyingError: underlyingError
    )
  }
}

/// Maps basic security errors to enhanced SecurityError
/// Follows Alpha Dot Five architecture with proper Swift 6 Sendable compliance
public struct BasicToEnhancedSecurityErrorMapper<S: SecurityErrorType>: ErrorMapper {
  public init() {}

  /// Maps from a basic security error to enhanced SecurityError
  /// - Parameter error: The basic security error to map
  /// - Returns: The equivalent enhanced SecurityError
  public func map(_ error: S) -> SecurityError {
    // Since basic security errors only have a description, we need to infer the error code
    // This is a best-effort mapping based on the description
    let description=error.description.lowercased()

    if description.contains("bookmark") {
      return SecurityError(
        code: .bookmarkError,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("access") {
      return SecurityError(
        code: .accessError,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("encrypt") {
      return SecurityError(
        code: .encryptionFailed,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("decrypt") {
      return SecurityError(
        code: .decryptionFailed,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("key") {
      return SecurityError(
        code: .invalidKey,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("certificate") {
      return SecurityError(
        code: .certificateInvalid,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("unauthorised") || description.contains("unauthorized") {
      return SecurityError(
        code: .unauthorisedAccess,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else if description.contains("storage") {
      return SecurityError(
        code: .secureStorageFailure,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    } else {
      // Default fallback for unknown descriptions
      return SecurityError(
        code: .accessError,
        description: error.description,
        source: nil,
        underlyingError: error
      )
    }
  }
}

/// Generic implementation of SecurityErrorType for use in adapters
/// This provides a simple implementation that can be constructed from a string
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
