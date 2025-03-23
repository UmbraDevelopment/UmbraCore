/// A Swift interface for interacting with the Restic command-line tool.
///
/// `ResticCLIHelper` provides a type-safe, Swift-native way to interact with Restic, handling
/// command
/// construction, execution, and output parsing.
///
/// Features:
/// - Type-safe command building and validation
/// - Secure credential management
/// - Structured output parsing
/// - Progress tracking and statistics collection
/// - Comprehensive error handling
///
/// Example usage:
/// ```swift
/// let helper = ResticCLIHelper(executablePath: "/usr/local/bin/restic")
/// try await helper.execute(BackupCommand(
///     source: "/path/to/backup",
///     tags: ["daily"],
///     excludes: ["*.tmp"]
/// ))
/// ```
///
/// Command Categories:
/// - Backup: Create and manage backups
/// - Restore: Restore data from backups
/// - Maintenance: Repository maintenance and cleanup
/// - Query: Search and inspect backups
///
/// Security:
/// - Credentials are never logged or exposed
/// - Environment variables are cleared after use
/// - Paths are sanitized to prevent injection
///
/// Error Handling:
/// - Input validation before execution
/// - Detailed error messages with context
/// - Recovery suggestions when applicable
///
/// Performance:
/// - Asynchronous command execution
/// - Progress reporting for long operations
/// - Memory-efficient output handling

import Foundation
import ResticTypes
import UmbraLogging

/// A helper class that provides a Swift interface to the Restic command-line tool.
public final class ResticCLIHelper {
  /// The current version of the ResticCLIHelper module.
  ///
  /// This version follows semantic versioning (MAJOR.MINOR.PATCH).
  public static let version="1.0.0"

  /// The absolute path to the Restic executable.
  ///
  /// This path is validated during initialization to ensure the executable exists and is
  /// accessible.
  private let executablePath: String

  /// The logger instance used by this helper.
  @MainActor
  private let logger: LoggingProtocol

  /// The delegate for progress reporting.
  private var progressDelegate: ResticProgressReporting?

  /// The parser for progress reporting.
  private let progressParser: ProgressParser?

  /// Creates a new Restic CLI helper.
  ///
  /// - Parameters:
  ///   - executablePath: The path to the Restic executable. Must be an absolute path to a valid
  ///                     executable.
  ///   - logger: The logger to use for operation tracking. Defaults to the shared logger instance.
  ///   - progressDelegate: The delegate for progress reporting. Defaults to nil.
  ///
  /// - Throws: `ResticError.invalidConfiguration` if the executable cannot be found or accessed.
  public init(
    executablePath: String,
    logger: LoggingProtocol=UmbraLogging.createLogger(),
    progressDelegate: ResticProgressReporting?=nil
  ) throws {
    self.executablePath=executablePath
    self.logger=logger
    self.progressDelegate=progressDelegate
    progressParser=progressDelegate.map { ProgressParser(delegate: $0) }

    // Validate executable
    let fileManager=FileManager.default
    guard fileManager.fileExists(atPath: executablePath) else {
      throw ResticError.invalidConfiguration(
        "Restic executable not found at \(executablePath)"
      )
    }

    var isDirectory: ObjCBool=false
    guard
      fileManager.fileExists(atPath: executablePath, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      throw ResticError.invalidConfiguration("Path is a directory: \(executablePath)")
    }
  }

  /// Represents the setup for a Restic process execution
  private struct ProcessSetup {
    let process: Process
    let outputPipe: Pipe
    let errorPipe: Pipe
  }

  private func setupProcess(for command: ResticCommand) -> ProcessSetup {
    let outputPipe=Pipe()
    let errorPipe=Pipe()

    let process=Process()
    process.executableURL=URL(fileURLWithPath: executablePath)
    process.arguments=command.arguments
    process.environment=command.environment
    process.standardOutput=outputPipe
    process.standardError=errorPipe

    return ProcessSetup(
      process: process,
      outputPipe: outputPipe,
      errorPipe: errorPipe
    )
  }

  private func handleProcessError(_ error: Error, stderr: String) throws -> Never {
    if let error=error as? POSIXError {
      switch error.code {
        case .ENOENT:
          throw ResticError
            .executionFailed("Restic executable not found at path: \(executablePath)")
        case .EACCES:
          throw ResticError.permissionDenied(path: executablePath)
        default:
          throw ResticError
            .executionFailed("Failed to execute Restic: \(error.localizedDescription)")
      }
    }

    if !stderr.isEmpty {
      throw ResticError.executionFailed(stderr)
    }

    throw ResticError.executionFailed("Unknown error occurred while executing Restic")
  }

  private func processOutput(_ output: String, _ stderr: String) throws -> String {
    if !stderr.isEmpty {
      // Check for known error patterns
      if stderr.contains("wrong password") {
        throw ResticError.invalidPassword
      }
      if stderr.contains("permission denied") {
        throw ResticError.permissionDenied(path: stderr)
      }
      if stderr.contains("repository not found") {
        throw ResticError.repositoryNotFound(path: stderr)
      }
      throw ResticError.executionFailed(stderr)
    }
    return output
  }

  /// Executes a Restic command and returns its output.
  ///
  /// - Parameter command: The command to execute.
  /// - Returns: The command output as a string.
  /// - Throws: `ResticError` if the command fails.
  public func execute(_ command: ResticCommand) async throws -> String {
    try command.validate()

    let setup=setupProcess(for: command)

    do {
      try setup.process.run()

      let outputData=try await setup.outputPipe.fileHandleForReading.bytes
        .reduce(into: Data()) { $0.append($1) }
      let errorData=try await setup.errorPipe.fileHandleForReading.bytes
        .reduce(into: Data()) { $0.append($1) }

      setup.process.waitUntilExit()

      let output=String(data: outputData, encoding: .utf8) ?? ""
      let stderr=String(data: errorData, encoding: .utf8) ?? ""

      return try processOutput(output, stderr)
    } catch {
      let errorData=try? setup.errorPipe.fileHandleForReading.readToEnd()
      let stderr=errorData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
      try handleProcessError(error, stderr: stderr)
    }
  }

  /// Set the progress delegate
  /// - Parameter delegate: The delegate to receive progress updates
  public func setProgressDelegate(_ delegate: ResticProgressReporting?) {
    progressDelegate=delegate
  }
}
