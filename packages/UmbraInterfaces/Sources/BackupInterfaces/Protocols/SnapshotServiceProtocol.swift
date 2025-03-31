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
  /// - Returns: Array of backup snapshots matching the criteria
  /// - Throws: `BackupError` if the listing operation fails
  func listSnapshots(
    repositoryID: String?,
    tags: [String]?,
    before: Date?,
    after: Date?,
    path: URL?,
    limit: Int?
  ) async throws -> [BackupSnapshot]

  /// Retrieves detailed information about a specific snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - includeFileStatistics: Whether to include detailed file statistics
  /// - Returns: Detailed backup snapshot information
  /// - Throws: `BackupError` if the snapshot cannot be found or accessed
  func getSnapshotDetails(
    snapshotID: String,
    includeFileStatistics: Bool
  ) async throws -> BackupSnapshot

  /// Compares two snapshots and returns differences
  /// - Parameters:
  ///   - snapshotID1: First snapshot ID
  ///   - snapshotID2: Second snapshot ID
  ///   - path: Optional specific path to compare
  /// - Returns: Snapshot difference result and a progress sequence
  /// - Throws: `BackupError` if comparison fails
  func compareSnapshots(
    snapshotID1: String,
    snapshotID2: String,
    path: URL?
  ) async throws -> (SnapshotDifference, AsyncStream<BackupProgressInfo>)

  /// Updates tags for a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to update
  ///   - addTags: Tags to add
  ///   - removeTags: Tags to remove
  /// - Returns: Updated backup snapshot
  /// - Throws: `BackupError` if tag update fails
  func updateSnapshotTags(
    snapshotID: String,
    addTags: [String],
    removeTags: [String]
  ) async throws -> BackupSnapshot

  /// Updates the description for a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to update
  ///   - description: New description
  /// - Returns: Updated backup snapshot
  /// - Throws: `BackupError` if description update fails
  func updateSnapshotDescription(
    snapshotID: String,
    description: String
  ) async throws -> BackupSnapshot

  /// Deletes a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to delete
  ///   - pruneAfterDelete: Whether to prune repository after deletion
  /// - Returns: Result of the delete operation and a progress sequence
  /// - Throws: `BackupError` if deletion fails
  func deleteSnapshot(
    snapshotID: String,
    pruneAfterDelete: Bool
  ) async throws -> (BackupDeleteResult, AsyncStream<BackupProgressInfo>)

  /// Exports a snapshot to a specified location
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to export
  ///   - destination: Destination path for export
  ///   - format: Export format
  /// - Returns: Export result and a progress sequence
  /// - Throws: `BackupError` if export fails
  func exportSnapshot(
    snapshotID: String,
    destination: URL,
    format: BackupExportFormat
  ) async throws -> (BackupExportResult, AsyncStream<BackupProgressInfo>)

  /// Imports a snapshot from a specified location
  /// - Parameters:
  ///   - source: Source path for import
  ///   - repositoryID: Target repository ID
  ///   - format: Import format
  /// - Returns: Import result and a progress sequence
  /// - Throws: `BackupError` if import fails
  func importSnapshot(
    source: URL,
    repositoryID: String,
    format: BackupImportFormat
  ) async throws -> (BackupImportResult, AsyncStream<BackupProgressInfo>)

  /// Verifies the integrity of a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to verify
  ///   - level: Verification level
  /// - Returns: Verification result and a progress sequence
  /// - Throws: `BackupError` if verification fails
  func verifySnapshot(
    snapshotID: String,
    level: VerificationLevel
  ) async throws -> (VerificationResult, AsyncStream<BackupProgressInfo>)

  /// Copies a snapshot to another repository
  /// - Parameters:
  ///   - snapshotID: Snapshot ID to copy
  ///   - targetRepositoryID: Target repository ID
  /// - Returns: Copy result and a progress sequence
  /// - Throws: `BackupError` if copy fails
  func copySnapshot(
    snapshotID: String,
    targetRepositoryID: String
  ) async throws -> (BackupCopyResult, AsyncStream<BackupProgressInfo>)

  /// Retrieves the content of a specific file in a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID
  ///   - path: Path to the file
  /// - Returns: File content and metadata
  /// - Throws: `BackupError` if file retrieval fails
  func getFileContent(
    snapshotID: String,
    path: URL
  ) async throws -> FileContent

  /// Lists the files in a directory within a snapshot
  /// - Parameters:
  ///   - snapshotID: Snapshot ID
  ///   - path: Path to the directory
  ///   - recursive: Whether to list files recursively
  /// - Returns: Array of file information
  /// - Throws: `BackupError` if listing fails
  func listFiles(
    snapshotID: String,
    path: URL,
    recursive: Bool
  ) async throws -> [FileInfo]
}
