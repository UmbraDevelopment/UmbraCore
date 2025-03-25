import Foundation
import UmbraErrorsCore

// We directly use UmbraErrorsCore.ErrorContext instead of typealias
// This file only contains the ErrorSource definition for compatibility

/// A structure that provides source information about where an error occurred.
///
/// `ErrorSource` captures the file, line, and function where an error was generated,
/// making it easier to locate the source of errors during debugging and analysis.
///
/// Example:
/// ```swift
/// let source = ErrorSource(file: #file, line: #line, function: #function)
/// let error = DomainError.fileNotFound.with(source: source)
/// ```
public struct ErrorSource: Sendable {
  /// The file where the error occurred
  public let file: String

  /// The line where the error occurred
  public let line: Int

  /// The function where the error occurred
  public let function: String

  /// Creates a new error source with the specified file, line, and function.
  ///
  /// - Parameters:
  ///   - file: The file where the error occurred (defaults to current file)
  ///   - line: The line where the error occurred (defaults to current line)
  ///   - function: The function where the error occurred (defaults to current function)
  public init(
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) {
    self.file=file
    self.line=line
    self.function=function
  }
}
