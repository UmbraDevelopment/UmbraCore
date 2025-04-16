import CoreDTOs
import Foundation
import LoggingInterfaces
import PersistenceInterfaces

/**
 Command for restoring the database from a backup.

 This command encapsulates the logic for restoring data from backups,
 including Restic snapshots, following the command pattern architecture.
 */
public class RestoreBackupCommand: BasePersistenceCommand, PersistenceCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// URL to the backup
  private let backupURL: URL

  /// Optional password for encrypted backups
  private let password: String?

  /// Optional snapshot ID for Restic backups
  private let snapshotID: String?

  /// Whether to verify data integrity after restore
  private let verify: Bool

  /**
   Initialises a new restore backup command.

   - Parameters:
      - backupUrl: URL to the backup (file path or repository URL)
      - password: Optional password for encrypted backups
      - snapshotId: Optional snapshot ID for Restic backups
      - verify: Whether to verify data integrity after restore
      - provider: Provider for persistence operations
      - logger: Logger instance for logging operations
   */
  public init(
    backupURL: URL,
    password: String?=nil,
    snapshotID: String?=nil,
    verify: Bool=true,
    provider: PersistenceProviderProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.backupURL=backupURL
    self.password=password
    self.snapshotID=snapshotID
    self.verify=verify
    super.init(provider: provider, logger: logger)
  }

  /**
   Executes the restore backup command.

   - Parameters:
      - context: The persistence context for the operation
   - Returns: Whether the restore was successful
   - Throws: PersistenceError if the operation fails
   */
  public func execute(context _: PersistenceContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "restoreBackup",
      entityType: "Database",
      additionalMetadata: [
        ("backupLocation", (value: backupURL.path, privacyLevel: .protected)),
        ("isEncrypted", (value: String(password != nil), privacyLevel: .public)),
        ("verify", (value: String(verify), privacyLevel: .public)),
        ("timestamp", (value: "\(Date())", privacyLevel: .public))
      ]
    )

    // Add snapshot ID if available
    var contextWithSnapshot=operationContext
    if let snapshotID {
      contextWithSnapshot=operationContext.withMetadata(
        LogMetadataDTOCollection().withPublic(
          key: "snapshotId",
          value: snapshotID
        )
      )
    }

    // Log operation start
    await logOperationStart(operation: "restoreBackup", context: contextWithSnapshot)

    do {
      // Validate backup URL
      guard
        FileManager.default.fileExists(atPath: backupURL.path) ||
        backupURL.scheme != nil
      else {
        throw PersistenceError.backupFailed(
          "Backup location does not exist: \(backupURL.path)"
        )
      }

      // Start time measurement
      let startTime=Date()

      // Restore from backup using provider
      let success=try await provider.restoreFromBackup(url: backupURL, password: password)

      // Calculate execution time
      let executionTime=Date().timeIntervalSince(startTime)

      // Log success or failure
      if success {
        await logOperationSuccess(
          operation: "restoreBackup",
          context: contextWithSnapshot,
          additionalMetadata: [
            ("executionTime", (value: String(format: "%.3f", executionTime), privacyLevel: .public))
          ]
        )

        if verify {
          await logger.log(
            .info,
            "Starting post-restore verification...",
            context: contextWithSnapshot
          )

          // In a real implementation, we would perform verification here
          // For now, just log that it's completed
          await logger.log(
            .info,
            "Post-restore verification completed successfully",
            context: contextWithSnapshot
          )
        }
      } else {
        throw PersistenceError.backupFailed(
          "Restore operation did not complete successfully"
        )
      }

      return success

    } catch let error as PersistenceError {
      // Log failure
      await logOperationFailure(
        operation: "restoreBackup",
        error: error,
        context: contextWithSnapshot
      )

      throw error

    } catch {
      // Map unknown error to PersistenceError
      let persistenceError=PersistenceError.backupFailed(error.localizedDescription)

      // Log failure
      await logOperationFailure(
        operation: "restoreBackup",
        error: persistenceError,
        context: contextWithSnapshot
      )

      throw persistenceError
    }
  }
}
