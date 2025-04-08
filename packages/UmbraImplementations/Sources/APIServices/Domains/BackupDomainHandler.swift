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

  // MARK: - DomainHandler Conformance
  public var domain: String { APIDomain.backup.rawValue }

  public func handleOperation<T: APIOperation>(operation: T) async throws -> Any {
    // Call the existing execute method
    return try await execute(operation)
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
    let startMetadata=LogMetadataDTOCollection()
      .with(key: "operation", value: operationName, privacyLevel: .public)
      .with(key: "event", value: "start", privacyLevel: .public)

    await logger?.info(
      "Starting backup operation",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: startMetadata
      )
    )

    do {
      // Execute the appropriate operation based on type
      let result=try await executeBackupOperation(operation)

      // Log success
      let successMetadata=LogMetadataDTOCollection()
        .with(key: "operation", value: operationName, privacyLevel: .public)
        .with(key: "event", value: "success", privacyLevel: .public)
        .with(key: "status", value: "success", privacyLevel: .public)

      await logger?.info(
        "Backup operation completed successfully",
        context: BaseLogContextDTO(
          domainName: "backup",
          source: "BackupDomainHandler",
          metadata: successMetadata
        )
      )

      return result
    } catch {
      // Log failure with privacy-aware error details
      let errorMetadata=LogMetadataDTOCollection()
        .with(key: "operation", value: operationName, privacyLevel: .public)
        .with(key: "event", value: "failure", privacyLevel: .public)
        .with(key: "status", value: "failed", privacyLevel: .public)
        .with(key: "error", value: error.localizedDescription, privacyLevel: .private)

      await logger?.error(
        "Backup operation failed",
        context: BaseLogContextDTO(
          domainName: "backup",
          source: "BackupDomainHandler",
          metadata: errorMetadata
        )
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
            identifier: id
          )
        case let .repositoryNotFound(id):
          return APIError.resourceNotFound(
            message: "Repository not found: \(id)",
            identifier: id
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
            identifier: path
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
    var metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "listSnapshots", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)

    if let tagFilter=operation.tagFilter, !tagFilter.isEmpty {
      metadata=metadata.with(
        key: "tag_filter",
        value: tagFilter.joined(separator: ", "),
        privacyLevel: .public
      )
    }

    if let pathFilter=operation.pathFilter {
      metadata=metadata.with(key: "path_filter", value: pathFilter, privacyLevel: .public)
    }

    if let beforeDate=operation.beforeDate {
      metadata=metadata.with(
        key: "before_date",
        value: ISO8601DateFormatter().string(from: beforeDate),
        privacyLevel: .public
      )
    }

    if let afterDate=operation.afterDate {
      metadata=metadata.with(
        key: "after_date",
        value: ISO8601DateFormatter().string(from: afterDate),
        privacyLevel: .public
      )
    }

    if let limit=operation.limit {
      metadata=metadata.with(key: "limit", value: String(limit), privacyLevel: .public)
    }

    await logger?.info(
      "Listing snapshots",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
        )
      }
    }

    // Get snapshots with filtering
    let filters=SnapshotFilters(
      tags: operation.tagFilter ?? [],
      path: operation.pathFilter,
      before: operation.beforeDate,
      after: operation.afterDate,
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
        timestamp: snapshot.creationTime,
        tags: snapshot.tags,
        summary: SnapshotSummary(
          fileCount: snapshot.fileCount,
          totalSize: snapshot.totalSize
        )
      )
    }

    // Log the result count
    let resultMetadata=metadata.with(
      key: "count",
      value: String(snapshotInfos.count),
      privacyLevel: .public
    )

    await logger?.info(
      "Found snapshots",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: resultMetadata
      )
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
    let metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "getSnapshot", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)
      .with(key: "snapshot_id", value: operation.snapshotID, privacyLevel: .public)
      .with(key: "include_files", value: operation.includeFiles.description, privacyLevel: .public)

    await logger?.info(
      "Retrieving snapshot details",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
        )
      }
    }

    // Get snapshot details
    let snapshot=try await backupService.getSnapshot(
      id: operation.snapshotID,
      fromRepository: operation.repositoryID
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
      timestamp: snapshot.creationTime,
      tags: snapshot.tags,
      summary: SnapshotSummary(
        fileCount: snapshot.fileCount,
        totalSize: snapshot.totalSize
      )
    )

    // Create details
    let details=SnapshotDetails(
      basicInfo: basicInfo,
      creationHostname: snapshot.hostname,
      options: [:],
      metadata: [:],
      files: fileEntries
    )

    await logger?.info(
      "Snapshot details retrieved",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata.with(
          key: "status",
          value: "success",
          privacyLevel: .public
        ).with(
          key: "file_count",
          value: operation.includeFiles ? String(fileEntries.count) : "0",
          privacyLevel: .public
        )
      )
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
    var metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "createSnapshot", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)

    if !operation.parameters.tags.isEmpty {
      metadata=metadata.with(
        key: "tags",
        value: operation.parameters.tags.joined(separator: ", "),
        privacyLevel: .public
      )
    }

    if !operation.parameters.paths.isEmpty {
      metadata=metadata.with(
        key: "path_count",
        value: String(operation.parameters.paths.count),
        privacyLevel: .public
      )
      // Keep actual paths private
      metadata=metadata.with(
        key: "paths",
        value: operation.parameters.paths.joined(separator: ", "),
        privacyLevel: .private
      )
    }

    await logger?.info(
      "Creating new snapshot",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
        )
      }
    }

    // Create the snapshot parameters
    let backupParams=SnapshotCreationConfig(
      paths: operation.parameters.paths,
      tags: operation.parameters.tags,
      metadata: operation.parameters.metadata
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
      timestamp: createdSnapshot.creationTime,
      tags: createdSnapshot.tags,
      summary: SnapshotSummary(
        fileCount: createdSnapshot.fileCount,
        totalSize: createdSnapshot.totalSize
      )
    )

    await logger?.info(
      "Snapshot created successfully",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata.with(
          key: "snapshot_id",
          value: createdSnapshot.id,
          privacyLevel: .public
        ).with(
          key: "file_count",
          value: String(createdSnapshot.fileCount),
          privacyLevel: .public
        ).with(
          key: "status",
          value: "success",
          privacyLevel: .public
        )
      )
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
    var metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "updateSnapshot", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)
      .with(key: "snapshot_id", value: operation.snapshotID, privacyLevel: .public)

    if let tags=operation.parameters.tags, !tags.isEmpty {
      metadata=metadata.with(
        key: "tags",
        value: tags.joined(separator: ", "),
        privacyLevel: .public
      )
    }

    await logger?.info(
      "Updating snapshot metadata",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
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
      with: updateConfig
    )

    // Convert to API model
    let snapshotInfo=SnapshotInfo(
      id: updatedSnapshot.id,
      repositoryID: operation.repositoryID,
      timestamp: updatedSnapshot.creationTime,
      tags: updatedSnapshot.tags,
      summary: SnapshotSummary(
        fileCount: updatedSnapshot.fileCount,
        totalSize: updatedSnapshot.totalSize
      )
    )

    await logger?.info(
      "Snapshot updated successfully",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata.with(
          key: "status",
          value: "success",
          privacyLevel: .public
        )
      )
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
    let metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "deleteSnapshot", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)
      .with(key: "snapshot_id", value: operation.snapshotID, privacyLevel: .public)

    await logger?.info(
      "Deleting snapshot",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
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
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata.with(
          key: "status",
          value: "success",
          privacyLevel: .public
        )
      )
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
    var metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "restoreSnapshot", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)
      .with(key: "snapshot_id", value: operation.snapshotID, privacyLevel: .public)

    if !operation.parameters.paths.isEmpty {
      metadata=metadata.with(
        key: "path_count",
        value: String(operation.parameters.paths.count),
        privacyLevel: .public
      )
      // Keep actual paths private
      metadata=metadata.with(
        key: "paths",
        value: operation.parameters.paths.joined(separator: ", "),
        privacyLevel: .private
      )
    }

    metadata=metadata.with(
      key: "target_location",
      value: operation.parameters.targetDirectory.absoluteString,
      privacyLevel: .private
    )

    await logger?.info(
      "Restoring from snapshot",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
        )
      }
    }

    // Create restore configuration
    let restoreConfig=RestoreConfig(
      paths: operation.parameters.paths,
      targetDirectory: operation.parameters.targetDirectory
    )

    // Restore from the snapshot
    let result=try await backupService.restoreFromSnapshot(
      id: operation.snapshotID,
      fromRepository: operation.repositoryID,
      config: restoreConfig
    )

    // Convert to API model
    let restoreResult=RestoreResult(
      snapshotID: operation.snapshotID,
      restoreTime: Date(),
      totalSize: result.totalSize,
      fileCount: result.fileCount,
      duration: result.duration,
      targetPath: operation.parameters.targetDirectory
    )

    await logger?.info(
      "Snapshot restore completed successfully",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata.with(
          key: "files_restored",
          value: String(result.fileCount),
          privacyLevel: .public
        ).with(
          key: "total_size",
          value: String(result.totalSize),
          privacyLevel: .public
        ).with(
          key: "duration",
          value: String(format: "%.2f", result.duration),
          privacyLevel: .public
        ).with(
          key: "status",
          value: "success",
          privacyLevel: .public
        )
      )
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
    let metadata=LogMetadataDTOCollection()
      .with(key: "operation", value: "forgetSnapshot", privacyLevel: .public)
      .with(key: "repository_id", value: operation.repositoryID, privacyLevel: .public)
      .with(key: "snapshot_id", value: operation.snapshotID, privacyLevel: .public)
      .with(key: "keep_data", value: String(operation.keepData), privacyLevel: .public)

    await logger?.info(
      "Forgetting snapshot",
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata
      )
    )

    // Validate repository existence if repository service is available
    if let repoService=repositoryService {
      let exists=await repoService.isRegistered(identifier: operation.repositoryID)
      if !exists {
        throw APIError.resourceNotFound(
          message: "Repository not found: \(operation.repositoryID)",
          identifier: operation.repositoryID
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
      context: BaseLogContextDTO(
        domainName: "backup",
        source: "BackupDomainHandler",
        metadata: metadata.with(
          key: "status",
          value: "success",
          privacyLevel: .public
        )
      )
    )

    // Return void as specified in the operation result type
    return ()
  }
}

// MARK: - Helper Extensions

// This section would normally contain helper extensions if needed
