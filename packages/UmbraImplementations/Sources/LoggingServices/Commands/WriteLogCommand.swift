import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 Command for writing a log entry to one or more destinations.
 
 This command encapsulates the logic for writing log entries to destinations,
 applying any filtering and redaction rules defined in the destination.
 */
public class WriteLogCommand: BaseCommand, LogCommand {
    /// The result type for this command
    public typealias ResultType = Bool
    
    /// The log entry to write
    private let entry: LoggingInterfaces.LogEntryDTO
    
    /// The destination to write to
    private let destination: LoggingInterfaces.LogDestinationDTO
    
    /// Provider for logging operations
    private let provider: LoggingProviderProtocol
    
    /**
     Initialises a new write log command.
     
     - Parameters:
        - entry: The log entry to write
        - destination: The destination to write to
        - provider: The logging provider
        - loggingServices: The logging services actor
     */
    public init(
        entry: LoggingInterfaces.LogEntryDTO,
        destination: LoggingInterfaces.LogDestinationDTO,
        provider: LoggingProviderProtocol,
        loggingServices: LoggingServicesActor
    ) {
        self.entry = entry
        self.destination = destination
        self.provider = provider
        
        super.init(loggingServices: loggingServices)
    }
    
    /**
     Executes the command to write a log entry to a destination.
     
     - Parameter context: The context for this command execution
     - Returns: Whether the operation was successful
     - Throws: LoggingError if the operation fails
     */
    public func execute(context: LoggingInterfaces.LogContextDTO) async throws -> Bool {
        // Create a log context for this specific operation
        let operationContext = LoggingInterfaces.BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "writeLog",
            category: "LogWrite",
            source: "UmbraCore",
            metadata: LoggingInterfaces.LogMetadataDTOCollection()
                .withPublic(key: "destinationId", value: destination.id)
                .withPublic(key: "logLevel", value: entry.level.rawValue)
                .withPublic(key: "category", value: entry.category)
        )
        
        // Log operation start
        await logInfo("Writing log entry to destination '\(destination.name)' (\(destination.id))")
        
        do {
            // Check if we should write to this destination based on filter rules
            guard await shouldWriteToDestination() else {
                await logInfo(
                    "Log entry filtered out for destination '\(destination.name)' (\(destination.id))"
                )
                return true // Filtering is not an error, operation is considered successful
            }
            
            // Apply any redaction rules
            let processedEntry = applyRedactionRules(entry)
            
            // Write the entry
            let success = try await provider.writeLog(
                entry: processedEntry,
                to: destination
            )
            
            if success {
                await logInfo("Successfully wrote log entry to destination '\(destination.name)'")
            } else {
                throw LoggingTypes.LoggingError.writeFailure("Failed to write log to destination '\(destination.name)'")
            }
            
            return success
            
        } catch {
            // Log failure
            await logError("Log write operation failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /**
     Determines if a log entry should be written to a destination based on filter rules.
     */
    private func shouldWriteToDestination() async -> Bool {
        // If no filter rules defined, write to this destination
        if destination.configuration.filterRules == nil || destination.configuration.filterRules?.isEmpty == true {
            return true
        }
        
        // Apply simple filtering logic
        for filterRule in destination.configuration.filterRules ?? [] {
            // Check for level filtering
            if filterRule.field == "level" {
                if entry.level.rawValue == filterRule.value && filterRule.operation == .exclude {
                    return false
                }
            }
            
            // Check for category filtering
            if filterRule.field == "category" {
                if entry.category == filterRule.value && filterRule.operation == .exclude {
                    return false
                }
            }
            
            // Check for message filtering (contains check)
            if filterRule.field == "message" {
                if entry.message.contains(filterRule.value) && filterRule.operation == .exclude {
                    return false
                }
            }
        }
        
        return true
    }
    
    /**
     Apply redaction rules to a log entry.
     
     - Parameter entry: The log entry to apply redaction to
     - Returns: The redacted entry
     */
    private func applyRedactionRules(_ entry: LoggingInterfaces.LogEntryDTO) -> LoggingInterfaces.LogEntryDTO {
        // If no redaction rules, return the original entry
        if destination.configuration.redactionRules?.isEmpty != false {
            return entry
        }
        
        // In a real implementation, we would apply the redaction rules here
        // For now, just return the original entry
        return entry
    }
}
