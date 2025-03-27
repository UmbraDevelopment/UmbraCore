import Foundation

/// Provides information about the source location where an error occurred
public struct ErrorSource: Sendable, Equatable, Codable {
  /// The file where the error occurred
  public let file: String

  /// The line number where the error occurred
  public let line: Int

  /// The function where the error occurred
  public let function: String

  /// Creates a new ErrorSource instance
  /// - Parameters:
  ///   - file: Source file where the error occurred
  ///   - line: Line number in the source file
  ///   - function: Function name where the error occurred
  public init(file: String = #file, line: Int = #line, function: String = #function) {
    self.file = file
    self.line = line
    self.function = function
  }

  /// A shortened version of the file path, showing only the file name
  public var fileName: String {
    URL(fileURLWithPath: file).lastPathComponent
  }
}

/// A function that creates an ErrorSource using compiler directives
/// - Parameters:
///   - file: Source file (auto-filled by the compiler)
///   - line: Line number (auto-filled by the compiler)
///   - function: Function name (auto-filled by the compiler)
/// - Returns: An ErrorSource instance
public func makeErrorSource(
  file: String = #file,
  line: Int = #line,
  function: String = #function
) -> ErrorSource {
  ErrorSource(file: file, line: line, function: function)
}
