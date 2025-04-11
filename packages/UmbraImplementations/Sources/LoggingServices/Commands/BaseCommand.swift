import Foundation
import LoggingTypes
import LoggingInterfaces

/**
 Base class for all logging commands with access to the logging services.
 This provides a proper inheritance hierarchy for command classes to access
 the LoggingServicesActor methods without circular references.
 */
public class BaseCommand {
    /// Reference to logging services actor
    internal let loggingServices: LoggingServicesActor
    
    /// Creates a new base command
    /// - Parameter loggingServices: The logging services actor to use
    init(loggingServices: LoggingServicesActor) {
        self.loggingServices = loggingServices
    }
    
    /// Log a message at info level
    /// - Parameter message: The message to log
    internal func logInfo(_ message: String) async {
        await loggingServices.logString(.info, message, context: createCommandContext())
    }
    
    /// Log a message at warning level
    /// - Parameter message: The message to log
    internal func logWarning(_ message: String) async {
        await loggingServices.logString(.warning, message, context: createCommandContext())
    }
    
    /// Log a message at error level
    /// - Parameter message: The message to log
    internal func logError(_ message: String) async {
        await loggingServices.logString(.error, message, context: createCommandContext())
    }
    
    /// Log operation success
    /// - Parameters:
    ///   - operation: The operation name
    ///   - details: Additional details
    internal func logOperationSuccess(operation: String, details: String? = nil) async {
        let message = details != nil ? "\(operation) completed: \(details!)" : "\(operation) completed successfully"
        await logInfo(message)
    }
    
    /// Create a command context for logging
    /// - Returns: The log context
    private func createCommandContext() -> BaseLogContextDTO {
        return BaseLogContextDTO(
            domainName: "LoggingServices",
            operation: "Command",
            category: String(describing: type(of: self)),
            source: "UmbraCore",
            metadata: LogMetadataDTOCollection()
        )
    }
    
    // Utility methods to access services from the actor
    
    /// Get a destination by ID
    /// - Parameter id: The destination ID
    /// - Returns: The destination if found
    internal func getDestination(id: String) async -> LogDestinationDTO? {
        return await loggingServices.getDestination(id: id)
    }
    
    /// Get all registered destinations
    /// - Returns: All destinations
    internal func getAllDestinations() async -> [LogDestinationDTO] {
        return await loggingServices.getAllDestinations()
    }
    
    /// Validate a destination
    /// - Parameters:
    ///   - destination: The destination to validate
    ///   - provider: The provider to use
    /// - Returns: The validation result
    internal func validateDestination(_ destination: LogDestinationDTO, for provider: any LoggingProviderProtocol) async -> LogDestinationValidationResultDTO {
        return await loggingServices.validateDestination(destination, for: provider)
    }
    
    /// Apply filter rules to a log entry
    /// - Parameters:
    ///   - entry: The entry to filter
    ///   - rules: The rules to apply
    /// - Returns: Whether the entry passes the filters
    internal func applyFilterRules(to entry: LogEntryDTO, rules: [UmbraLogFilterRuleDTO]) async -> Bool {
        return await loggingServices.applyFilterRules(to: entry, rules: rules)
    }
    
    /// Register a destination with the logging services
    /// - Parameter destination: The destination to register
    internal func registerDestination(_ destination: LogDestinationDTO) async {
        _ = try? await loggingServices.addDestination(destination)
    }
    
    /// Unregister a destination 
    /// - Parameter id: The ID of the destination to remove
    internal func unregisterDestination(id: String) async {
        _ = try? await loggingServices.removeDestination(withId: id)
    }
    
    /// Apply redaction rules to an entry
    /// - Parameters:
    ///   - entry: The entry to redact
    ///   - rules: The rules to apply
    /// - Returns: The redacted entry
    internal func applyRedactionRules(to entry: LogEntryDTO, rules: [UmbraLogRedactionRuleDTO]) -> LogEntryDTO {
        // If no rules, return the original entry
        if rules.isEmpty {
            return entry
        }
        
        // Simple implementation - just return the original entry for now
        return entry
    }
}
