import BackupInterfaces
import Foundation
import LoggingInterfaces
import ResticInterfaces

/**
 Factory for creating backup command objects.

 This factory is responsible for creating specific command objects that encapsulate
 the logic for each backup operation, following the command pattern architecture.
 */
public struct BackupCommandFactory {
  /// Restic service for executing commands
  private let resticService: ResticServiceProtocol

  /// Repository connection information
  private let repositoryInfo: RepositoryInfo

  /// Factory for creating Restic commands
  private let resticCommandFactory: BackupCommandFactory

  /// Parser for command results
  private let resultParser: BackupResultParser

  /// Error mapper for translating errors
  private let errorMapper: BackupErrorMapper

  /// Logger for tracking operations
  private let logger: LoggingProtocol?

  /**
   Initialises a new backup command factory.

   - Parameters:
      - resticService: Service for executing Restic commands
      - repositoryInfo: Repository connection information
      - resticCommandFactory: Factory for creating Restic commands
      - resultParser: Parser for command results
      - errorMapper: Error mapper for translating errors
      - logger: Optional logger for tracking operations
   */
  public init(
    resticService: ResticServiceProtocol,
    repositoryInfo: RepositoryInfo,
    resticCommandFactory: BackupCommandFactory,
    resultParser: BackupResultParser,
    errorMapper: BackupErrorMapper,
    logger: LoggingProtocol?=nil
  ) {
    self.resticService=resticService
    self.repositoryInfo=repositoryInfo
    self.resticCommandFactory=resticCommandFactory
    self.resultParser=resultParser
    self.errorMapper=errorMapper
    self.logger=logger
  }

  /**
   Creates a command for creating a new backup.

   - Parameters:
      - parameters: Parameters for the backup creation
      - progressReporter: Reporter for tracking progress
      - cancellationToken: Optional token for cancelling the operation
   - Returns: A configured create backup command
   */
  public func createBackupCommand(
    parameters: BackupCreateParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) -> CreateBackupCommand {
    CreateBackupCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }

  /**
   Creates a command for restoring a backup.

   - Parameters:
      - parameters: Parameters for the backup restoration
      - progressReporter: Reporter for tracking progress
      - cancellationToken: Optional token for cancelling the operation
   - Returns: A configured restore backup command
   */
  public func createRestoreCommand(
    parameters: BackupRestoreParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) -> RestoreBackupCommand {
    RestoreBackupCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }

  /**
   Creates a command for listing backup snapshots.

   - Parameters:
      - parameters: Parameters for listing snapshots
   - Returns: A configured list snapshots command
   */
  public func createListSnapshotsCommand(
    parameters: BackupListSnapshotsParameters
  ) -> ListSnapshotsCommand {
    ListSnapshotsCommand(
      parameters: parameters,
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }

  /**
   Creates a command for deleting a backup.

   - Parameters:
      - parameters: Parameters for deleting a backup
      - progressReporter: Reporter for tracking progress
      - cancellationToken: Optional token for cancelling the operation
   - Returns: A configured delete backup command
   */
  public func createDeleteCommand(
    parameters: BackupDeleteParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) -> DeleteBackupCommand {
    DeleteBackupCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }

  /**
   Creates a command for performing maintenance on the backup repository.

   - Parameters:
      - parameters: Parameters for the maintenance operation
      - progressReporter: Reporter for tracking progress
      - cancellationToken: Optional token for cancelling the operation
   - Returns: A configured maintenance command
   */
  public func createMaintenanceCommand(
    parameters: BackupMaintenanceParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) -> MaintenanceCommand {
    MaintenanceCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }

  /**
   Creates a command for verifying a backup's integrity.

   - Parameters:
      - parameters: Parameters for backup verification
      - progressReporter: Reporter for tracking progress
      - cancellationToken: Optional token for cancelling the operation
   - Returns: A configured verify backup command
   */
  public func createVerifyCommand(
    parameters: BackupVerificationParameters,
    progressReporter: BackupProgressReporter?,
    cancellationToken: CancellationToken?
  ) -> VerifyBackupCommand {
    VerifyBackupCommand(
      parameters: parameters,
      progressReporter: progressReporter,
      cancellationToken: cancellationToken,
      resticService: resticService,
      repositoryInfo: repositoryInfo,
      commandFactory: resticCommandFactory,
      resultParser: resultParser,
      errorMapper: errorMapper,
      logger: logger
    )
  }
}
