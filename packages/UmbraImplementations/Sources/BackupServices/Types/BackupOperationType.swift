import Foundation

/**
 * Types of backup operations.
 *
 * This enum defines the different types of operations that can be performed
 * on backups, used for progress reporting and logging.
 */
public enum BackupOperationType: String, Sendable, Equatable, CaseIterable {
  /// Create a new backup
  case create

  /// Restore from a backup
  case restore

  /// List available backups
  case list

  /// Delete a backup
  case delete

  /// Verify a backup
  case verify

  /// Prune old backups
  case prune

  /// Maintenance operations
  case maintenance
}
