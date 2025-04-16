import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Command for creating a backup of the database.

 This command encapsulates the logic for backing up data with support for
 different backup mechanisms including Restic, following the command pattern architecture.
 */
public class CreateBackupCommand: BasePersistenceCommand, PersistenceCommand {
  /// The result type for this command
  public typealias ResultType=BackupResultDTO

  /// Options for the backup
  private let options: BackupOptionsDTO

  /**
   Initialises a new create backup command.

   - Parameters:
      - options: Options for the backup
      - provider: Provider for persistence operations
      - logger: Logger instance for logging operations
   */
  public init(
    options: BackupOptionsDTO = .default,
    provider: PersistenceProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.options=options
    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the create backup command.

   - Parameters:
      - context: The persistence context for the operation
   - Returns: The result of the backup operation
   - Throws: PersistenceError if the operation fails
   */
  public func execute(context _: PersistenceContextDTO) async throws -> BackupResultDTO {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "createBackup",
      entityType: "Database",
      additionalMetadata: [
        ("backupType", (value: options.type.rawValue, privacyLevel: .public)),
        ("compress", (value: String(options.compress), privacyLevel: .public)),
        ("encrypt", (value: String(options.encrypt), privacyLevel: .public)),
        ("verify", (value: String(options.verify), privacyLevel: .public)),
        ("timestamp", (value: "\(Date())", privacyLevel: .public))
      ]
    )

    // Add repository location with protected privacy level if available
    var contextWithRepo=operationContext
    if let repoLocation=options.repositoryLocation {
      contextWithRepo=operationContext.withMetadata(
        LogMetadataDTOCollection().withProtected(
          key: "repositoryLocation",
          value: repoLocation
        )
      )
    }

    // Log operation start
    await logOperationStart(operation: "createBackup", context: contextWithRepo)

    do {
      // Prepare database for backup (e.g., flush any pending writes)
      do {
        _=try await provider.prepareForBackup()

        await logger.log(
          .debug,
          "Database successfully prepared for backup",
          context: contextWithRepo
        )
      } catch {
        throw PersistenceError.backupFailed(
          "Failed to prepare database for backup: \(error.localizedDescription)"
        )
      }

      // Start time measurement
      let startTime=Date()

      // Create backup using provider
      let backupResult=try await provider.createBackup(options: options)

      // Log success or warnings
      if backupResult.success {
        var successMetadata: [(key: String, value: (value: String, privacyLevel: PrivacyLevel))]=[
          ("backupId", (value: backupResult.backupID ?? "unknown", privacyLevel: .public)),
          (
            "executionTime",
            (value: String(format: "%.3f", backupResult.executionTime), privacyLevel: .public)
          )
        ]

        if let sizeBytes=backupResult.sizeBytes {
          successMetadata.append(("sizeBytes", (value: String(sizeBytes), privacyLevel: .public)))
        }

        if let fileCount=backupResult.fileCount {
          successMetadata.append(("fileCount", (value: String(fileCount), privacyLevel: .public)))
        }

        if let location=backupResult.location {
          successMetadata.append(("location", (value: location, privacyLevel: .protected)))
        }

        // Log any warnings
        if !backupResult.warnings.isEmpty {
          await logger.log(
            .warning,
            "Backup completed with warnings: \(backupResult.warnings.joined(separator: "; "))",
            context: contextWithRepo
          )
        }

        await logOperationSuccess(
          operation: "createBackup",
          context: contextWithRepo,
          additionalMetadata: successMetadata
        )
      } else if let error=backupResult.error {
        await logOperationFailure(
          operation: "createBackup",
          error: PersistenceError.backupFailed(error),
          context: contextWithRepo
        )
      }

      return backupResult

    } catch let error as PersistenceError {
      // Log failure
      await logOperationFailure(
        operation: "createBackup",
        error: error,
        context: contextWithRepo
      )

      throw error

    } catch {
      // Map unknown error to PersistenceError
      let persistenceError=PersistenceError.backupFailed(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "createBackup",
        error: persistenceError,
        context: contextWithRepo
      )

      throw persistenceError
    }
  }
}
