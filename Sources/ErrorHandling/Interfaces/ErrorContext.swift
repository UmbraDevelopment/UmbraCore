import Foundation

/// A structure that provides detailed context about an error's occurrence.
///
/// `ErrorContext` enriches errors with information about where and how they
/// occurred, making debugging and error reporting more effective. It captures
/// both programmatic details (file, line, function) and semantic information
/// (source, operation, details).
///
/// Example:
/// ```swift
/// do {
///     try processPayment(amount: 100)
/// } catch let error {
///     throw ErrorContext(
///         source: "PaymentProcessor",
///         operation: "processPayment",
///         details: "Invalid card number",
///         underlyingError: error
///     )
/// }
/// ```
public struct ErrorContext: Sendable {
  /// The source of the error (e.g., module name, class name)
  public let source: String

  /// Operation being performed when the error occurred
  public let operation: String

  /// Additional details about the error
  public let details: String?

  /// Underlying error if any
  public let underlyingError: Error?

  /// File where the error occurred
  public let file: String

  /// Line number where the error occurred
  public let line: Int

  /// Function where the error occurred
  public let function: String

  /// Creates a new error context with the specified information.
  ///
  /// - Parameters:
  ///   - source: The source of the error (e.g., module name, class name)
  ///   - operation: Operation being performed when the error occurred
  ///   - details: Additional details about the error (optional)
  ///   - underlyingError: The original error that caused this error (optional)
  ///   - file: File where the error occurred (defaults to current file)
  ///   - line: Line number where the error occurred (defaults to current line)
  ///   - function: Function where the error occurred (defaults to current function)
  public init(
    source: String,
    operation: String,
    details: String?=nil,
    underlyingError: Error?=nil,
    file: String=#file,
    line: Int=#line,
    function: String=#function
  ) {
    self.source=source
    self.operation=operation
    self.details=details
    self.underlyingError=underlyingError
    self.file=file
    self.line=line
    self.function=function
  }
}

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
