import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/**
 Command for listing available backup snapshots.

 This command encapsulates the logic for retrieving a list of available
 backup snapshots from the repository.
 */
public class ListSnapshotsCommand: BaseBackupCommand, BackupCommand {
  /// The result type for this command
  public typealias ResultType=[BackupSnapshot]

  /// Parameters for listing snapshots
  private let parameters: BackupListSnapshotsParameters

  /**
   Initialises a new list snapshots command.

   - Parameters:
      - parameters: Parameters for listing snapshots
      - resticService: Service for executing Restic commands
      - repositoryInfo: Repository connection information
      - commandFactory: Factory for creating Restic commands
      - resultParser: Parser for command results
      - errorMapper: Error mapper for translating errors
      - logger: Optional logger for tracking operations
   */
  public init(
    parameters: BackupListSnapshotsParameters,
    resticService: ResticServiceProtocol,
    repositoryInfo: RepositoryInfo,
    commandFactory: BackupCommandFactory,
    resultParser: BackupResultParser,
    errorMapper: BackupErrorMapper,
    logger: LoggingProtocol?=nil
  ) {
    self.parameters=parameters

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
   Executes the list snapshots command.

   - Parameters:
      - context: The logging context for the operation
      - operationID: A unique identifier for this operation instance
   - Returns: The result of the operation
   */
  public func execute(
    context: LogContextDTO,
    operationID: String
  ) async -> Result<[BackupSnapshot], BackupOperationError> {
    // Enhance the log context with specific operation details
    let backupLogContext=context
      .withPublic(key: "operationID", value: operationID)
      .withPublic(key: "operation", value: "listSnapshots")

    if let path=parameters.path {
      _=backupLogContext.withPrivate(key: "path", value: path)
    }

    if let tags=parameters.tags, !tags.isEmpty {
      _=backupLogContext.withPublic(key: "tags", value: tags.joined(separator: ", "))
    }

    await logInfo("Listing backup snapshots", context: backupLogContext)

    do {
      // Create the list snapshots command
      let command=try commandFactory.createListSnapshotsCommand(
        path: parameters.path,
        tags: parameters.tags,
        host: parameters.host
      )

      await logDebug(
        "Executing list snapshots command: \(command.description)",
        context: backupLogContext
      )

      // Execute the command
      let result=try await resticService.execute(
        command: command,
        repository: repositoryInfo
      )

      // Parse the result
      let snapshots=try resultParser.parseSnapshotsList(output: result)

      await logInfo(
        "Successfully retrieved \(snapshots.count) snapshots",
        context: backupLogContext.withPublic(key: "snapshotCount", value: String(snapshots.count))
      )

      return .success(snapshots)

    } catch {
      // Map the error and log failure
      let backupError=errorMapper.mapError(error)
      await logError(
        "Listing snapshots failed: \(backupError.localizedDescription)",
        context: backupLogContext
      )

      return .failure(backupError)
    }
  }
}
