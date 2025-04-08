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

 This handler is implemented as an actor to ensure thread safety and memory isolation
 throughout all operations. The actor-based design provides automatic synchronisation
 and eliminates potential race conditions when handling concurrent requests.
 */
public actor BackupDomainHandler: DomainHandler {
  /// Backup service for snapshot operations
  private let backupService: BackupServiceProtocol

  /// Repository service for repository validation
  private let repositoryService: RepositoryServiceProtocol?

  /// Logger with privacy controls
  private let logger: LoggingProtocol?
  
  /// Cache for snapshot information to improve performance of repeated requests
  private var snapshotCache: [String: (SnapshotInfo, Date)] = [:]
  
  /// Cache time-to-live in seconds
  private let cacheTTL: TimeInterval = 60 // 1 minute

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
  public nonisolated var domain: String { APIDomain.backup.rawValue }

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
    // Get operation name once for reuse
    let operationName = String(describing: type(of: operation))
    
    // Log operation start with optimised metadata creation
    await logOperationStart(operationName: operationName, source: "BackupDomainHandler")
    
    do {
      // Execute the appropriate operation based on type
      let result = try await executeBackupOperation(operation)
      
      // Log success with optimised metadata creation
      await logOperationSuccess(operationName: operationName, source: "BackupDomainHandler")
      
      return result
    } catch {
      // Log failure with optimised metadata creation
      await logOperationFailure(operationName: operationName, error: error, source: "BackupDomainHandler")
      
      // Map to appropriate API error and rethrow
      throw mapToAPIError(error)
    }
  }

  /**
   Determines if this handler supports the given operation.

   - Parameter operation: The operation to check support for
   - Returns: true if the operation is supported, false otherwise
   */
  public nonisolated func supports(_ operation: some APIOperation) -> Bool {
    operation is any BackupAPIOperation
  }

  // MARK: - Private Helper Methods
  
  /**
   Creates base metadata for logging with common fields.
   
   - Parameters:
     - operation: The operation name
     - event: The event type (start, success, failure)
   - Returns: Metadata collection with common fields
   */
  private func createBaseMetadata(operation: String, event: String) -> LogMetadataDTOCollection {
    LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "event", value: event)
      .withPublic(key: "domain", value: domain)
  }
  
  /**
   Logs the start of an operation with optimised metadata creation.
   
   - Parameter operationName: The name of the operation being executed
   - Parameter source: The source of the log message
   */
  private func logOperationStart(operationName: String, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .info) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "start")
      
      await logger?.info(
        "Starting backup operation",
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Logs the successful completion of an operation with optimised metadata creation.
   
   - Parameter operationName: The name of the operation that completed
   - Parameter source: The source of the log message
   */
  private func logOperationSuccess(operationName: String, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .info) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "success")
        .withPublic(key: "status", value: "completed")
      
      await logger?.info(
        "Backup operation completed successfully",
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Logs the failure of an operation with optimised metadata creation.
   
   - Parameters:
     - operationName: The name of the operation that failed
     - error: The error that caused the failure
     - source: The source of the log message
   */
  private func logOperationFailure(operationName: String, error: Error, source: String) async {
    // Only create metadata if logging is enabled
    if await logger?.isEnabled(for: .error) == true {
      let metadata = createBaseMetadata(operation: operationName, event: "failure")
        .withPublic(key: "status", value: "failed")
        .withPrivate(key: "error", value: error.localizedDescription)
      
      await logger?.error(
        "Backup operation failed",
        context: CoreLogContext(
          source: source,
          metadata: metadata
        )
      )
    }
  }
  
  /**
   Retrieves a snapshot from the cache if available and not expired.
   
   - Parameters:
     - id: The snapshot ID
     - repositoryID: The repository ID
   - Returns: The cached snapshot if available, nil otherwise
   */
  private func getCachedSnapshot(id: String, repositoryID: String) -> SnapshotInfo? {
    let cacheKey = "\(repositoryID):\(id)"
    if let (info, timestamp) = snapshotCache[cacheKey],
       Date().timeIntervalSince(timestamp) < cacheTTL {
      return info
    }
    return nil
  }
  
  /**
   Caches a snapshot for future use.
   
   - Parameters:
     - id: The snapshot ID
     - repositoryID: The repository ID
     - info: The snapshot information to cache
   */
  private func cacheSnapshot(id: String, repositoryID: String, info: SnapshotInfo) {
    let cacheKey = "\(repositoryID):\(id)"
    snapshotCache[cacheKey] = (info, Date())
  }
  
  /**
   Clears all cached snapshots.
   */
  public func clearCache() {
    snapshotCache.removeAll()
  }

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
        // Check cache first for better performance
        if let cachedSnapshot = getCachedSnapshot(id: op.snapshotID, repositoryID: op.repositoryID) {
          // Log cache hit if logging is enabled
          if await logger?.isEnabled(for: .debug) == true {
            let metadata = createBaseMetadata(operation: "getSnapshot", event: "cacheHit")
              .withPublic(key: "repository_id", value: op.repositoryID)
              .withPublic(key: "snapshot_id", value: op.snapshotID)
            
            await logger?.debug(
              "Retrieved snapshot from cache",
              context: CoreLogContext(
                source: "BackupDomainHandler",
                metadata: metadata
              )
            )
          }
          return SnapshotDetails(from: cachedSnapshot)
        }
        return try await handleGetSnapshot(op)
      case let op as CreateSnapshotOperation:
        let result = try await handleCreateSnapshot(op)
        // Cache the result for future use
        if let snapshotInfo = result as? SnapshotInfo {
          cacheSnapshot(id: snapshotInfo.id, repositoryID: op.repositoryID, info: snapshotInfo)
        }
        return result
      case let op as UpdateSnapshotOperation:
        let result = try await handleUpdateSnapshot(op)
        // Update cache with new information
        if let snapshotInfo = result as? SnapshotInfo {
          cacheSnapshot(id: snapshotInfo.id, repositoryID: op.repositoryID, info: snapshotInfo)
        }
        return result
      case let op as DeleteSnapshotOperation:
        // Invalidate cache entry for this snapshot
        let cacheKey = "\(op.repositoryID):\(op.snapshotID)"
        snapshotCache.removeValue(forKey: cacheKey)
        return try await handleDeleteSnapshot(op)
      case let op as RestoreSnapshotOperation:
        return try await handleRestoreSnapshot(op)
      case let op as ForgetSnapshotOperation:
        // Invalidate cache entry for this snapshot
        let cacheKey = "\(op.repositoryID):\(op.snapshotID)"
        snapshotCache.removeValue(forKey: cacheKey)
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
    if let apiError = error as? APIError {
      return apiError
    }

    // Use a type-based approach for more efficient error mapping
    switch error {
      case let backupError as BackupError:
        return mapBackupError(backupError)
      case let repositoryError as RepositoryError:
        return mapRepositoryError(repositoryError)
      default:
        return APIError.internalError(
          message: "An unexpected error occurred: \(error.localizedDescription)",
          underlyingError: error
        )
    }
  }
  
  /**
   Maps BackupError to standardised APIError.
   
   - Parameter error: The backup error to map
   - Returns: An APIError instance
   */
  private func mapBackupError(_ error: BackupError) -> APIError {
    switch error {
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
          underlyingError: error
        )
      case let .pathNotFound(path):
        return APIError.resourceNotFound(
          message: "Path not found: \(path)",
          identifier: path
        )
      case .invalidConfiguration:
        return APIError.validationError(
          message: "Invalid backup configuration",
          details: "The provided backup configuration is invalid or incomplete",
          code: "INVALID_BACKUP_CONFIG"
        )
      case let .operationCancelled(reason):
        return APIError.operationCancelled(
          message: "Backup operation cancelled: \(reason)",
          code: "BACKUP_CANCELLED"
        )
      case let .accessDenied(path):
        return APIError.accessDenied(
          message: "Access denied to path: \(path)",
          details: "The application does not have permission to access this path",
          code: "BACKUP_ACCESS_DENIED"
        )
      case .concurrentOperationLimitExceeded:
        return APIError.resourceExhausted(
          message: "Too many concurrent backup operations",
          details: "The maximum number of concurrent backup operations has been exceeded",
          code: "BACKUP_CONCURRENCY_LIMIT"
        )
      case let .other(message):
        return APIError.operationFailed(
          message: message,
          code: "BACKUP_ERROR",
          underlyingError: error
        )
    }
  }
  
  /**
   Maps RepositoryError to standardised APIError.
   
   - Parameter error: The repository error to map
   - Returns: An APIError instance
   */
  private func mapRepositoryError(_ error: RepositoryError) -> APIError {
    switch error {
      case .notFound:
        return APIError.resourceNotFound(
          message: "Repository not found",
          identifier: "unknown"
        )
      case .duplicateIdentifier:
        return APIError.conflict(
          message: "Repository already exists with this identifier",
          details: "A repository with the given identifier is already registered",
          code: "REPOSITORY_ALREADY_EXISTS"
        )
      case .locked:
        return APIError.conflict(
          message: "Repository is locked by another operation",
          details: "Try again later when the repository is not in use",
          code: "REPOSITORY_LOCKED"
        )
      case .invalidRepository:
        return APIError.validationError(
          message: "Invalid repository configuration",
          details: "The repository configuration is invalid or incomplete",
          code: "INVALID_REPOSITORY"
        )
      case .accessDenied:
        return APIError.accessDenied(
          message: "Access denied to repository",
          details: "The application does not have permission to access this repository",
          code: "REPOSITORY_ACCESS_DENIED"
        )
      case .networkError:
        return APIError.networkError(
          message: "Network error accessing repository",
          details: "A network error occurred while trying to access the repository",
          code: "REPOSITORY_NETWORK_ERROR"
        )
      case .other:
        return APIError.internalError(
          message: "An unexpected repository error occurred",
          underlyingError: error
        )
    }
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

  // MARK: - Batch Operation Support
  
  /**
   Executes a batch of backup operations more efficiently than individual execution.
   
   - Parameter operations: Array of operations to execute
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  public func executeBatch(_ operations: [any APIOperation]) async throws -> [String: Any] {
    var results: [String: Any] = [:]
    
    // Group operations by type for more efficient processing
    let groupedOperations = Dictionary(grouping: operations) { type(of: $0) }
    
    // Log batch operation start
    if await logger?.isEnabled(for: .info) == true {
      let metadata = LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "batchExecution")
        .withPublic(key: "event", value: "start")
        .withPublic(key: "operationCount", value: String(operations.count))
        .withPublic(key: "operationTypes", value: String(describing: groupedOperations.keys))
      
      await logger?.info(
        "Starting batch backup operation",
        context: CoreLogContext(
          source: "BackupDomainHandler.executeBatch",
          metadata: metadata
        )
      )
    }
    
    do {
      // Process each group of operations
      for (_, operationsOfType) in groupedOperations {
        if let firstOp = operationsOfType.first {
          // Process based on operation type
          if firstOp is ListSnapshotsOperation {
            // Example: Batch process all list operations together
            let batchResult = try await batchListSnapshots(
              operationsOfType.compactMap { $0 as? ListSnapshotsOperation }
            )
            for (id, result) in batchResult {
              results[id] = result
            }
          } else {
            // Fall back to individual processing for other types
            for operation in operationsOfType {
              let result = try await executeBackupOperation(operation)
              results[operation.operationId] = result
            }
          }
        }
      }
      
      // Log batch operation success
      if await logger?.isEnabled(for: .info) == true {
        let metadata = LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "batchExecution")
          .withPublic(key: "event", value: "success")
          .withPublic(key: "operationCount", value: String(operations.count))
          .withPublic(key: "resultsCount", value: String(results.count))
        
        await logger?.info(
          "Batch backup operation completed successfully",
          context: CoreLogContext(
            source: "BackupDomainHandler.executeBatch",
            metadata: metadata
          )
        )
      }
      
      return results
    } catch {
      // Log batch operation failure
      if await logger?.isEnabled(for: .error) == true {
        let metadata = LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "batchExecution")
          .withPublic(key: "event", value: "failure")
          .withPublic(key: "operationCount", value: String(operations.count))
          .withPrivate(key: "error", value: error.localizedDescription)
        
        await logger?.error(
          "Batch backup operation failed",
          context: CoreLogContext(
            source: "BackupDomainHandler.executeBatch",
            metadata: metadata
          )
        )
      }
      
      throw mapToAPIError(error)
    }
  }
  
  /**
   Processes multiple list snapshots operations in a batch for better performance.
   
   - Parameter operations: Array of ListSnapshotsOperation to process
   - Returns: Dictionary mapping operation IDs to results
   - Throws: APIError if any operation fails
   */
  private func batchListSnapshots(_ operations: [ListSnapshotsOperation]) async throws -> [String: [SnapshotInfo]] {
    var results: [String: [SnapshotInfo]] = [:]
    
    // Group operations by repository ID to minimize service calls
    let groupedByRepository = Dictionary(grouping: operations) { $0.repositoryID }
    
    // Process each repository's operations
    for (repositoryID, repoOperations) in groupedByRepository {
      // Validate repository once per group
      if let repositoryService = self.repositoryService,
         await !repositoryService.isRegistered(identifier: repositoryID) {
        throw BackupError.repositoryNotFound(repositoryID)
      }
      
      // Get all snapshots for this repository in one call
      let allSnapshots = try await backupService.listSnapshots(
        repositoryID: repositoryID,
        filter: nil,
        includeDetails: true
      )
      
      // Apply filters for each operation
      for operation in repoOperations {
        let filteredSnapshots: [SnapshotInfo]
        
        if let filter = operation.filter {
          // Apply the filter to the retrieved snapshots
          filteredSnapshots = allSnapshots.filter { snapshot in
            // Apply tag filtering
            if let tags = filter.tags, !tags.isEmpty {
              let snapshotTags = Set(snapshot.tags ?? [])
              let filterTags = Set(tags)
              if !filterTags.isSubset(of: snapshotTags) {
                return false
              }
            }
            
            // Apply date range filtering
            if let startDate = filter.startDate, snapshot.creationDate < startDate {
              return false
            }
            
            if let endDate = filter.endDate, snapshot.creationDate > endDate {
              return false
            }
            
            // Apply status filtering
            if let status = filter.status, snapshot.status != status {
              return false
            }
            
            return true
          }
        } else {
          filteredSnapshots = allSnapshots
        }
        
        // Store the result for this operation
        results[operation.operationId] = filteredSnapshots
      }
    }
    
    return results
  }

  // MARK: - Helper Extensions

  // This section would normally contain helper extensions if needed
}
