import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for archiving logs from a destination.
 
 This command encapsulates the logic for creating archives of logs from a destination,
 following the command pattern architecture.
 */
public class ArchiveLogsCommand: BaseCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The ID of the destination to archive logs from
    private let destinationId: String
    
    /// Options for archiving logs
    private let options: LoggingInterfaces.ArchiveLogsOptionsDTO
    
    /// Provider for logging operations
    private let provider: LoggingProviderProtocol
    
    /**
     Initialises a new archive logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to archive logs for
        - options: Options for archiving logs
        - provider: Provider for archive operations
        - loggingServices: The logging services actor
     */
    public init(
        destinationId: String,
        options: LoggingInterfaces.ArchiveLogsOptionsDTO,
        provider: LoggingProviderProtocol,
        loggingServices: LoggingServicesActor
    ) {
        self.destinationId = destinationId
        self.options = options
        self.provider = provider
        
        super.init(loggingServices: loggingServices)
    }
    
    /**
     Executes the archive logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LoggingInterfaces.LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = LoggingInterfaces.BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "archiveLogs",
            category: "LogArchiving",
            source: "UmbraCore",
            metadata: LoggingInterfaces.LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withPublic(key: "archivePath", value: options.destinationPath)
                .withPublic(key: "format", value: options.format.rawValue)
                .withPublic(key: "compress", value: String(options.compress))
        )
        
        // Log operation start
        await logInfo("Starting log archive operation for destination '\(destinationId)'")
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingTypes.LoggingError.destinationNotFound("Destination with ID \(destinationId) not found")
            }
            
            // Validate archive path
            if options.destinationPath.isEmpty {
                throw LoggingTypes.LoggingError.invalidDestinationConfig(
                    "Archive destination path cannot be empty"
                )
            }
            
            // Check if archive directory exists, create if necessary
            let fileManager = FileManager.default
            let archiveURL = URL(fileURLWithPath: options.destinationPath)
            let directoryURL = archiveURL.deletingLastPathComponent()
            
            if !fileManager.fileExists(atPath: directoryURL.path) {
                do {
                    try fileManager.createDirectory(
                        at: directoryURL,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                } catch {
                    throw LoggingTypes.LoggingError.writeFailure(
                        "Failed to create archive directory: \(error.localizedDescription)"
                    )
                }
            }
            
            // Archive logs using provider
            let success = try await provider.archiveLogs(
                from: destination,
                options: options
            )
            
            // Log success or failure
            if success {
                await logInfo("Successfully archived logs from destination '\(destinationId)'")
            } else {
                await logWarning("Failed to archive logs from destination '\(destinationId)'")
            }
            
            return success
            
        } catch {
            // Log failure
            await logError("Log archive operation failed: \(error.localizedDescription)")
            throw error
        }
    }
}
