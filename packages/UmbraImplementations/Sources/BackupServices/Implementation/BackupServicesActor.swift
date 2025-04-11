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
 - Command pattern architecture for improved maintainability and testability
 - Privacy-aware logging with appropriate data classification
 - Structured error handling with specific error types
 - Progress reporting through AsyncStream
 */
public actor BackupServicesActor: BackupServiceProtocol {
  // MARK: - Properties

  /// Factory for creating backup commands
  private let commandFactory: BackupCommandFactory

  /// The Restic command factory
  private let resticCommandFactory: BackupCommandFactory

  /// Result parser for processing command output
  private let resultParser: BackupResultParser

  /// The backup logger
  private let backupLogger: BackupLogger

  /// The Restic service for backend operations
  private let resticService: ResticServiceProtocol

  /// Repository connection information
  private let repositoryInfo: RepositoryInfo

  /// Error mapper for translating errors
  private let errorMapper: BackupErrorMapper

  /// Dictionary of active operations
  private var activeOperations: [UUID: BackupOperationToken]=[:]

  /// Active operation cancellation tokens
  private var activeOperationsCancellationTokens: [String: BackupOperationCancellationTokenImpl]=[:]

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
    // Store key dependencies
    self.resticService=resticService
    self.repositoryInfo=repositoryInfo

    // Create components for command infrastructure
    resticCommandFactory=BackupCommandFactory()
    resultParser=BackupResultParser()
    errorMapper=BackupErrorMapper()

    // Create the backup command factory
    commandFactory=BackupCommandFactory(
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      resticCommandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )

    // Create the backup logger
    backupLogger=BackupLogger(loggingService: logger, domainName: "BackupServices")
  }

  // MARK: - Operation Tracking

  /**
   * Registers an operation for tracking.
   *
   * - Parameters:
   *   - operationID: Unique ID for the operation
   *   - type: Type of operation being performed
   *   - cancellationToken: Token for cancellation
   */
  private func registerOperation(
    operationID: String,
    type: BackupOperationType,
    cancellationToken: BackupOperationCancellationTokenImpl?=nil
  ) {
    let uuid=UUID()
    activeOperations[uuid]=BackupOperationToken(
      id: uuid,
      operationID: operationID,
      type: type
    )

    if let token=cancellationToken {
      activeOperationsCancellationTokens[operationID]=token
    }
  }

  /**
   * Unregisters an operation from tracking.
   *
   * - Parameter operationID: ID of the operation to unregister
   */
  private func unregisterOperation(operationID: String) {
    if let key=activeOperations.first(where: { $0.value.operationID == operationID })?.key {
      activeOperations.removeValue(forKey: key)
    }

    activeOperationsCancellationTokens.removeValue(forKey: operationID)
  }

  // MARK: - Public API

  /**
   * Creates a new backup with the specified sources, exclusions, and tags.
   *
   * - Parameters:
   *   - sources: Array of URLs to include in the backup
   *   - excludePaths: Optional array of paths to exclude
   *   - tags: Optional array of tags to apply to the backup
   *   - options: Optional backup configuration options
   * - Returns: Result containing the backup operation response or an error
   */
  public func createBackup(
    sources: [URL],
    excludePaths: [URL]?=nil,
    tags: [String]?=nil,
    options: BackupOptions?=nil
  ) async -> Result<BackupOperationResponse<BackupResult>, BackupOperationError> {
    // Create a log context
    let logContext=LogContextDTO(
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "source", value: "BackupServicesActor.createBackup")
    )

    // Generate an operation ID
    let operationID=UUID().uuidString

    // Create a cancellation token
    let cancellationToken=BackupOperationCancellationTokenImpl(operationID: operationID)

    // Register the operation
    registerOperation(
      operationID: operationID,
      type: .createBackup,
      cancellationToken: cancellationToken
    )

    // Create the progress reporter
    let progressReporter=BackupProgressReporterImpl()

    // Create the parameters
    let parameters=BackupCreateParameters(
      operationID: operationID,
      sources: sources,
      excludePaths: excludePaths,
      tags: tags,
      options: options
    )

    // Create the command
    let createBackupCommand=commandFactory.createBackupCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken
    )

    // Execute the command
    let result=await createBackupCommand.execute(
      context: logContext,
      operationID: operationID
    )

    // Map the result to the expected response format
    let mappedResult: Result<BackupOperationResponse<BackupResult>, BackupOperationError>

    switch result {
      case .success(let (value, progressStream)):
        let response=BackupOperationResponse(
          value: value,
          progressStream: progressStream
        )
        mappedResult = .success(response)

      case let .failure(error):
        mappedResult = .failure(error)
    }

    // Unregister the operation
    unregisterOperation(operationID: operationID)

    return mappedResult
  }

  /**
   * Restores a backup from a snapshot ID to the specified target location.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to restore
   *   - targetPath: Location to restore the files to
   *   - includePaths: Optional specific paths within the snapshot to restore
   *   - excludePaths: Optional paths to exclude from restoration
   *   - options: Optional restore configuration options
   * - Returns: Result containing the restore operation response or an error
   */
  public func restoreBackup(
    snapshotID: String,
    targetPath: URL,
    includePaths: [URL]?=nil,
    excludePaths: [URL]?=nil,
    options: RestoreOptions?=nil
  ) async -> Result<BackupOperationResponse<RestoreResult>, BackupOperationError> {
    // Create a log context
    let logContext=LogContextDTO(
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "source", value: "BackupServicesActor.restoreBackup")
    )

    // Generate an operation ID
    let operationID=UUID().uuidString

    // Create a cancellation token
    let cancellationToken=BackupOperationCancellationTokenImpl(operationID: operationID)

    // Register the operation
    registerOperation(
      operationID: operationID,
      type: .restoreBackup,
      cancellationToken: cancellationToken
    )

    // Create the progress reporter
    let progressReporter=BackupProgressReporterImpl()

    // Create the parameters
    let parameters=BackupRestoreParameters(
      operationID: operationID,
      snapshotID: snapshotID,
      targetPath: targetPath,
      includePaths: includePaths,
      excludePaths: excludePaths,
      options: options
    )

    // Create the command
    let restoreBackupCommand=commandFactory.createRestoreCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken
    )

    // Execute the command
    let result=await restoreBackupCommand.execute(
      context: logContext,
      operationID: operationID
    )

    // Map the result to the expected response format
    let mappedResult: Result<BackupOperationResponse<RestoreResult>, BackupOperationError>

    switch result {
      case .success(let (value, progressStream)):
        let response=BackupOperationResponse(
          value: value,
          progressStream: progressStream
        )
        mappedResult = .success(response)

      case let .failure(error):
        mappedResult = .failure(error)
    }

    // Unregister the operation
    unregisterOperation(operationID: operationID)

    return mappedResult
  }

  /**
   * Lists available backup snapshots.
   *
   * - Parameters:
   *   - path: Optional path to filter snapshots by
   *   - tags: Optional tags to filter snapshots by
   *   - host: Optional host to filter snapshots by
   * - Returns: Result containing array of snapshots or an error
   */
  public func listSnapshots(
    path: String?=nil,
    tags: [String]?=nil,
    host: String?=nil
  ) async -> Result<[BackupSnapshot], BackupOperationError> {
    // Create a log context
    let logContext=LogContextDTO(
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "source", value: "BackupServicesActor.listSnapshots")
    )

    // Generate an operation ID
    let operationID=UUID().uuidString

    // Register the operation
    registerOperation(
      operationID: operationID,
      type: .listSnapshots
    )

    // Create the parameters
    let parameters=BackupListSnapshotsParameters(
      operationID: operationID,
      path: path,
      tags: tags,
      host: host
    )

    // Create the command
    let listSnapshotsCommand=commandFactory.createListSnapshotsCommand(
      parameters: parameters
    )

    // Execute the command
    let result=await listSnapshotsCommand.execute(
      context: logContext,
      operationID: operationID
    )

    // Unregister the operation
    unregisterOperation(operationID: operationID)

    return result
  }

  /**
   * Deletes a backup snapshot or snapshots matching criteria.
   *
   * - Parameters:
   *   - snapshotID: Optional specific snapshot ID to delete
   *   - tags: Optional tags to match snapshots for deletion
   *   - host: Optional host to match snapshots for deletion
   *   - options: Optional delete configuration options
   * - Returns: Result containing the delete operation response or an error
   */
  public func deleteBackup(
    snapshotID: String?=nil,
    tags: [String]?=nil,
    host: String?=nil,
    options: DeleteOptions?=nil
  ) async -> Result<BackupOperationResponse<BackupDeleteResult>, BackupOperationError> {
    // Create a log context
    let logContext=LogContextDTO(
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "source", value: "BackupServicesActor.deleteBackup")
    )

    // Generate an operation ID
    let operationID=UUID().uuidString

    // Create a cancellation token
    let cancellationToken=BackupOperationCancellationTokenImpl(operationID: operationID)

    // Register the operation
    registerOperation(
      operationID: operationID,
      type: .deleteBackup,
      cancellationToken: cancellationToken
    )

    // Create the progress reporter
    let progressReporter=BackupProgressReporterImpl()

    // Create the parameters
    let parameters=BackupDeleteParameters(
      operationID: operationID,
      snapshotID: snapshotID,
      tags: tags,
      host: host,
      options: options
    )

    // Create the command
    let deleteBackupCommand=commandFactory.createDeleteCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken
    )

    // Execute the command
    let result=await deleteBackupCommand.execute(
      context: logContext,
      operationID: operationID
    )

    // Map the result to the expected response format
    let mappedResult: Result<BackupOperationResponse<BackupDeleteResult>, BackupOperationError>

    switch result {
      case .success(let (value, progressStream)):
        let response=BackupOperationResponse(
          value: value,
          progressStream: progressStream
        )
        mappedResult = .success(response)

      case let .failure(error):
        mappedResult = .failure(error)
    }

    // Unregister the operation
    unregisterOperation(operationID: operationID)

    return mappedResult
  }

  /**
   * Performs maintenance on the backup repository.
   *
   * - Parameters:
   *   - type: Type of maintenance to perform
   *   - options: Optional maintenance configuration options
   * - Returns: Result containing the maintenance operation response or an error
   */
  public func performMaintenance(
    type: MaintenanceType,
    options: MaintenanceOptions?=nil
  ) async -> Result<BackupOperationResponse<MaintenanceResult>, BackupOperationError> {
    // Create a log context
    let logContext=LogContextDTO(
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "source", value: "BackupServicesActor.performMaintenance")
    )

    // Generate an operation ID
    let operationID=UUID().uuidString

    // Create a cancellation token
    let cancellationToken=BackupOperationCancellationTokenImpl(operationID: operationID)

    // Register the operation
    registerOperation(
      operationID: operationID,
      type: .maintenance,
      cancellationToken: cancellationToken
    )

    // Create the progress reporter
    let progressReporter=BackupProgressReporterImpl()

    // Create the parameters
    let parameters=BackupMaintenanceParameters(
      operationID: operationID,
      type: type,
      options: options
    )

    // Create the command
    let maintenanceCommand=commandFactory.createMaintenanceCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken
    )

    // Execute the command
    let result=await maintenanceCommand.execute(
      context: logContext,
      operationID: operationID
    )

    // Map the result to the expected response format
    let mappedResult: Result<BackupOperationResponse<MaintenanceResult>, BackupOperationError>

    switch result {
      case .success(let (value, progressStream)):
        let response=BackupOperationResponse(
          value: value,
          progressStream: progressStream
        )
        mappedResult = .success(response)

      case let .failure(error):
        mappedResult = .failure(error)
    }

    // Unregister the operation
    unregisterOperation(operationID: operationID)

    return mappedResult
  }

  /**
   * Verifies the integrity of a backup snapshot.
   *
   * - Parameters:
   *   - snapshotID: ID of the snapshot to verify
   *   - verifyOptions: Optional verification configuration options
   * - Returns: Result containing the verification operation response or an error
   */
  public func verifyBackup(
    snapshotID: String,
    verifyOptions: VerifyOptions?=nil
  ) async -> Result<BackupOperationResponse<VerificationResult>, BackupOperationError> {
    // Create a log context
    let logContext=LogContextDTO(
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "source", value: "BackupServicesActor.verifyBackup")
    )

    // Generate an operation ID
    let operationID=UUID().uuidString

    // Create a cancellation token
    let cancellationToken=BackupOperationCancellationTokenImpl(operationID: operationID)

    // Register the operation
    registerOperation(
      operationID: operationID,
      type: .verifyBackup,
      cancellationToken: cancellationToken
    )

    // Create the progress reporter
    let progressReporter=BackupProgressReporterImpl()

    // Create the parameters
    let parameters=BackupVerificationParameters(
      operationID: operationID,
      snapshotID: snapshotID,
      verifyOptions: verifyOptions
    )

    // Create the command
    let verifyCommand=commandFactory.createVerifyCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken
    )

    // Execute the command
    let result=await verifyCommand.execute(
      context: logContext,
      operationID: operationID
    )

    // Map the result to the expected response format
    let mappedResult: Result<BackupOperationResponse<VerificationResult>, BackupOperationError>

    switch result {
      case .success(let (value, progressStream)):
        let response=BackupOperationResponse(
          value: value,
          progressStream: progressStream
        )
        mappedResult = .success(response)

      case let .failure(error):
        mappedResult = .failure(error)
    }

    // Unregister the operation
    unregisterOperation(operationID: operationID)

    return mappedResult
  }

  /**
   * Cancels an ongoing backup operation.
   *
   * This method attempts to gracefully cancel an in-progress operation.
   * Cancellation may not be immediate, and some operations might not be
   * cancellable after reaching certain stages.
   *
   * - Parameter operationID: ID of the operation to cancel
   * - Returns: True if cancellation was successful, false otherwise
   */
  public func cancelOperation(operationID: String) async -> Bool {
    // Get the cancellation token
    guard let token=activeOperationsCancellationTokens[operationID] else {
      return false
    }

    // Set the cancellation flag
    token.isCancelled=true

    // Log the cancellation
    await backupLogger.info(
      message: "Operation \(operationID) cancellation requested",
      context: LogContextDTO(
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "source", value: "BackupServicesActor.cancelOperation")
          .withPublic(key: "operationID", value: operationID)
      )
    )

    return true
  }

  /**
   * Lists all currently active backup operations.
   *
   * - Returns: Array of active operation tokens
   */
  public func listActiveOperations() async -> [BackupOperationToken] {
    Array(activeOperations.values)
  }
}
