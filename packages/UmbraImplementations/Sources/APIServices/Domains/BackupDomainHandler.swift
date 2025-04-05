import APIInterfaces
import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import RepositoryInterfaces
import UmbraErrors

/**
 # Backup Domain Handler

 Handles backup-related API operations within the Alpha Dot Five architecture.
 This implementation provides operations for snapshot management, including
 creation, retrieval, updates, and deletion with proper privacy controls.

 ## Privacy-Enhanced Logging

 All operations are logged with appropriate privacy classifications to
 ensure sensitive data is properly protected.

 ## Thread Safety

 Operations use proper isolation and async/await patterns to ensure
 thread safety throughout the handler.
 */
public struct BackupDomainHandler: DomainHandler {
  /// Backup service for snapshot operations
  private let backupService: BackupServiceProtocol

  /// Repository service for repository validation
  private let repositoryService: RepositoryServiceProtocol?

  /// Logger with privacy controls
  private let logger: LoggingProtocol?

  /**
   Initialises a new backup domain handler.

   - Parameters:
      - service: The backup service implementation
      - repositoryService: Optional repository service for validation
      - logger: Optional logger for privacy-aware operation recording
   */
  public init(
    service: BackupServiceProtocol,
    repositoryService: RepositoryServiceProtocol?=nil,
    logger: LoggingProtocol?=nil
  ) {
    backupService=service
    self.repositoryService=repositoryService
    self.logger=logger
  }

  /**
   Executes a backup operation and returns its result.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails
   */
  public func execute(_ operation: some APIOperation) async throws -> Any {
    // Log the operation start with privacy-aware metadata
    let operationName=String(describing: type(of: operation))
    let startMetadata=PrivacyMetadata([
      "operation": .public(operationName),
      "event": .public("start")
    ])

    await logger?.info(
      "Starting backup operation",
      metadata: startMetadata,
      source: "BackupDomainHandler"
    )

    do {
      // Execute the appropriate operation based on type
      let result=try await executeBackupOperation(operation)

      // Log success
      let successMetadata=PrivacyMetadata([
        "operation": .public(operationName),
        "event": .public("success"),
        "status": .public("completed")
      ])

      await logger?.info(
        "Backup operation completed successfully",
        metadata: successMetadata,
        source: "BackupDomainHandler"
      )

      return result
    } catch {
      // Log failure with privacy-aware error details
      let errorMetadata=PrivacyMetadata([
        "operation": .public(operationName),
        "event": .public("failure"),
        "status": .public("failed"),
        "error": .private(error.localizedDescription)
      ])

      await logger?.error(
        "Backup operation failed",
        metadata: errorMetadata,
        source: "BackupDomainHandler"
      )

      // Map to appropriate API error and rethrow
      throw mapToAPIError(error)
    }
  }

  /**
   Determines if this handler supports the given operation.

   - Parameter operation: The operation to check support for
   - Returns: true if the operation is supported, false otherwise
   */
  public func supports(_ operation: some APIOperation) -> Bool {
    operation is any BackupAPIOperation
  }

  // MARK: - Private Helper Methods

  /**
   Routes the operation to the appropriate handler method based on its type.

   - Parameter operation: The operation to execute
   - Returns: The result of the operation
   - Throws: APIError if the operation fails or is unsupported
   */
  private func executeBackupOperation(_ operation: some APIOperation) async throws -> Any {
    switch operation {
      case let op as ListSnapshotsOperation:
        return try await handleListSnapshots(op)
      case let op as GetSnapshotOperation:
        return try await handleGetSnapshot(op)
      case let op as CreateSnapshotOperation:
        return try await handleCreateSnapshot(op)
      case let op as UpdateSnapshotOperation:
        return try await handleUpdateSnapshot(op)
      case let op as DeleteSnapshotOperation:
        return try await handleDeleteSnapshot(op)
      case let op as RestoreSnapshotOperation:
        return try await handleRestoreSnapshot(op)
      case let op as ForgetSnapshotOperation:
        return try await handleForgetSnapshot(op)
      default:
        throw APIError.operationNotSupported(
          message: "Unsupported backup operation: \(type(of: operation))",
          code: "BACKUP_OPERATION_NOT_SUPPORTED"
        )
    }
  }

