import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import ResticServices
import UmbraErrors

/**
 # Backup Services Actor

 This actor provides thread-safe backup operations following the
 Alpha Dot Five architecture, ensuring proper state isolation and
 concurrency safety while providing a clean interface for clients.

 ## Usage

 ```swift
 let actor = BackupServicesActor(repository: myRepo, logger: myLogger)

 let result = await actor.createBackup(
     sources: [myURL],
     excludePaths: nil,
     tags: ["weekly"]
 )

 switch result {
 case .success(let operationResult):
     // Use operationResult.value and operationResult.progressStream
 case .failure(let error):
     // Handle error
 }
 ```

 ## Features

 - Thread-safe operations with proper actor isolation
 - Privacy-aware logging with appropriate data classification
 - Structured error handling with specific error types
 - Progress reporting through AsyncStream
 */
public actor BackupServicesActor: BackupServiceProtocol {
  // MARK: - Properties

  /// The operations service
  private let operationsService: BackupOperationsService

  /// The operation executor
  private let operationExecutor: BackupOperationExecutor

  /// The backup logger
  private let backupLogger: BackupLogger

  /// Active operation cancellation tokens
  private var activeOperations: [String: BackupOperationCancellationToken]=[:]

  // MARK: - Initialisation

  /**
   * Initialises a new backup services actor.
   *
   * - Parameters:
   *   - resticService: Restic service for backend operations
   *   - logger: Logger for operation tracking
   *   - repositoryInfo: Repository connection details
   */
  public init(
    resticService: ResticServiceProtocol,
    logger: any LoggingProtocol,
    repositoryInfo: RepositoryInfo
  ) {
    // Create components
    let commandFactory=BackupCommandFactory()
    let resultParser=BackupResultParser()

    // Initialize component services
    operationsService=BackupOperationsService(
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: commandFactory,
      resultParser: resultParser
    )

    // Create the backup logger
    backupLogger=BackupLogger(logger: logger)

    // Create needed components
    let errorLogContextMapper=ErrorLogContextMapper()
    let errorMapper=BackupErrorMapper()
    let metricsCollector=BackupMetricsCollector()
    let cancellationHandler=ModernCancellationHandler()

    // Initialize operation executor
    operationExecutor=BackupOperationExecutor(
      logger: logger,
      cancellationHandler: cancellationHandler,
      metricsCollector: metricsCollector,
      errorLogContextMapper: errorLogContextMapper,
      errorMapper: errorMapper
    )
  }

  // MARK: - BackupServiceProtocol Implementation

  /**
   * Creates a new backup.
   *
   * - Parameters:
   *   - sources: Source paths to back up
   *   - excludePaths: Optional paths to exclude
   *   - tags: Optional tags to associate with the backup
   *   - backupOptions: Optional backup configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  public func createBackup(
    sources: [URL],
    excludePaths: [URL]?,
    tags: [String]?,
    backupOptions: BackupOptions?
  ) async -> Result<BackupOperationResponse<BackupResult>, BackupOperationError> {
    // Create a log context
    var logContext=BackupLogContext()
      .with(operation: "createBackup")

    // Add source information with privacy classification
    logContext=logContext.with(
      sources: sources.map(\.path),
      privacy: .restricted
    )

    if let excludePaths, !excludePaths.isEmpty {
      logContext=logContext.with(
        excludePaths: excludePaths.map(\.path),
        privacy: .restricted
      )
    }

    if let tags, !tags.isEmpty {
      logContext=logContext.with(
        tags: tags,
        privacy: .public
      )
    }

    // Log operation start
    await backupLogger.logOperationStart(context: logContext)

    // Input validation
    guard !sources.isEmpty else {
      let error=BackupOperationError.invalidInput("Sources cannot be empty")
      await backupLogger.logOperationError(context: logContext, error: error)
      return .failure(error)
    }

    // Record the start time
    let startTime=Date()

    // Create parameters
    let parameters=BackupCreateParameters(
      sources: sources,
      excludePaths: excludePaths,
      tags: tags,
      options: backupOptions
    )

    // Create a cancellation token for this operation
    let token=BackupOperationCancellationToken(id: UUID().uuidString)
    let operationID=token.id
    activeOperations[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgress>()

      // Execute the operation
      let result=try await operationExecutor.execute(
        parameters: parameters,
        operation: { params, progress, token in
          try await operationsService.createBackup(
            parameters: params as! BackupCreateParameters,
            progressReporter: progress,
            cancellationToken: token
          )
        },
        progressReporter: progressReporter,
        cancellationToken: token
      )

      // Record the end time
      let endTime=Date()

      // Create metadata
      let metadata=BackupOperationMetadata(
        startTime: startTime,
        endTime: endTime,
        operationType: "createBackup",
        additionalInfo: [
          "sourceCount": "\(sources.count)",
          "hasExcludes": "\(excludePaths != nil && !excludePaths!.isEmpty)"
        ]
      )

      // Create operation result
      let operationResult=BackupOperationResponse(
        value: result,
        progressStream: progressReporter.stream,
        metadata: metadata
      )

      // Enhanced log context with result information
      let enhancedContext=logContext.with(
        key: "backupId",
        value: result.backupID,
        privacy: .public
      ).with(
        key: "fileCount",
        value: "\(result.fileCount)",
        privacy: .public
      ).with(
        key: "duration",
        value: "\(metadata.duration)",
        privacy: .public
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperations[operationID]=nil
      return .success(operationResult)
    } catch {
      // Map error to BackupOperationError
      let backupError=mapToBackupOperationError(error)

      // Log error
      await backupLogger.logOperationError(
        context: logContext,
        error: backupError
      )

      // Remove token and return error
      activeOperations[operationID]=nil
      return .failure(backupError)
    }
  }

  /**
   * Restores a backup.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to restore
   *   - targetPath: Path to restore to
   *   - includePaths: Optional paths to include
   *   - excludePaths: Optional paths to exclude
   *   - restoreOptions: Optional restore configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  public func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?,
    excludePaths: [URL]?,
    restoreOptions: RestoreOptions?
  ) async -> Result<BackupOperationResponse<RestoreResult>, BackupOperationError> {
    // Create a log context
    var logContext=BackupLogContext()
      .with(operation: "restoreBackup")
      .with(key: "snapshotID", value: snapshotID, privacy: .public)
      .with(key: "targetPath", value: targetPath.path, privacy: .restricted)

    if let includePaths, !includePaths.isEmpty {
      logContext=logContext.with(
        includePaths: includePaths.map(\.path),
        privacy: .restricted
      )
    }

    if let excludePaths, !excludePaths.isEmpty {
      logContext=logContext.with(
        excludePaths: excludePaths.map(\.path),
        privacy: .restricted
      )
    }

    // Log operation start
    await backupLogger.logOperationStart(context: logContext)

    // Input validation
    guard !snapshotID.isEmpty else {
      let error=BackupOperationError.invalidInput("Snapshot ID cannot be empty")
      await backupLogger.logOperationError(context: logContext, error: error)
      return .failure(error)
    }

    // Record the start time
    let startTime=Date()

    // Create parameters
    let parameters=BackupRestoreParameters(
      snapshotID: snapshotID,
      targetPath: targetPath,
      includePaths: includePaths,
      excludePaths: excludePaths,
      options: restoreOptions
    )

    // Create a cancellation token for this operation
    let token=BackupOperationCancellationToken(id: UUID().uuidString)
    let operationID=token.id
    activeOperations[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgress>()

      // Execute the operation
      let result=try await operationExecutor.execute(
        parameters: parameters,
        operation: { params, progress, token in
          try await operationsService.restoreBackup(
            parameters: params as! BackupRestoreParameters,
            progressReporter: progress,
            cancellationToken: token
          )
        },
        progressReporter: progressReporter,
        cancellationToken: token
      )

      // Record the end time
      let endTime=Date()

      // Create metadata
      let metadata=BackupOperationMetadata(
        startTime: startTime,
        endTime: endTime,
        operationType: "restoreBackup",
        additionalInfo: [
          "snapshotID": snapshotID,
          "fileCount": "\(result.fileCount)"
        ]
      )

      // Create operation result
      let operationResult=BackupOperationResponse(
        value: result,
        progressStream: progressReporter.stream,
        metadata: metadata
      )

      // Enhanced log context with result information
      let enhancedContext=logContext.with(
        key: "fileCount",
        value: "\(result.fileCount)",
        privacy: .public
      ).with(
        key: "duration",
        value: "\(metadata.duration)",
        privacy: .public
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperations[operationID]=nil
      return .success(operationResult)
    } catch {
      // Map error to BackupOperationError
      let backupError=mapToBackupOperationError(error)

      // Log error
      await backupLogger.logOperationError(
        context: logContext,
        error: backupError
      )

      // Remove token and return error
      activeOperations[operationID]=nil
      return .failure(backupError)
    }
  }

  /**
   * Lists available snapshots with optional filtering.
   *
   * - Parameters:
   *   - tags: Optional tags to filter by
   *   - before: Optional date to filter snapshots before
   *   - after: Optional date to filter snapshots after
   *   - options: Optional listing options
   * - Returns: A Result containing either the list of snapshots or an error
   */
  public func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    options: ListOptions?
  ) async -> Result<[BackupSnapshot], BackupOperationError> {
    // Create a log context
    var logContext=BackupLogContext()
      .with(operation: "listSnapshots")

    if let tags, !tags.isEmpty {
      logContext=logContext.with(
        tags: tags,
        privacy: .public
      )
    }

    if let before {
      logContext=logContext.with(
        key: "before",
        value: before.description,
        privacy: .public
      )
    }

    if let after {
      logContext=logContext.with(
        key: "after",
        value: after.description,
        privacy: .public
      )
    }

    // Log operation start
    await backupLogger.logOperationStart(context: logContext)

    // Record the start time
    let startTime=Date()

    // Create parameters
    let parameters=BackupListParameters(
      tags: tags,
      before: before,
      after: after,
      options: options
    )

    do {
      // Execute the operation
      let snapshots=try await operationsService.listSnapshots(parameters: parameters)

      // Record the end time
      let endTime=Date()

      // Enhanced log context with result information
      let enhancedContext=logContext.with(
        key: "snapshotCount",
        value: "\(snapshots.count)",
        privacy: .public
      ).with(
        key: "duration",
        value: "\(endTime.timeIntervalSince(startTime))",
        privacy: .public
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: snapshots
      )

      return .success(snapshots)
    } catch {
      // Map error to BackupOperationError
      let backupError=mapToBackupOperationError(error)

      // Log error
      await backupLogger.logOperationError(
        context: logContext,
        error: backupError
      )

      return .failure(backupError)
    }
  }

  /**
   * Deletes a backup snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to delete
   *   - deleteOptions: Optional delete configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  public func deleteBackup(
    snapshotID: String,
    deleteOptions: DeleteOptions?
  ) async -> Result<BackupOperationResponse<BackupDeleteResult>, BackupOperationError> {
    // Create a log context
    let logContext=BackupLogContext()
      .with(operation: "deleteBackup")
      .with(key: "snapshotID", value: snapshotID, privacy: .public)

    // Log operation start
    await backupLogger.logOperationStart(context: logContext)

    // Input validation
    guard !snapshotID.isEmpty else {
      let error=BackupOperationError.invalidInput("Snapshot ID cannot be empty")
      await backupLogger.logOperationError(context: logContext, error: error)
      return .failure(error)
    }

    // Record the start time
    let startTime=Date()

    // Create parameters
    let parameters=BackupDeleteParameters(
      snapshotID: snapshotID,
      pruneAfterDelete: deleteOptions?.prune ?? false
    )

    // Create a cancellation token for this operation
    let token=BackupOperationCancellationToken(id: UUID().uuidString)
    let operationID=token.id
    activeOperations[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgress>()

      // Execute the operation
      let result=try await operationExecutor.execute(
        parameters: parameters,
        operation: { params, progress, token in
          try await operationsService.deleteBackup(
            parameters: params as! BackupDeleteParameters,
            progressReporter: progress,
            cancellationToken: token
          )
        },
        progressReporter: progressReporter,
        cancellationToken: token
      )

      // Record the end time
      let endTime=Date()

      // Create metadata
      let metadata=BackupOperationMetadata(
        startTime: startTime,
        endTime: endTime,
        operationType: "deleteBackup",
        additionalInfo: [
          "snapshotID": snapshotID,
          "pruneAfterDelete": "\(parameters.pruneAfterDelete)"
        ]
      )

      // Create operation result
      let operationResult=BackupOperationResponse(
        value: result,
        progressStream: progressReporter.stream,
        metadata: metadata
      )

      // Enhanced log context with result information
      let enhancedContext=logContext.with(
        key: "duration",
        value: "\(metadata.duration)",
        privacy: .public
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperations[operationID]=nil
      return .success(operationResult)
    } catch {
      // Map error to BackupOperationError
      let backupError=mapToBackupOperationError(error)

      // Log error
      await backupLogger.logOperationError(
        context: logContext,
        error: backupError
      )

      // Remove token and return error
      activeOperations[operationID]=nil
      return .failure(backupError)
    }
  }

  /**
   * Performs maintenance on the backup repository.
   *
   * - Parameters:
   *   - type: Type of maintenance to perform
   *   - maintenanceOptions: Optional maintenance configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  public func performMaintenance(
    type: MaintenanceType,
    maintenanceOptions: MaintenanceOptions?
  ) async -> Result<BackupOperationResponse<MaintenanceResult>, BackupOperationError> {
    // Create a log context
    let logContext=BackupLogContext()
      .with(operation: "performMaintenance")
      .with(key: "maintenanceType", value: String(describing: type), privacy: .public)

    // Log operation start
    await backupLogger.logOperationStart(context: logContext)

    // Record the start time
    let startTime=Date()

    // Create parameters
    let parameters=BackupMaintenanceParameters(
      maintenanceType: type,
      options: maintenanceOptions
    )

    // Create a cancellation token for this operation
    let token=BackupOperationCancellationToken(id: UUID().uuidString)
    let operationID=token.id
    activeOperations[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgress>()

      // Execute the operation
      let result=try await operationExecutor.execute(
        parameters: parameters,
        operation: { params, progress, token in
          try await operationsService.performMaintenance(
            parameters: params as! BackupMaintenanceParameters,
            progressReporter: progress,
            cancellationToken: token
          )
        },
        progressReporter: progressReporter,
        cancellationToken: token
      )

      // Record the end time
      let endTime=Date()

      // Create metadata
      let metadata=BackupOperationMetadata(
        startTime: startTime,
        endTime: endTime,
        operationType: "performMaintenance",
        additionalInfo: [
          "maintenanceType": String(describing: type)
        ]
      )

      // Create operation result
      let operationResult=BackupOperationResponse(
        value: result,
        progressStream: progressReporter.stream,
        metadata: metadata
      )

      // Enhanced log context with result information
      let enhancedContext=logContext.with(
        key: "duration",
        value: "\(metadata.duration)",
        privacy: .public
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperations[operationID]=nil
      return .success(operationResult)
    } catch {
      // Map error to BackupOperationError
      let backupError=mapToBackupOperationError(error)

      // Log error
      await backupLogger.logOperationError(
        context: logContext,
        error: backupError
      )

      // Remove token and return error
      activeOperations[operationID]=nil
      return .failure(backupError)
    }
  }

  // MARK: - Helper Methods

  /**
   * Maps any error to a BackupOperationError.
   *
   * - Parameter error: The error to map
   * - Returns: A BackupOperationError
   */
  private func mapToBackupOperationError(_ error: Error) -> BackupOperationError {
    if let backupError=error as? BackupOperationError {
      backupError
    } else if error is CancellationError {
      .operationCancelled("Operation was cancelled")
    } else if let repositoryError=error as? RepositoryError {
      .repositoryError(repositoryError)
    } else if let timeout=error as? TimeoutError {
      .timeout("Operation timed out after \(timeout.duration) seconds")
    } else {
      .unexpected("Unexpected error: \(error.localizedDescription)")
    }
  }

  /**
   * Cancels all active operations.
   *
   * - Returns: The number of operations cancelled
   */
  public func cancelAllOperations() async -> Int {
    let count=activeOperations.count

    for (id, _) in activeOperations {
      await cancelOperation(id: id)
    }

    return count
  }

  /**
   * Cancels a specific operation.
   *
   * - Parameter id: The operation ID to cancel
   * - Returns: Whether the operation was found and cancelled
   */
  public func cancelOperation(id: String) async -> Bool {
    guard let token=activeOperations[id] else {
      return false
    }

    // Create a log context
    let logContext=BackupLogContext()
      .with(operation: "cancelOperation")
      .with(key: "operationID", value: id, privacy: .public)

    // Log cancellation
    await backupLogger.logOperationCancelled(context: logContext)

    // Cancel the operation
    await operationExecutor.cancelOperation(id: token.id)

    // Remove the token
    activeOperations[id]=nil

    return true
  }
}
