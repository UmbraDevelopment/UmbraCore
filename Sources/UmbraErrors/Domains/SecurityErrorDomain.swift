import ErrorHandlingInterfaces
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
        return "Error managing security bookmarks"
      case .accessError:
        return "Security access error"
      case .encryptionFailed:
        return "Encryption operation failed"
      case .decryptionFailed:
        return "Decryption operation failed"
      case .invalidKey:
        return "Invalid security key"
      case .keyGenerationFailed:
        return "Failed to generate security key"
      case .certificateInvalid:
        return "Certificate is invalid or expired"
      case .unauthorisedAccess:
        return "Unauthorised access attempt"
      case .secureStorageFailure:
        return "Secure storage operation failed"
    }
  }
}

/// Enhanced implementation of a SecurityError
public struct SecurityError: UmbraError {
  /// Domain of the error
  public var domain: String { return SecurityErrorDomain.domain }
  
  /// The specific error code
  public let errorCode: SecurityErrorDomain
  
  /// Code representation as a string
  public var code: String { return errorCode.rawValue }
  
  /// Human-readable description of the error
  public var errorDescription: String {
    return customDescription ?? errorCode.description
  }
  
  /// Custom description if provided
  private let customDescription: String?
  
  /// Source location of the error
  public let source: ErrorSource?
  
  /// Underlying error that caused this error, if any
  public let underlyingError: Error?
  
  /// Additional contextual information
  public let context: ErrorContext
  
  /// Provide CustomStringConvertible conformance
  public var description: String {
    return "\(domain).\(code): \(errorDescription)"
  }
  
  /// Creates a new SecurityError
  /// - Parameters:
  ///   - code: The specific error code
  ///   - description: Optional human-readable description
  ///   - source: Optional source information
  ///   - underlyingError: Optional underlying error
  ///   - context: Additional context information
  public init(
    code: SecurityErrorDomain,
    description: String?=nil,
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext(source: "SecurityError", operation: "unknown", details: "")
  ) {
    errorCode=code
    customDescription=description
    self.source=source
    self.underlyingError=underlyingError
    self.context=context
  }
  
  /// Creates a new instance with the given context
  public func with(context newContext: ErrorContext) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: customDescription,
      source: source,
      underlyingError: underlyingError,
      context: newContext
    )
  }
  
  /// Creates a new instance with the given underlying error
  public func with(underlyingError: Error) -> SecurityError {
    SecurityError(
      code: errorCode,
      description: customDescription,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }
  
  /// Creates a new instance with the given source information
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
    
    if let underlyingError=underlyingError {
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
    
    if let underlyingError=underlyingError {
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
