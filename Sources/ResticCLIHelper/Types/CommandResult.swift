/// Represents the result of a Restic command execution.
/// This type is thread-safe and can be shared across concurrent contexts.
///
/// Example usage:
/// ```swift
/// let result = CommandResult(exitCode: 0, stdout: "Backup complete", stderr: "")
/// if result.isSuccess {
///     print("Command succeeded: \(result.stdout)")
/// }
/// ```
public struct CommandResult: Sendable, Equatable, CustomDebugStringConvertible {
  /// The exit code returned by the command.
  /// A value of 0 typically indicates success.
  public let exitCode: Int

  /// The standard output produced by the command.
  /// Contains the command's normal output stream.
  public let stdout: String

  /// The standard error produced by the command.
  /// Contains any error messages or warnings.
  public let stderr: String

  /// Indicates whether the command executed successfully.
  /// A command is considered successful if its exit code is 0.
  public var isSuccess: Bool { exitCode == 0 }

  /// Creates a new command result with the specified outputs.
  ///
  /// - Parameters:
  ///   - exitCode: The command's exit code (0 for success)
  ///   - stdout: The command's standard output
  ///   - stderr: The command's standard error output
  public init(exitCode: Int, stdout: String, stderr: String) {
    self.exitCode=exitCode
    self.stdout=stdout
    self.stderr=stderr
  }

  /// A debug description of the command result, useful for logging.
  public var debugDescription: String {
    """
    CommandResult(exitCode: \(exitCode), success: \(isSuccess))
    stdout: \(stdout.isEmpty ? "<empty>" : "\n\(stdout)")
    stderr: \(stderr.isEmpty ? "<empty>" : "\n\(stderr)")
    """
  }
}
