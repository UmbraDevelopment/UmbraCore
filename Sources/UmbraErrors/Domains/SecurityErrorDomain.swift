import Foundation

import UmbraErrorsCore

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
  var displayDescription: String {
    switch self {
      case .bookmarkError:
        "Bookmark error"
      case .accessError:
        "Access error"
      case .encryptionFailed:
        "Encryption failed"
      case .decryptionFailed:
        "Decryption failed"
      case .invalidKey:
        "Invalid key"
      case .keyGenerationFailed:
        "Key generation failed"
      case .certificateInvalid:
        "Certificate invalid"
      case .unauthorisedAccess:
        "Unauthorised access"
      case .secureStorageFailure:
        "Secure storage failure"
    }
  }
}

/// Enhanced implementation of a SecurityError
public struct SecurityError: UmbraError {
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
    customDescription ?? errorCode.displayDescription
  }

  /// Human-readable description of the error
  public var errorDescription: String {
    let baseDescription=description
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
    context: ErrorContext=ErrorContext()
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

  /// Creates a new error with the given source information
  /// - Parameter source: The source information
  /// - Returns: A new error with the given source information
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

/// Convenience methods for creating specific security errors
extension SecurityError {
  /// Creates a bookmark error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - underlyingError: Optional underlying error
  /// - Returns: A configured SecurityError
  public static func bookmarkError(
    message: String?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    underlyingError: Error?=nil
  ) -> SecurityError {
    var contextDict: [String: Any]=[
      "file": file,
      "function": function,
      "line": line
    ]
    if let message {
      contextDict["details"]=message
    }

    let context=ErrorContext(contextDict)
    let source=ErrorSource(file: file, line: line, function: function)

    return SecurityError(
      code: .bookmarkError,
      description: message,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates an access error
  /// - Parameters:
  ///   - message: Optional custom message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - underlyingError: Optional underlying error
  /// - Returns: A configured SecurityError
  public static func accessError(
    message: String?=nil,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    underlyingError: Error?=nil
  ) -> SecurityError {
    var contextDict: [String: Any]=[
      "file": file,
      "function": function,
      "line": line
    ]
    if let message {
      contextDict["details"]=message
    }

    let context=ErrorContext(contextDict)
    let source=ErrorSource(file: file, line: line, function: function)

    return SecurityError(
      code: .accessError,
      description: message,
      source: source,
      underlyingError: underlyingError,
      context: context
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
  let source=ErrorSource(file: file, line: line, function: function)

  // Return error with source information
  return error.with(source: source)
}
