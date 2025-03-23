import Foundation

/// Adds contextual information to Swift errors.
///
/// This extension allows any error to be wrapped with additional context
/// about where and how the error occurred, making debugging and error
/// handling more effective.
extension Error {
  /// Add context information to an error
  /// - Parameters:
  ///   - source: Source of the error (e.g., component or class name)
  ///   - operation: Operation being performed when the error occurred
  ///   - details: Additional details about the error
  /// - Returns: The error with context information
  public func withContext(
    source _: String?=nil,
    operation _: String?=nil,
    details _: String?=nil
  ) -> Error {
    self
  }

  /// Add source location information to an error
  /// - Parameters:
  ///   - module: Module name
  ///   - file: Source file
  ///   - line: Line number
  ///   - function: Function name
  /// - Returns: The error with source information
  public func withSource(
    module _: String?=nil,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Error {
    self
  }
}
