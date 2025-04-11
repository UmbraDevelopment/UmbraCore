import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Command for verifying a backup snapshot's integrity.

 This command encapsulates the logic for verifying the integrity of
 a backup snapshot by checking its data and metadata.
 */
public class VerifyBackupCommand: BaseBackupCommand, BackupCommand {
  /// The result type for this command
  public typealias ResultType=(BackupVerificationResultDTO, AsyncStream<BackupProgressInfo>)

  /// Parameters for backup verification
  private let parameters: BackupVerificationParameters

  /// Progress reporter for tracking progress
  private let progressReporter: BackupProgressReporter?

  /// Cancellation token for the operation
  private let cancellationToken: CancellationToken?

  /**
   Initialises a new verify backup command.

   - Parameters:
      - parameters: Parameters for backup verification
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
    parameters: BackupVerificationParameters,
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
   Executes the verify backup command.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  public func execute(
    context: LogContextDTO,
    operationID _: String
  ) async
    -> Result<
      (BackupVerificationResultDTO, AsyncStream<BackupProgressInfo>),
      BackupOperationError
    >
  {
    // Create the progress stream
    let (progressStream, progressContinuation)=createProgressStream()

    // Create a progress handler that forwards progress updates
    let progressHandler={ [progressReporter, progressContinuation] (
      progress: BackupProgressInfo
    ) async in
      if let reporter=progressReporter {
        await reporter.reportProgress(progress, for: .verifyBackup)
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
      .withPublic(key: "operation", value: "verifyBackup")
      .withPublic(key: "snapshotID", value: parameters.snapshotID)

    await logInfo("Starting backup verification", context: backupLogContext)

    do {
      // First, get the snapshot details to verify it exists
      let snapshotCommand=try commandFactory.createListSnapshotsCommand(
        path: nil,
        tags: nil,
        host: nil,
        snapshotID: parameters.snapshotID
      )

      let snapshotResult=try await resticService.execute(
        command: snapshotCommand,
        repository: repositoryInfo
      )

      let snapshots=try resultParser.parseSnapshotsList(output: snapshotResult)

      guard let snapshot=snapshots.first(where: { $0.id == parameters.snapshotID }) else {
        throw BackupError.snapshotNotFound(id: parameters.snapshotID)
      }

      // Create the verify command
      let command=try commandFactory.createVerifyCommand(
        snapshotID: parameters.snapshotID,
        options: parameters.verifyOptions
      )

      await logDebug("Executing verify command: \(command.description)", context: backupLogContext)

      // Execute the verify command with progress and cancellation support
      let result=try await resticService.executeWithProgress(
        command: command,
        repository: repositoryInfo,
        progressHandler: progressHandler,
        cancellationToken: cancellationToken
      )

      // Parse the result
      let verificationResult=try resultParser.parseVerificationResult(
        output: result,
        snapshotID: parameters.snapshotID
      )

      await logInfo(
        "Verification completed: \(verificationResult.verified ? "successful" : "issues found")",
        context: backupLogContext
          .withPublic(key: "verified", value: String(verificationResult.verified))
          .withPublic(key: "issueCount", value: String(verificationResult.issues.count))
      )

      return .success((verificationResult, progressStream))

    } catch {
      // Map the error and log failure
      let backupError=errorMapper.mapError(error)
      await logError(
        "Backup verification failed: \(backupError.localizedDescription)",
        context: backupLogContext
      )

      // Ensure the progress stream is completed
      progressContinuation.finish()

      return .failure(backupError)
    }
  }
}
