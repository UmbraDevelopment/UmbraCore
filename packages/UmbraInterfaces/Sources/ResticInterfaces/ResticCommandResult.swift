import Foundation

/// Represents the result of a Restic command execution.
///
/// This type encapsulates both the raw output and structured data resulting from
/// a Restic command execution, providing a consistent interface for handling command results.
public struct ResticCommandResult: Sendable {
  /// The raw output string from the command
  public let output: String
  
  /// The exit code of the command (0 for success)
  public let exitCode: Int
  
  /// Whether the command was successful
  public let isSuccess: Bool
  
  /// Duration of the command execution in seconds
  public let duration: TimeInterval
  
  /// Any structured data parsed from the command output
  public let data: [String: Any]
  
  /// Creates a new command result.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - exitCode: The exit code of the command (0 for success)
  ///   - duration: Duration of the command execution in seconds
  ///   - data: Any structured data parsed from the command output
  public init(
    output: String,
    exitCode: Int = 0,
    duration: TimeInterval = 0,
    data: [String: Any] = [:]
  ) {
    self.output = output
    self.exitCode = exitCode
    self.isSuccess = exitCode == 0
    self.duration = duration
    self.data = data
  }
  
  /// Creates a successful result.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - duration: Duration of the command execution in seconds
  ///   - data: Any structured data parsed from the command output
  /// - Returns: A successful command result
  public static func success(
    output: String,
    duration: TimeInterval = 0,
    data: [String: Any] = [:]
  ) -> ResticCommandResult {
    ResticCommandResult(output: output, exitCode: 0, duration: duration, data: data)
  }
  
  /// Creates a failure result.
  ///
  /// - Parameters:
  ///   - output: The raw output string from the command
  ///   - exitCode: The non-zero exit code of the command
  ///   - duration: Duration of the command execution in seconds
  /// - Returns: A failure command result
  public static func failure(
    output: String,
    exitCode: Int = 1,
    duration: TimeInterval = 0
  ) -> ResticCommandResult {
    ResticCommandResult(output: output, exitCode: exitCode, duration: duration)
  }
}
