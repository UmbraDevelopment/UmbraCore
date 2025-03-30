import Foundation
import ErrorLoggingInterfaces
import LoggingInterfaces
import LoggingTypes
import LoggingServices
import UmbraErrors
import UmbraErrorsCore

/// Protocol for errors that provide additional context information
public protocol ContextualError: Error {
    /// Domain where the error occurred
    var domain: String { get }
    
    /// Operation being performed when error occurred
    var operation: String? { get }
    
    /// Details about the error
    var details: String? { get }
    
    /// Optional underlying error
    var underlyingError: Error? { get }
    
    /// Severity of the error
    var severity: ErrorSeverity? { get }
    
    /// Context metadata
    var contextMetadata: [String: String] { get }
}

/**
 # Error Logger Actor
 
 Actor-based implementation of ErrorLoggingProtocol that provides thread-safe
 error logging capabilities following the Alpha Dot Five architecture.
 
 ## Thread Safety
 
 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in logging configuration and operation.
 
 ## Features
 
 This implementation provides a comprehensive error logging service with:
 - Context-aware error logging
 - Domain-specific filtering
 - Privacy controls for sensitive information
 - Severity mapping based on error types
 - Source code location tracking
 
 ## Implementation Details
 
 The implementation delegates the actual logging to a LoggingServiceProtocol instance,
 applying appropriate transformations to errors and context information before logging.
 */
