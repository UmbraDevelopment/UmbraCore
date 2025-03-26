import Foundation
import UmbraErrorsCore

/// Factory functions for creating errors with source attribution
public enum ErrorFactory {
  /// Creates a new UmbraError with source information
  /// - Parameters:
  ///   - error: The original error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new error with source information
  public static func makeError<E: UmbraError>(
    _ error: E,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> E {
    let source=ErrorSource(file: file, line: line, function: function)
    return error.with(source: source)
  }

  /// Creates a new UmbraError with underlying error and source information
  /// - Parameters:
  ///   - error: The original error
  ///   - underlyingError: The underlying error that caused this error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new error with source information
  public static func makeError<E: UmbraError>(
    _ error: E,
    underlyingError: Error,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> E {
    let source=ErrorSource(file: file, line: line, function: function)
    let withSource=error.with(source: source)
    return withSource.with(underlyingError: underlyingError)
  }

  /// Creates a new UmbraError with context and source information
  /// - Parameters:
  ///   - error: The original error
  ///   - context: Additional context information
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new error with source and context information
  public static func makeError<E: UmbraError>(
    _ error: E,
    context: ErrorContext,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> E {
    let source=ErrorSource(file: file, line: line, function: function)
    let withSource=error.with(source: source)
    return withSource.with(context: context)
  }

  /// Creates a new GenericUmbraError with given domain, code and description
  /// - Parameters:
  ///   - domain: Error domain
  ///   - code: Error code
  ///   - description: Error description
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new GenericUmbraError with source information
  public static func makeGenericError(
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
}

/// Convenience function for creating an error with source information
/// - Parameters:
///   - error: The original error
///   - file: Source file (auto-filled by the compiler)
///   - line: Line number (auto-filled by the compiler)
///   - function: Function name (auto-filled by the compiler)
/// - Returns: A new error with source information
public func makeError<E: UmbraError>(
  _ error: E,
  file: String=#file,
  line: Int=#line,
  function: String=#function
) -> E {
  ErrorFactory.makeError(error, file: file, line: line, function: function)
}
