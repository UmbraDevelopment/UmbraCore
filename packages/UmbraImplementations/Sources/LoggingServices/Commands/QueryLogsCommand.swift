import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 Command for querying logs from a destination.
 
 This command encapsulates the logic for querying logs from a destination,
 applying any filtering rules defined in the query options.
 */
public class QueryLogsCommand: BaseCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = [LoggingInterfaces.LogEntryDTO]
    
    /// The ID of the destination to query logs from
    private let destinationId: String
    
    /// Options for querying logs
    private let options: LoggingInterfaces.QueryLogsOptionsDTO
    
    /// Provider for logging operations
    private let provider: LoggingProviderProtocol
    
    /**
     Initialises a new query logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to query logs from
        - options: Options for querying logs
        - provider: The logging provider
        - loggingServices: The logging services actor
     */
    public init(
        destinationId: String,
        options: LoggingInterfaces.QueryLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        loggingServices: LoggingServicesActor
    ) {
        self.destinationId = destinationId
        self.options = options
        self.provider = provider
        
        super.init(loggingServices: loggingServices)
    }
    
    /**
     Executes the command to query logs from the destination.
     
     - Parameter context: The context for this command execution
     - Returns: The log entries matching the query
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LoggingInterfaces.LogContextDTO) async throws -> [LoggingInterfaces.LogEntryDTO] {
        // Create a log context for this specific operation
        let operationContext = LoggingInterfaces.BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "queryLogs",
            category: "LogQuery",
            source: "UmbraCore",
            metadata: LoggingInterfaces.LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destinationId)
                .withPublic(key: "maxEntries", value: options.maxEntries.map(String.init) ?? "unlimited")
                .withPublic(key: "offset", value: String(options.offset))
                .withPublic(key: "sortOrder", value: options.sortOrder.rawValue)
                .withPublic(key: "includeMetadata", value: String(options.includeMetadata))
                .withPublic(key: "applyRedactionRules", value: String(options.applyRedactionRules))
        )
        
        await logInfo("Starting log query for destination '\(destinationId)'")
        
        do {
            // Get the destination
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingInterfaces.LoggingError.destinationNotFound("Destination with ID '\(destinationId)' not found")
            }
            
            // Query logs from the destination
            let entries = try await provider.queryLogs(
                from: destination,
                options: options
            )
            
            // Log success
            await logInfo("Query completed successfully, retrieved \(entries.count) log entries")
            
            return entries
            
        } catch {
            // Log failure
            await logError("Log query failed: \(error.localizedDescription)")
            throw error
        }
    }
}
