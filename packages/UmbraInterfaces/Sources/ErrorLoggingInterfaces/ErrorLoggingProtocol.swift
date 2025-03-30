import Foundation
import LoggingTypes
import UmbraErrors
import UmbraErrorsCore

/**
 # Error Logging Protocol
 
 This protocol standardises how errors are logged throughout the application,
 providing consistent context and severity handling.
 
 ## Thread Safety
 
 Implementations of this protocol are expected to be actor-based to ensure
 proper thread safety when logging errors from multiple concurrent contexts.
 The protocol itself conforms to Sendable to support use across actor isolation
 boundaries.
 
 ## Context Handling
 
 Error logs include rich contextual information such as:
 - Error domain and code
 - Operation being performed when the error occurred
 - Source location (file, function, line)
 - Additional metadata relevant to the error
 
 ## Alpha Dot Five Architecture
 
 This protocol is part of the Alpha Dot Five architecture, which emphasises:
 - Clean separation between interface and implementation
 - Thread safety through actor isolation
 - Domain-specific error handling
 - Consistent British English in documentation
 
 ## Implementation Note
 
 All methods in this protocol are async to accommodate actor-based implementations
 without requiring explicit marking with `isolated` parameters.
 */
public protocol ErrorLoggingProtocol: Sendable {
    /**
     Log an error with full context.
     
     This method provides complete control over the logging process,
     allowing detailed customisation of context and severity.
     
     - Parameters:
       - error: The error to log
       - context: Additional context for the error
       - level: The severity level for logging
       - file: Source file where the error occurred
       - function: Function where the error occurred
       - line: Line number where the error occurred
     */
    func logWithContext(
        _ error: Error,
        context: ErrorContext,
        level: ErrorLoggingLevel,
        file: String,
        function: String,
        line: Int
    ) async
    
    /**
     Log an error with automatic context extraction.
     
     This convenience method automatically extracts context from the error
     if it conforms to relevant contextual protocols, simplifying common logging.
     
     - Parameters:
       - error: The error to log
       - level: Optional override for the severity level
       - file: Source file where the error occurred
       - function: Function where the error occurred
       - line: Line number where the error occurred
     */
    func log(
        _ error: Error,
        level: ErrorLoggingLevel?,
        file: String,
        function: String,
        line: Int
    ) async
    
    /**
     Set filters for domain-specific log levels.
     
     This method allows configuring different minimum log levels
     for different error domains, enabling fine-grained control.
     
     - Parameter filters: Dictionary mapping domain names to minimum log levels
     */
    func setDomainFilters(_ filters: [String: ErrorLoggingLevel]) async
    
    /**
     Get the current domain filters.
     
     Retrieves the currently active domain-specific logging level filters.
     
     - Returns: Dictionary of domain filters
     */
    func getDomainFilters() async -> [String: ErrorLoggingLevel]
    
    /**
     Add a single domain filter.
     
     Sets the minimum logging level for a specific error domain.
     
     - Parameters:
       - level: The minimum logging level for the domain
       - domain: The error domain to filter
     */
    func setLogLevel(_ level: ErrorLoggingLevel, forDomain domain: String) async
    
    /**
     Clear all domain-specific filters.
     
     Removes all domain-specific log level filters, returning to
     global minimum level filtering only.
     */
    func clearDomainFilters() async
}
