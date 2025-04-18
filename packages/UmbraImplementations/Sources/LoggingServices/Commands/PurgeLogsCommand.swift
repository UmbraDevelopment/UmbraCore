import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for purging logs from a destination.

 This command encapsulates the logic for purging logs with various options,
 following the command pattern architecture.
 */
public class PurgeLogsCommand: BaseCommand, LogCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// The ID of the destination to purge logs from, or nil for all destinations
  private let destinationID: String?

  /// Options for purging logs
  private let options: LoggingInterfaces.PurgeLogsOptionsDTO

  /// Provider for logging operations
  private let provider: LoggingProviderProtocol

  /**
   Initialises a new purge logs command.

   - Parameters:
      - destinationId: The ID of the destination to purge logs from, or nil for all destinations
      - options: Options for purging logs
      - provider: Provider for purge operations
      - loggingServices: The logging services actor
   */
  public init(
    destinationID: String?=nil,
    options: LoggingInterfaces.PurgeLogsOptionsDTO = .default,
    provider: LoggingProviderProtocol,
    loggingServices: LoggingServicesActor
  ) {
    self.destinationID=destinationID
    self.options=options
    self.provider=provider

    super.init(loggingServices: loggingServices)
  }

  /**
   Executes the purge logs command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: Whether the purge operation was successful
   - Throws: LoggingError if the operation fails
   */
  public func execute(context _: LoggingInterfaces.LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    _=LoggingInterfaces.BaseLogContextDTO(
      domainName: "LoggingServices",
      operation: "purgeLogs",
      category: "Command",
      source: "PurgeLogsCommand",
      metadata: LoggingInterfaces.LogMetadataDTOCollection()
    )

    // Log operation start
    await logInfo(
      "Starting log purge operation" +
        (destinationID != nil ? " for destination '\(destinationID!)'" : " for all destinations")
    )

    do {
      // Get target destinations
      let destinations=try await getTargetDestinations()

      if destinations.isEmpty {
        throw LoggingTypes.LoggingError.noDestinationsFound(
          "No destinations found for purging logs"
        )
      }

      // Create backup if requested and path is provided
      if options.createBackup && options.backupPath != nil {
        await createBackupBeforePurge(
          for: destinations,
          backupPath: options.backupPath!
        )
      }

      // Track overall success across all destinations
      var overallSuccess=true

      // Purge logs from each destination
      for destination in destinations {
        let success=try await provider.purgeLogs(
          from: destination,
          options: options
        )

        if success {
          await logInfo(
            "Successfully purged logs from destination: \(destination.name)"
          )
        } else {
          overallSuccess=false
          await logWarning(
            "Failed to purge logs from destination: \(destination.name)"
          )
        }
      }

      // Log final result
      if overallSuccess {
        await logInfo(
          "Log purge operation completed successfully for all \(destinations.count) destinations"
        )
      } else {
        await logWarning("Log purge operation completed with some failures")
      }

      return overallSuccess

    } catch {
      // Log failure
      await logError("Log purge operation failed: \(error.localizedDescription)")
      throw error
    }
  }

  // MARK: - Private Methods

  /**
   Gets the target destinations for purging logs.

   - Returns: The destinations to purge logs from
   - Throws: LoggingError if a specified destination isn't found
   */
  private func getTargetDestinations() async throws -> [LoggingInterfaces.LogDestinationDTO] {
    if let destinationID {
      // Use specific destination
      if let destination=await getDestination(id: destinationID) {
        return [destination]
      } else {
        throw LoggingTypes.LoggingError.noDestinationsFound(
          "Cannot purge logs for destination with ID \(destinationID): not found"
        )
      }
    } else if !options.destinationIDs.isEmpty {
      // Use specified list of destinations
      var result: [LoggingInterfaces.LogDestinationDTO]=[]

      for id in options.destinationIDs {
        if let destination=await getDestination(id: id) {
          result.append(destination)
        } else {
          // Log a warning that destination wasn't found
          await logWarning("Skipping unknown destination with ID \(id)")
        }
      }

      if result.isEmpty {
        throw LoggingTypes.LoggingError.noDestinationsFound(
          "None of the specified destinations could be found"
        )
      }

      return result
    } else {
      // Use all registered destinations
      return await getAllDestinations()
    }
  }

  /**
   Creates a backup of logs before purging.

   - Parameters:
      - destinations: The destinations to back up
      - backupPath: Path where the backup should be stored
   */
  private func createBackupBeforePurge(
    for _: [LoggingInterfaces.LogDestinationDTO],
    backupPath: String
  ) async {
    await logInfo("Creating backup before purge at path: \(backupPath)")

    // In a real implementation, this would create a backup of the logs
    // using the archive functionality or similar approach

    // For now, just log that we would create a backup
    await logInfo("Backup creation before purge is a placeholder in this implementation")
  }
}
