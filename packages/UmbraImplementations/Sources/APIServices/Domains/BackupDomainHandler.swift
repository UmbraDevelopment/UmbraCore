import APIInterfaces
import BackupInterfaces
import Foundation
import UmbraErrors

/**
 # Backup Domain Handler

 Handles backup and snapshot-related API operations by delegating to the underlying
 backup service. This handler follows the Alpha Dot Five architecture
 with proper thread safety and structured error handling.

 ## Operation Processing

 Each backup operation is processed by mapping it to the appropriate
 backup service methods, with proper error handling and result conversion.
 */
public struct BackupDomainHandler: DomainHandler {
  /// The backup service for performing operations
  private let service: BackupServiceProtocol

  /**
   Initialises a new backup domain handler.

   - Parameter service: The backup service
   */
  public init(service: BackupServiceProtocol) {
    self.service=service
  }

  /**
   Executes a backup operation and returns the result.

   - Parameter operation: The operation to execute

   - Returns: The result of the operation
   - Throws: Error if the operation fails
   */
  public func execute<T: APIOperation>(_ operation: T) async throws -> Any {
    // Handle specific backup operations
    if let op=operation as? ListSnapshotsOperation {
      return try await handleListSnapshots(op)
    } else if let op=operation as? GetSnapshotOperation {
      return try await handleGetSnapshot(op)
    } else if let op=operation as? CreateSnapshotOperation {
      return try await handleCreateSnapshot(op)
    } else if let op=operation as? UpdateSnapshotOperation {
      return try await handleUpdateSnapshot(op)
    } else if let op=operation as? DeleteSnapshotOperation {
      return try await handleDeleteSnapshot(op)
    } else if let op=operation as? RestoreSnapshotOperation {
      return try await handleRestoreSnapshot(op)
    }

    // Unsupported operation
    throw APIError
      .operationNotSupported("Unsupported backup operation: \(String(describing: T.self))")
  }

  /**
   Checks if this handler supports the given operation.

   - Parameter operation: The operation to check

   - Returns: True if the operation is supported, false otherwise
   */
  public func supports(_ operation: some APIOperation) -> Bool {
    operation is BackupAPIOperation
  }

  // MARK: - Operation Handlers

  /**
   Handles the list snapshots operation.

   - Parameter operation: The operation to handle

   - Returns: Array of snapshot information
   - Throws: Error if the operation fails
   */
  private func handleListSnapshots(_ operation: ListSnapshotsOperation) async throws
  -> [SnapshotInfo] {
    // Create filter options from the operation parameters
    let filterOptions=SnapshotFilterOptions(
      tags: operation.tagFilter,
      pathFilter: operation.pathFilter,
      beforeDate: operation.beforeDate,
      afterDate: operation.afterDate,
      limit: operation.limit
    )

    // Get snapshots from the service
    let snapshots=try await service.listSnapshots(
      forRepositoryID: operation.repositoryID,
      filterOptions: filterOptions
    )

    // Convert to API models
    return snapshots.map { snapshot in
      SnapshotInfo(
        id: snapshot.id,
        repositoryID: snapshot.repositoryID,
        createdAt: snapshot.creationDate,
        tags: snapshot.tags,
        summary: snapshot.summary
      )
    }
  }

