import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Command for performing maintenance operations on the backup repository.

 This command encapsulates the logic for performing maintenance tasks such as
 checking repository integrity, removing unnecessary data, or optimising storage.
 */
public class MaintenanceCommand: BaseBackupCommand, BackupCommand {
  /// The result type for this command
  public typealias ResultType=(MaintenanceResult, AsyncStream<BackupProgressInfo>)

  /// Parameters for maintenance operation
  private let parameters: BackupMaintenanceParameters

  /// Progress reporter for tracking progress
  private let progressReporter: BackupProgressReporter?

  /// Cancellation token for the operation
  private let cancellationToken: CancellationToken?

  /**
   Initialises a new maintenance command.

   - Parameters:
      - parameters: Parameters for maintenance operation
      - progressReporter: Reporter for tracking progress
      - cancellationToken: Optional token for cancelling the operation
      - resticService: Service for executing Restic commands
      - repositoryInfo: Repository connection information
      - commandFactory: Factory for creating Restic commands
      - resultParser: Parser for command results
      - errorMapper: Error mapper for translating errors
      - logger: Optional logger for tracking operations
   */
  public init(
    parameters: BackupMaintenanceParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?,
    resticService: ResticServiceProtocol,
    repositoryInfo: RepositoryInfo,
    commandFactory: BackupCommandFactory,
    resultParser: BackupResultParser,
    errorMapper: BackupErrorMapper,
    logger: LoggingProtocol?=nil
  ) {
    self.parameters=parameters
    self.progressReporter=progressReporter
    self.cancellationToken=cancellationToken

    super.init(
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: commandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }

  /**
   Executes the maintenance command.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  public func execute(
    context: LogContextDTO,
    operationID _: String
  ) async -> Result<(MaintenanceResult, AsyncStream<BackupProgressInfo>), BackupOperationError> {
    // Create the progress stream
    let (progressStream, progressContinuation)=createProgressStream()

    // Create a progress handler that forwards progress updates
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .maintenance)
      }
      progressContinuation.yield(progress)

      // Check if we're done
      if case .completed=progress.phase {
        progressContinuation.finish()
      }
    }

    // Enhance the log context with specific operation details
    let backupLogContext=context
      .withPublic(key: "operationID", value: parameters.operationID)
      .withPublic(key: "operation", value: "maintenance")
      .withPublic(key: "maintenanceType", value: parameters.type.rawValue)

    await logInfo("Starting backup repository maintenance", context: backupLogContext)

    do {
      // Create the maintenance command
      let command=try commandFactory.createMaintenanceCommand(
        type: parameters.type,
        options: parameters.options
      )

      await logDebug(
        "Executing maintenance command: \(command.description)",
        context: backupLogContext
      )

      // Execute the maintenance command with progress and cancellation support
      let result=try await resticService.executeWithProgress(
        command: command,
        repository: repositoryInfo,
        progressHandler: progressHandler,
        cancellationToken: cancellationToken
      )

      // Parse the result
      let maintenanceResult=try resultParser.parseMaintenanceResult(
        output: result,
        type: parameters.type
      )

      await logInfo(
        "Maintenance operation successful",
        context: backupLogContext
          .withPublic(key: "issues", value: String(maintenanceResult.issuesFound))
          .withPublic(key: "fixed", value: String(maintenanceResult.issuesFixed))
      )

      return .success((maintenanceResult, progressStream))

    } catch {
      // Map the error and log failure
      let backupError=errorMapper.mapError(error)
      await logError(
        "Maintenance operation failed: \(backupError.localizedDescription)",
        context: backupLogContext
      )

      // Ensure the progress stream is completed
      progressContinuation.finish()

      return .failure(backupError)
    }
  }
}
