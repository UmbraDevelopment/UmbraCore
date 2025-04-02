import Foundation

/// Protocol defining the requirements for a backup coordinator service
///
/// The BackupCoordinator provides a unified interface for managing backup operations,
/// including both backup and snapshot-related functionality. It coordinates between
/// various services to provide a cohesive backup management experience.
public protocol BackupCoordinatorProtocol: Sendable {
  /// Creates a new backup
  /// - Parameters:
  ///   - sources: Source paths to back up
  ///   - excludePaths: Optional paths to exclude
  ///   - tags: Optional tags to associate with the backup
  ///   - options: Optional backup options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the backup operation
  /// - Throws: `BackupError` if backup creation fails or is cancelled
  func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupCreateResult

  /// Restores a backup
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to restore
  ///   - targetPath: Path to restore to
  ///   - includePaths: Optional paths to include
  ///   - excludePaths: Optional paths to exclude
  ///   - options: Optional restore options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the restore operation
  /// - Throws: `BackupError` if restore fails or is cancelled
  func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    options: RestoreOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupRestoreResult

  /// Deletes a backup
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - options: Optional delete options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the delete operation
  /// - Throws: `BackupError` if deletion fails or is cancelled
  func deleteBackup(
    snapshotID: String,
    options: DeleteOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupDeleteResult

  /// Lists all available snapshots
  /// - Parameters:
  ///   - tags: Optional tags to filter by
  ///   - before: Optional date to filter snapshots before
  ///   - after: Optional date to filter snapshots after
  ///   - options: Optional listing options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Array of matching snapshots
  /// - Throws: `BackupError` if listing fails or is cancelled
  func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    options: ListOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> [BackupSnapshot]

  /// Gets detailed information about a specific snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - includeFileStatistics: Whether to include file statistics
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Detailed snapshot information
  /// - Throws: `BackupError` if retrieval fails or is cancelled
  func getSnapshotDetails(
    snapshotID: String,
    includeFileStatistics: Bool,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupSnapshot

  /// Updates tags for a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - addTags: Tags to add
  ///   - removeTags: Tags to remove
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Updated snapshot
  /// - Throws: `BackupError` if tag update fails or is cancelled
  func updateSnapshotTags(
    snapshotID: String,
    addTags: [String],
    removeTags: [String],
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupSnapshot

  /// Finds files within a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - pattern: Pattern to search for
  ///   - caseSensitive: Whether search is case-sensitive
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: List of matching files
  /// - Throws: `BackupError` if search fails or is cancelled
  func findFiles(
    snapshotID: String,
    pattern: String,
    caseSensitive: Bool,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> [SnapshotFile]

  /// Verifies a snapshot's integrity
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to verify
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Verification result
  /// - Throws: `BackupError` if verification fails or is cancelled
  func verifySnapshot(
    snapshotID: String,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> BackupVerificationResultDTO

  /// Performs a maintenance operation on the repository
  /// - Parameters:
  ///   - type: Type of maintenance to perform
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the maintenance operation
  /// - Throws: `BackupError` if maintenance fails or is cancelled
  func performMaintenance(
    type: MaintenanceType,
    progressReporter: BackupProgressReporter?,
    cancellationToken: BackupCancellationToken?
  ) async throws -> MaintenanceResult
}
