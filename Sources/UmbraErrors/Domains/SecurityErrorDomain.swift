import ErrorHandlingDomains
import Foundation

/// Domain for security-related errors
public enum SecurityErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Security"

  /// Error codes within the security domain
  case bookmarkError="BOOKMARK_ERROR"
  case accessError="ACCESS_ERROR"
  case encryptionFailed="ENCRYPTION_FAILED"
  case decryptionFailed="DECRYPTION_FAILED"
  case invalidKey="INVALID_KEY"
  case keyGenerationFailed="KEY_GENERATION_FAILED"
  case certificateInvalid="CERTIFICATE_INVALID"
  case unauthorisedAccess="UNAUTHORISED_ACCESS"
  case secureStorageFailure="SECURE_STORAGE_FAILURE"

  /// Returns a human-readable description for this error code
  public var description: String {
    switch self {
      case .bookmarkError:
        "Failed to create or resolve a security bookmark"
      case .accessError:
        "Security access error occurred"
      case .encryptionFailed:
        "Data encryption operation failed"
      case .decryptionFailed:
        "Data decryption operation failed"
      case .invalidKey:
        "The cryptographic key is invalid or corrupted"
      case .keyGenerationFailed:
        "Failed to generate cryptographic key"
      case .certificateInvalid:
        "Certificate validation failed"
      case .unauthorisedAccess:
        "Unauthorised access attempt detected"
      case .secureStorageFailure:
        "Secure storage operation failed"
    }
  }
}

/// Enhanced implementation of a SecurityError
public struct SecurityError: DomainError {
  /// Domain identifier
  public static let domain=SecurityErrorDomain.domain

  /// The specific error code
  public let errorCode: SecurityErrorDomain

  /// Error code as string
  public var code: String {
    errorCode.rawValue
  }

  /// Human-readable error description
  public let errorDescription: String

  /// Source location of the error
  public let source: ErrorSource?

  /// Underlying error that caused this error, if any
  public let underlyingError: Error?

  /// Additional contextual information
  public let context: ErrorContext

  /// Creates a new SecurityError
  /// - Parameters:
  ///   - code: The error code
  ///   - description: Custom error description (defaults to the standard description for the code)
  ///   - source: Source location information
  ///   - underlyingError: The underlying cause of this error
  ///   - context: Additional context information
  public init(
    code: SecurityErrorDomain,
    description: String?=nil,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) {
    errorCode=code
    errorDescription=description ?? code.description
    self.source=source
    self.underlyingError=underlyingError
    self.context=context
  }

  /// Creates a new instance with the given context
  public func with(context: ErrorContext) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: errorDescription,
      source: source,
      underlyingError: underlyingError,
      context: self.context.merging(with: context)
    )
  }

  /// Creates a new instance with the given underlying error
  public func with(underlyingError: Error) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: errorDescription,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new instance with the given source information
  public func with(source: ErrorSource) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: errorDescription,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }
}

/// Convenience initializers for common security errors
extension SecurityError {
  /// Creates a bookmark error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new SecurityError
  public static func bookmarkError(
    message: String?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    makeError(
      SecurityError(
        code: .bookmarkError,
        description: message
      ),
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates an access error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new SecurityError
  public static func accessError(
    message: String?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    makeError(
      SecurityError(
        code: .accessError,
        description: message
      ),
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates an encryption failed error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - cause: Optional underlying error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new SecurityError
  public static func encryptionFailed(
    message: String?=nil,
    cause: Error?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    var error=SecurityError(
      code: .encryptionFailed,
      description: message
    )

    if let cause {
      error=error.with(underlyingError: cause)
    }

    return makeError(
      error,
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates a decryption failed error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - cause: Optional underlying error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new SecurityError
  public static func decryptionFailed(
    message: String?=nil,
    cause: Error?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    var error=SecurityError(
      code: .decryptionFailed,
      description: message
    )

    if let cause {
      error=error.with(underlyingError: cause)
    }

    return makeError(
      error,
      file: file,
      line: line,
      function: function
    )
  }

  /// Creates an invalid key error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new SecurityError
  public static func invalidKey(
    message: String?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    makeError(
      SecurityError(
        code: .invalidKey,
        description: message
      ),
      file: file,
      line: line,
      function: function
    )
  }
}
