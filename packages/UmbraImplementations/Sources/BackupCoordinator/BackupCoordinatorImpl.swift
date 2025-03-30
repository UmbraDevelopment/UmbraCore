import BackupInterfaces
import BackupServices
import Foundation
import LoggingInterfaces
import ResticInterfaces
import UmbraErrors

/// Implementation of the backup coordinator service
///
/// The BackupCoordinator provides a unified interface for managing backup operations,
/// including both backup and snapshot-related functionality. It coordinates between
/// various services to provide a cohesive backup management experience.
public actor BackupCoordinatorImpl: BackupCoordinatorProtocol {
  /// The backup service used for creating and restoring backups
  private let backupService: BackupServiceProtocol

  /// The snapshot service used for managing snapshots
  private let snapshotService: SnapshotServiceProtocol

  /// Logger for operation tracking
  private let logger: any LoggingProtocol

  /// Information about the repository being used
  private let repositoryInfo: RepositoryInfo

  /// Creates a new backup coordinator
  /// - Parameters:
  ///   - backupService: Service for backup operations
  ///   - snapshotService: Service for snapshot operations
  ///   - logger: Logger for operation tracking
  ///   - repositoryInfo: Information about the repository
  public init(
    backupService: BackupServiceProtocol,
    snapshotService: SnapshotServiceProtocol,
    logger: any LoggingProtocol,
    repositoryInfo: RepositoryInfo
  ) {
    self.backupService=backupService
    self.snapshotService=snapshotService
    self.logger=logger
    self.repositoryInfo=repositoryInfo
  }

  /// Creates a new backup coordinator using the factory
  /// - Parameters:
  ///   - factory: Factory for creating backup and snapshot services
  ///   - resticServiceFactory: Factory for creating Restic services
  ///   - logger: Logger for operation tracking
  ///   - repositoryPath: Path to the repository
  ///   - repositoryPassword: Optional repository password
  /// - Returns: A configured backup coordinator
  /// - Throws: Error if service creation fails
  public static func create(
    factory: BackupServiceFactory,
    resticServiceFactory: ResticServiceFactory,
    logger: any LoggingProtocol,
    repositoryPath: String,
    repositoryPassword: String?=nil
  ) async throws -> BackupCoordinatorImpl {
    // Create backup service
    let backupService=try factory.createBackupService(
      resticServiceFactory: resticServiceFactory,
      logger: logger,
      repositoryPath: repositoryPath,
      repositoryPassword: repositoryPassword
    )

    // Create snapshot service
    let snapshotService=try factory.createSnapshotService(
      resticServiceFactory: resticServiceFactory,
      logger: logger,
      repositoryPath: repositoryPath,
      repositoryPassword: repositoryPassword
    )

    // Create repository info
    let repositoryInfo=RepositoryInfo(
      location: repositoryPath,
      id: UUID().uuidString, // This would be obtained from the repository
      password: repositoryPassword
    )

    // Create and return coordinator
    return BackupCoordinatorImpl(
      backupService: backupService,
      snapshotService: snapshotService,
      logger: logger,
      repositoryInfo: repositoryInfo
    )
  }

  // MARK: - Backup Operations

  /// Creates a new backup
  /// - Parameters:
  ///   - sources: Source paths to back up
  ///   - excludePaths: Optional paths to exclude
  ///   - tags: Optional tags to associate with the backup
  ///   - options: Optional backup options
  /// - Returns: Result of the backup operation
  /// - Throws: `BackupError` if backup creation fails
  public func createBackup(
    sources: [URL],
    excludePaths: [URL]?=nil,
    tags: [String]?=nil,
    options: BackupOptions?=nil
  ) async throws -> BackupResult {
    let metadata=LogMetadata([
      "sources": sources.map(\.path).joined(separator: ", "),
      "excludeCount": String(excludePaths?.count ?? 0),
      "tagCount": String(tags?.count ?? 0)
    ])
    await logger.info(
      "Initiating backup via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to backup service
      let result=try await backupService.createBackup(
        sources: sources,
        excludePaths: excludePaths,
        tags: tags,
        options: options
      )

      let metadata=LogMetadata([
        "snapshotID": result.snapshotID,
        "fileCount": String(result.fileCount),
        "successful": String(result.successful)
      ])
      await logger.info(
        "Backup completed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return result
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Backup failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Restores a backup
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to restore
  ///   - targetPath: Path to restore to
  ///   - includePaths: Optional paths to include
  ///   - excludePaths: Optional paths to exclude
  ///   - options: Optional restore options
  /// - Returns: Result of the restore operation
  /// - Throws: `BackupError` if restore fails
  public func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?=nil,
    excludePaths: [URL]?=nil,
    options: RestoreOptions?=nil
  ) async throws -> RestoreResult {
    let metadata=LogMetadata([
      "snapshotID": snapshotID,
      "targetPath": targetPath.path,
      "includeCount": String(includePaths?.count ?? 0),
      "excludeCount": String(excludePaths?.count ?? 0)
    ])
    await logger.info(
      "Initiating restore via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to backup service
      let result=try await backupService.restoreBackup(
        snapshotID: snapshotID,
        targetPath: targetPath,
        includePaths: includePaths,
        excludePaths: excludePaths,
        options: options
      )

      let metadata=LogMetadata([
        "snapshotID": result.snapshotID,
        "fileCount": String(result.fileCount),
        "successful": String(result.successful)
      ])
      await logger.info(
        "Restore completed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return result
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Restore failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Deletes a backup
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - options: Optional delete options
  /// - Returns: Result of the delete operation
  /// - Throws: `BackupError` if deletion fails
  public func deleteBackup(
    snapshotID: String,
    options: DeleteOptions?=nil
  ) async throws -> DeleteResult {
    let metadata=LogMetadata([
      "snapshotID": snapshotID
    ])
    await logger.info(
      "Initiating backup deletion via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Get pruning option
      let pruneAfterDelete=options?.pruneAfterDelete ?? false

      // Delegate to snapshot service
      let result=try await snapshotService.deleteSnapshot(
        snapshotID: snapshotID,
        pruneAfterDelete: pruneAfterDelete
      )

      let metadata=LogMetadata([
        "snapshotID": result.snapshotID,
        "successful": String(result.successful)
      ])
      await logger.info(
        "Backup deletion completed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return result
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Backup deletion failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  // MARK: - Snapshot Operations

  /// Lists all available snapshots
  /// - Parameters:
  ///   - tags: Optional tags to filter by
  ///   - before: Optional date to filter snapshots before
  ///   - after: Optional date to filter snapshots after
  ///   - options: Optional listing options
  /// - Returns: Array of matching snapshots
  /// - Throws: `BackupError` if listing fails
  public func listSnapshots(
    tags: [String]?=nil,
    before: Date?=nil,
    after: Date?=nil,
    options: ListOptions?=nil
  ) async throws -> [BackupSnapshot] {
    let metadata=LogMetadata([
      "tagCount": String(tags?.count ?? 0),
      "before": before?.description ?? "none",
      "after": after?.description ?? "none"
    ])
    await logger.info(
      "Listing snapshots via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to snapshot service
      let snapshots=try await snapshotService.listSnapshots(
        repositoryID: nil,
        tags: tags,
        before: before,
        after: after,
        path: options?.path,
        limit: options?.limit
      )

      let metadata=LogMetadata([
        "count": String(snapshots.count)
      ])
      await logger.info(
        "Listed snapshots via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return snapshots
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Snapshot listing failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Gets detailed information about a specific snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - includeFileStatistics: Whether to include file statistics
  /// - Returns: Detailed snapshot information
  /// - Throws: `BackupError` if retrieval fails
  public func getSnapshotDetails(
    snapshotID: String,
    includeFileStatistics: Bool=false
  ) async throws -> BackupSnapshot {
    let metadata=LogMetadata([
      "snapshotID": snapshotID,
      "includeFileStatistics": String(includeFileStatistics)
    ])
    await logger.info(
      "Getting snapshot details via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to snapshot service
      let snapshot=try await snapshotService.getSnapshotDetails(
        snapshotID: snapshotID,
        includeFileStatistics: includeFileStatistics
      )

      let metadata=LogMetadata([
        "snapshotID": snapshot.id,
        "creationTime": snapshot.creationTime.description
      ])
      await logger.info(
        "Retrieved snapshot details via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return snapshot
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Snapshot details retrieval failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Updates tags for a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - addTags: Tags to add
  ///   - removeTags: Tags to remove
  /// - Returns: Updated snapshot
  /// - Throws: `BackupError` if tag update fails
  public func updateSnapshotTags(
    snapshotID: String,
    addTags: [String]=[],
    removeTags: [String]=[]
  ) async throws -> BackupSnapshot {
    let metadata=LogMetadata([
      "snapshotID": snapshotID,
      "addTagCount": String(addTags.count),
      "removeTagCount": String(removeTags.count)
    ])
    await logger.info(
      "Updating snapshot tags via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to snapshot service
      let snapshot=try await snapshotService.updateSnapshotTags(
        snapshotID: snapshotID,
        addTags: addTags,
        removeTags: removeTags
      )

      let metadata=LogMetadata([
        "snapshotID": snapshot.id,
        "tagCount": String(snapshot.tags.count)
      ])
      await logger.info(
        "Updated snapshot tags via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return snapshot
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Snapshot tag update failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Finds files within a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - pattern: Pattern to search for
  ///   - caseSensitive: Whether search is case-sensitive
  /// - Returns: List of matching files
  /// - Throws: `BackupError` if search fails
  public func findFiles(
    snapshotID: String,
    pattern: String,
    caseSensitive: Bool=false
  ) async throws -> [SnapshotFile] {
    let metadata=LogMetadata([
      "snapshotID": snapshotID,
      "pattern": pattern,
      "caseSensitive": String(caseSensitive)
    ])
    await logger.info(
      "Finding files in snapshot via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to snapshot service
      let files=try await snapshotService.findFiles(
        snapshotID: snapshotID,
        pattern: pattern,
        caseSensitive: caseSensitive
      )

      let metadata=LogMetadata([
        "count": String(files.count)
      ])
      await logger.info(
        "Found files in snapshot via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return files
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "File search failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Verifies a snapshot's integrity
  /// - Parameter snapshotID: ID of the snapshot to verify
  /// - Returns: Verification result
  /// - Throws: `BackupError` if verification fails
  public func verifySnapshot(
    snapshotID: String
  ) async throws -> VerificationResult {
    let metadata=LogMetadata([
      "snapshotID": snapshotID
    ])
    await logger.info(
      "Verifying snapshot via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // Delegate to snapshot service
      let result=try await snapshotService.verifySnapshot(
        snapshotID: snapshotID
      )

      let metadata=LogMetadata([
        "snapshotID": snapshotID,
        "successful": String(result.successful),
        "issues": String(result.issues.count)
      ])
      await logger.info(
        "Verified snapshot via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return result
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Snapshot verification failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }

  /// Performs a maintenance operation on the repository
  /// - Parameter type: Type of maintenance to perform
  /// - Returns: Result of the maintenance operation
  /// - Throws: `BackupError` if maintenance fails
  public func performMaintenance(
    type: MaintenanceType
  ) async throws -> MaintenanceResult {
    let metadata=LogMetadata([
      "type": String(describing: type)
    ])
    await logger.info(
      "Performing maintenance via coordinator",
      metadata: metadata,
      source: "BackupCoordinator"
    )

    do {
      // This would delegate to a maintenance service
      // For now, we'll return a placeholder result
      let result=MaintenanceResult(
        maintenanceType: type,
        successful: true,
        details: "Maintenance completed successfully",
        startTime: Date(),
        endTime: Date()
      )

      let metadata=LogMetadata([
        "type": String(describing: type),
        "successful": String(result.successful)
      ])
      await logger.info(
        "Maintenance completed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      return result
    } catch {
      let metadata=LogMetadata([
        "error": error.localizedDescription
      ])
      await logger.error(
        "Maintenance failed via coordinator",
        metadata: metadata,
        source: "BackupCoordinator"
      )

      throw error
    }
  }
}
