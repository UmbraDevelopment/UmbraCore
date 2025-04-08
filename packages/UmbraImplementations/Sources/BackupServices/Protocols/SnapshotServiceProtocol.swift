import BackupInterfaces
import Foundation

/**
 * Protocol defining snapshot service operations.
 *
 * This protocol provides methods for working with backup snapshots,
 * including retrieval, comparison, and verification operations.
 */
public protocol SnapshotServiceProtocol: Sendable {
  /**
   * Gets details for a specific snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to retrieve
   *   - includeFileStatistics: Whether to include file statistics in the result
   * - Returns: The snapshot details or nil if not found
   * - Throws: BackupOperationError if the operation fails
   */
  func getSnapshotDetails(
    snapshotID: String,
    includeFileStatistics: Bool
  ) async throws -> BackupInterfaces.BackupSnapshot?

  /**
   * Gets the latest snapshot.
   *
   * - Parameter includeFileStatistics: Whether to include file statistics in the result
   * - Returns: The latest snapshot or nil if no snapshots exist
   * - Throws: BackupOperationError if the operation fails
   */
  func getLatestSnapshot(
    includeFileStatistics: Bool
  ) async throws -> BackupInterfaces.BackupSnapshot?

  /**
   * Lists all snapshots.
   *
   * - Parameter includeFileStatistics: Whether to include file statistics in the results
   * - Returns: Array of snapshots
   * - Throws: BackupOperationError if the operation fails
   */
  func listSnapshots(
    includeFileStatistics: Bool
  ) async throws -> [BackupInterfaces.BackupSnapshot]

  /**
   * Compares two snapshots.
   *
   * - Parameters:
   *   - firstSnapshotID: ID of the first snapshot
   *   - secondSnapshotID: ID of the second snapshot
   * - Returns: Comparison result
   * - Throws: BackupOperationError if the operation fails
   */
  func compareSnapshots(
    firstSnapshotID: String,
    secondSnapshotID: String
  ) async throws -> BackupInterfaces.BackupSnapshotComparisonResult

  /**
   * Verifies a snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify
   *   - fullVerification: Whether to perform a full verification
   * - Returns: Verification result
   * - Throws: BackupOperationError if the operation fails
   */
  func verifySnapshot(
    snapshotID: String,
    fullVerification: Bool
  ) async throws -> BackupInterfaces.BackupVerificationResult
}
