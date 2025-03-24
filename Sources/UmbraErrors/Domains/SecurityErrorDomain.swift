import ErrorHandlingInterfaces
import Foundation

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
        "Error managing security bookmarks"
      case .accessError:
        "Security access error"
      case .encryptionFailed:
        "Encryption operation failed"
      case .decryptionFailed:
        "Decryption operation failed"
      case .invalidKey:
        "Invalid security key"
      case .keyGenerationFailed:
        "Failed to generate security key"
      case .certificateInvalid:
        "Certificate is invalid or expired"
      case .unauthorisedAccess:
        "Unauthorised access attempt"
      case .secureStorageFailure:
        "Secure storage operation failed"
    }
  }
}

/// Enhanced implementation of a SecurityError
public struct SecurityError: UmbraError, CustomStringConvertible {
  /// Domain identifier
  public let domain: String=SecurityErrorDomain.domain

  /// Error code string
  public var code: String { errorCode.rawValue }

  /// The specific error code
  public let errorCode: SecurityErrorDomain

  /// Custom description if provided
  private let customDescription: String?

  /// Human-readable description
  public var description: String {
    "\(domain).\(code): \(errorDescription)"
  }

  /// Human-readable description of the error
  public var errorDescription: String {
    let baseDescription=customDescription ?? errorCode.description
    return underlyingError != nil ?
      "\(baseDescription) (Caused by: \(String(describing: underlyingError)))" : baseDescription
  }

  /// Source location of the error
  public let source: ErrorSource?

  /// Underlying error that caused this error, if any
  public let underlyingError: Error?

  /// Additional contextual information
  public let context: ErrorContext

  /// Creates a new SecurityError
  /// - Parameters:
  ///   - code: The error code
  ///   - description: Optional custom description
  ///   - source: Optional source information
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional context information
  public init(
    code: SecurityErrorDomain,
    description: String?=nil,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext(
      source: "UmbraErrors",
      operation: "SecurityOperation",
      details: "Security error"
    )
  ) {
    errorCode=code
    customDescription=description
    self.source=source
    self.underlyingError=underlyingError
    self.context=context
  }

  /// Creates a new error with the given context
  /// - Parameter context: The context to associate with the error
  /// - Returns: A new error with the given context
  public func with(context: ErrorContext) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: customDescription,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new error with the given underlying error
  /// - Parameter underlyingError: The underlying error
  /// - Returns: A new error with the given underlying error
  public func with(underlyingError: Error) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: customDescription,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new error with the given source
  /// - Parameter source: The source to associate with the error
  /// - Returns: A new error with the given source
  public func with(source: ErrorSource) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: customDescription,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }
}

/// Extension to add additional custom error creation methods
extension SecurityError {
  /// Creates a bookmark error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Source line (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A fully configured SecurityError
  public static func bookmarkError(
    _ message: String?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    SecurityError(
      code: .bookmarkError,
      description: message,
      source: ErrorSource(identifier: "\(file):\(line)", location: function)
    )
  }

  /// Creates an access error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Source line (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A fully configured SecurityError
  public static func accessError(
    _ message: String?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    SecurityError(
      code: .accessError,
      description: message,
      source: ErrorSource(identifier: "\(file):\(line)", location: function)
    )
  }

  /// Creates an encryption failure error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - underlyingError: Optional underlying error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Source line (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A fully configured SecurityError
  public static func encryptionFailed(
    _ message: String?=nil,
    underlyingError: Error?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    var error=SecurityError(
      code: .encryptionFailed,
      description: message
    )

    if let underlyingError {
      error=error.with(underlyingError: underlyingError)
    }

    return error.with(source: ErrorSource(identifier: "\(file):\(line)", location: function))
  }

  /// Creates a decryption failure error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - underlyingError: Optional underlying error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Source line (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A fully configured SecurityError
  public static func decryptionFailed(
    _ message: String?=nil,
    underlyingError: Error?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    var error=SecurityError(
      code: .decryptionFailed,
      description: message
    )

    if let underlyingError {
      error=error.with(underlyingError: underlyingError)
    }

    return error.with(source: ErrorSource(identifier: "\(file):\(line)", location: function))
  }

  /// Creates an invalid key error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Source line (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A fully configured SecurityError
  public static func invalidKey(
    _ message: String?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> SecurityError {
    SecurityError(
      code: .invalidKey,
      description: message,
      source: ErrorSource(identifier: "\(file):\(line)", location: function)
    )
  }
}

/// Helper function to create an error with source information
/// - Parameters:
///   - error: The error to enhance with source information
///   - file: Source file
///   - line: Source line
///   - function: Source function
/// - Returns: The error with source information
public func makeError<E: UmbraError>(_ error: E, file: String, line: Int, function: String) -> E {
  // Create source information
  let sourceLocation="\(file):\(line) \(function)"
  let source=ErrorSource(identifier: "UmbraCore", location: sourceLocation)

  // Return error with source information
  return error.with(source: source)
}
