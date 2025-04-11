import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Command for creating a new backup.

 This command encapsulates the logic for creating a new backup with the
 specified source paths, exclusions, and tags.
 */
public class CreateBackupCommand: BaseBackupCommand, BackupCommand {
  /// The result type for this command
  public typealias ResultType=(BackupResult, AsyncStream<BackupProgressInfo>)

  /// Parameters for backup creation
  private let parameters: BackupCreateParameters

  /// Progress reporter for tracking progress
  private let progressReporter: BackupProgressReporter?

  /// Cancellation token for the operation
  private let cancellationToken: CancellationToken?

  /**
   Initialises a new create backup command.

   - Parameters:
      - parameters: Parameters for backup creation
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
    parameters: BackupCreateParameters,
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
   Executes the create backup command.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  public func execute(
    context: LogContextDTO,
    operationID _: String
  ) async -> Result<(BackupResult, AsyncStream<BackupProgressInfo>), BackupOperationError> {
    // Create the progress stream
    let (progressStream, progressContinuation)=createProgressStream()

    // Create a progress handler that forwards progress updates
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .createBackup)
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
      .withPublic(key: "operation", value: "createBackup")
      .withPrivate(key: "sources", value: parameters.sources.map(\.path).joined(separator: ", "))
      .withPublic(key: "sourceCount", value: String(parameters.sources.count))

    if let tags=parameters.tags {
      _=backupLogContext.withPublic(key: "tags", value: tags.joined(separator: ", "))
    }

    await logInfo("Starting backup creation", context: backupLogContext)

    do {
      // Create the backup command
      let command=try commandFactory.createBackupCommand(
        sources: parameters.sources,
        excludePaths: parameters.excludePaths,
        tags: parameters.tags,
        options: parameters.options
      )

      await logDebug("Executing backup command: \(command.description)", context: backupLogContext)

      // Execute the backup command with progress and cancellation support
      let result=try await resticService.executeWithProgress(
        command: command,
        repository: repositoryInfo,
        progressHandler: progressHandler,
        cancellationToken: cancellationToken
      )

      // Parse the result
      let backupResult=try resultParser.parseBackupResult(output: result)

      await logInfo(
        "Backup successful: created snapshot \(backupResult.snapshotID)",
        context: backupLogContext.withPublic(key: "snapshotID", value: backupResult.snapshotID)
      )

      return .success((backupResult, progressStream))

    } catch {
      // Map the error and log failure
      let backupError=errorMapper.mapError(error)
      await logError(
        "Backup creation failed: \(backupError.localizedDescription)",
        context: backupLogContext
      )

      // Ensure the progress stream is completed
      progressContinuation.finish()

      return .failure(backupError)
    }
  }
}
