import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Command for deleting a backup snapshot.

 This command encapsulates the logic for deleting a backup snapshot
 from the repository by its ID or matching criteria.
 */
public class DeleteBackupCommand: BaseBackupCommand, BackupCommand {
  /// The result type for this command
  public typealias ResultType=(DeleteResult, AsyncStream<BackupProgressInfo>)

  /// Parameters for deleting a backup
  private let parameters: BackupDeleteParameters

  /// Progress reporter for tracking progress
  private let progressReporter: BackupProgressReporter?

  /// Cancellation token for the operation
  private let cancellationToken: CancellationToken?

  /**
   Initialises a new delete backup command.

   - Parameters:
      - parameters: Parameters for deleting a backup
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
    parameters: BackupDeleteParameters,
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
   Executes the delete backup command.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  public func execute(
    context: LogContextDTO,
    operationID _: String
  ) async -> Result<(DeleteResult, AsyncStream<BackupProgressInfo>), BackupOperationError> {
    // Create the progress stream
    let (progressStream, progressContinuation)=createProgressStream()

    // Create a progress handler that forwards progress updates
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .deleteBackup)
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
      .withPublic(key: "operation", value: "deleteBackup")

    if let snapshotID=parameters.snapshotID {
      _=backupLogContext.withPublic(key: "snapshotID", value: snapshotID)
    }

    if let tags=parameters.tags, !tags.isEmpty {
      _=backupLogContext.withPublic(key: "tags", value: tags.joined(separator: ", "))
    }

    await logInfo("Starting backup deletion", context: backupLogContext)

    do {
      // Create the delete command
      let command=try commandFactory.createDeleteCommand(
        snapshotID: parameters.snapshotID,
        tags: parameters.tags,
        host: parameters.host,
        options: parameters.options
      )

      await logDebug("Executing delete command: \(command.description)", context: backupLogContext)

      // Execute the delete command with progress and cancellation support
      let result=try await resticService.executeWithProgress(
        command: command,
        repository: repositoryInfo,
        progressHandler: progressHandler,
        cancellationToken: cancellationToken
      )

      // Parse the result
      let deleteResult=try resultParser.parseDeleteResult(
        output: result,
        snapshotID: parameters.snapshotID ?? "multiple snapshots"
      )

      await logInfo(
        "Delete successful: removed \(deleteResult.deletedSnapshots) snapshots",
        context: backupLogContext.withPublic(
          key: "deletedSnapshots",
          value: String(deleteResult.deletedSnapshots)
        )
      )

      return .success((deleteResult, progressStream))

    } catch {
      // Map the error and log failure
      let backupError=errorMapper.mapError(error)
      await logError(
        "Backup deletion failed: \(backupError.localizedDescription)",
        context: backupLogContext
      )

      // Ensure the progress stream is completed
      progressContinuation.finish()

      return .failure(backupError)
    }
  }
}
