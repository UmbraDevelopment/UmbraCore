import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for purging logs from a destination.
 
 This command encapsulates the logic for purging logs with various options,
 following the command pattern architecture.
 */
public class PurgeLogsCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = LogPurgeResultDTO
    
    /// The ID of the destination to purge logs from, or nil for all destinations
    private let destinationId: String?
    
    /// Options for purging logs
    private let options: PurgeLogsOptionsDTO
    
    /**
     Initialises a new purge logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to purge logs from, or nil for all destinations
        - options: Options for purging logs
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destinationId: String? = nil,
        options: PurgeLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destinationId = destinationId
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the purge logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the purge operation
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> LogPurgeResultDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "purgeLogs",
            destinationId: destinationId,
            additionalMetadata: [
                "createBackup": (value: String(options.createBackup), privacyLevel: .public),
                "backupPath": (value: options.backupPath ?? "none", privacyLevel: .protected),
                "dryRun": (value: String(options.dryRun), privacyLevel: .public),
                "hasFilterCriteria": (value: String(options.filterCriteria != nil), privacyLevel: .public),
                "targetDestinations": (value: String(options.destinationIds.count), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "purgeLogs", context: operationContext)
        
        do {
            // Get target destinations
            let destinations = try await getTargetDestinations()
            
            if destinations.isEmpty {
                throw LoggingError.noDestinationsFound(
                    "No destinations found for purging logs"
                )
            }
            
            // Create backup if requested and path is provided
            if options.createBackup && options.backupPath != nil {
                await createBackupBeforePurge(
                    for: destinations,
                    context: operationContext
                )
            }
            
            // Count of purged entries across all destinations
            var totalPurgedEntryCount = 0
            var totalPurgedSizeBytes: UInt64 = 0
            
            // Purge logs from each destination
            for destination in destinations {
                let purgeResult = try await provider.purgeLogs(
                    from: destination,
                    options: options
                )
                
                if purgeResult.success {
                    totalPurgedEntryCount += purgeResult.purgedEntryCount ?? 0
                    totalPurgedSizeBytes += purgeResult.purgedSizeBytes ?? 0
                    
                    await logger.log(
                        .info,
                        "Successfully purged logs from destination: \(destination.name)",
                        context: operationContext.withMetadata(
                            LogMetadataDTOCollection().withPublic(
                                key: "purgedEntryCount",
                                value: String(purgeResult.purgedEntryCount ?? 0)
                            )
                        )
                    )
                } else {
                    await logger.log(
                        .warning,
                        "Failed to purge logs from destination: \(destination.name)",
                        context: operationContext.withMetadata(
                            LogMetadataDTOCollection().withProtected(
                                key: "purgeError",
                                value: purgeResult.metadata["error"] ?? "Unknown error"
                            )
                        )
                    )
                }
            }
            
            // Create aggregate result
            let result = LogPurgeResultDTO(
                success: true,
                purgedEntryCount: totalPurgedEntryCount,
                purgedSizeBytes: totalPurgedSizeBytes,
                backupPath: options.backupPath,
                wasDryRun: options.dryRun,
                metadata: ["destinationCount": String(destinations.count)]
            )
            
            // Log success
            await logOperationSuccess(
                operation: "purgeLogs",
                context: operationContext,
                additionalMetadata: [
                    "totalPurgedEntryCount": (value: String(totalPurgedEntryCount), privacyLevel: .public),
                    "totalPurgedSizeBytes": (value: String(totalPurgedSizeBytes), privacyLevel: .public),
                    "wasDryRun": (value: String(options.dryRun), privacyLevel: .public)
                ]
            )
            
            return result
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "purgeLogs",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.initialisationFailed(reason: error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "purgeLogs",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Gets the target destinations for purging logs.
     
     - Returns: The destinations to purge logs from
     - Throws: LoggingError if a specified destination isn't found
     */
    private func getTargetDestinations() async throws -> [LogDestinationDTO] {
        if let destinationId = destinationId {
            // Use specific destination
            if let destination = await getDestination(id: destinationId) {
                return [destination]
            } else {
                throw LoggingError.destinationNotFound(
                    "Cannot purge logs for destination with ID \(destinationId): not found"
                )
            }
        } else if !options.destinationIds.isEmpty {
            // Use specified list of destinations
            var result: [LogDestinationDTO] = []
            
            for id in options.destinationIds {
                if let destination = await getDestination(id: id) {
                    result.append(destination)
                } else {
                    // Log a warning that destination wasn't found
                    await logWarning("Skipping unknown destination with ID \(id)")
                }
            }
            
            if result.isEmpty {
                throw LoggingError.noDestinationsFound(
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
     Creates a backup before purging logs.
     
     - Parameters:
        - destinations: The destinations to back up
        - context: The logging context for the operation
     - Throws: LoggingError if backup fails
     */
    private func createBackupBeforePurge(
        for destinations: [LogDestinationDTO],
        context: LogContextDTO
    ) async {
        guard let backupPath = options.backupPath else {
            await logger.log(
                .warning,
                "Cannot create backup: no backup path specified",
                context: context
            )
            return
        }
        
        await logger.log(
            .info,
            "Creating backup before purging logs",
            context: context.withMetadata(
                LogMetadataDTOCollection().withProtected(
                    key: "backupPath",
                    value: backupPath
                )
            )
        )
        
        for destination in destinations {
            do {
                let archiveOptions = ArchiveLogsOptionsDTO(
                    destinationPath: backupPath,
                    compress: true,
                    format: .zip,
                    filterCriteria: options.filterCriteria,
                    deleteAfterArchiving: false
                )
                
                let archiveCommand = ArchiveLogsCommand(
                    destinationId: destination.id,
                    options: archiveOptions,
                    provider: provider,
                    logger: logger
                )
                
                _ = try await archiveCommand.execute(context: context)
                
                await logger.log(
                    .info,
                    "Successfully backed up destination: \(destination.name)",
                    context: context
                )
                
            } catch {
                await logger.log(
                    .warning,
                    "Failed to back up destination: \(destination.name) - \(error.localizedDescription)",
                    context: context
                )
            }
        }
    }
}
