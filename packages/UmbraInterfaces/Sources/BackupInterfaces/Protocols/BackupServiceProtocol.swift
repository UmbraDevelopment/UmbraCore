import Foundation

/**
 * Protocol defining the requirements for a backup service.
 *
 * This protocol follows the Alpha Dot Five architecture and provides
 * operations for creating, managing, and restoring backups with proper
 * concurrency safety and privacy controls.
 *
 * ## Actor-Based Implementation
 *
 * Implementations of this protocol MUST use Swift actors to ensure proper
 * state isolation and thread safety:
 *
 * ```swift
 * actor BackupServiceImpl: BackupServiceProtocol {
 *     // Private state should be isolated within the actor
 *     private var activeOperations: [UUID: BackupOperation] = [:]
 *     private let fileManager: FileManagerProtocol
 *     
 *     // All function implementations must use 'await' appropriately when
 *     // accessing actor-isolated state or calling other actor methods
 * }
 * ```
 *
 * ## Protocol Forwarding
 *
 * To support proper protocol conformance while maintaining actor isolation,
 * implementations should consider using the protocol forwarding pattern:
 *
 * ```swift
 * // Public non-actor class that conforms to protocol
 * public final class BackupService: BackupServiceProtocol {
 *     private let actor: BackupServiceActor
 *     
 *     // Forward all protocol methods to the actor
 *     public func createBackup(...) async -> Result<...> {
 *         await actor.createBackup(...)
 *     }
 * }
 * ```
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
   *   - backupOptions: Optional backup configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    backupOptions: BackupOptions?
  ) async -> Result<BackupOperationResponse<BackupResult>, BackupOperationError>

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
   *   - restoreOptions: Optional restore configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    restoreOptions: RestoreOptions?
  ) async -> Result<BackupOperationResponse<RestoreResult>, BackupOperationError>

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
   *   - listOptions: Optional listing configuration options
   * - Returns: A Result containing either the list of snapshots or an error
   */
  func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    listOptions: ListOptions?
  ) async -> Result<[BackupSnapshot], BackupOperationError>

  /**
   * Deletes a backup snapshot.
   *
   * This operation permanently removes a snapshot and its unique data from
   * the repository. Data that is referenced by other snapshots will be retained.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to delete
   *   - deleteOptions: Optional delete configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  func deleteBackup(
    snapshotID: String,
    deleteOptions: DeleteOptions?
  ) async -> Result<BackupOperationResponse<BackupDeleteResult>, BackupOperationError>

  /**
   * Performs maintenance on the backup repository.
   *
   * This operation performs maintenance tasks such as checking integrity,
   * removing unreferenced data, or optimising storage. These operations help
   * ensure the repository remains in a healthy state.
   *
   * - Parameters:
   *   - type: Type of maintenance to perform
   *   - maintenanceOptions: Optional maintenance configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  func performMaintenance(
    type: MaintenanceType,
    maintenanceOptions: MaintenanceOptions?
  ) async -> Result<BackupOperationResponse<MaintenanceResult>, BackupOperationError>

  /**
   * Verifies the integrity of a backup.
   *
   * This operation checks that all data referenced by a snapshot is present
   * and uncorrupted in the repository.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify, or nil to verify the latest
   *   - verifyOptions: Optional verification configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  func verifyBackup(
    snapshotID: String?,
    verifyOptions: VerifyOptions?
  ) async -> Result<BackupOperationResponse<VerificationResult>, BackupOperationError>

  /**
   * Cancels an ongoing backup operation.
   *
   * This method attempts to gracefully cancel an in-progress operation.
   * Cancellation may not be immediate, and some operations might not be
   * cancellable once they've reached a certain stage.
   *
   * - Parameter operationID: ID of the operation to cancel
   * - Returns: True if cancellation was initiated, false if the operation
   *            doesn't exist or cannot be cancelled
   */
  func cancelOperation(operationID: UUID) async -> Bool
}
