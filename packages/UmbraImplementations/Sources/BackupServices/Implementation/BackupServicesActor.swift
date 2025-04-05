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

  /// Dictionary of active operations
  private var activeOperations: [UUID: BackupOperationToken]=[:]

  /// Active operation cancellation tokens
  private var activeOperationsCancellationTokens: [String: BackupOperationCancellationToken]=[:]

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
    logContext=logContext.withOperation("createBackup")

    // Add source information with privacy classification
    logContext=logContext.withPrivate(
      key: "sources",
      value: sources.map(\.path).joined(separator: ", ")
    )

    if let excludePaths, !excludePaths.isEmpty {
      logContext=logContext.withPrivate(
        key: "excludePaths",
        value: excludePaths.map(\.path).joined(separator: ", ")
      )
    }

    if let tags, !tags.isEmpty {
      logContext=logContext.withPublic(
        key: "tags",
        value: tags.joined(separator: ", ")
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
    activeOperationsCancellationTokens[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgressInfo>()

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
      let enhancedContext=logContext.withPublic(
        key: "backupId",
        value: result.backupID
      ).withPublic(
        key: "fileCount",
        value: "\(result.fileCount)"
      ).withPublic(
        key: "duration",
        value: "\(metadata.duration)"
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperationsCancellationTokens[operationID]=nil
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
      activeOperationsCancellationTokens[operationID]=nil
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
    logContext=logContext.withOperation("restoreBackup")
    logContext=logContext.withPublic(key: "snapshotID", value: snapshotID)
    logContext=logContext.withPrivate(key: "targetPath", value: targetPath.path)

    if let includePaths, !includePaths.isEmpty {
      logContext=logContext.withPrivate(
        key: "includePaths",
        value: includePaths.map(\.path).joined(separator: ", ")
      )
    }

    if let excludePaths, !excludePaths.isEmpty {
      logContext=logContext.withPrivate(
        key: "excludePaths",
        value: excludePaths.map(\.path).joined(separator: ", ")
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
    activeOperationsCancellationTokens[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgressInfo>()

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
      let enhancedContext=logContext.withPublic(
        key: "fileCount",
        value: "\(result.fileCount)"
      ).withPublic(
        key: "duration",
        value: "\(metadata.duration)"
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperationsCancellationTokens[operationID]=nil
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
      activeOperationsCancellationTokens[operationID]=nil
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
   *   - listOptions: Optional listing configuration options
   * - Returns: A Result containing either the list of snapshots or an error
   */
  public func listSnapshots(
    tags: [String]?,
    before: Date?,
    after: Date?,
    listOptions: ListOptions?
  ) async -> Result<[BackupSnapshot], BackupOperationError> {
    // Create a log context
    var logContext=BackupLogContext()
    logContext=logContext.withOperation("listSnapshots")

    if let tags, !tags.isEmpty {
      logContext=logContext.withPublic(
        key: "tags",
        value: tags.joined(separator: ", ")
      )
    }

    if let before {
      logContext=logContext.withPublic(
        key: "before",
        value: before.description
      )
    }

    if let after {
      logContext=logContext.withPublic(
        key: "after",
        value: after.description
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
      listOptions: listOptions
    )

    do {
      // Execute the operation
      let snapshots=try await operationsService.listSnapshots(parameters: parameters)

      // Record the end time
      let endTime=Date()

      // Enhanced log context with result information
      let enhancedContext=logContext.withPublic(
        key: "snapshotCount",
        value: "\(snapshots.count)"
      ).withPublic(
        key: "duration",
        value: "\(endTime.timeIntervalSince(startTime))"
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
      .withOperation("deleteBackup")
      .withPublic(key: "snapshotID", value: snapshotID)

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
    activeOperationsCancellationTokens[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgressInfo>()

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
      let enhancedContext=logContext.withPublic(
        key: "duration",
        value: "\(metadata.duration)"
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperationsCancellationTokens[operationID]=nil
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
      activeOperationsCancellationTokens[operationID]=nil
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
      .withOperation("performMaintenance")
      .withPublic(key: "maintenanceType", value: String(describing: type))

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
    activeOperationsCancellationTokens[operationID]=token

    do {
      // Create progress reporter
      let progressReporter=AsyncProgressReporter<BackupProgressInfo>()

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
      let enhancedContext=logContext.withPublic(
        key: "duration",
        value: "\(metadata.duration)"
      )

      // Log success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        result: result
      )

      // Remove token and return result
      activeOperationsCancellationTokens[operationID]=nil
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
      activeOperationsCancellationTokens[operationID]=nil
      return .failure(backupError)
    }
  }

  /**
   * Verifies the integrity of a backup.
   *
   * This operation checks that all data referenced by a snapshot is present
   * and uncorrupted in the repository.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify, or nil to verify the latest
   *   - verifyData: Whether to verify all data blocks (true) or only metadata (false)
   *   - repairMode: Optional mode for repairing any issues found
   *   - options: Optional verification configuration options
   * - Returns: A Result containing either the operation response or an error
   */
  public func verifyBackup(
    snapshotID: String?,
    verifyData: Bool=true,
    repairMode: BackupInterfaces.RepairMode?=nil,
    options: BackupInterfaces.VerifyOptions?=nil
  ) async -> Result<BackupOperationResponse<VerificationResult>, BackupOperationError> {
    // Create a log context
    let logContext=BackupLogContext()
      .withOperation("verifyBackup")

    // Add snapshot ID if provided
    let enhancedContext=snapshotID != nil ?
      logContext.withPublic(key: "snapshotID", value: snapshotID!) :
      logContext

    // Log operation start
    await backupLogger.logOperationStart(context: enhancedContext)

    // Record the start time
    let startTime=Date()

    // Create a progress reporter for this operation
    let progressReporter=AsyncProgressReporter<BackupProgressInfo>()

    // Create an operation token and register it
    let token=BackupOperationToken(
      id: UUID(),
      operation: .verifyBackup,
      cancellable: true
    )

    // Register the token
    activeOperations[token.id]=token

    // Create a cancellation token for the operation
    let cancellationToken=BackupOperationCancellationToken(id: token.id.uuidString)
    activeOperationsCancellationTokens[token.id]=cancellationToken

    // Create DTO parameters for the operation using adapter pattern
    let localRepairMode=repairMode.map {
      BackupVerifyParameters.RepairMode(rawValue: $0.rawValue) ?? .reportOnly
    }

    let localOptions=options.map { VerifyOptions.from(options: $0) }

    let parameters=BackupVerifyParameters(
      snapshotID: snapshotID,
      verifyData: verifyData,
      repairMode: localRepairMode,
      options: localOptions
    )

    do {
      // Execute the operation
      let verificationResultDTO=try await operationExecutor.executeVerifyOperation(
        parameters: parameters,
        progressReporter: progressReporter,
        cancellationToken: cancellationToken,
        logContext: enhancedContext
      )

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log operation success
      await backupLogger.logOperationSuccess(
        context: enhancedContext,
        duration: duration
      )

      // Remove token
      activeOperationsCancellationTokens[token.id]=nil

      // Convert DTO to interface type using adapter
      let result=verificationResultDTO.toVerificationResult()

      // Return successful result with operation response
      return .success(
        BackupOperationResponse(
          value: result,
          progressStream: progressReporter.stream
        )
      )
    } catch {
      // Map error
      let backupError=error.asBackupOperationError

      // Log error
      await backupLogger.logOperationError(
        context: enhancedContext,
        error: backupError
      )

      // Remove token and return error
      activeOperationsCancellationTokens[token.id]=nil
      return .failure(backupError)
    }
  }

  /**
   * Cancels an ongoing backup operation.
   *
   * This method attempts to gracefully cancel an in-progress operation.
   * Cancellation may not be immediate, and some operations might not be
   * cancellable once they've reached a certain stage.
   *
   * - Parameter operationID: ID of the operation to cancel
   * - Returns: True if cancellation was initiated, false if the operation
   *            doesn't exist or cannot be cancelled
   */
  public func cancelOperation(operationID: UUID) async -> Bool {
    // Create a log context
    let logContext=BackupLogContext()
      .withOperation("cancelOperation")
      .withPublic(key: "operationID", value: operationID.uuidString)

    // Log cancellation attempt
    await backupLogger.logOperationStart(context: logContext)

    // Check if the operation exists
    guard let token=activeOperations[operationID] else {
      // Log that operation wasn't found
      await backupLogger.logOperationFailure(
        context: logContext,
        error: BackupOperationError.operationNotFound("Operation with ID \(operationID) not found")
      )
      return false
    }

    // Check if the operation is cancellable
    guard token.cancellable else {
      // Log that operation can't be cancelled
      await backupLogger.logOperationFailure(
        context: logContext,
        error: BackupOperationError
          .operationNotCancellable("Operation \(token.operation) cannot be cancelled")
      )
      return false
    }

    // Try to cancel the operation
    do {
      try await cancelOperationImpl(token: token)

      // Log success
      await backupLogger.logOperationSuccess(
        context: logContext,
        message: "Operation cancelled successfully"
      )

      return true
    } catch {
      // Log failure
      await backupLogger.logOperationFailure(
        context: logContext,
        error: error
      )

      return false
    }
  }

  /**
   * Implementation of cancellation logic.
   * This handles the actual cancellation work.
   *
   * - Parameter token: The operation token to cancel
   */
  private func cancelOperationImpl(token: BackupOperationToken) async throws {
    // Signal cancellation to the operation
    token.cancelled=true

    // Remove from active operations
    activeOperations[token.id]=nil

    // Log the cancellation
    let logContext=BackupLogContext()
      .withOperation("cancelOperationImpl")
      .withPublic(key: "operationID", value: token.id.uuidString)
      .withPublic(key: "operationType", value: String(describing: token.operation))

    await backupLogger.logInfo(
      context: logContext,
      message: "Operation cancellation complete"
    )
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
   * Maps standard errors to BackupOperationError types.
   *
   * This helper method ensures consistent error mapping throughout the service.
   *
   * - Parameter error: The original error to map
   * - Returns: A BackupOperationError representing the original error
   */
  private func mapToOperationError(_ error: Error) -> BackupOperationError {
    if let backupError=error as? BackupOperationError {
      return backupError
    }

    // Map known error types
    if let nsError=error as? NSError {
      switch nsError.domain {
        case NSURLErrorDomain:
          return .networkError("Network error: \(nsError.localizedDescription)")
        case NSCocoaErrorDomain:
          return .fileSystemError("File system error: \(nsError.localizedDescription)")
        default:
          break
      }
    }

    // Default to unknown error with the original description
    return .unknownError("Operation failed: \(error.localizedDescription)")
  }

  /**
   * Cancels all active operations.
   *
   * - Returns: The number of operations cancelled
   */
  public func cancelAllOperations() async -> Int {
    let count=activeOperationsCancellationTokens.count

    for (id, _) in activeOperationsCancellationTokens {
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
    guard let token=activeOperationsCancellationTokens[id] else {
      return false
    }

    // Create a log context
    let logContext=BackupLogContext()
      .withOperation("cancelOperation")
      .withPublic(key: "operationID", value: id.uuidString)

    // Log cancellation
    await backupLogger.logOperationCancelled(context: logContext)

    // Cancel the operation
    await operationExecutor.cancelOperation(id: token.id)

    // Remove the token
    activeOperationsCancellationTokens[id]=nil

    return true
  }
}