  /**
   Maps domain-specific errors to standardised API errors.

   - Parameter error: The original error
   - Returns: An APIError instance
   */
  private func mapToAPIError(_ error: Error) -> APIError {
    // If it's already an APIError, return it
    if let apiError=error as? APIError {
      return apiError
    }

    // Handle specific backup error types
    if let backupError=error as? BackupError {
      switch backupError {
        case let .snapshotNotFound(id):
          return APIError.resourceNotFound(
            message: "Snapshot not found: \(id)",
            code: "SNAPSHOT_NOT_FOUND"
          )
        case let .repositoryNotFound(id):
          return APIError.resourceNotFound(
            message: "Repository not found: \(id)",
            code: "REPOSITORY_NOT_FOUND"
          )
        case let .backupFailed(message):
          return APIError.operationFailed(
            message: message,
            code: "BACKUP_FAILED",
            underlyingError: backupError
          )
        case let .pathNotFound(path):
          return APIError.resourceNotFound(
            message: "Backup path not found: \(path)",
            code: "BACKUP_PATH_NOT_FOUND"
          )
        case let .permissionDenied(message):
          return APIError.permissionDenied(
            message: message,
            code: "BACKUP_PERMISSION_DENIED"
          )
        case let .invalidOperation(message):
          return APIError.validationFailed(
            message: message,
            code: "INVALID_BACKUP_OPERATION"
          )
      }
    }

    // Default to a generic operation failed error
    return APIError.operationFailed(
      message: "Backup operation failed: \(error.localizedDescription)",
      code: "BACKUP_OPERATION_FAILED",
      underlyingError: error
    )
  }

  // MARK: - Operation Handlers

