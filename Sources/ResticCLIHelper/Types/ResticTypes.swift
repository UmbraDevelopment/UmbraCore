/// Types used by the ResticCLIHelper module
import Foundation

/// Result of executing a Restic command
public struct CommandResult {
  /// Exit code of the command
  public let exitCode: Int

  /// Standard output from the command
  public let output: String

  /// Standard error from the command
  public let error: String

  /// JSON output if available
  public let jsonOutput: [String: Any]?

  /// Whether the command was successful
  public var isSuccess: Bool {
    exitCode == 0
  }
}

/// Type of maintenance operation
public enum MaintenanceType: String {
  /// Remove unused data from repository
  case prune

  /// Check repository for errors
  case check

  /// Rebuild repository index
  case rebuildIndex="rebuild-index"
}
