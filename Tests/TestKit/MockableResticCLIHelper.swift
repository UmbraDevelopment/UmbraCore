import Foundation
import ResticCLIHelper
import ResticCLIHelperCommands
import ResticTypes
import UmbraLogging

/// A mockable version of ResticCLIHelper that uses a configurable process executor
public final class MockableResticCLIHelper {
  /// The absolute path to the Restic executable
  private let executablePath: String

  /// The process executor to use (can be mocked)
  private let processExecutor: ProcessExecutorProtocol

  /// The logger instance
  private let logger: LoggingProtocol

  /// Creates a new mockable Restic CLI helper
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable (can be a dummy path for tests)
  ///   - processExecutor: The process executor to use
  ///   - logger: The logger to use
  public init(
    executablePath: String,
    processExecutor: ProcessExecutorProtocol,
    logger: LoggingProtocol=UmbraLogging.createLogger()
  ) {
    self.executablePath=executablePath
    self.processExecutor=processExecutor
    self.logger=logger
  }

  /// Execute a backup command
  /// - Parameter command: The backup command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: BackupCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute a restore command
  /// - Parameter command: The restore command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: RestoreCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute a snapshot command
  /// - Parameter command: The snapshot command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: SnapshotCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute a stats command
  /// - Parameter command: The stats command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: StatsCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute an init command
  /// - Parameter command: The init command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: InitCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute a check command
  /// - Parameter command: The check command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: CheckCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute a copy command
  /// - Parameter command: The copy command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: CopyCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.commandArguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Execute a testable backup command
  /// - Parameter command: The testable backup command to execute
  /// - Returns: The command output
  /// - Throws: ResticError if the command fails
  public func execute(_ command: TestableBackupCommand) throws -> String {
    try command.validate()

    let arguments=[command.commandName] + command.arguments
    return try executeCommand(arguments: arguments, environment: command.environment)
  }

  /// Common method to execute a command with arguments and environment
  private func executeCommand(arguments: [String], environment: [String: String]) throws -> String {
    do {
      return try processExecutor.execute(
        executablePath: executablePath,
        arguments: arguments,
        environment: environment
      )
    } catch let error as ResticTypes.ResticError {
      throw error
    } catch {
      throw ResticTypes.ResticError
        .executionFailed("Execution failed: \(error.localizedDescription)")
    }
  }
}
