import Foundation

/**
 * Protocol defining the requirements for a backup service.
 *
 * This protocol follows the Alpha Dot Five architecture and provides
 * operations for creating, managing, and restoring backups with proper
 * concurrency safety and privacy controls.
 */
public protocol BackupServiceProtocol: Sendable {
  /**
   * Creates a new backup.
   *
   * This operation captures a point-in-time backup of the specified sources,
   * excluding any paths in the exclusions list. The operation is performed
   * asynchronously and reports progress through the returned stream.
   *
   * - Parameters:
   *   - sources: Source paths to back up
   *   - excludePaths: Optional paths to exclude
   *   - tags: Optional tags to associate with the backup
   *   - options: Optional backup options
   * - Returns: A Result containing either the operation result or an error
   */
  func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?
  ) async -> Result<BackupOperationResult<BackupResult>, BackupOperationError>

  /**
   * Restores a backup.
   *
   * This operation restores files from the specified snapshot to the target path,
   * optionally limiting the restore to specific included paths and excluding others.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to restore
   *   - targetPath: Path to restore to
   *   - includePaths: Optional paths to include
   *   - excludePaths: Optional paths to exclude
   *   - options: Optional restore options
   * - Returns: A Result containing either the operation result or an error
   */
  func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    options: RestoreOptions?
  ) async -> Result<BackupOperationResult<RestoreResult>, BackupOperationError>

  /**
   * Lists available snapshots.
   *
   * This operation retrieves a list of available snapshots, optionally filtered
   * by tags and date ranges. It provides detailed snapshot information including
   * creation time, size, and associated tags.
   *
   * - Parameters:
   *   - tags: Optional tags to filter by
   *   - before: Optional date to filter snapshots before
   *   - after: Optional date to filter snapshots after
   *   - options: Optional listing options
   * - Returns: A Result containing either the list of snapshots or an error
   */
  func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    options: ListOptions?
  ) async -> Result<[BackupSnapshot], BackupOperationError>

  /**
   * Deletes a backup snapshot.
   *
   * This operation permanently removes a snapshot and its unique data from
   * the repository. Data that is referenced by other snapshots will be retained.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to delete
   *   - options: Optional delete options
   * - Returns: A Result containing either the operation result or an error
   */
  func deleteBackup(
    snapshotID: String,
    options: DeleteOptions?
  ) async -> Result<BackupOperationResult<BackupDeleteResult>, BackupOperationError>

  /**
   * Performs maintenance on the backup repository.
   *
   * This operation performs maintenance tasks such as checking integrity,
   * removing unreferenced data, or optimising storage. These operations help
   * ensure the repository remains in a healthy state.
   *
   * - Parameters:
   *   - type: Type of maintenance to perform
   *   - options: Optional maintenance options
   * - Returns: A Result containing either the operation result or an error
   */
  func performMaintenance(
    type: MaintenanceType,
    options: MaintenanceOptions?
  ) async -> Result<BackupOperationResult<MaintenanceResult>, BackupOperationError>
}
