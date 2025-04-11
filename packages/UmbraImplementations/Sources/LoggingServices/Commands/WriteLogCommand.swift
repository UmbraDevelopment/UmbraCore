import Foundation
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Command for writing log entries to destinations.
 
 This command encapsulates the logic for writing log entries to configured
 destinations, following the command pattern architecture.
 */
public class WriteLogCommand: BaseLogCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The log entry to write
    private let entry: LogEntryDTO
    
    /// The destinations to write to (empty means all registered destinations)
    private let destinationIds: [String]
    
    /**
     Initialises a new write log command.
     
     - Parameters:
        - entry: The log entry to write
        - destinationIds: The destinations to write to (empty means all registered destinations)
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    public init(
        entry: LogEntryDTO,
        destinationIds: [String] = [],
        provider: LoggingProviderProtocol,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.entry = entry
        self.destinationIds = destinationIds
        
        super.init(provider: provider, logger: logger)
    }
    
    /**
     Executes the write log command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: Whether the write was successful
     - Throws: LoggingError if writing fails
     */
    public func execute(context: LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "writeLog",
            additionalMetadata: [
                "logLevel": (value: entry.level.rawValue, privacyLevel: .public),
                "category": (value: entry.category, privacyLevel: .public),
                "targetDestinations": (value: String(destinationIds.count), privacyLevel: .public)
            ]
        )
        
        // Log operation start (only when writing to system log)
        if entry.level == .debug || entry.level == .trace {
            await logOperationStart(operation: "writeLog", context: operationContext)
        }
        
        do {
            // Determine which destinations to write to
            let destinations = try getTargetDestinations()
            
            if destinations.isEmpty {
                // No eligible destinations found
                if entry.level == .debug || entry.level == .trace {
                    await logger.log(
                        .warning,
                        "No eligible destinations found for log entry",
                        context: operationContext
                    )
                }
                return true
            }
            
            // Write to each destination
            var allSuccessful = true
            
            for destination in destinations {
                if shouldWriteToDestination(destination) {
                    // Apply redaction if needed
                    let processedEntry = applyRedactionRules(
                        to: entry,
                        rules: destination.configuration.redactionRules
                    )
                    
                    // Write to destination using provider
                    let success = try await provider.writeLog(
                        entry: processedEntry,
                        to: destination
                    )
                    
                    if !success {
                        allSuccessful = false
                    }
                }
            }
            
            // Log success (only for debug/trace to avoid infinite recursion)
            if entry.level == .debug || entry.level == .trace {
                await logOperationSuccess(
                    operation: "writeLog",
                    context: operationContext,
                    additionalMetadata: [
                        "success": (value: String(allSuccessful), privacyLevel: .public)
                    ]
                )
            }
            
            return allSuccessful
            
        } catch let error as LoggingError {
            // Log failure (only for debug/trace to avoid infinite recursion)
            if entry.level == .debug || entry.level == .trace {
                await logOperationFailure(
                    operation: "writeLog",
                    error: error,
                    context: operationContext
                )
            }
            
            throw error
            
        } catch {
            // Map unknown error to LoggingError
            let loggingError = LoggingError.writeFailure(error.localizedDescription)
            
            // Log failure (only for debug/trace to avoid infinite recursion)
            if entry.level == .debug || entry.level == .trace {
                await logOperationFailure(
                    operation: "writeLog",
                    error: loggingError,
                    context: operationContext
                )
            }
            
            throw loggingError
        }
    }
    
    // MARK: - Private Methods
    
    /**
     Gets the target destinations for writing the log entry.
     
     - Returns: The destinations to write to
     - Throws: LoggingError if a specified destination isn't found
     */
    private func getTargetDestinations() throws -> [LogDestinationDTO] {
        if destinationIds.isEmpty {
            // Use all registered destinations
            return getAllDestinations().filter { $0.isEnabled }
        } else {
            // Use specific destinations
            var result: [LogDestinationDTO] = []
            
            for destinationId in destinationIds {
                if let destination = getDestination(id: destinationId) {
                    if destination.isEnabled {
                        result.append(destination)
                    }
                } else {
                    throw LoggingError.destinationNotFound("Destination not found: \(destinationId)")
                }
            }
            
            return result
        }
    }
    
    /**
     Determines if a log entry should be written to a destination based on
     log level and filter rules.
     
     - Parameters:
        - destination: The destination to check
     - Returns: Whether the entry should be written to the destination
     */
    private func shouldWriteToDestination(_ destination: LogDestinationDTO) -> Bool {
        // Check log level
        if entry.level.rawValue < destination.minimumLevel.rawValue {
            return false
        }
        
        // Apply filter rules if they exist
        return applyFilterRules(
            to: entry,
            rules: destination.configuration.filterRules
        )
    }
}
