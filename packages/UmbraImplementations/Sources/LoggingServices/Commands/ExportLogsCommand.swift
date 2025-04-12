import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for exporting logs to a specific format.
 
 This command encapsulates the logic for exporting logs from a destination,
 following the command pattern architecture.
 */
public class ExportLogsCommand: BaseCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Data
    
    /// The ID of the destination to export logs from
    private let destinationId: String
    
    /// Options for exporting logs
    private let options: LoggingInterfaces.ExportLogsOptionsDTO
    
    /// Provider for logging operations
    private let provider: LoggingProviderProtocol
    
    /**
     Initialises a new export logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to export logs for
        - options: Options for exporting logs
        - provider: Provider for export operations
        - loggingServices: The logging services actor
     */
    public init(
        destinationId: String,
        options: LoggingInterfaces.ExportLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        loggingServices: LoggingServicesActor
    ) {
        self.destinationId = destinationId
        self.options = options
        self.provider = provider
        
        super.init(loggingServices: loggingServices)
    }
    
    /**
     Executes the export logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The exported log data
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LoggingInterfaces.LogContextDTO) async throws -> Data {
        // Create a log context for this specific operation
        let operationContext = LoggingInterfaces.BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "exportLogs",
            category: "LogExport",
            source: "UmbraCore",
            metadata: LoggingInterfaces.LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withPublic(key: "exportFormat", value: options.format.rawValue)
                .withPublic(key: "includeMetadata", value: String(options.includeMetadata))
                .withPublic(key: "applyRedactionRules", value: String(options.applyRedactionRules))
                .withPublic(key: "maxEntries", value: options.maxEntries.map(String.init) ?? "unlimited")
                .withPublic(key: "sortOrder", value: options.sortOrder.rawValue)
        )
        
        // Log operation start
        await logInfo("Starting log export operation for destination '\(destinationId)'")
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingInterfaces.LoggingError.destinationNotFound(
                    "Cannot export logs for destination with ID \(destinationId): not found"
                )
            }
            
            // Export logs using provider
            let exportedData = try await provider.exportLogs(
                from: destination,
                options: options
            )
            
            // Log success
            await logInfo("Successfully exported \(exportedData.count) bytes of log data in \(options.format.rawValue) format")
            
            return exportedData
            
        } catch {
            // Log failure
            await logError("Log export failed: \(error.localizedDescription)")
            throw error
        }
    }
}
