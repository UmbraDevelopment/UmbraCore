import BackupInterfaces
import Foundation
import LoggingTypes

/**
 * Implementation of the SnapshotServiceProtocol.
 *
 * This service provides operations for working with backup snapshots,
 * including retrieval, comparison, and verification.
 */
public actor SnapshotServiceImpl: SnapshotServiceProtocol {
  /// The Restic service used for backend operations
  private let resticService: ResticServiceProtocol

  /// Parser for snapshot results
  private let resultParser: SnapshotResultParser

  /// Logger for snapshot operations
  private let logger: LoggingProtocol

  /**
   * Initialises a new snapshot service.
   *
   * - Parameters:
   *   - resticService: The Restic service for backend operations
   *   - resultParser: Parser for snapshot results
   *   - logger: Logger for snapshot operations
   */
  public init(
    resticService: ResticServiceProtocol,
    resultParser: SnapshotResultParser,
    logger: LoggingProtocol
  ) {
    self.resticService=resticService
    self.resultParser=resultParser
    self.logger=logger
  }

  /**
   * Gets details for a specific snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to retrieve
   *   - includeFileStatistics: Whether to include file statistics in the result
   * - Returns: The snapshot details or nil if not found
   * - Throws: BackupOperationError if the operation fails
   */
  public func getSnapshotDetails(
    snapshotID: String,
    includeFileStatistics: Bool
  ) async throws -> BackupInterfaces.BackupSnapshot? {
    // Create a log context
    let context=SnapshotLogContext(
      operation: "getSnapshotDetails",
      source: "SnapshotServiceImpl"
    )
    .withPublic(key: "snapshotID", value: snapshotID)
    .withPublic(key: "includeFileStatistics", value: String(includeFileStatistics))

    await logger.info("Getting snapshot details", context: context)

    // Create command to get snapshot details
    var args=["snapshots", snapshotID, "--json"]
    if includeFileStatistics {
      args.append("--stats")
    }

    let command=ResticCommandImpl(arguments: args)

    do {
      // Execute the command
      let output=try await resticService.execute(command)

      // Parse the result
      let snapshot=try resultParser.parseSnapshot(output)

      await logger.info("Retrieved snapshot details", context: context)

      return snapshot
    } catch {
      // Handle case where snapshot is not found
      if let error=error as? BackupOperationError, case .snapshotNotFound=error {
        await logger.info("Snapshot not found", context: context)
        return nil
      }

      // Log and rethrow other errors
      await logger.error(
        "Failed to get snapshot details: \(error.localizedDescription)",
        context: context
      )
      throw error
    }
  }

  /**
   * Gets the latest snapshot.
   *
   * - Parameter includeFileStatistics: Whether to include file statistics in the result
   * - Returns: The latest snapshot or nil if no snapshots exist
   * - Throws: BackupOperationError if the operation fails
   */
  public func getLatestSnapshot(
    includeFileStatistics: Bool=false
  ) async throws -> BackupInterfaces.BackupSnapshot? {
    // Create a log context
    let context=SnapshotLogContext(
      operation: "getLatestSnapshot",
      source: "SnapshotServiceImpl"
    )
    .withPublic(key: "includeFileStatistics", value: String(includeFileStatistics))

    await logger.info("Getting latest snapshot", context: context)

    // Create command to get latest snapshot
    var args=["snapshots", "latest", "--json"]
    if includeFileStatistics {
      args.append("--stats")
    }

    let command=ResticCommandImpl(arguments: args)

    do {
      // Execute the command
      let output=try await resticService.execute(command)

      // Parse the result
      let snapshot=try resultParser.parseSnapshot(output)

      await logger.info("Retrieved latest snapshot", context: context)

      return snapshot
    } catch {
      // Handle case where no snapshots exist
      if let error=error as? BackupOperationError, case .snapshotNotFound=error {
        await logger.info("No snapshots found", context: context)
        return nil
      }

      // Log and rethrow other errors
      await logger.error(
        "Failed to get latest snapshot: \(error.localizedDescription)",
        context: context
      )
      throw error
    }
  }

  /**
   * Lists all snapshots.
   *
   * - Parameter includeFileStatistics: Whether to include file statistics in the results
   * - Returns: Array of snapshots
   * - Throws: BackupOperationError if the operation fails
   */
  public func listSnapshots(
    includeFileStatistics: Bool=false
  ) async throws -> [BackupInterfaces.BackupSnapshot] {
    // Create a log context
    let context=SnapshotLogContext(
      operation: "listSnapshots",
      source: "SnapshotServiceImpl"
    )
    .withPublic(key: "includeFileStatistics", value: String(includeFileStatistics))

    await logger.info("Listing snapshots", context: context)

    // Create command to list snapshots
    var args=["snapshots", "--json"]
    if includeFileStatistics {
      args.append("--stats")
    }

    let command=ResticCommandImpl(arguments: args)

    do {
      // Execute the command
      let output=try await resticService.execute(command)

      // Parse the result
      let snapshots=try resultParser.parseSnapshotList(output)

      await logger.info("Retrieved \(snapshots.count) snapshots", context: context)

      return snapshots
    } catch {
      // Log and rethrow errors
      await logger.error(
        "Failed to list snapshots: \(error.localizedDescription)",
        context: context
      )
      throw error
    }
  }

  /**
   * Compares two snapshots.
   *
   * - Parameters:
   *   - firstSnapshotID: ID of the first snapshot
   *   - secondSnapshotID: ID of the second snapshot
   * - Returns: Comparison result
   * - Throws: BackupOperationError if the operation fails
   */
  public func compareSnapshots(
    firstSnapshotID: String,
    secondSnapshotID: String
  ) async throws -> BackupInterfaces.BackupSnapshotComparisonResult {
    // Create a log context
    let context=SnapshotLogContext(
      operation: "compareSnapshots",
      source: "SnapshotServiceImpl"
    )
    .withPublic(key: "firstSnapshotID", value: firstSnapshotID)
    .withPublic(key: "secondSnapshotID", value: secondSnapshotID)

    await logger.info("Comparing snapshots", context: context)

    // Create command to compare snapshots
    let command=ResticCommandImpl(arguments: [
      "diff",
      firstSnapshotID,
      secondSnapshotID,
      "--json"
    ])

    do {
      // Execute the command
      let output=try await resticService.execute(command)

      // Parse the result
      let result=try resultParser.parseSnapshotComparisonResult(
        output: output,
        firstSnapshotID: firstSnapshotID,
        secondSnapshotID: secondSnapshotID
      )

      await logger.info("Completed snapshot comparison", context: context)

      return result
    } catch {
      // Log and rethrow errors
      await logger.error(
        "Failed to compare snapshots: \(error.localizedDescription)",
        context: context
      )
      throw error
    }
  }

  /**
   * Verifies a snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify
   *   - fullVerification: Whether to perform a full verification
   * - Returns: Verification result
   * - Throws: BackupOperationError if the operation fails
   */
  public func verifySnapshot(
    snapshotID: String,
    fullVerification: Bool=false
  ) async throws -> BackupInterfaces.BackupVerificationResult {
    // Create a log context
    let context=SnapshotLogContext(
      operation: "verifySnapshot",
      source: "SnapshotServiceImpl"
    )
    .withPublic(key: "snapshotID", value: snapshotID)
    .withPublic(key: "fullVerification", value: String(fullVerification))

    await logger.info("Verifying snapshot", context: context)

    // Create command to verify snapshot
    var args=["check"]
    if fullVerification {
      args.append("--read-data")
    }

    let command=ResticCommandImpl(arguments: args)

    do {
      // Execute the command
      let output=try await resticService.execute(command)

      // Parse the result
      let result=try resultParser.parseVerificationResult(output: output, snapshotID: snapshotID)

      await logger.info("Completed snapshot verification", context: context)

      return result
    } catch {
      // Log and rethrow errors
      await logger.error(
        "Failed to verify snapshot: \(error.localizedDescription)",
        context: context
      )
      throw error
    }
  }
}