  /**
   Handles the get snapshot operation.

   - Parameter operation: The operation to handle

   - Returns: Snapshot details
   - Throws: Error if the operation fails
   */
  private func handleGetSnapshot(_ operation: GetSnapshotOperation) async throws
  -> SnapshotDetails {
    // Get snapshot from the service
    let snapshot=try await service.getSnapshot(
      withID: operation.snapshotID,
      inRepositoryWithID: operation.repositoryID
    )

    // Get snapshot statistics
    let stats=try await service.getSnapshotStatistics(
      forSnapshotID: operation.snapshotID,
      inRepositoryWithID: operation.repositoryID
    )

    // Get file listings if requested
    let files: [SnapshotFileInfo]?
    if operation.includeFiles {
      let fileListings=try await service.listSnapshotFiles(
        forSnapshotID: operation.snapshotID,
        inRepositoryWithID: operation.repositoryID
      )

      files=fileListings.map { file in
        SnapshotFileInfo(
          path: file.path,
          sizeBytes: file.sizeBytes,
          modifiedAt: file.modificationDate
        )
      }
    } else {
      files=nil
    }

    // Convert to API model
    let info=SnapshotInfo(
      id: snapshot.id,
      repositoryID: snapshot.repositoryID,
      createdAt: snapshot.creationDate,
      tags: snapshot.tags,
      summary: snapshot.summary
    )

    return SnapshotDetails(
      info: info,
      totalSizeBytes: stats.totalSizeBytes,
      fileCount: stats.fileCount,
      files: files
    )
  }

  /**
   Handles the create snapshot operation.

   - Parameter operation: The operation to handle

   - Returns: Snapshot information
   - Throws: Error if the operation fails
   */
  private func handleCreateSnapshot(_ operation: CreateSnapshotOperation) async throws
  -> SnapshotInfo {
    // Create options for the snapshot
    let options=SnapshotCreationOptions(
      includePaths: operation.parameters.includePaths,
      excludePaths: operation.parameters.excludePaths,
      tags: operation.parameters.tags,
      useCompression: operation.parameters.useCompression
    )

    // Create the snapshot
    let snapshot=try await service.createSnapshot(
      inRepositoryWithID: operation.repositoryID,
      options: options
    )

    // Convert to API model
    return SnapshotInfo(
      id: snapshot.id,
      repositoryID: snapshot.repositoryID,
      createdAt: snapshot.creationDate,
      tags: snapshot.tags,
      summary: snapshot.summary
    )
  }

  /**
   Handles the update snapshot operation.

   - Parameter operation: The operation to handle

   - Returns: Updated snapshot information
   - Throws: Error if the operation fails
   */
  private func handleUpdateSnapshot(_ operation: UpdateSnapshotOperation) async throws
  -> SnapshotInfo {
    // Create options for the update
    let options=SnapshotUpdateOptions(
      tags: operation.parameters.tags
    )

    // Update the snapshot
    let snapshot=try await service.updateSnapshot(
      withID: operation.snapshotID,
      inRepositoryWithID: operation.repositoryID,
      options: options
    )

    // Convert to API model
    return SnapshotInfo(
      id: snapshot.id,
      repositoryID: snapshot.repositoryID,
      createdAt: snapshot.creationDate,
      tags: snapshot.tags,
      summary: snapshot.summary
    )
  }

  /**
   Handles the delete snapshot operation.

   - Parameter operation: The operation to handle

   - Throws: Error if the operation fails
   */
  private func handleDeleteSnapshot(_ operation: DeleteSnapshotOperation) async throws {
    try await service.deleteSnapshot(
      withID: operation.snapshotID,
      inRepositoryWithID: operation.repositoryID
    )
  }

  /**
   Handles the restore snapshot operation.

   - Parameter operation: The operation to handle

   - Returns: Restore result
   - Throws: Error if the operation fails
   */
  private func handleRestoreSnapshot(_ operation: RestoreSnapshotOperation) async throws
  -> RestoreResult {
    // Create options for the restore
    let options=RestoreOptions(
      paths: operation.parameters.paths,
      targetDirectory: operation.parameters.targetDirectory,
      overwriteExisting: operation.parameters.overwriteExisting
    )

    // Perform the restore
    let result=try await service.restoreFromSnapshot(
      withID: operation.snapshotID,
      inRepositoryWithID: operation.repositoryID,
      options: options
    )

    // Convert to API model
    return RestoreResult(
      filesRestored: result.filesRestored,
      totalSizeBytes: result.totalSizeBytes,
      failedPaths: result.failedPaths
    )
  }
}
