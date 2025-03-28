import Foundation
import UmbraErrors

/// Protocol defining the requirements for a snapshot service
///
/// The snapshot service provides focused operations for managing
/// snapshots, including detailed information retrieval, metadata management,
/// and direct snapshot-level operations.
public protocol SnapshotServiceProtocol: Sendable {
    /// Lists available snapshots with optional filtering
    /// - Parameters:
    ///   - repositoryID: Optional repository ID to filter by
    ///   - tags: Optional tags to filter snapshots by
    ///   - before: Optional date to filter snapshots before
    ///   - after: Optional date to filter snapshots after
    ///   - path: Optional path that must be included in the snapshot
    ///   - limit: Maximum number of snapshots to return
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Array of backup snapshots matching the criteria
    /// - Throws: `BackupError` if the listing operation fails or is cancelled
    func listSnapshots(
        repositoryID: String?,
        tags: [String]?,
        before: Date?,
        after: Date?,
        path: URL?,
        limit: Int?,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> [BackupSnapshot]
    
    /// Retrieves detailed information about a specific snapshot
    /// - Parameters:
    ///   - snapshotID: ID of the snapshot
    ///   - includeFileStatistics: Whether to include detailed file statistics
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Detailed backup snapshot information
    /// - Throws: `BackupError` if the snapshot cannot be found or accessed or the operation is cancelled
    func getSnapshotDetails(
        snapshotID: String,
        includeFileStatistics: Bool,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> BackupSnapshot
    
    /// Compares two snapshots and returns differences
    /// - Parameters:
    ///   - snapshotID1: First snapshot ID
    ///   - snapshotID2: Second snapshot ID
    ///   - path: Optional specific path to compare
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Snapshot difference result
    /// - Throws: `BackupError` if comparison fails or is cancelled
    func compareSnapshots(
        snapshotID1: String,
        snapshotID2: String,
        path: URL?,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> SnapshotDifference
    
    /// Updates tags for a snapshot
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to update
    ///   - addTags: Tags to add
    ///   - removeTags: Tags to remove
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Updated backup snapshot
    /// - Throws: `BackupError` if tag update fails or is cancelled
    func updateSnapshotTags(
        snapshotID: String,
        addTags: [String],
        removeTags: [String],
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> BackupSnapshot
    
    /// Updates the description for a snapshot
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to update
    ///   - description: New description
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Updated backup snapshot
    /// - Throws: `BackupError` if description update fails or is cancelled
    func updateSnapshotDescription(
        snapshotID: String,
        description: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> BackupSnapshot
    
    /// Deletes a snapshot
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to delete
    ///   - pruneAfterDelete: Whether to prune repository after deletion
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Result of deletion operation
    /// - Throws: `BackupError` if deletion fails or is cancelled
    func deleteSnapshot(
        snapshotID: String,
        pruneAfterDelete: Bool,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> DeleteResult
    
    /// Copies a snapshot to another repository
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to copy
    ///   - targetRepositoryID: Target repository ID
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: ID of the new snapshot in the target repository
    /// - Throws: `BackupError` if copy operation fails or is cancelled
    func copySnapshot(
        snapshotID: String,
        targetRepositoryID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> String
    
    /// Finds files within a snapshot
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to search
    ///   - pattern: Pattern to search for
    ///   - caseSensitive: Whether the search is case-sensitive
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: List of matching files
    /// - Throws: `BackupError` if search fails or is cancelled
    func findFiles(
        snapshotID: String,
        pattern: String,
        caseSensitive: Bool,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> [SnapshotFile]
    
    /// Locks a snapshot to prevent modification or deletion
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to lock
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Throws: `BackupError` if locking fails or is cancelled
    func lockSnapshot(
        snapshotID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws
    
    /// Unlocks a previously locked snapshot
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to unlock
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Throws: `BackupError` if unlocking fails or is cancelled
    func unlockSnapshot(
        snapshotID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws
    
    /// Verifies a snapshot's integrity
    /// - Parameters:
    ///   - snapshotID: Snapshot ID to verify
    ///   - progressReporter: Optional reporter for tracking operation progress
    ///   - cancellationToken: Optional token for cancelling the operation
    /// - Returns: Verification result
    /// - Throws: `BackupError` if verification fails or is cancelled
    func verifySnapshot(
        snapshotID: String,
        progressReporter: BackupProgressReporter?,
        cancellationToken: CancellationToken?
    ) async throws -> VerificationResult
}
