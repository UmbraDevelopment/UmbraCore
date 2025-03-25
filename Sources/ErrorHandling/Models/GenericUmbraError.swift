import Foundation
import Interfaces

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// A generic implementation of UmbraError that can be used for any error domain
public struct GenericUmbraError: UmbraError, CustomStringConvertible {
  /// The error domain
  public let domain: String

  /// The error code
  public let code: String

  /// Human-readable description of the error
  public let errorDescription: String

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Source information about where the error occurred
  public let source: ErrorSource?

  /// Additional context for the error
  public let context: ErrorContext

  /// Creates a new GenericUmbraError instance
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - errorDescription: A human-readable description of the error
  ///   - underlyingError: The underlying error, if any
  ///   - source: Source information about where the error occurred
  ///   - context: Additional context for the error
  public init(
    domain: String,
    code: String,
    errorDescription: String,
    underlyingError: Error?=nil,
    source: ErrorSource?=nil,
    context: ErrorContext?=nil
  ) {
    self.domain=domain
    self.code=code
    self.errorDescription=errorDescription
    self.underlyingError=underlyingError
    self.source=source
    self.context=context ?? ErrorContext(
      source: domain,
      operation: "unknown",
      details: "No additional context available"
    )
  }

  /// Creates a new instance of the error with additional context
  public func with(context: ErrorContext) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance of the error with additional underlying error
  public func with(underlyingError: Error) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorSource) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// A readable string representation of the error
  public var description: String {
    let sourceInfo = source?.file ?? "unknown"
    let contextInfo = "\(context.source).\(context.operation)"
    
    return "\(domain).\(code) (\(sourceInfo)): \(errorDescription) [Context: \(contextInfo)]"
  }
}

/// Factory methods for creating GenericUmbraError instances
extension GenericUmbraError {
  /// Creates a new error with the given domain, code, and description
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: A human-readable description of the error
  ///   - file: The file where the error occurred
  ///   - function: The function where the error occurred
  ///   - line: The line where the error occurred
  /// - Returns: A new GenericUmbraError instance
  public static func create(
    domain: String,
    code: String,
    description: String,
    file: String=#file,
    function: String=#function,
    line: Int=#line
  ) -> GenericUmbraError {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      source: ErrorSource(
        file: file,
        line: line,
        function: function
      )
    )
  }

  /// Creates a security error with the given code and description
  /// - Parameters:
  ///   - code: The error code
  ///   - description: A human-readable description of the error
  /// - Returns: A new GenericUmbraError instance
  public static func security(
    code: String,
    description: String
  ) -> GenericUmbraError {
    create(
      domain: ErrorDomain.security,
      code: code,
      description: description
    )
  }

  /// Creates a crypto error with the given code and description
  /// - Parameters:
  ///   - code: The error code
  ///   - description: A human-readable description of the error
  /// - Returns: A new GenericUmbraError instance
  public static func crypto(
    code: String,
    description: String
  ) -> GenericUmbraError {
    create(
      domain: ErrorDomain.crypto,
      code: code,
      description: description
    )
  }
}
