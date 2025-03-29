import Foundation

/// Protocol defining the requirements for a backup service
public protocol BackupServiceProtocol: Sendable {
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
    cancellationToken: CancellationToken?
  ) async throws -> BackupResult

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
    cancellationToken: CancellationToken?
  ) async throws -> RestoreResult

  /// Lists available snapshots
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
    cancellationToken: CancellationToken?
  ) async throws -> [BackupSnapshot]

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
    cancellationToken: CancellationToken?
  ) async throws -> DeleteResult

  /// Performs maintenance on the backup repository
  /// - Parameters:
  ///   - type: Type of maintenance to perform
  ///   - options: Optional maintenance options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the maintenance operation
  /// - Throws: `BackupError` if maintenance fails or is cancelled
  func performMaintenance(
    type: MaintenanceType,
    options: MaintenanceOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) async throws -> MaintenanceResult
}
