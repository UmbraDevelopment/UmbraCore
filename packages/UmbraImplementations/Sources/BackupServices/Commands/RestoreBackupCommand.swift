import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Command for restoring a backup from a snapshot.

 This command encapsulates the logic for restoring files from a
 backup snapshot to a specified destination path.
 */
public class RestoreBackupCommand: BaseBackupCommand, BackupCommand {
  /// The result type for this command
  public typealias ResultType=(RestoreResult, AsyncStream<BackupProgressInfo>)

  /// Parameters for backup restoration
  private let parameters: BackupRestoreParameters

  /// Progress reporter for tracking progress
  private let progressReporter: BackupProgressReporter?

  /// Cancellation token for the operation
  private let cancellationToken: CancellationToken?

  /**
   Initialises a new restore backup command.

   - Parameters:
      - parameters: Parameters for backup restoration
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
    parameters: BackupRestoreParameters,
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
   Executes the restore backup command.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  public func execute(
    context: LogContextDTO,
    operationID _: String
  ) async -> Result<(RestoreResult, AsyncStream<BackupProgressInfo>), BackupOperationError> {
    // Create the progress stream
    let (progressStream, progressContinuation)=createProgressStream()

    // Create a progress handler that forwards progress updates
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .restoreBackup)
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
      .withPublic(key: "operation", value: "restoreBackup")
      .withPublic(key: "snapshotID", value: parameters.snapshotID)
      .withPrivate(key: "targetPath", value: parameters.targetPath.path)

    if let includePaths=parameters.includePaths, !includePaths.isEmpty {
      _=backupLogContext.withPrivate(
        key: "includePaths",
        value: includePaths.map(\.path).joined(separator: ", ")
      )
    }

    await logInfo("Starting backup restoration", context: backupLogContext)

    do {
      // Create the restore command
      let command=try commandFactory.createRestoreCommand(
        snapshotID: parameters.snapshotID,
        targetPath: parameters.targetPath,
        includePaths: parameters.includePaths,
        excludePaths: parameters.excludePaths,
        options: parameters.options
      )

      await logDebug("Executing restore command: \(command.description)", context: backupLogContext)

      // Execute the restore command with progress and cancellation support
      let result=try await resticService.executeWithProgress(
        command: command,
        repository: repositoryInfo,
        progressHandler: progressHandler,
        cancellationToken: cancellationToken
      )

      // Parse the result
      let restoreResult=try resultParser.parseRestoreResult(
        output: result,
        snapshotID: parameters.snapshotID,
        targetPath: parameters.targetPath
      )

      await logInfo(
        "Restore successful: restored \(restoreResult.restoredFiles) files",
        context: backupLogContext.withPublic(
          key: "restoredFiles",
          value: String(restoreResult.restoredFiles)
        )
        .withPublic(key: "targetPath", value: parameters.targetPath.lastPathComponent)
      )

      return .success((restoreResult, progressStream))

    } catch {
      // Map the error and log failure
      let backupError=errorMapper.mapError(error)
      await logError(
        "Backup restoration failed: \(backupError.localizedDescription)",
        context: backupLogContext
      )

      // Ensure the progress stream is completed
      progressContinuation.finish()

      return .failure(backupError)
    }
  }
}
