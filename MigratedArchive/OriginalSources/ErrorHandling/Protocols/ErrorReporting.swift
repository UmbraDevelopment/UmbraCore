import Foundation

/// A protocol that defines error reporting capabilities.
///
/// Types conforming to `ErrorReporting` can report errors with additional context,
/// making it easier to track down and diagnose issues.
public protocol ErrorReporting {
  /// Reports an error with additional context.
  ///
  /// - Parameters:
  ///   - error: The error to report
  ///   - source: The source of the error (e.g., module name, class name)
  ///   - operation: Operation being performed when the error occurred
  ///   - details: Additional details about the error
  ///   - file: File where the error occurred
  ///   - line: Line number where the error occurred
  ///   - function: Function where the error occurred
  func reportError(
    _ error: Error,
    source: String,
    operation: String,
    details: String?,
    file: String,
    line: Int,
    function: String
  )
}
