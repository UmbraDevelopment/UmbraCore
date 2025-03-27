import Foundation

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
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> E {
    let source=ErrorSource(file: file, line: line, function: function)
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
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> E {
    let source=ErrorSource(file: file, line: line, function: function)
    return error
      .with(source: source)
      .with(context: context)
  }

  /// Creates a new UmbraError with source information, underlying error, and context
  /// - Parameters:
  ///   - error: The original error
  ///   - underlyingError: The underlying error that caused this error
  ///   - context: Additional context information
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new error with source, cause, and context information
  public static func makeError<E: UmbraError>(
    _ error: E,
    underlyingError: Error,
    context: ErrorContext,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) -> E {
    let source=ErrorSource(file: file, line: line, function: function)
    return error
      .with(source: source)
      .with(underlyingError: underlyingError)
      .with(context: context)
  }

  /// Wraps any Error in an UmbraError
  /// - Parameters:
  ///   - error: Any error to wrap
  ///   - domain: Domain identifier for the wrapper error
  ///   - code: Error code for the wrapper error
  ///   - description: Human-readable description for the wrapper error
  ///   - file: Source file (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  /// - Returns: A new UmbraError that wraps the provided error
  public static func wrapError(
    _ error: Error,
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
      underlyingError: error,
      source: source
    )
  }
}

/// A convenience wrapper for `ErrorFactory.makeError`
public func makeError<E: UmbraError>(
  _ error: E,
  file: String=#file,
  line: Int=#line,
  function: String=#function
) -> E {
  ErrorFactory.makeError(error, file: file, line: line, function: function)
}
