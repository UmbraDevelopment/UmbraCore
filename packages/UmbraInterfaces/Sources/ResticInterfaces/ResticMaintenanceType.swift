import Foundation

/// Types of maintenance operations that can be performed on a Restic repository.
///
/// These operations help maintain repository health, optimise storage usage,
/// and ensure data integrity over time.
public enum ResticMaintenanceType: String, Sendable {
  /// Removes unneeded data and performs housekeeping
  case prune

  /// Verifies the integrity of repository data
  case check

  /// Rebuilds the repository index for improved performance
  case rebuildIndex="rebuild-index"
}
