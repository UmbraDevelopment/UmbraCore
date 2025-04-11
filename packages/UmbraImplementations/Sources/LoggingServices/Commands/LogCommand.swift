import Foundation
import LoggingInterfaces
import LoggingTypes
import SchedulingTypes

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
 Base class for log commands, providing common functionality
 such as standardised logging and error handling.
 */
public class BaseLogCommand: BaseCommand {
    /// Logging provider to perform the actual operations
    let provider: LoggingProviderProtocol
    
    /// Shared registered destinations
    @MainActor static var registeredDestinations: [String: LogDestinationDTO] = [:]
    
    /**
     Initialises a new base logging command.
     
     - Parameters:
        - provider: Provider for logging operations
        - loggingServices: The logging services actor
     */
    init(provider: LoggingProviderProtocol, loggingServices: LoggingServicesActor) {
        self.provider = provider
        super.init(loggingServices: loggingServices)
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
        additionalMetadata: [String: (value: String, privacyLevel: LogPrivacyLevel)] = [:]
    ) -> LogContextDTO {
        var metadata = LogMetadataDTOCollection.empty
        
        if let destinationId = destinationId {
            metadata = metadata.withPublic(key: "destinationId", value: destinationId)
        }
        
        for (key, value) in additionalMetadata {
            metadata = metadata.with(
                key: key,
                value: value.value,
                privacyLevel: value.privacyLevel.toPrivacyClassification()
            )
        }
        
        return BaseLogContextDTO(
            domainName: "LoggingCommand",
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
        additionalMetadata: [String: (value: String, privacyLevel: LogPrivacyLevel)] = [:]
    ) async {
        var enrichedContext = context
        
        for (key, value) in additionalMetadata {
            enrichedContext = enrichedContext.withMetadata(
                LogMetadataDTOCollection().with(
                    key: key,
                    value: value.value,
                    privacyLevel: value.privacyLevel.toPrivacyClassification()
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
    @MainActor
    func registerDestination(_ destination: LogDestinationDTO) {
        Self.registeredDestinations[destination.id] = destination
    }
    
    /**
     Unregisters a destination.
     
     - Parameters:
        - destinationId: The ID of the destination to unregister
     */
    @MainActor
    func unregisterDestination(id destinationId: String) {
        Self.registeredDestinations.removeValue(forKey: destinationId)
    }
    
    /**
     Retrieves a registered destination by ID.
     
     - Parameters:
        - destinationId: The ID of the destination to retrieve
     - Returns: The destination if found
     - Throws: LoggingError.destinationNotFound if the destination does not exist
     */
    @MainActor
    func getRegisteredDestination(id destinationId: String) throws -> LogDestinationDTO {
        guard let destination = Self.registeredDestinations[destinationId] else {
            throw LoggingError.destinationNotFound("Destination with ID '\(destinationId)' not found")
        }
        
        return destination
    }
    
    /**
     Applies log filters to a log entry.
     
     - Parameters:
        - entry: The log entry to filter
        - filters: The filters to apply
     - Returns: True if the entry passes all filters, false otherwise
     */
    func applyLogFilters(entry: LogEntryDTO, filters: [UmbraLogFilterRuleDTO]?) -> Bool {
        guard let filters = filters, !filters.isEmpty else {
            // No filters means all entries pass
            return true
        }
        
        // Check each filter rule
        for rule in filters {
            if matchesFilterRule(entry: entry, rule: rule) {
                // If any rule matches, include the entry
                return true
            }
        }
        
        // No rules matched, exclude the entry
        return false
    }
    
    /**
     Checks if a log entry matches a filter rule.
     
     - Parameters:
        - entry: The log entry to check
        - rule: The filter rule to apply
     - Returns: Whether the entry matches the rule
     */
    private func matchesFilterRule(entry: LogEntryDTO, rule: UmbraLogFilterRuleDTO) -> Bool {
        // Extract the field value from the entry based on the rule's field
        var fieldValue: String = ""
        
        // Process special fields first
        switch rule.field {
        case "level":
            fieldValue = entry.level.rawValue
        case "timestamp":
            let date = Date(timeIntervalSince1970: entry.timestamp)
            let formatter = ISO8601DateFormatter()
            fieldValue = formatter.string(from: date)
        default:
            // Check metadata fields
            if let metadata = entry.metadata, let metadataValue = metadata.getString(key: rule.field) {
                fieldValue = metadataValue
            } else {
                fieldValue = ""
            }
        }
        
        // Apply the operation
        return applyOperation(operation: rule.operation, fieldValue: fieldValue, targetValue: rule.value)
    }
    
    /**
     Applies a filter operation to a field value
     - Parameters:
        - operation: The operation to apply
        - fieldValue: The field value to apply the operation to
        - targetValue: The target value for the operation
     - Returns: Whether the operation matches
     */
    private func applyOperation(operation: LoggingTypes.FilterOperation, fieldValue: String, targetValue: String) -> Bool {
        // Apply the operation
        switch operation {
        case .equals:
            return fieldValue == targetValue
        case .contains:
            return fieldValue.contains(targetValue)
        case .startsWith:
            return fieldValue.hasPrefix(targetValue)
        case .endsWith:
            return fieldValue.hasSuffix(targetValue)
        case .matches:
            // Simple pattern matching implementation
            return fieldValue.range(of: targetValue, options: .regularExpression) != nil
        case .greaterThan:
            if let fieldNumeric = Double(fieldValue), let valueNumeric = Double(targetValue) {
                return fieldNumeric > valueNumeric
            }
            return false
        case .lessThan:
            if let fieldNumeric = Double(fieldValue), let valueNumeric = Double(targetValue) {
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
                let pattern = rule.pattern
                if !pattern.isEmpty {
                    // For now, we'll use a simplified approach since NSRegularExpression isn't directly available
                    // Replace this with proper regex handling later
                    let replacement = rule.replacement ?? ""
                    // Using the functional approach with Swift 6 compliant replacingOccurrences
                    redactedMessage = redactedMessage.replacingOccurrences(
                        of: pattern,
                        with: replacement
                    )
                }
            }
            
            // Process metadata fields
            if let metadata = redactedMetadata {
                for key in metadata.getKeys() {
                    if rule.targetFields.isEmpty || rule.targetFields.contains(key) {
                        if let stringValue = metadata.getString(key: key) {
                            // No preserve fields in UmbraLogRedactionRuleDTO so we process all fields
                            
                            // Apply pattern if provided
                            var redactedValue = stringValue
                            let pattern = rule.pattern
                            if !pattern.isEmpty {
                                // For now, we'll use a simplified approach since NSRegularExpression isn't directly available
                                // Replace this with proper regex handling later
                                let replacement = rule.replacement ?? ""
                                // Using the functional approach with Swift 6 compliant replacingOccurrences
                                redactedValue = redactedValue.replacingOccurrences(
                                    of: pattern,
                                    with: replacement
                                )
                            } else {
                                // Use default redaction if no pattern
                                redactedValue = rule.replacement ?? ""
                            }
                            
                            // Update metadata with redacted value if it's not nil
                            if let updatedMetadata = redactedMetadata?.with(
                                key: key,
                                value: redactedValue,
                                privacyLevel: .public
                            ) {
                                redactedMetadata = updatedMetadata
                            }
                        }
                    }
                }
            }
        }
        
        // Create a new entry with redacted content
        return LogEntryDTO(
            timestamp: entry.timestamp,
            level: entry.level,
            message: redactedMessage,
            category: entry.category,
            metadata: redactedMetadata,
            source: entry.source,
            entryID: entry.entryID
        )
    }
    
    /**
     Redacts sensitive information in a log entry.
     
     - Parameters:
        - entry: The log entry to redact
        - redactionRules: Rules for redaction
     - Returns: A redacted copy of the log entry
     */
    private func redactLogEntry(
        _ entry: LogEntryDTO,
        withRules redactionRules: [RedactionRule]
    ) -> LogEntryDTO {
        // If no redaction rules, return the original entry
        if redactionRules.isEmpty {
            return entry
        }
        
        // Start with the original entry's message
        var redactedMessage = entry.message
        var redactedMetadata = entry.metadata
        
        // Apply each redaction rule
        for rule in redactionRules {
            // Skip rules that don't apply to this entry
            if !rule.categories.isEmpty && !rule.categories.contains(entry.category) {
                continue
            }
            
            // Apply rule to message if it matches
            if rule.targetFields.isEmpty || rule.targetFields.contains("message") {
                let pattern = rule.pattern
                if !pattern.isEmpty {
                    // For now, we'll use a simplified approach since NSRegularExpression isn't directly available
                    // Replace this with proper regex handling later
                    let replacement = rule.replacement ?? ""
                    // Using the functional approach with Swift 6 compliant replacingOccurrences
                    redactedMessage = redactedMessage.replacingOccurrences(
                        of: pattern,
                        with: replacement
                    )
                }
            }
            
            // Process metadata fields
            if let metadata = redactedMetadata {
                for key in metadata.getKeys() {
                    if rule.targetFields.isEmpty || rule.targetFields.contains(key) {
                        if let stringValue = metadata.getString(key: key) {
                            // Skip fields that should be preserved
                            if rule.preserveFields.contains(key) {
                                continue
                            }
                            
                            // Apply pattern if provided
                            var redactedValue = stringValue
                            let pattern = rule.pattern
                            if !pattern.isEmpty {
                                // For now, we'll use a simplified approach since NSRegularExpression isn't directly available
                                // Replace this with proper regex handling later
                                let replacement = rule.replacement ?? ""
                                // Using the functional approach with Swift 6 compliant replacingOccurrences
                                redactedValue = redactedValue.replacingOccurrences(
                                    of: pattern,
                                    with: replacement
                                )
                            } else {
                                // Use default redaction if no pattern
                                redactedValue = rule.replacement ?? ""
                            }
                            
                            // Update metadata with redacted value if it's not nil
                            if let updatedMetadata = redactedMetadata?.with(
                                key: key,
                                value: redactedValue,
                                privacyLevel: .public
                            ) {
                                redactedMetadata = updatedMetadata
                            }
                        }
                    }
                }
            }
        }
        
        // Create a new entry with redacted content
        return LogEntryDTO(
            timestamp: entry.timestamp,
            level: entry.level,
            message: redactedMessage,
            category: entry.category,
            metadata: redactedMetadata,
            source: entry.source,
            entryID: entry.entryID
        )
    }
    
    /**
     Converts LogPrivacyLevel to PrivacyClassification.
     
     - Parameter level: The LogPrivacyLevel to convert
     - Returns: The corresponding PrivacyClassification
     */
    private func convertPrivacyLevel(_ level: LogPrivacyLevel) -> PrivacyClassification {
        switch level {
        case .public:
            return .public
        case .private:
            return .private
        case .sensitive:
            return .sensitive
        case .hash:
            return .hash
        case .auto:
            return .auto
        case .never:
            return .public // Map 'never' to public classification
        case .protected:
            return .private // Map 'protected' to private classification
        }
    }
}
