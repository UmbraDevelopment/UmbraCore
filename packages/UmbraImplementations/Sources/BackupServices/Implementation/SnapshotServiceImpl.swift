import BackupInterfaces
import Foundation
import LoggingInterfaces
import ResticInterfaces
import ResticServices
import UmbraErrors

/// Actor-based implementation of the snapshot service
///
/// This implementation provides a thread-safe, actor-based service for managing
/// snapshots using the Restic backend for storage.
@preconcurrency
public actor SnapshotServiceImpl: SnapshotServiceProtocol {
  /// The Restic service used for backend operations
  private let resticService: ResticServiceProtocol

  /// Logger for operation tracking
  private let logger: any LoggingProtocol

  /// Factory for creating Restic commands
  private let commandFactory: ResticCommandFactory

  /// Parser for Restic command outputs
  private let resultParser: SnapshotResultParser

  /// Error mapper for converting Restic errors to backup errors
  private let errorMapper: ErrorMapper

  /// Creates a new snapshot service implementation
  /// - Parameters:
  ///   - resticService: Restic service for backend operations
  ///   - logger: Logger for operation tracking
  public init(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol
  ) {
    self.resticService=resticService
    self.logger=logger
    commandFactory=ResticCommandFactory()
    resultParser=SnapshotResultParser()
    errorMapper=ErrorMapper()
  }

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
  /// - Throws: `BackupError` if the listing operation fails
  public func listSnapshots(
    repositoryID: String?,
    tags: [String]?,
    before: Date?,
    after: Date?,
    path: URL?,
    limit: Int?,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> [BackupSnapshot] {
    // Create metadata
    var metadata=LogMetadata()
    metadata["repositoryID"]=repositoryID ?? "any"
    metadata["tags"]=tags?.joined(separator: ", ") ?? "any"
    metadata["before"]=before?.description ?? "any"
    metadata["after"]=after?.description ?? "any"
    metadata["path"]=path?.path ?? "any"
    metadata["limit"]=limit != nil ? String(limit!) : "unlimited"

    await logger.info(
      "Listing snapshots with detailed criteria",
      metadata: metadata,
      source: "SnapshotService"
    )

    do {
      // Create command to list snapshots
      let command=try commandFactory.createListCommand(
        repositoryID: repositoryID,
        tags: tags,
        before: before,
        after: after,
        path: path,
        limit: limit
      )

      // Execute command
      let output=try await resticService.execute(command)

      // Parse snapshots
      let snapshots=try resultParser.parseSnapshotsList(output: output, repositoryID: repositoryID)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["count"]=String(snapshots.count)

      await logger.info(
        "Listed snapshots successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return snapshots
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "List snapshots failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "List snapshots failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "List snapshots failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Retrieves detailed information about a specific snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - includeFileStatistics: Whether to include detailed file statistics
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Detailed backup snapshot information
  /// - Throws: `BackupError` if the snapshot cannot be found or accessed
  public func getSnapshotDetails(
    snapshotID: String,
    includeFileStatistics: Bool,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupSnapshot {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["includeFileStatistics"]=String(includeFileStatistics)

    await logger.info(
      "Getting detailed snapshot information",
      metadata: metadata,
      source: "SnapshotService"
    )

    do {
      // Create command to get snapshot details
      let command=try commandFactory.createSnapshotDetailsCommand(
        snapshotID: snapshotID,
        includeFileStatistics: includeFileStatistics
      )

      // Execute command
      let output=try await resticService.execute(command)

      // Parse snapshot details
      guard
        let snapshot=try resultParser.parseSnapshotDetails(
          output: output,
          snapshotID: snapshotID,
          includeFileStatistics: includeFileStatistics,
          repositoryID: nil
        )
      else {
        throw BackupError.snapshotNotFound(id: snapshotID)
      }

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshot.id
      resultMetadata["creationTime"]=snapshot.creationTime.description
      resultMetadata["fileCount"]=String(snapshot.fileCount)

      await logger.info(
        "Retrieved snapshot details successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return snapshot
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Get snapshot details failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Get snapshot details failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Get snapshot details failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Compares two snapshots and returns the differences
  /// - Parameters:
  ///   - snapshotID1: ID of the first snapshot
  ///   - snapshotID2: ID of the second snapshot
  ///   - path: Optional path to compare within the snapshots
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: A detailed comparison of the snapshots
  /// - Throws: `BackupError` if comparison fails
  public func compareSnapshots(
    snapshotID1: String,
    snapshotID2: String,
    path: URL?,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> SnapshotDifference {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID1"]=snapshotID1
    metadata["snapshotID2"]=snapshotID2
    metadata["path"]=path?.path ?? "all"

    await logger.info("Comparing snapshots", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to compare snapshots
      let command=try commandFactory.createCompareCommand(
        snapshotID1: snapshotID1,
        snapshotID2: snapshotID2,
        path: path
      )

      // Execute command
      let output=try await resticService.execute(command)

      // Parse comparison result
      let difference=try resultParser.parseComparisonResult(
        output: output,
        snapshotID1: snapshotID1,
        snapshotID2: snapshotID2
      )

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["addedFiles"]=String(difference.addedFiles?.count ?? 0)
      resultMetadata["removedFiles"]=String(difference.removedFiles?.count ?? 0)
      resultMetadata["modifiedFiles"]=String(difference.modifiedFiles?.count ?? 0)

      await logger.info(
        "Snapshot comparison completed",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return difference
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Snapshot comparison failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Snapshot comparison failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Snapshot comparison failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Updates tags for a specific snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to update
  ///   - addTags: Tags to add
  ///   - removeTags: Tags to remove
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Updated snapshot
  /// - Throws: `BackupError` if update fails
  public func updateSnapshotTags(
    snapshotID: String,
    addTags: [String],
    removeTags: [String],
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupSnapshot {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["addTags"]=addTags.joined(separator: ", ")
    metadata["removeTags"]=removeTags.joined(separator: ", ")

    await logger.info("Updating snapshot tags", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to update tags
      let command=try commandFactory.createUpdateTagsCommand(
        snapshotID: snapshotID,
        addTags: addTags,
        removeTags: removeTags
      )

      // Execute command
      _=try await resticService.execute(command)

      // Get updated snapshot
      let snapshot=try await getSnapshotDetails(
        snapshotID: snapshotID,
        includeFileStatistics: false,
        progressReporter: nil,
        cancellationToken: nil
      )

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshot.id
      resultMetadata["tags"]=snapshot.tags.joined(separator: ", ")

      await logger.info(
        "Updated snapshot tags successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return snapshot
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Update snapshot tags failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Update snapshot tags failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Update snapshot tags failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Updates the description for a specific snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to update
  ///   - description: New description
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Updated snapshot
  /// - Throws: `BackupError` if update fails
  public func updateSnapshotDescription(
    snapshotID: String,
    description: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupSnapshot {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["description"]=description

    await logger.info(
      "Updating snapshot description",
      metadata: metadata,
      source: "SnapshotService"
    )

    do {
      // Create command to update description
      let command=try commandFactory.createUpdateDescriptionCommand(
        snapshotID: snapshotID,
        description: description
      )

      // Execute command
      _=try await resticService.execute(command)

      // Get updated snapshot
      let snapshot=try await getSnapshotDetails(
        snapshotID: snapshotID,
        includeFileStatistics: false,
        progressReporter: nil,
        cancellationToken: nil
      )

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshot.id
      resultMetadata["description"]=snapshot.description ?? "none"

      await logger.info(
        "Updated snapshot description successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return snapshot
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Update snapshot description failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Update snapshot description failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Update snapshot description failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Deletes a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - pruneAfterDelete: Whether to prune repository after deletion
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of deletion operation
  /// - Throws: `BackupError` if deletion fails
  public func deleteSnapshot(
    snapshotID: String,
    pruneAfterDelete: Bool,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> DeleteResult {
    let deletionTime=Date()

    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["pruneAfterDelete"]=String(pruneAfterDelete)

    await logger.info("Deleting snapshot", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to delete snapshot
      let command=try commandFactory.createDeleteCommand(
        snapshotID: snapshotID,
        pruneAfterDelete: pruneAfterDelete
      )

      // Execute command
      _=try await resticService.execute(command)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID
      resultMetadata["pruneAfterDelete"]=String(pruneAfterDelete)

      await logger.info(
        "Deleted snapshot successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      // Basic parse of delete result - for a more robust implementation, we'd
      // need to parse the JSON output to determine success/failure in detail
      return DeleteResult(
        snapshotID: snapshotID,
        deletionTime: deletionTime,
        successful: true // Assuming success if we get here (failures throw errors)
      )
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Delete snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Delete snapshot failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Delete snapshot failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Copies a snapshot to another repository
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to copy
  ///   - targetRepositoryID: ID of the target repository
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: ID of the new snapshot in the target repository
  /// - Throws: `BackupError` if copy operation fails
  public func copySnapshot(
    snapshotID: String,
    targetRepositoryID: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> String {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["targetRepositoryID"]=targetRepositoryID

    await logger.info(
      "Copying snapshot to another repository",
      metadata: metadata,
      source: "SnapshotService"
    )

    do {
      // Create command to copy snapshot
      let command=try commandFactory.createCopyCommand(
        snapshotID: snapshotID,
        targetRepositoryID: targetRepositoryID
      )

      // Execute command
      let output=try await resticService.execute(command)

      // Parse new snapshot ID
      let newSnapshotID=try resultParser.parseNewSnapshotID(output: output)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID
      resultMetadata["targetRepositoryID"]=targetRepositoryID
      resultMetadata["newSnapshotID"]=newSnapshotID

      await logger.info(
        "Copied snapshot successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return newSnapshotID
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Copy snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error("Copy snapshot failed", metadata: errorMetadata, source: "SnapshotService")

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Copy snapshot failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Finds files in a snapshot that match a pattern
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to search
  ///   - pattern: Pattern to search for
  ///   - caseSensitive: Whether the search is case-sensitive
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: List of matching files
  /// - Throws: `BackupError` if search fails
  public func findFiles(
    snapshotID: String,
    pattern: String,
    caseSensitive: Bool,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> [SnapshotFile] {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["pattern"]=pattern
    metadata["caseSensitive"]=String(caseSensitive)

    await logger.info("Finding files in snapshot", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to find files
      let command=try commandFactory.createFindCommand(
        snapshotID: snapshotID,
        pattern: pattern,
        caseSensitive: caseSensitive
      )

      // Execute command
      let output=try await resticService.execute(command)

      // Parse find result
      let files=try resultParser.parseFindResult(output: output, pattern: pattern)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID
      resultMetadata["pattern"]=pattern
      resultMetadata["matchCount"]=String(files.count)

      await logger.info(
        "Found files in snapshot",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return files
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Find files failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error("Find files failed", metadata: errorMetadata, source: "SnapshotService")

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Find files failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Locks a snapshot to prevent modification or deletion
  /// - Parameter snapshotID: Snapshot ID to lock
  /// - Parameter progressReporter: Optional reporter for tracking operation progress
  /// - Parameter cancellationToken: Optional token for cancelling the operation
  /// - Throws: `BackupError` if locking fails
  public func lockSnapshot(
    snapshotID: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID

    await logger.info("Locking snapshot", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to lock snapshot
      let command=try commandFactory.createLockCommand(snapshotID: snapshotID)

      // Execute command
      _=try await resticService.execute(command)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID

      await logger.info(
        "Locked snapshot successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Lock snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error("Lock snapshot failed", metadata: errorMetadata, source: "SnapshotService")

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Lock snapshot failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Unlocks a previously locked snapshot
  /// - Parameter snapshotID: Snapshot ID to unlock
  /// - Parameter progressReporter: Optional reporter for tracking operation progress
  /// - Parameter cancellationToken: Optional token for cancelling the operation
  /// - Throws: `BackupError` if unlocking fails
  public func unlockSnapshot(
    snapshotID: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID

    await logger.info("Unlocking snapshot", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to unlock snapshot
      let command=try commandFactory.createUnlockCommand(snapshotID: snapshotID)

      // Execute command
      _=try await resticService.execute(command)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID

      await logger.info(
        "Unlocked snapshot successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Unlock snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Unlock snapshot failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Unlock snapshot failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Verifies a snapshot's integrity
  /// - Parameter snapshotID: Snapshot ID to verify
  /// - Parameter progressReporter: Optional reporter for tracking operation progress
  /// - Parameter cancellationToken: Optional token for cancelling the operation
  /// - Returns: Verification result
  /// - Throws: `BackupError` if verification fails
  public func verifySnapshot(
    snapshotID: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> VerificationResult {
    let startTime=Date()

    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID

    await logger.info("Verifying snapshot integrity", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to verify snapshot
      let command=try commandFactory.createVerifyCommand(snapshotID: snapshotID)

      // Execute command
      let output=try await resticService.execute(command)
      let endTime=Date()

      // Parse verification result
      let result=try resultParser.parseVerificationResult(
        output: output,
        startTime: startTime,
        endTime: endTime
      )

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID
      resultMetadata["duration"]=String(format: "%.2fs", endTime.timeIntervalSince(startTime))

      await logger.info(
        "Snapshot verification completed successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return result
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Snapshot verification failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Snapshot verification failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Snapshot verification failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }
}
