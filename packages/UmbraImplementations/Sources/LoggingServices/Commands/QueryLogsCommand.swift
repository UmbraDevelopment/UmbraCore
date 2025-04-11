import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for querying logs from a destination.
 
 This command encapsulates the logic for retrieving and filtering logs,
 following the command pattern architecture.
 */
public class QueryLogsCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = [LogEntryDTO]
    
    /// The ID of the destination to query logs from
    private let destinationId: String
    
    /// Options for querying logs
    private let options: QueryLogsOptionsDTO
    
    /**
     Initialises a new query logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to query logs from
        - options: Options for querying logs
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destinationId: String,
        options: QueryLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destinationId = destinationId
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the query logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The matching log entries
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> [LogEntryDTO] {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "queryLogs",
            destinationId: destinationId,
            additionalMetadata: [
                "maxEntries": (value: options.maxEntries.map(String.init) ?? "unlimited", privacyLevel: .public),
                "offset": (value: String(options.offset), privacyLevel: .public),
                "sortOrder": (value: options.sortOrder.rawValue, privacyLevel: .public),
                "includeMetadata": (value: String(options.includeMetadata), privacyLevel: .public),
                "applyRedactionRules": (value: String(options.applyRedactionRules), privacyLevel: .public),
                "hasFilterCriteria": (value: String(options.filterCriteria != nil), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "queryLogs", context: operationContext)
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingError.destinationNotFound(
                    "Cannot query logs for destination with ID \(destinationId): not found"
                )
            }
            
            // Query logs using provider
            let logEntries = try await provider.queryLogs(
                from: destination,
                options: options
            )
            
            // Log success
            await logOperationSuccess(
                operation: "queryLogs",
                context: operationContext,
                additionalMetadata: [
                    "retrievedEntryCount": (value: String(logEntries.count), privacyLevel: .public)
                ]
            )
            
            return logEntries
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "queryLogs",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.serialisationFailed(reason: error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "queryLogs",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
}
