import Foundation

/**
 * Protocol for the Restic command execution service.
 *
 * This protocol defines the interface for executing Restic commands
 * and handling their output.
 */
public protocol ResticServiceProtocol: Sendable {
  /**
   * Executes a Restic command.
   *
   * - Parameter command: The command to execute
   * - Returns: The command output as a string
   * - Throws: BackupOperationError if the command fails
   */
  func execute(_ command: ResticCommand) async throws -> String

  /**
   * Executes a Restic command with progress reporting.
   *
   * - Parameters:
   *   - command: The command to execute
   *   - progressHandler: Handler for progress updates
   * - Returns: The command output as a string
   * - Throws: BackupOperationError if the command fails
   */
  func executeWithProgress(
    _ command: ResticCommand,
    progressHandler: @escaping (String) -> Void
  ) async throws -> String

  /**
   * Cancels a running command.
   *
   * - Returns: Whether the command was successfully cancelled
   */
  func cancelCommand() async -> Bool
}
