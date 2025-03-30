import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
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
  
  /// Privacy-aware logging adapter for structured logging
  private let snapshotLogging: SnapshotLoggingAdapter

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
    self.resticService = resticService
    self.logger = logger
    self.snapshotLogging = SnapshotLoggingAdapter(logger: logger)
    commandFactory = ResticCommandFactory()
    resultParser = SnapshotResultParser()
    errorMapper = ErrorMapper()
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
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(repositoryID: repositoryID, privacy: .public)
        .with(tags: tags, privacy: .public)
        .with(beforeDate: before, privacy: .public)
        .with(afterDate: after, privacy: .public)
        .with(path: path?.path, privacy: .public)
        .with(key: "limit", value: limit != nil ? String(limit!) : "unlimited", privacy: .public)
        .with(operation: "listSnapshots")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to list snapshots
      let command = try commandFactory.createListCommand(
        repositoryID: repositoryID,
        tags: tags,
        before: before,
        after: after,
        path: path,
        limit: limit
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse snapshots
      let snapshots = try resultParser.parseSnapshotsList(output: output, repositoryID: repositoryID)

      // Log successful operation
      let resultContext = logContext.with(key: "count", value: String(snapshots.count), privacy: .public)
      await snapshotLogging.logOperationSuccess(logContext: resultContext)

      return snapshots
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "List snapshots failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "List snapshots failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "List snapshots failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
    }
  }

  /// Gets a specific snapshot by ID
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - includeFileStatistics: Whether to include detailed file statistics
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Detailed backup snapshot information
  /// - Throws: `BackupError` if the snapshot lookup fails
  public func getSnapshot(
    snapshotID: String,
    includeFileStatistics: Bool,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupSnapshot {
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(key: "includeFileStatistics", value: String(includeFileStatistics), privacy: .public)
        .with(operation: "getSnapshot")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to get the snapshot
      let command = try commandFactory.createGetCommand(
        snapshotID: snapshotID,
        includeFileStatistics: includeFileStatistics
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse snapshot
      let snapshot = try resultParser.parseSnapshotDetail(output: output)

      // Log successful operation
      await snapshotLogging.logOperationSuccess(logContext: logContext)

      return snapshot
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Get snapshot failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Get snapshot failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Get snapshot failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
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
    var metadata=PrivacyMetadata()
    metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)
    metadata["includeFileStatistics"]=PrivacyMetadataValue(value: String(includeFileStatistics), privacy: .public)

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
      var resultMetadata=PrivacyMetadata()
      resultMetadata["snapshotID"]=PrivacyMetadataValue(value: snapshot.id, privacy: .public)
      resultMetadata["creationTime"]=PrivacyMetadataValue(value: snapshot.creationTime.description, privacy: .public)
      resultMetadata["fileCount"]=PrivacyMetadataValue(value: String(snapshot.fileCount), privacy: .public)

      await logger.info(
        "Retrieved snapshot details successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return snapshot
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Get snapshot details failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Get snapshot details failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Get snapshot details failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }

  /// Compares two snapshots to identify differences
  /// - Parameters:
  ///   - snapshotID1: ID of the first snapshot
  ///   - snapshotID2: ID of the second snapshot
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Detailed snapshot difference information
  /// - Throws: `BackupError` if the compare operation fails
  public func compareSnapshots(
    snapshotID1: String,
    snapshotID2: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> SnapshotDifference {
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(key: "snapshotID1", value: snapshotID1, privacy: .public)
        .with(key: "snapshotID2", value: snapshotID2, privacy: .public)
        .with(operation: "compareSnapshots")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to compare snapshots
      let command = try commandFactory.createCompareCommand(
        snapshotID1: snapshotID1,
        snapshotID2: snapshotID2
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse difference
      let difference = try resultParser.parseSnapshotDifference(output: output)

      // Log successful operation with results
      let resultContext = logContext
          .with(key: "addedFiles", value: String(difference.addedFiles.count), privacy: .public)
          .with(key: "modifiedFiles", value: String(difference.modifiedFiles.count), privacy: .public)
          .with(key: "removedFiles", value: String(difference.removedFiles.count), privacy: .public)

      await snapshotLogging.logOperationSuccess(logContext: resultContext)

      return difference
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Compare snapshots failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Compare snapshots failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Compare snapshots failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
    }
  }

  /// Adds tags to a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - addTags: Tags to add to the snapshot
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Updated backup snapshot information
  /// - Throws: `BackupError` if the tag update fails
  public func addTagsToSnapshot(
    snapshotID: String,
    addTags: [String],
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupSnapshot {
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(key: "addTags", value: addTags.joined(separator: ", "), privacy: .public)
        .with(operation: "addTagsToSnapshot")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to add tags
      let command = try commandFactory.createAddTagsCommand(
        snapshotID: snapshotID,
        tags: addTags
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse updated snapshot
      let snapshot = try resultParser.parseTagUpdateResult(output: output)

      // Log successful operation
      let resultContext = logContext
          .with(key: "totalTags", value: String(snapshot.tags.count), privacy: .public)

      await snapshotLogging.logOperationSuccess(logContext: resultContext)

      return snapshot
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Add tags to snapshot failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Add tags to snapshot failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Add tags to snapshot failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
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
    var metadata=PrivacyMetadata()
    metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)
    metadata["addTags"]=PrivacyMetadataValue(value: addTags.joined(separator: ", "), privacy: .public)
    metadata["removeTags"]=PrivacyMetadataValue(value: removeTags.joined(separator: ", "), privacy: .public)

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
      var resultMetadata=PrivacyMetadata()
      resultMetadata["snapshotID"]=PrivacyMetadataValue(value: snapshot.id, privacy: .public)
      resultMetadata["tags"]=PrivacyMetadataValue(value: snapshot.tags.joined(separator: ", "), privacy: .public)

      await logger.info(
        "Updated snapshot tags successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return snapshot
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Update snapshot tags failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Update snapshot tags failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

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
  ///   - snapshotID: ID of the snapshot
  ///   - description: New description for the snapshot
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Updated backup snapshot information
  /// - Throws: `BackupError` if the description update fails
  public func updateSnapshotDescription(
    snapshotID: String,
    description: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> BackupSnapshot {
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(key: "description", value: description, privacy: .public)
        .with(operation: "updateSnapshotDescription")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to update the description
      let command = try commandFactory.createUpdateDescriptionCommand(
        snapshotID: snapshotID,
        description: description
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse updated snapshot
      let snapshot = try resultParser.parseDescriptionUpdateResult(output: output)

      // Log successful operation
      await snapshotLogging.logOperationSuccess(logContext: logContext)

      return snapshot
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Update snapshot description failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Update snapshot description failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Update snapshot description failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
    }
  }

  /// Deletes a snapshot
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot to delete
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Returns: Result of the delete operation
  /// - Throws: `BackupError` if the delete operation fails
  public func deleteSnapshot(
    snapshotID: String,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws -> DeleteResult {
    let deletionTime = Date()

    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(operation: "deleteSnapshot")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to delete the snapshot
      let command = try commandFactory.createDeleteCommand(snapshotID: snapshotID)

      // Execute command
      let output = try await resticService.execute(command)

      // Parse delete result
      let result = try resultParser.parseDeleteResult(output: output)

      // Log successful operation with results
      let resultContext = logContext
          .with(key: "deletedFiles", value: String(result.deletedFiles), privacy: .public)
          .with(key: "deletedBytes", value: String(result.deletedBytes), privacy: .public)

      await snapshotLogging.logOperationSuccess(logContext: resultContext)

      return result
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Delete snapshot failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Delete snapshot failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Delete snapshot failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
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
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(key: "targetRepositoryID", value: targetRepositoryID, privacy: .public)
        .with(operation: "copySnapshot")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to copy the snapshot
      let command = try commandFactory.createCopyCommand(
        snapshotID: snapshotID,
        targetRepositoryID: targetRepositoryID
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse the ID of the copied snapshot
      let newSnapshotID = try resultParser.parseCopyResult(output: output)

      // Log successful operation with the new ID
      let resultContext = logContext
          .with(key: "newSnapshotID", value: newSnapshotID, privacy: .public)

      await snapshotLogging.logOperationSuccess(logContext: resultContext)

      return newSnapshotID
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Copy snapshot failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Copy snapshot failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Copy snapshot failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
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
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(key: "pattern", value: pattern, privacy: .public)
        .with(key: "caseSensitive", value: String(caseSensitive), privacy: .public)
        .with(operation: "findFiles")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to find files
      let command = try commandFactory.createFindCommand(
        snapshotID: snapshotID,
        pattern: pattern,
        caseSensitive: caseSensitive
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse find result
      let files = try resultParser.parseFindResult(output: output, pattern: pattern)

      // Log successful operation with the file count
      let resultContext = logContext
          .with(key: "fileCount", value: String(files.count), privacy: .public)

      await snapshotLogging.logOperationSuccess(logContext: resultContext)

      return files
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Find files failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Find files failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Find files failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
    }
  }

  /// Restores files from a snapshot to the filesystem
  /// - Parameters:
  ///   - snapshotID: ID of the snapshot
  ///   - targetPath: Path to restore files to
  ///   - includePattern: Optional pattern of files to include
  ///   - excludePattern: Optional pattern of files to exclude
  ///   - progressReporter: Optional reporter for tracking operation progress
  ///   - cancellationToken: Optional token for cancelling the operation
  /// - Throws: `BackupError` if the restore operation fails
  public func restoreFiles(
    snapshotID: String,
    targetPath: URL,
    includePattern: String?,
    excludePattern: String?,
    progressReporter _: BackupProgressReporter?,
    cancellationToken _: CancellationToken?
  ) async throws {
    // Create a structured log context with privacy-aware metadata
    let logContext = SnapshotLogContext()
        .with(snapshotID: snapshotID, privacy: .public)
        .with(key: "targetPath", value: targetPath.path, privacy: .private)
        .with(key: "includePattern", value: includePattern ?? "all", privacy: .public)
        .with(key: "excludePattern", value: excludePattern ?? "none", privacy: .public)
        .with(operation: "restoreFiles")

    await snapshotLogging.logOperationStart(logContext: logContext)

    do {
      // Create command to restore files
      let command = try commandFactory.createRestoreCommand(
        snapshotID: snapshotID,
        targetPath: targetPath,
        includePattern: includePattern,
        excludePattern: excludePattern
      )

      // Execute command
      let output = try await resticService.execute(command)

      // Parse restore result
      let fileCount = try resultParser.parseRestoreResult(output: output)

      // Log successful operation with the file count
      let resultContext = logContext
          .with(key: "restoredFiles", value: String(fileCount), privacy: .public)

      await snapshotLogging.logOperationSuccess(logContext: resultContext)
    } catch let error as ResticError {
      // Log Restic error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Restore files failed with Restic error")
      
      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Log backup error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Restore files failed")
      
      throw error
    } catch {
      // Log unexpected error
      let errorContext = logContext.withError(error)
      await snapshotLogging.logOperationError(logContext: errorContext, message: "Restore files failed with unexpected error")
      
      throw BackupError.unexpectedError(error.localizedDescription)
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
    var metadata=PrivacyMetadata()
    metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)

    await logger.info("Locking snapshot", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to lock snapshot
      let command=try commandFactory.createLockCommand(snapshotID: snapshotID)

      // Execute command
      _=try await resticService.execute(command)

      // Create result metadata
      var resultMetadata=PrivacyMetadata()
      resultMetadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)

      await logger.info(
        "Locked snapshot successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Lock snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error("Lock snapshot failed", metadata: errorMetadata, source: "SnapshotService")

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

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
    var metadata=PrivacyMetadata()
    metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)

    await logger.info("Unlocking snapshot", metadata: metadata, source: "SnapshotService")

    do {
      // Create command to unlock snapshot
      let command=try commandFactory.createUnlockCommand(snapshotID: snapshotID)

      // Execute command
      _=try await resticService.execute(command)

      // Create result metadata
      var resultMetadata=PrivacyMetadata()
      resultMetadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)

      await logger.info(
        "Unlocked snapshot successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Unlock snapshot failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Unlock snapshot failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

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
    var metadata=PrivacyMetadata()
    metadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)

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
      var resultMetadata=PrivacyMetadata()
      resultMetadata["snapshotID"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)
      resultMetadata["duration"]=PrivacyMetadataValue(value: String(format: "%.2fs", endTime.timeIntervalSince(startTime)), privacy: .public)

      await logger.info(
        "Snapshot verification completed successfully",
        metadata: resultMetadata,
        source: "SnapshotService"
      )

      return result
    } catch let error as ResticError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Snapshot verification failed with Restic error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw errorMapper.convertResticError(error)
    } catch let error as BackupError {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Snapshot verification failed",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw error
    } catch {
      // Create error metadata
      var errorMetadata=PrivacyMetadata()
      errorMetadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      await logger.error(
        "Snapshot verification failed with unexpected error",
        metadata: errorMetadata,
        source: "SnapshotService"
      )

      throw BackupError.genericError(reason: error.localizedDescription)
    }
  }
}
