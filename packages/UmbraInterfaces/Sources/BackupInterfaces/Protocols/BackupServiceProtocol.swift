import Foundation

/// Protocol defining the requirements for a backup service
public protocol BackupServiceProtocol: Sendable {
  /// Creates a new backup
  /// - Parameters:
  ///   - sources: Source paths to back up
  ///   - excludePaths: Optional paths to exclude
  ///   - tags: Optional tags to associate with the backup
  ///   - options: Optional backup options
  /// - Returns: Result of the backup operation and a progress sequence
  /// - Throws: `BackupError` if backup creation fails
  /// - Note: The returned task can be cancelled using Swift's built-in cancellation mechanism
  func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?
  ) async throws -> (BackupResult, AsyncStream<BackupProgress>)

  /// Restores a backup
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to restore
  ///   - targetPath: Path to restore to
  ///   - includePaths: Optional paths to include
  ///   - excludePaths: Optional paths to exclude
  ///   - options: Optional restore options
  /// - Returns: Result of the restore operation and a progress sequence
  /// - Throws: `BackupError` if restore fails
  /// - Note: The returned task can be cancelled using Swift's built-in cancellation mechanism
  func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    options: RestoreOptions?
  ) async throws -> (RestoreResult, AsyncStream<BackupProgress>)

  /// Lists available snapshots
  /// - Parameters:
  ///   - tags: Optional tags to filter by
  ///   - before: Optional date to filter snapshots before
  ///   - after: Optional date to filter snapshots after
  ///   - options: Optional listing options
  /// - Returns: Array of matching snapshots
  /// - Throws: `BackupError` if listing fails
  func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    options: ListOptions?
  ) async throws -> [BackupSnapshot]

  /// Deletes a backup
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - options: Optional delete options
  /// - Returns: Result of the delete operation and a progress sequence
  /// - Throws: `BackupError` if deletion fails
  func deleteBackup(
    snapshotID: String,
    options: DeleteOptions?
  ) async throws -> (DeleteResult, AsyncStream<BackupProgress>)

  /// Performs maintenance on the backup repository
  /// - Parameters:
  ///   - type: Type of maintenance to perform
  ///   - options: Optional maintenance options
  /// - Returns: Result of the maintenance operation and a progress sequence
  /// - Throws: `BackupError` if maintenance fails
  func performMaintenance(
    type: MaintenanceType,
    options: MaintenanceOptions?
  ) async throws -> (MaintenanceResult, AsyncStream<BackupProgress>)
}
