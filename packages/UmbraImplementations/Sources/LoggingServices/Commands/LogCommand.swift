import Foundation
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Protocol for all logging commands.
 
 This protocol defines the contract that all logging commands must adhere to,
 following the command pattern architecture.
 */
public protocol LogCommand {
    /// The type of result that the command produces
    associatedtype ResultType
    
    /**
     Executes the command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the command execution
     - Throws: Error if the command execution fails
     */
    func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for logging commands.
 
 This class provides common functionality for all logging commands,
 such as standardised logging and error handling.
 */
public class BaseLogCommand {
    /// Logger instance for logging operations
    let logger: PrivacyAwareLoggingProtocol
    
    /// Logging provider to perform the actual operations
    let provider: LoggingProviderProtocol
    
    /// Shared registered destinations
    static var registeredDestinations: [String: LogDestinationDTO] = [:]
    
    /**
     Initialises a new base logging command.
     
     - Parameters:
        - provider: Provider for logging operations
        - logger: Logger instance for logging operations
     */
    init(provider: LoggingProviderProtocol, logger: PrivacyAwareLoggingProtocol) {
        self.provider = provider
        self.logger = logger
    }
    
    /**
     Creates a log context for a logging operation.
     
     - Parameters:
        - operation: The operation being performed
        - destinationId: The identifier of the destination being operated on (optional)
        - additionalMetadata: Additional metadata to include in the context
     - Returns: A log context for the operation
     */
    func createLogContext(
        operation: String,
        destinationId: String? = nil,
        additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)] = [:]
    ) -> LogContextDTO {
        var metadata = LogMetadataDTOCollection.empty
        
        if let destinationId = destinationId {
            metadata = metadata.withPublic(key: "destinationId", value: destinationId)
        }
        
        for (key, value) in additionalMetadata {
            metadata = metadata.with(
                key: key,
                value: value.value,
                privacyLevel: value.privacyLevel
            )
        }
        
        return LogContextDTO(
            operation: operation,
            category: "LoggingSystem",
            metadata: metadata
        )
    }
    
    /**
     Logs the start of a logging operation.
     
     - Parameters:
        - operation: The name of the operation
        - context: The logging context
     */
    func logOperationStart(operation: String, context: LogContextDTO) async {
        await logger.log(.info, "Starting logging operation: \(operation)", context: context)
    }
    
    /**
     Logs the successful completion of a logging operation.
     
     - Parameters:
        - operation: The name of the operation
        - context: The logging context
        - additionalMetadata: Additional metadata to include in the log
     */
    func logOperationSuccess(
        operation: String,
        context: LogContextDTO,
        additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)] = [:]
    ) async {
        var enrichedContext = context
        
        for (key, value) in additionalMetadata {
            enrichedContext = enrichedContext.withMetadata(
                LogMetadataDTOCollection().with(
                    key: key,
                    value: value.value,
                    privacyLevel: value.privacyLevel
                )
            )
        }
        
        await logger.log(.info, "Logging operation successful: \(operation)", context: enrichedContext)
    }
    
    /**
     Logs the failure of a logging operation.
     
     - Parameters:
        - operation: The name of the operation
        - error: The error that occurred
        - context: The logging context
     */
    func logOperationFailure(operation: String, error: Error, context: LogContextDTO) async {
        let errorDescription = error.localizedDescription
        
        let enrichedContext = context.withMetadata(
            LogMetadataDTOCollection().withProtected(
                key: "errorDescription",
                value: errorDescription
            )
        )
        
        await logger.log(.error, "Logging operation failed: \(operation)", context: enrichedContext)
    }
    
    /**
     Registers a destination for future use.
     
     - Parameters:
        - destination: The destination to register
     */
    func registerDestination(_ destination: LogDestinationDTO) {
        Self.registeredDestinations[destination.id] = destination
    }
    
    /**
     Unregisters a destination.
     
     - Parameters:
        - destinationId: The ID of the destination to unregister
     */
    func unregisterDestination(id destinationId: String) {
        Self.registeredDestinations.removeValue(forKey: destinationId)
    }
    
    /**
     Retrieves a registered destination by ID.
     
     - Parameters:
        - destinationId: The ID of the destination to retrieve
     - Returns: The destination if registered, or nil if not found
     */
    func getDestination(id destinationId: String) -> LogDestinationDTO? {
        return Self.registeredDestinations[destinationId]
    }
    
    /**
     Retrieves all registered destinations.
     
     - Returns: Array of all registered destinations
     */
    func getAllDestinations() -> [LogDestinationDTO] {
        return Array(Self.registeredDestinations.values)
    }
    
    /**
     Checks if a destination is valid for the provided provider.
     
     - Parameters:
        - destination: The destination to validate
        - provider: The provider to validate against
     - Returns: Result of the validation with any issues found
     */
    func validateDestination(
        _ destination: LogDestinationDTO,
        for provider: LoggingProviderProtocol
    ) -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check if provider can handle this destination type
        if provider.canHandleDestinationType() != destination.type {
            issues.append("Provider cannot handle destination type: \(destination.type.rawValue)")
            return (false, issues)
        }
        
        // Validate required parameters based on destination type
        switch destination.type {
        case .file:
            if destination.configuration.parameters["filePath"] == nil {
                issues.append("Missing required parameter for file destination: filePath")
            }
            
        case .network:
            if destination.configuration.parameters["endpoint"] == nil {
                issues.append("Missing required parameter for network destination: endpoint")
            }
            
        default:
            // No specific validation for other types
            break
        }
        
        // Check for valid minimum log level
        if destination.minimumLevel == .unknown {
            issues.append("Invalid minimum log level: unknown")
        }
        
        return (issues.isEmpty, issues)
    }
    
    /**
     Applies filter rules to a log entry.
     
     - Parameters:
        - entry: The log entry to filter
        - rules: The filter rules to apply
     - Returns: Whether the entry passes the filters
     */
    func applyFilterRules(
        to entry: LogEntryDTO,
        rules: [LogFilterRuleDTO]?
    ) -> Bool {
        guard let rules = rules, !rules.isEmpty else {
            // No rules means entry passes
            return true
        }
        
        for rule in rules {
            let matches = matchesFilterRule(entry: entry, rule: rule)
            
            if matches && !rule.isIncludeRule {
                // Entry matches an exclude rule, so filter it out
                return false
            } else if !matches && rule.isIncludeRule {
                // Entry doesn't match an include rule, so filter it out
                return false
            }
        }
        
        // Entry passed all filter rules
        return true
    }
    
    /**
     Checks if a log entry matches a filter rule.
     
     - Parameters:
        - entry: The log entry to check
        - rule: The filter rule to apply
     - Returns: Whether the entry matches the rule
     */
    private func matchesFilterRule(entry: LogEntryDTO, rule: LogFilterRuleDTO) -> Bool {
        // Extract the field value from the entry based on the rule's field
        let fieldValue: String
        
        switch rule.field.lowercased() {
        case "level":
            fieldValue = entry.level.rawValue
        case "category", "subsystem":
            fieldValue = entry.category
        case "message":
            fieldValue = entry.message
        case "timestamp":
            let formatter = ISO8601DateFormatter()
            fieldValue = formatter.string(from: entry.timestamp)
        default:
            // Check metadata fields
            if let metadataValue = entry.metadata.getString(key: rule.field) {
                fieldValue = metadataValue
            } else {
                return false
            }
        }
        
        // Apply the operation
        switch rule.operation {
        case .equals:
            return fieldValue == rule.value
        case .contains:
            return fieldValue.contains(rule.value)
        case .startsWith:
            return fieldValue.hasPrefix(rule.value)
        case .endsWith:
            return fieldValue.hasSuffix(rule.value)
        case .matches:
            if let regex = try? NSRegularExpression(pattern: rule.value) {
                let range = NSRange(location: 0, length: fieldValue.utf16.count)
                return regex.firstMatch(in: fieldValue, options: [], range: range) != nil
            }
            return false
        case .greaterThan:
            if let fieldNumeric = Double(fieldValue), let valueNumeric = Double(rule.value) {
                return fieldNumeric > valueNumeric
            }
            return false
        case .lessThan:
            if let fieldNumeric = Double(fieldValue), let valueNumeric = Double(rule.value) {
                return fieldNumeric < valueNumeric
            }
            return false
        }
    }
    
    /**
     Applies redaction rules to a log entry.
     
     - Parameters:
        - entry: The log entry to redact
        - rules: The redaction rules to apply
     - Returns: A redacted copy of the log entry
     */
    func applyRedactionRules(
        to entry: LogEntryDTO,
        rules: [LogRedactionRuleDTO]?
    ) -> LogEntryDTO {
        guard let rules = rules, !rules.isEmpty else {
            // No rules means no redaction
            return entry
        }
        
        // Create mutable copies
        var redactedMessage = entry.message
        var redactedMetadata = entry.metadata
        
        for rule in rules {
            // Process the message
            if rule.targetFields.isEmpty || rule.targetFields.contains("message") {
                if rule.isRegex {
                    if let regex = try? NSRegularExpression(pattern: rule.pattern) {
                        let range = NSRange(location: 0, length: redactedMessage.utf16.count)
                        redactedMessage = regex.stringByReplacingMatches(
                            in: redactedMessage,
                            options: [],
                            range: range,
                            withTemplate: rule.replacement
                        )
                    }
                } else {
                    redactedMessage = redactedMessage.replacingOccurrences(
                        of: rule.pattern,
                        with: rule.replacement
                    )
                }
            }
            
            // Process metadata fields
            for key in redactedMetadata.getKeys() {
                if rule.targetFields.isEmpty || rule.targetFields.contains(key) {
                    if let stringValue = redactedMetadata.getString(key: key) {
                        var redactedValue = stringValue
                        
                        if rule.isRegex {
                            if let regex = try? NSRegularExpression(pattern: rule.pattern) {
                                let range = NSRange(location: 0, length: redactedValue.utf16.count)
                                redactedValue = regex.stringByReplacingMatches(
                                    in: redactedValue,
                                    options: [],
                                    range: range,
                                    withTemplate: rule.replacement
                                )
                            }
                        } else {
                            redactedValue = redactedValue.replacingOccurrences(
                                of: rule.pattern,
                                with: rule.replacement
                            )
                        }
                        
                        // Update metadata with redacted value
                        redactedMetadata = redactedMetadata.with(
                            key: key,
                            value: redactedValue,
                            privacyLevel: redactedMetadata.getPrivacyLevel(for: key) ?? .protected
                        )
                    }
                }
            }
        }
        
        // Create a new entry with redacted content
        return LogEntryDTO(
            id: entry.id,
            timestamp: entry.timestamp,
            level: entry.level,
            category: entry.category,
            message: redactedMessage,
            metadata: redactedMetadata,
            sourceLocation: entry.sourceLocation
        )
    }
}