  /**
   Handles the list snapshots operation.

   - Parameter operation: The operation to execute
   - Returns: Array of snapshot information
   - Throws: APIError if the operation fails
   */
  private func handleListSnapshots(_ operation: ListSnapshotsOperation) async throws
  -> [SnapshotInfo] {
    // Create privacy-aware logging metadata
    var metadata=PrivacyMetadata([
      "operation": .public("listSnapshots"),
      "repository_id": .public(operation.repositoryID)
    ])

    if let tagFilter=operation.tagFilter, !tagFilter.isEmpty {
      metadata["tag_filter"] = .public(tagFilter.joined(separator: ", "))
    }

    if let pathFilter=operation.pathFilter {
      metadata["path_filter"] = .private(pathFilter)
    }

    if let beforeDate=operation.beforeDate {
      metadata["before_date"] = .public(beforeDate)
    }

    if let afterDate=operation.afterDate {
      metadata["after_date"] = .public(afterDate)
    }

    if let limit=operation.limit {
      metadata["limit"] = .public(String(limit))
    }

    await logger?.info(
      "Listing snapshots",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Get snapshots with filtering
    let filters=SnapshotFilters(
      tags: operation.tagFilter ?? [],
      path: operation.pathFilter,
      beforeDate: operation.beforeDate.flatMap { ISO8601DateFormatter().date(from: $0) },
      afterDate: operation.afterDate.flatMap { ISO8601DateFormatter().date(from: $0) },
      limit: operation.limit
    )

    let snapshots=try await backupService.listSnapshots(
      forRepository: operation.repositoryID,
      filters: filters
    )

    // Convert to API model
    let snapshotInfos=snapshots.map { snapshot in
      SnapshotInfo(
        id: snapshot.id,
        repositoryID: operation.repositoryID,
        timestamp: snapshot.timestamp,
        tags: snapshot.tags,
        summary: SnapshotSummary(
          fileCount: snapshot.fileCount,
          totalSize: snapshot.size,
          rootPaths: snapshot.rootPaths
        )
      )
    }

    // Log the result count
    let resultMetadata=metadata.merging(PrivacyMetadata([
      "count": .public(String(snapshotInfos.count))
    ]))

    await logger?.info(
      "Found snapshots",
      metadata: resultMetadata,
      source: "BackupDomainHandler"
    )

    return snapshotInfos
  }

  /**
   Handles the get snapshot operation.

   - Parameter operation: The operation to execute
   - Returns: Detailed snapshot information
   - Throws: APIError if the operation fails
   */
  private func handleGetSnapshot(_ operation: GetSnapshotOperation) async throws
  -> SnapshotDetails {
    // Create privacy-aware logging metadata
    let metadata=PrivacyMetadata([
      "operation": .public("getSnapshot"),
      "repository_id": .public(operation.repositoryID),
      "snapshot_id": .public(operation.snapshotID),
      "include_files": .public(operation.includeFiles.description)
    ])

    await logger?.info(
      "Retrieving snapshot details",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Get snapshot details
    let snapshot=try await backupService.getSnapshot(
      id: operation.snapshotID,
      forRepository: operation.repositoryID
    )

    // Get file listing if requested
    var fileEntries: [FileEntry]=[]
    if operation.includeFiles {
      fileEntries=try await backupService.getSnapshotFiles(
        snapshotID: operation.snapshotID,
        repositoryID: operation.repositoryID
      )
    }

    // Create basic info
    let basicInfo=SnapshotInfo(
      id: snapshot.id,
      repositoryID: operation.repositoryID,
      timestamp: snapshot.timestamp,
      tags: snapshot.tags,
      summary: SnapshotSummary(
        fileCount: snapshot.fileCount,
        totalSize: snapshot.size,
        rootPaths: snapshot.rootPaths
      )
    )

    // Create details
    let details=SnapshotDetails(
      basicInfo: basicInfo,
      creationHostname: snapshot.hostname,
      backupDuration: snapshot.duration,
      fileEntries: fileEntries,
      metadata: snapshot.metadata
    )

    await logger?.info(
      "Snapshot details retrieved",
      metadata: metadata.merging(PrivacyMetadata([
        "status": .public("success"),
        "file_count": .public(operation.includeFiles ? String(fileEntries.count) : "0")
      ])),
      source: "BackupDomainHandler"
    )

    return details
  }

  /**
   Handles the create snapshot operation.

   - Parameter operation: The operation to execute
   - Returns: Information about the created snapshot
   - Throws: APIError if the operation fails
   */
  private func handleCreateSnapshot(_ operation: CreateSnapshotOperation) async throws
  -> SnapshotInfo {
    // Create privacy-aware logging metadata
    var metadata=PrivacyMetadata([
      "operation": .public("createSnapshot"),
      "repository_id": .public(operation.repositoryID)
    ])

    if !operation.parameters.tags.isEmpty {
      metadata["tags"] = .public(operation.parameters.tags.joined(separator: ", "))
    }

    if !operation.parameters.paths.isEmpty {
      metadata["path_count"] = .public(String(operation.parameters.paths.count))
      // Keep actual paths private
      metadata["paths"] = .private(operation.parameters.paths.joined(separator: ", "))
    }

    await logger?.info(
      "Creating new snapshot",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Create the snapshot parameters
    let backupParams=SnapshotCreationConfig(
      paths: operation.parameters.paths,
      tags: operation.parameters.tags,
      excludePaths: operation.parameters.excludePaths,
      excludePatterns: operation.parameters.excludePatterns,
      hostName: operation.parameters.hostName,
      metadata: operation.parameters.metadata ?? [:]
    )

    // Create the snapshot
    let createdSnapshot=try await backupService.createSnapshot(
      forRepository: operation.repositoryID,
      config: backupParams
    )

    // Convert to API model
    let snapshotInfo=SnapshotInfo(
      id: createdSnapshot.id,
      repositoryID: operation.repositoryID,
      timestamp: createdSnapshot.timestamp,
      tags: createdSnapshot.tags,
      summary: SnapshotSummary(
        fileCount: createdSnapshot.fileCount,
        totalSize: createdSnapshot.size,
        rootPaths: createdSnapshot.rootPaths
      )
    )

    await logger?.info(
      "Snapshot created successfully",
      metadata: metadata.merging(PrivacyMetadata([
        "snapshot_id": .public(createdSnapshot.id),
        "file_count": .public(String(createdSnapshot.fileCount)),
        "status": .public("success")
      ])),
      source: "BackupDomainHandler"
    )

    return snapshotInfo
  }

  /**
   Handles the update snapshot operation.

   - Parameter operation: The operation to execute
   - Returns: Updated snapshot information
   - Throws: APIError if the operation fails
   */
  private func handleUpdateSnapshot(_ operation: UpdateSnapshotOperation) async throws
  -> SnapshotInfo {
    // Create privacy-aware logging metadata
    var metadata=PrivacyMetadata([
      "operation": .public("updateSnapshot"),
      "repository_id": .public(operation.repositoryID),
      "snapshot_id": .public(operation.snapshotID)
    ])

    if let tags=operation.parameters.tags, !tags.isEmpty {
      metadata["tags"] = .public(tags.joined(separator: ", "))
    }

    await logger?.info(
      "Updating snapshot metadata",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Create update configuration
    let updateConfig=SnapshotUpdateConfig(
      tags: operation.parameters.tags,
      metadata: operation.parameters.metadata
    )

    // Update the snapshot
    let updatedSnapshot=try await backupService.updateSnapshot(
      id: operation.snapshotID,
      forRepository: operation.repositoryID,
      config: updateConfig
    )

    // Convert to API model
    let snapshotInfo=SnapshotInfo(
      id: updatedSnapshot.id,
      repositoryID: operation.repositoryID,
      timestamp: updatedSnapshot.timestamp,
      tags: updatedSnapshot.tags,
      summary: SnapshotSummary(
        fileCount: updatedSnapshot.fileCount,
        totalSize: updatedSnapshot.size,
        rootPaths: updatedSnapshot.rootPaths
      )
    )

    await logger?.info(
      "Snapshot updated successfully",
      metadata: metadata.merging(PrivacyMetadata([
        "status": .public("success")
      ])),
      source: "BackupDomainHandler"
    )

    return snapshotInfo
  }

  /**
   Handles the delete snapshot operation.

   - Parameter operation: The operation to execute
   - Returns: Void (nothing)
   - Throws: APIError if the operation fails
   */
  private func handleDeleteSnapshot(_ operation: DeleteSnapshotOperation) async throws {
    // Create privacy-aware logging metadata
    let metadata=PrivacyMetadata([
      "operation": .public("deleteSnapshot"),
      "repository_id": .public(operation.repositoryID),
      "snapshot_id": .public(operation.snapshotID)
    ])

    await logger?.info(
      "Deleting snapshot",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Delete the snapshot
    try await backupService.deleteSnapshot(
      id: operation.snapshotID,
      fromRepository: operation.repositoryID
    )

    await logger?.info(
      "Snapshot deleted successfully",
      metadata: metadata.merging(PrivacyMetadata([
        "status": .public("success")
      ])),
      source: "BackupDomainHandler"
    )

    // Return void as specified in the operation result type
    return ()
  }

  /**
   Handles the restore snapshot operation.

   - Parameter operation: The operation to execute
   - Returns: Information about the restore operation
   - Throws: APIError if the operation fails
   */
  private func handleRestoreSnapshot(_ operation: RestoreSnapshotOperation) async throws
  -> RestoreResult {
    // Create privacy-aware logging metadata
    var metadata=PrivacyMetadata([
      "operation": .public("restoreSnapshot"),
      "repository_id": .public(operation.repositoryID),
      "snapshot_id": .public(operation.snapshotID)
    ])

    if !operation.parameters.paths.isEmpty {
      metadata["path_count"] = .public(String(operation.parameters.paths.count))
      // Keep actual paths private
      metadata["paths"] = .private(operation.parameters.paths.joined(separator: ", "))
    }

    metadata["target_location"] = .private(operation.parameters.targetDirectory.absoluteString)

    await logger?.info(
      "Restoring from snapshot",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Create restore configuration
    let restoreConfig=RestoreConfig(
      paths: operation.parameters.paths,
      targetDirectory: operation.parameters.targetDirectory,
      overwrite: operation.parameters.overwrite
    )

    // Start the restore operation
    let result=try await backupService.restoreFromSnapshot(
      id: operation.snapshotID,
      fromRepository: operation.repositoryID,
      config: restoreConfig
    )

    // Convert to API model
    let restoreResult=RestoreResult(
      filesRestored: result.filesRestored,
      totalSize: result.totalSize,
      duration: result.duration,
      targetPath: operation.parameters.targetDirectory.absoluteString
    )

    await logger?.info(
      "Snapshot restore completed successfully",
      metadata: metadata.merging(PrivacyMetadata([
        "files_restored": .public(String(result.filesRestored)),
        "total_size": .public(String(result.totalSize)),
        "duration": .public(String(format: "%.2f", result.duration)),
        "status": .public("success")
      ])),
      source: "BackupDomainHandler"
    )

    return restoreResult
  }

  /**
   Handles the forget snapshot operation, which removes snapshot metadata but keeps the data.

   - Parameter operation: The operation to execute
   - Returns: Void (nothing)
   - Throws: APIError if the operation fails
   */
  private func handleForgetSnapshot(_ operation: ForgetSnapshotOperation) async throws {
    // Create privacy-aware logging metadata
    let metadata=PrivacyMetadata([
      "operation": .public("forgetSnapshot"),
      "repository_id": .public(operation.repositoryID),
      "snapshot_id": .public(operation.snapshotID),
      "keep_data": .public(operation.keepData.description)
    ])

    await logger?.info(
      "Forgetting snapshot",
      metadata: metadata,
      source: "BackupDomainHandler"
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          code: "REPOSITORY_NOT_FOUND"
        )
      }
    }

    // Forget the snapshot
    try await backupService.forgetSnapshot(
      id: operation.snapshotID,
      fromRepository: operation.repositoryID,
      keepData: operation.keepData
    )

    await logger?.info(
      "Snapshot forgotten successfully",
      metadata: metadata.merging(PrivacyMetadata([
        "status": .public("success")
      ])),
      source: "BackupDomainHandler"
    )

    // Return void as specified in the operation result type
    return ()
  }
}
