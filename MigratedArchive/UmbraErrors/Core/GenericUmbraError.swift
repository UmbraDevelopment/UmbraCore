import Foundation

/// A generic implementation of UmbraError used for wrapping arbitrary errors
/// and for creating simple errors without defining custom types
public struct GenericUmbraError: UmbraError {
  /// The domain this error belongs to
  public let domain: String

  /// The error code within the domain
  public let code: String

  /// A human-readable description of the error
  public let errorDescription: String

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Source information about where the error occurred
  public let source: ErrorSource?

  /// Additional contextual information
  public let context: ErrorContext

  /// Creates a new GenericUmbraError instance
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - errorDescription: A human-readable description
  ///   - underlyingError: Optional underlying error
  ///   - source: Optional source information
  ///   - context: Additional context information
  public init(
    domain: String,
    code: String,
    errorDescription: String,
    underlyingError: Error?=nil,
    source: ErrorSource?=nil,
    context: ErrorContext=ErrorContext()
  ) {
    self.domain=domain
    self.code=code
    self.errorDescription=errorDescription
    self.underlyingError=underlyingError
    self.source=source
    self.context=context
  }

  /// Creates a new instance with the specified context
  public func with(context: ErrorContext) -> GenericUmbraError {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: self.context.merging(with: context)
    )
  }

  /// Creates a new instance with the specified underlying error
  public func with(underlyingError: Error) -> GenericUmbraError {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance with the specified source information
  public func with(source: ErrorSource) -> GenericUmbraError {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }
}

/// Convenience functions for creating generic errors
extension GenericUmbraError {
  /// Creates a generic error with the specified details
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: A human-readable description
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new GenericUmbraError
  public static func generic(
    domain: String,
    code: String,
    description: String,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> GenericUmbraError {
    let source=ErrorSource(file: file, line: line, function: function)
    return GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      source: source
    )
  }

  /// Creates a generic error with the specified details and underlying error
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: A human-readable description
  ///   - underlyingError: The underlying error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new GenericUmbraError
  public static func wrap(
    domain: String,
    code: String,
    description: String,
    underlyingError: Error,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> GenericUmbraError {
    let source=ErrorSource(file: file, line: line, function: function)
    return GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      underlyingError: underlyingError,
      source: source
    )
  }
}
