import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for archiving logs from a destination.
 
 This command encapsulates the logic for archiving logs with various options,
 following the command pattern architecture.
 */
public class ArchiveLogsCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = LogArchiveResultDTO
    
    /// The ID of the destination to archive logs from
    private let destinationId: String
    
    /// Options for archiving logs
    private let options: ArchiveLogsOptionsDTO
    
    /**
     Initialises a new archive logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to archive logs from
        - options: Options for archiving logs
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destinationId: String,
        options: ArchiveLogsOptionsDTO,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destinationId = destinationId
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the archive logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the archive operation
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> LogArchiveResultDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "archiveLogs",
            destinationId: destinationId,
            additionalMetadata: [
                "destinationPath": (value: options.destinationPath, privacyLevel: .protected),
                "compress": (value: String(options.compress), privacyLevel: .public),
                "format": (value: options.format.rawValue, privacyLevel: .public),
                "deleteAfterArchiving": (value: String(options.deleteAfterArchiving), privacyLevel: .public),
                "isEncrypted": (value: String(options.encryptionPassword != nil), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "archiveLogs", context: operationContext)
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingError.destinationNotFound(
                    "Cannot archive logs for destination with ID \(destinationId): not found"
                )
            }
            
            // Validate archive path
            if options.destinationPath.isEmpty {
                throw LoggingError.invalidDestinationConfig(
                    "Archive destination path cannot be empty"
                )
            }
            
            // Create directory for archive if it doesn't exist
            let archiveURL = URL(fileURLWithPath: options.destinationPath)
            let archiveDirectory = archiveURL.deletingLastPathComponent()
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: archiveDirectory.path) {
                do {
                    try fileManager.createDirectory(
                        at: archiveDirectory,
                        withIntermediateDirectories: true
                    )
                } catch {
                    throw LoggingError.writeFailure(
                        "Failed to create archive directory: \(error.localizedDescription)"
                    )
                }
            }
            
            // Archive logs using provider
            let archiveResult = try await provider.archiveLogs(
                from: destination,
                options: options
            )
            
            // Log success or failure based on archive result
            if archiveResult.success {
                await logOperationSuccess(
                    operation: "archiveLogs",
                    context: operationContext,
                    additionalMetadata: [
                        "archivePath": (value: archiveResult.archivePath ?? "unknown", privacyLevel: .protected),
                        "archiveSizeBytes": (value: String(archiveResult.archiveSizeBytes ?? 0), privacyLevel: .public),
                        "archivedEntryCount": (value: String(archiveResult.archivedEntryCount ?? 0), privacyLevel: .public)
                    ]
                )
            } else {
                await logger.log(
                    .warning,
                    "Log archiving completed with issues",
                    context: operationContext.withMetadata(
                        LogMetadataDTOCollection().withProtected(
                            key: "archiveError",
                            value: archiveResult.metadata["error"] ?? "Unknown error"
                        )
                    )
                )
            }
            
            return archiveResult
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "archiveLogs",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.writeFailure(error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "archiveLogs",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
}
