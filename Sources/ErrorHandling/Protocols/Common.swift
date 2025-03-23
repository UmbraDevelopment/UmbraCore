import Foundation

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

/// Error source information
public struct ErrorSource: Sendable, Equatable {
  /// The file where the error occurred
  public let file: String
  /// The function where the error occurred
  public let function: String
  /// The line where the error occurred
  public let line: Int

  /// Initialize with file, function and line
  public init(file: String, function: String, line: Int) {
    self.file=file
    self.function=function
    self.line=line
  }
}

/// Error severity levels
public enum ErrorSeverity: String, Sendable {
  case debug
  case info
  case warning
  case error
  case critical
}

/// Detailed context for errors with service and operation information
public struct ErrorDetailContext: Sendable {
  /// Source of the error
  public let source: String
  /// Operation that was being performed
  public let operation: String
  /// Additional details about the error
  public let details: String?
  /// Underlying error if any
  public let underlyingError: Error?

  /// Initialize with source, operation, details, and optional underlyingError
  public init(
    source: String,
    operation: String,
    details: String?=nil,
    underlyingError: Error?=nil
  ) {
    self.source=source
    self.operation=operation
    self.details=details
    self.underlyingError=underlyingError
  }
}
