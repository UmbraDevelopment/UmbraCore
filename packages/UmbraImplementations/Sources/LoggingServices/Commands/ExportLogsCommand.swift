import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

/**
 Command for exporting logs to a specific format.
 
 This command encapsulates the logic for exporting logs from a destination,
 following the command pattern architecture.
 */
public class ExportLogsCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Data
    
    /// The ID of the destination to export logs from
    private let destinationId: String
    
    /// Options for exporting logs
    private let options: ExportLogsOptionsDTO
    
    /**
     Initialises a new export logs command.
     
     - Parameters:
        - destinationId: The ID of the destination to export logs from
        - options: Options for exporting logs
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        destinationId: String,
        options: ExportLogsOptionsDTO = .default,
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.destinationId = destinationId
        self.options = options
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the export logs command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The exported log data
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LogContextDTO) async throws -> Data {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "exportLogs",
            destinationId: destinationId,
            additionalMetadata: [
                "exportFormat": (value: options.format.rawValue, privacyLevel: .public),
                "includeMetadata": (value: String(options.includeMetadata), privacyLevel: .public),
                "applyRedactionRules": (value: String(options.applyRedactionRules), privacyLevel: .public),
                "maxEntries": (value: options.maxEntries.map(String.init) ?? "unlimited", privacyLevel: .public),
                "sortOrder": (value: options.sortOrder.rawValue, privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logOperationStart(operation: "exportLogs", context: operationContext)
        
        do {
            // Check if destination exists
            guard let destination = await getDestination(id: destinationId) else {
                throw LoggingError.destinationNotFound(
                    "Cannot export logs for destination with ID \(destinationId): not found"
                )
            }
            
            // Export logs using provider
            let exportedData = try await provider.exportLogs(
                from: destination,
                options: options
            )
            
            // Log success
            await logOperationSuccess(
                operation: "exportLogs",
                context: operationContext,
                additionalMetadata: [
                    "exportedDataSize": (value: String(exportedData.count), privacyLevel: .public)
                ]
            )
            
            return exportedData
            
        } catch let error as LoggingError {
            // Log failure
            await logOperationFailure(
                operation: "exportLogs",
                error: error,
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.serialisationFailed(reason: error.localizedDescription)
            
            // Log failure
            await logOperationFailure(
                operation: "exportLogs",
                error: loggingError,
                context: operationContext
            )
            
            throw loggingError
        }
    }
}
