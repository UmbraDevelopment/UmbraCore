import Foundation
import ErrorHandlingInterfaces

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
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> E {
    let source = ErrorSource(identifier: "\(file):\(line):\(function)")
    return error.with(source: source)
  }

  /// Creates a new UmbraError with source information and an underlying error
  /// - Parameters:
  ///   - error: The original error
  ///   - underlyingError: The underlying error that caused this error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new error with source and cause information
  public static func makeError<E: UmbraError>(
    _ error: E,
    underlyingError: Error,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> E {
    let source = ErrorSource(identifier: "\(file):\(line):\(function)")
    return error
      .with(source: source)
      .with(underlyingError: underlyingError)
  }

  /// Creates a new UmbraError with source information and context
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
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> E {
    let source = ErrorSource(identifier: "\(file):\(line):\(function)")
    return error
      .with(source: source)
      .with(context: context)
  }

  /// Creates a new UmbraError with source information, context, and an underlying error
  /// - Parameters:
  ///   - error: The original error
  ///   - context: Additional context information
  ///   - underlyingError: The underlying error that caused this error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new error with source, context, and cause information
  public static func makeError<E: UmbraError>(
    _ error: E,
    context: ErrorContext,
    underlyingError: Error,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> E {
    let source = ErrorSource(identifier: "\(file):\(line):\(function)")
    return error
      .with(source: source)
      .with(context: context)
      .with(underlyingError: underlyingError)
  }

  /// Creates a generic error with the specified details
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: A human-readable description
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new GenericUmbraError
  public static func genericError(
    domain: String,
    code: String,
    description: String,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> GenericUmbraError {
    let source = ErrorSource(identifier: "\(file):\(line):\(function)")
    return GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      source: source
    )
  }

  /// Wraps an error in a GenericUmbraError
  /// - Parameters:
  ///   - error: The error to wrap
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: A human-readable description
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new GenericUmbraError that wraps the original error
  public static func wrapError(
    _ error: Error,
    domain: String,
    code: String,
    description: String,
    file: String = #file,
    line: Int = #line,
    function: String = #function
  ) -> GenericUmbraError {
    let source = ErrorSource(identifier: "\(file):\(line):\(function)")
    return GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      underlyingError: error,
      source: source
    )
  }
}
