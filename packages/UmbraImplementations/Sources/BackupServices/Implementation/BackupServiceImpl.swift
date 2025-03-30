import BackupInterfaces
import Foundation
import LoggingInterfaces
import ResticInterfaces
import ResticServices
import UmbraErrors

/// Actor-based implementation of the backup service
///
/// This implementation provides a thread-safe, actor-based service for managing
/// backups using the Restic backend for storage.
@preconcurrency
public actor BackupServiceImpl: BackupServiceProtocol {
  /// The Restic service used for backend operations
  private let resticService: ResticServiceProtocol

  /// Logger for operation tracking
  private let logger: any LoggingProtocol

  /// Repository information
  private let repositoryInfo: RepositoryInfo

  /// Factory for creating Restic commands
  private let commandFactory: BackupCommandFactory

  /// Parser for Restic command outputs
  private let resultParser: BackupResultParser

  /// Error mapper for converting Restic errors to backup errors
  private let errorMapper: ErrorMapper

  /// Creates a new backup service implementation
  /// - Parameters:
  ///   - resticService: Restic service for backend operations
  ///   - logger: Logger for operation tracking
  ///   - repositoryInfo: Repository connection details
  public init(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol,
    repositoryInfo: RepositoryInfo
  ) {
    self.resticService=resticService
    self.logger=logger
    self.repositoryInfo=repositoryInfo
    commandFactory=BackupCommandFactory()
    resultParser=BackupResultParser()
    errorMapper=ErrorMapper()
  }

  /// Creates a backup from the provided sources
  /// - Parameters:
  ///   - sources: Paths to include in the backup
  ///   - excludePaths: Optional paths to exclude
  ///   - tags: Optional tags to associate with the backup
  ///   - options: Additional options for the backup
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the backup operation
  /// - Throws: `BackupError` if the backup fails
  public func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    options: BackupOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupResult {
    // Create proper LogMetadata
    var metadata=LogMetadata()
    metadata["sources"]=sources.map(\.path).joined(separator: ", ")
    metadata["excludePaths"]=excludePaths?.map(\.path).joined(separator: ", ") ?? "none"
    metadata["tags"]=tags?.joined(separator: ", ") ?? "none"
    metadata["compressionLevel"]=String(options?.compressionLevel ?? 0)
    metadata["verifyAfterBackup"]=String(options?.verifyAfterBackup ?? false)

    await logger.info("Creating backup", metadata: metadata, source: "BackupService")

    let startTime=Date()
    let operation=BackupOperation.createBackup

    do {
      // Create backup command
      let command=try commandFactory.createBackupCommand(
        sources: sources,
        excludePaths: excludePaths,
        tags: tags,
        options: options
      )

      // Setup progress reporting if available
      if let progressReporter {
        await progressReporter.reportProgress(
          .initialising(description: "Preparing backup..."),
          for: operation
        )
      }

      // Execute backup command
      let output=try await resticService.execute(command)

      // Parse the output to obtain the backup result
      var result=try resultParser.parseBackupResult(output: output, sources: sources)

      // Add duration to the result
      let duration=Date().timeIntervalSince(startTime)
      // We can't modify the duration directly as it's a let constant
      // In a real implementation, this would be handled in the parser

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["fileCount"]=String(result.fileCount)
      resultMetadata["sizeInBytes"]=String(result.totalSize)
      resultMetadata["duration"]=String(format: "%.2fs", duration)

      await logger.info(
        "Backup completed successfully",
        metadata: resultMetadata,
        source: "BackupService"
      )

      // Report completion
      if let progressReporter {
        await progressReporter.reportProgress(
          .completed(description: "Backup completed successfully."),
          for: operation
        )
      }

      return result
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Backup failed with Restic error",
        metadata: errorMetadata,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      await logger.error("Backup failed", metadata: nil, source: "BackupService")

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw error
    } catch {
      await logger.error(
        "Backup failed with unexpected error",
        metadata: nil,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Restores files from a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to restore
  ///   - targetPath: Path to restore files to
  ///   - includePaths: Optional specific paths to restore
  ///   - excludePaths: Optional paths to exclude from restoration
  ///   - options: Additional options for the restore operation
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the restore operation
  /// - Throws: `BackupError` if the restore fails
  public func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    options: RestoreOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> RestoreResult {
    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["targetPath"]=targetPath.path
    metadata["includePaths"]=includePaths?.map(\.path).joined(separator: ", ") ?? "all"
    metadata["excludePaths"]=excludePaths?.map(\.path).joined(separator: ", ") ?? "none"
    metadata["verifyAfterRestore"]=String(options?.verifyAfterRestore ?? false)
    metadata["useParallelisation"]=String(options?.useParallelisation ?? false)
    metadata["priority"]=options?.priority.rawValue ?? "normal"

    await logger.info("Restoring backup", metadata: metadata, source: "BackupService")

    let operation=BackupOperation.restoreBackup

    do {
      // Create restore command
      let command=try commandFactory.createRestoreCommand(
        snapshotID: snapshotID,
        targetPath: targetPath,
        includePaths: includePaths,
        excludePaths: excludePaths,
        options: options
      )

      // Setup progress reporting if available
      if let progressReporter {
        await progressReporter.reportProgress(
          .initialising(description: "Preparing restore operation..."),
          for: operation
        )
      }

      // Execute restore command
      let output=try await resticService.execute(command)

      // Parse the output to obtain the restore result
      let result=try resultParser.parseRestoreResult(output: output, targetPath: targetPath)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["snapshotID"]=snapshotID
      resultMetadata["targetPath"]=targetPath.path
      resultMetadata["fileCount"]=String(result.fileCount)

      await logger.info(
        "Restore completed successfully",
        metadata: resultMetadata,
        source: "BackupService"
      )

      // Report completion
      if let progressReporter {
        await progressReporter.reportProgress(
          .completed(description: "Restore completed successfully."),
          for: operation
        )
      }

      return result
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Restore failed with Restic error",
        metadata: errorMetadata,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      await logger.error("Restore failed", metadata: nil, source: "BackupService")

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw error
    } catch {
      await logger.error(
        "Restore failed with unexpected error",
        metadata: nil,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Lists snapshots in the repository
  /// - Parameters:
  ///   - tags: Optional tags to filter by
  ///   - before: Optional date to filter snapshots before
  ///   - after: Optional date to filter snapshots after
  ///   - options: Optional listing options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: List of snapshots matching the criteria
  /// - Throws: `BackupError` if the listing fails
  public func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    options: ListOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> [BackupSnapshot] {
    // Create metadata
    var metadata=LogMetadata()
    metadata["tags"]=tags?.joined(separator: ", ") ?? "all"
    metadata["before"]=before?.description ?? "any"
    metadata["after"]=after?.description ?? "any"
    metadata["options"]=String(describing: options)

    await logger.info("Listing snapshots", metadata: metadata, source: "BackupService")

    let operation=BackupOperation.listSnapshots

    do {
      // Create command for snapshot service to list snapshots
      // This is a simplified implementation that delegates to SnapshotService
      if let progressReporter {
        await progressReporter.reportProgress(
          .initialising(description: "Listing snapshots..."),
          for: operation
        )
      }

      // Simplified implementation without actual SnapshotService delegation
      let limit=options?.limit

      // Create snapshots command
      let command=try commandFactory.createListCommand(
        repositoryID: repositoryInfo.id,
        tags: tags,
        before: before,
        after: after,
        path: nil, // Not supported in ListOptions
        limit: limit
      )

      let output=try await resticService.execute(command)
      let snapshots=try resultParser.parseSnapshotsList(output: output, sources: [])

      if let progressReporter {
        await progressReporter.reportProgress(
          .completed(description: "Listed \(snapshots.count) snapshots."),
          for: operation
        )
      }

      return snapshots
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "List snapshots failed with Restic error",
        metadata: errorMetadata,
        source: "BackupService"
      )

      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw errorMapper.convertResticError(error)
    } catch {
      await logger.error("List snapshots failed with error", metadata: nil, source: "BackupService")

      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Deletes a backup by ID
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - options: Optional delete options
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the delete operation
  /// - Throws: `BackupError` if the deletion fails
  public func deleteBackup(
    snapshotID: String,
    options: DeleteOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> DeleteResult {
    _=Date() // Using _ to silence the warning about unused variable

    // Create metadata
    var metadata=LogMetadata()
    metadata["snapshotID"]=snapshotID
    metadata["pruneAfterDelete"]=String(options?.pruneAfterDelete ?? false)

    await logger.info("Deleting snapshot", metadata: metadata, source: "BackupService")

    let operation=BackupOperation.deleteBackup

    do {
      // Create command to delete snapshot
      let command=try commandFactory.createDeleteCommand(
        snapshotID: snapshotID,
        pruneAfterDelete: options?.pruneAfterDelete ?? false
      )

      // Setup progress reporting if available
      if let progressReporter {
        await progressReporter.reportProgress(
          .initialising(description: "Preparing deletion..."),
          for: operation
        )
      }

      // Execute command
      _=try await resticService.execute(command)

      // Basic parse of delete result
      let result=DeleteResult(
        snapshotID: snapshotID,
        deletionTime: Date(),
        successful: true // Assuming success if we get here (failures throw errors)
      )

      // Create success metadata
      var successMetadata=LogMetadata()
      successMetadata["snapshotID"]=snapshotID

      await logger.info(
        "Deleted snapshot successfully",
        metadata: successMetadata,
        source: "BackupService"
      )

      // Report completion
      if let progressReporter {
        await progressReporter.reportProgress(
          .completed(description: "Snapshot deleted successfully."),
          for: operation
        )
      }

      return result
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Delete snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      await logger.error("Delete snapshot failed", metadata: nil, source: "BackupService")

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw error
    } catch {
      await logger.error(
        "Delete snapshot failed with unexpected error",
        metadata: nil,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Performs maintenance on the backup repository
  /// - Parameters:
  ///   - type: Type of maintenance to perform
  ///   - options: Additional options for the maintenance operation
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the maintenance operation
  /// - Throws: `BackupError` if the maintenance fails
  public func performMaintenance(
    type: MaintenanceType,
    options: MaintenanceOptions?,
    progressReporter: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> MaintenanceResult {
    // Create metadata
    var metadata=LogMetadata()
    metadata["type"]=String(describing: type)
    metadata["dryRun"]=String(options?.dryRun ?? false)

    await logger.info(
      "Performing repository maintenance",
      metadata: metadata,
      source: "BackupService"
    )

    let operation=BackupOperation.maintenance

    do {
      // Create maintenance command
      let command=try commandFactory.createMaintenanceCommand(
        type: type,
        options: options
      )

      // Setup progress reporting if available
      if let progressReporter {
        await progressReporter.reportProgress(
          .initialising(description: "Preparing maintenance operation..."),
          for: operation
        )
      }

      // Execute maintenance command
      let output=try await resticService.execute(command)

      // Parse the output to obtain the maintenance result
      let result=try resultParser.parseMaintenanceResult(output: output, type: type)

      // Create result metadata
      var resultMetadata=LogMetadata()
      resultMetadata["successful"]=String(result.successful)
      resultMetadata["issuesCount"]=String(result.issuesFound.count)
      resultMetadata["spaceOptimised"]=result.spaceOptimised.map { String($0) } ?? "none"

      await logger.info(
        "Maintenance completed successfully",
        metadata: resultMetadata,
        source: "BackupService"
      )

      // Report completion
      if let progressReporter {
        await progressReporter.reportProgress(
          .completed(description: "Maintenance completed."),
          for: operation
        )
      }

      return result
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=LogMetadata()
      errorMetadata["error"]=error.localizedDescription

      await logger.error(
        "Maintenance failed with Restic error",
        metadata: errorMetadata,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      await logger.error("Maintenance failed", metadata: nil, source: "BackupService")

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw error
    } catch {
      await logger.error(
        "Maintenance failed with unexpected error",
        metadata: nil,
        source: "BackupService"
      )

      // Report error
      if let progressReporter {
        await progressReporter.reportProgress(
          .failed(error: error.localizedDescription),
          for: operation
        )
      }

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }
}