public actor ErrorLoggerActor: ErrorLoggingProtocol {
    /// The underlying logger for output
    private let logger: LoggingServiceProtocol
    
    /// Configuration for the error logger
    private let configuration: ErrorLoggerConfiguration
    
    /// Domain-specific log level filters
    private var domainFilters: [String: ErrorLoggingLevel] = [:]
    
    /**
     Initialise a new error logger with default settings.
     
     - Parameter logger: The logging service to use for output
     */
    public init(logger: LoggingServiceProtocol) {
        self.logger = logger
        self.configuration = ErrorLoggerConfiguration()
    }
    
    /**
     Initialise a new error logger with custom configuration.
     
     - Parameters:
       - logger: The logging service to use for output
       - configuration: Custom configuration for error logging
     */
    public init(logger: LoggingServiceProtocol, configuration: ErrorLoggerConfiguration) {
        self.logger = logger
        self.configuration = configuration
    }
    
    // MARK: - Error Logging Methods
    
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
    public func logWithContext(
        _ error: Error,
        context: ErrorContext,
        level: ErrorLoggingLevel,
        file: String,
        function: String,
        line: Int
    ) async {
        // Check if we should log based on domain filters
        let errorDomain = extractErrorDomain(from: error)
        guard shouldLog(level: level, forDomain: errorDomain) else {
            return
        }
        
        // Create metadata from error and context
        let metadata = constructMetadata(from: error, context: context)
        
        // Format the message
        let message = formatErrorMessage(error: error, context: context)
        
        // Log using the appropriate level - using the correct logging method
        switch level {
        case .debug:
            await logger.debug(message, metadata: metadata, source: errorDomain)
        case .info:
            await logger.info(message, metadata: metadata, source: errorDomain)
        case .warning:
            await logger.warning(message, metadata: metadata, source: errorDomain)
        case .error:
            await logger.error(message, metadata: metadata, source: errorDomain)
        case .critical:
            await logger.critical(message, metadata: metadata, source: errorDomain)
        }
    }
    
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
    public func log(
        _ error: Error,
        level: ErrorLoggingLevel?,
        file: String,
        function: String,
        line: Int
    ) async {
        // Extract context from the error if possible
        let context = extractContext(from: error)
        
        // Determine the appropriate logging level
        let logLevel = level ?? determineSeverity(for: error, context: context)
        
        // Log with the extracted/determined values
        await logWithContext(
            error,
            context: context,
            level: logLevel,
            file: file,
            function: function,
            line: line
        )
    }
    
    // MARK: - Domain Filter Methods
    
    /**
     Set filters for domain-specific log levels.
     
     This method allows configuring different minimum log levels
     for different error domains, enabling fine-grained control.
     
     - Parameter filters: Dictionary mapping domain names to minimum log levels
     */
    public func setDomainFilters(_ filters: [String: ErrorLoggingLevel]) async {
        domainFilters = filters
    }
    
    /**
     Get the current domain filters.
     
     Retrieves the currently active domain-specific logging level filters.
     
     - Returns: Dictionary of domain filters
     */
    public func getDomainFilters() async -> [String: ErrorLoggingLevel] {
        return domainFilters
    }
    
    /**
     Add a single domain filter.
     
     Sets the minimum logging level for a specific error domain.
     
     - Parameters:
       - level: The minimum logging level for the domain
       - domain: The error domain to filter
     */
    public func setLogLevel(_ level: ErrorLoggingLevel, forDomain domain: String) async {
        domainFilters[domain] = level
    }
    
    /**
     Clear all domain-specific filters.
     
     Removes all domain-specific log level filters, returning to
     global minimum level filtering only.
     */
    public func clearDomainFilters() async {
        domainFilters.removeAll()
    }
    
    // MARK: - Helper Methods
    
    /**
     Determine if an error should be logged based on level and domain filters.
     
     - Parameters:
       - level: The level the error would be logged at
       - domain: The domain of the error
     - Returns: True if the error should be logged, false otherwise
     */
    private func shouldLog(level: ErrorLoggingLevel, forDomain domain: String?) -> Bool {
        // First check against global minimum
        guard level.rawValue >= configuration.globalMinimumLevel.rawValue else {
            return false
        }
        
        // Then check domain-specific filters if applicable
        if let domain = domain, let minLevel = domainFilters[domain] {
            return level.rawValue >= minLevel.rawValue
        }
        
        // If we get here, we passed all filters
        return true
    }
    
    /**
     Extract the domain from an error if possible.
     
     - Parameter error: The error to extract domain from
     - Returns: The domain string, or nil if none could be determined
     */
    private func extractErrorDomain(from error: Error) -> String? {
        // NSError domains
        if let nsError = error as NSError? {
            return nsError.domain
        }
        
        // Context metadata (from ErrorContext)
        if let contextualError = error as? ContextualError {
            return contextualError.domain
        }
        
        // No domain info found
        return nil
    }
    
    /**
     Extract or create an ErrorContext from an error.
     
     - Parameter error: The error to extract context from
     - Returns: An ErrorContext with available information
     */
    private func extractContext(from error: Error) -> ErrorContext {
        var domain: String? = nil
        var operation: String? = nil
        var details: String? = nil
        var metadata: [String: Any] = [:]
        
        // Extract from NSError if available
        if let nsError = error as NSError? {
            domain = nsError.domain
            details = nsError.localizedDescription
            
            // Extract user info dictionary
            for (key, value) in nsError.userInfo where key != NSLocalizedDescriptionKey {
                if let stringValue = value as? String {
                    metadata[key] = stringValue
                } else {
                    metadata[key] = String(describing: value)
                }
            }
        }
        
        // Extract from ContextualError if available
        if let contextualError = error as? ContextualError {
            domain = contextualError.domain
            operation = contextualError.operation
            details = contextualError.details
            
            // Add metadata from contextual error
            for (key, value) in contextualError.contextMetadata {
                metadata[key] = value
            }
            
            // Add underlying error if available
            if let underlyingError = contextualError.underlyingError {
                metadata["underlyingError"] = String(describing: underlyingError)
            }
        }
        
        // Create context with extracted information
        return ErrorContext(
            metadata,
            source: domain,
            operation: operation,
            details: details
        )
    }
    
    /**
     Construct metadata dictionary from error and context.
     
     - Parameters:
       - error: The error to extract metadata from
       - context: Additional context for the error
     - Returns: Dictionary of metadata for logging
     */
    private func constructMetadata(from error: Error, context: ErrorContext) -> LoggingTypes.LogMetadata {
        var metadata = LoggingTypes.LogMetadata()
        
        // Add basic error type information
        metadata["errorType"] = String(describing: type(of: error))
        
        // Add domain and other context info if available
        if let source = context.source {
            metadata["domain"] = source
        }
        
        if let operation = context.operation {
            metadata["operation"] = operation
        }
        
        // Add source information if configured
        if configuration.includeSourceInfo {
            metadata["file"] = context.file
            metadata["function"] = context.function
            metadata["line"] = String(context.line)
        }
        
        // Add contextual information from the error
        let nsError = error as NSError
        metadata["errorCode"] = String(nsError.code)
        
        // Add user info keys that might be relevant
        if let failureReason = nsError.localizedFailureReason {
            metadata["failureReason"] = failureReason
        }
        if let recoverySuggestion = nsError.localizedRecoverySuggestion {
            metadata["recoverySuggestion"] = recoverySuggestion
        }
        
        // Add additional metadata from the context using value(for:)
        for key in ["documentId", "userId", "errorCode", "attemptCount", "sessionId"] {
            if let value = context.value(for: key) as? String {
                metadata[key] = value
            } else if let value = context.value(for: key) {
                metadata[key] = String(describing: value)
            }
        }
        
        return metadata
    }
    
    /**
     Format an error message with available context information.
     
     - Parameters:
       - error: The error to format
       - context: Additional context for the error
     - Returns: Formatted error message string
     */
    private func formatErrorMessage(error: Error, context: ErrorContext) -> String {
        var components: [String] = []
        
        // Add domain and operation if available
        if let operation = context.operation {
            if let source = context.source {
                components.append("[\(source):\(operation)]")
            } else {
                components.append("[\(operation)]")
            }
        } else if let source = context.source {
            components.append("[\(source)]")
        }
        
        // Add error message
        if let details = context.details {
            components.append(details)
        } else if let nsError = error as NSError? {
            components.append(nsError.localizedDescription)
        } else {
            components.append(String(describing: error))
        }
        
        return components.joined(separator: " ")
    }
    
    /**
     Determine severity level for an error based on its type and context.
     
     - Parameters:
       - error: The error to determine severity for
       - context: Additional context for the error
     - Returns: Appropriate logging level for the error
     */
    private func determineSeverity(for error: Error, context: ErrorContext) -> ErrorLoggingLevel {
        // Use explicit severity if available
        if let contextualError = error as? ContextualError, let severity = contextualError.severity {
            return mapSeverityToLevel(severity)
        }
        
        // Check for HTTP-like status codes
        if let nsError = error as NSError? {
            let code = nsError.code
            
            // HTTP-like severity mapping
            if code >= 500 {
                return .error
            } else if code >= 400 {
                return .warning
            } else if code >= 300 {
                return .info
            }
            
            // Fall back to configuration default
            return configuration.defaultErrorLevel
        }
        
        // If all else fails, use the configured default level
        return configuration.defaultErrorLevel
    }
    
    /**
     Map error severity enum to logging level.
     
     - Parameter severity: The severity enum value
     - Returns: Corresponding logging level
     */
    private func mapSeverityToLevel(_ severity: ErrorSeverity) -> ErrorLoggingLevel {
        switch severity {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .error
        case .trace:
            return .debug
        @unknown default:
            return .error
        }
    }
}
