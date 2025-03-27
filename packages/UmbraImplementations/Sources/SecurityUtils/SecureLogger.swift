import Foundation
import os.log

/**
 # Secure Logging Framework
 
 This module provides a secure logging capability specifically designed for security-sensitive
 applications. It implements privacy-aware logging that properly handles sensitive information
 to prevent accidental exposure in log files or monitoring systems.
 
 ## Security Considerations
 
 Improper logging of sensitive data presents several risks:
 
 1. **Data Exposure**: Sensitive information like credentials, tokens, or personal data
    could be exposed if logged in plain text.
    
 2. **Compliance Violations**: Inadvertent logging of protected data may violate
    regulatory requirements such as GDPR, PCI-DSS, or HIPAA.
    
 3. **Forensic Contamination**: Sensitive data in logs complicates forensic analysis
    and incident response by creating additional attack surfaces.
    
 4. **Credential Persistence**: Authentication credentials or session tokens might
    persist long after they've been revoked or changed.
 
 ## Implementation Approach
 
 This framework addresses these concerns through:
 
 - Explicit privacy levels for all logged data
 - Automatic redaction of sensitive information
 - Structured logging with contextual information
 - Integration with system logging facilities for proper storage and rotation
 
 ## Usage Guidelines
 
 When using this logging framework:
 
 - Explicitly mark all data with appropriate privacy levels
 - Never log authentication credentials, even with privacy markers
 - Prefer logging identifiers rather than actual sensitive data
 - Use structured logging patterns for better analysis and filtering
 */

/// Privacy level for logged data to control how information is handled in logs
public enum LogPrivacyLevel {
    /// Public data that can be logged in plain text with no redaction
    case `public`
    
    /// Private data that should be redacted in logs but may be visible to authorised personnel
    case `private`
    
    /// Sensitive data that should be completely masked in all contexts
    case sensitive
}

/**
 A logger that provides secure, privacy-aware logging capabilities.
 
 This logger builds upon the system logging facilities while adding privacy
 controls, contextual information, and security-focused features designed
 to prevent sensitive data exposure.
 */
public class SecureLogger {
    /// The underlying system logger
    private let logger: Logger
    
    /// The subsystem for the logger, typically the application's bundle identifier
    private let subsystem: String
    
    /// The category for the logger, used to organise log messages
    private let category: String
    
    /// Whether to include timestamps in console logs for better correlation
    private let includeTimestamps: Bool
    
    /**
     Initialises a new secure logger with the specified configuration.
     
     - Parameters:
        - subsystem: The subsystem identifier, typically the application or module's bundle identifier
        - category: The category name, used to organise and filter log messages
        - includeTimestamps: Whether to include timestamps in formatted log messages
     */
    public init(
        subsystem: String = "com.umbra.security",
        category: String,
        includeTimestamps: Bool = true
    ) {
        self.subsystem = subsystem
        self.category = category
        self.includeTimestamps = includeTimestamps
        self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    /**
     Logs a message at the debug level.
     
     Debug messages should contain detailed information useful during development
     or troubleshooting but not typically needed in production environments.
     
     ## Example
     
     ```swift
     secureLogger.debug("Initialising encryption service with provider type: \(providerType)")
     ```
     
     - Parameters:
        - message: The message to log
        - privacy: The privacy level for the message content
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    public func debug(
        _ message: String,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, privacy: privacy, file: file, function: function, line: line)
    }
    
    /**
     Logs a message at the info level.
     
     Info messages should contain information about normal system operation
     that might be useful for monitoring and auditing.
     
     ## Example
     
     ```swift
     secureLogger.info("User authentication successful", privacy: .private)
     ```
     
     - Parameters:
        - message: The message to log
        - privacy: The privacy level for the message content
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    public func info(
        _ message: String,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, privacy: privacy, file: file, function: function, line: line)
    }
    
    /**
     Logs a message at the warning level.
     
     Warning messages indicate potential issues that don't prevent normal operation
     but might require attention or monitoring.
     
     ## Example
     
     ```swift
     secureLogger.warning("Certificate expiration approaching for service: \(serviceName)")
     ```
     
     - Parameters:
        - message: The message to log
        - privacy: The privacy level for the message content
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    public func warning(
        _ message: String,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .default, privacy: privacy, file: file, function: function, line: line)
    }
    
    /**
     Logs a message at the error level.
     
     Error messages indicate failures that disrupt normal operation but
     don't necessarily require immediate intervention.
     
     ## Example
     
     ```swift
     secureLogger.error("Failed to encrypt data: \(error.localizedDescription)")
     ```
     
     - Parameters:
        - message: The message to log
        - privacy: The privacy level for the message content
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    public func error(
        _ message: String,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, privacy: privacy, file: file, function: function, line: line)
    }
    
    /**
     Logs a message at the critical level.
     
     Critical messages indicate severe failures that require immediate attention
     and likely prevent normal system operation.
     
     ## Example
     
     ```swift
     secureLogger.critical("Security breach detected: \(details)", privacy: .private)
     ```
     
     - Parameters:
        - message: The message to log
        - privacy: The privacy level for the message content
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    public func critical(
        _ message: String,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .fault, privacy: privacy, file: file, function: function, line: line)
    }
    
    /**
     Internal method that logs a message with the specified parameters.
     
     This method handles the common logic for all log levels, including
     formatting, privacy controls, and integration with the system logger.
     
     - Parameters:
        - message: The message to log
        - level: The log level
        - privacy: The privacy level for the message
        - file: Source file where the log was called
        - function: Function where the log was called
        - line: Line number where the log was called
     */
    private func log(
        _ message: String,
        level: OSLogType,
        privacy: LogPrivacyLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let fileInfo = "\(fileName):\(line) - \(function)"
        
        let timestamp = includeTimestamps ? "[\(formattedDate())] " : ""
        let formattedMessage = "\(timestamp)[\(category)] \(fileInfo) - \(message)"
        
        // Log with appropriate privacy level
        switch privacy {
        case .public:
            logger.log(level: level, "\(formattedMessage, privacy: .public)")
        case .private:
            logger.log(level: level, "\(formattedMessage, privacy: .private)")
        case .sensitive:
            let redactedMessage = redactSensitiveData(message)
            logger.log(level: level, "\(redactedMessage, privacy: .private)")
        }
    }
    
    /**
     Formats the current date and time for inclusion in log messages.
     
     - Returns: A formatted date string with millisecond precision
     */
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    /**
     Redacts sensitive patterns from log messages to prevent inadvertent exposure.
     
     This method uses regular expressions to identify common patterns of sensitive
     data and replace them with redacted placeholders.
     
     ## Current Redaction Patterns
     
     - Passwords (`password=123` → `password=<REDACTED>`)
     - API keys and tokens (`token=abc` → `token=<REDACTED>`)
     - Secrets and other sensitive values
     
     ## Implementation Note
     
     This provides basic redaction but should not be relied upon exclusively.
     Always mark truly sensitive data with the appropriate privacy level and
     avoid including it in logs when possible.
     
     - Parameter message: The message containing potentially sensitive data
     - Returns: A redacted message with sensitive patterns masked
     */
    private func redactSensitiveData(_ message: String) -> String {
        // Basic redaction - replace with more sophisticated logic as needed
        return message.replacingOccurrences(of: #"(password|key|token|secret)[\s]*[=:][\s]*[^\s,;]+"#, 
                                            with: "$1=<REDACTED>", 
                                            options: [.regularExpression, .caseInsensitive])
    }
}

/**
 Extension to SecureLogger providing additional logging capabilities for
 specific data types and scenarios.
 */
public extension SecureLogger {
    /**
     Logs an error object with appropriate formatting and detail extraction.
     
     This method extracts useful information from Error objects, including
     domain, code, and user info for NSError instances.
     
     ## Example
     
     ```swift
     do {
         try encryptData()
     } catch {
         secureLogger.logError(error, privacy: .private)
     }
     ```
     
     - Parameters:
        - err: The error to log
        - privacy: The privacy level for the error information
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    func logError(
        _ err: Error,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let errorMessage = "Error: \(err.localizedDescription)"
        error(errorMessage, privacy: privacy, file: file, function: function, line: line)
        
        // Log additional error details if available
        let nsError = err as NSError
        let details = "Domain: \(nsError.domain), Code: \(nsError.code), UserInfo: \(nsError.userInfo)"
        debug(details, privacy: privacy, file: file, function: function, line: line)
    }
    
    /**
     Logs a security event with structured formatting.
     
     Security events should be logged consistently to enable proper
     monitoring, alerting, and forensic analysis. This method provides
     a standardised format for security-related log entries.
     
     ## Example
     
     ```swift
     secureLogger.logSecurityEvent(
         event: "USER_AUTHENTICATION",
         details: ["userId": "12345", "method": "2FA"],
         outcome: "SUCCESS"
     )
     ```
     
     - Parameters:
        - event: The security event name (use consistent naming conventions)
        - details: Additional details about the event
        - outcome: The outcome of the event (success, failure, etc.)
        - file: Source file where the log was called (automatically provided)
        - function: Function where the log was called (automatically provided)
        - line: Line number where the log was called (automatically provided)
     */
    func logSecurityEvent(
        event: String,
        details: [String: String] = [:],
        outcome: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let detailsString = details.isEmpty ? "" : ", Details: \(details)"
        let message = "Security Event: \(event), Outcome: \(outcome)\(detailsString)"
        
        info(message, privacy: .private, file: file, function: function, line: line)
    }
}

/// A factory for creating secure loggers with consistent configuration
public struct SecureLoggerFactory {
    /// The subsystem for all loggers
    private let subsystem: String
    
    /// Whether to include timestamps in console logs
    private let includeTimestamps: Bool
    
    /// Initialise a new logger factory
    /// - Parameters:
    ///   - subsystem: The subsystem for all loggers
    ///   - includeTimestamps: Whether to include timestamps in console logs
    public init(
        subsystem: String = "com.umbra.security",
        includeTimestamps: Bool = true
    ) {
        self.subsystem = subsystem
        self.includeTimestamps = includeTimestamps
    }
    
    /// Create a new secure logger
    /// - Parameter category: The category for the logger
    /// - Returns: A configured secure logger
    public func createLogger(category: String) -> SecureLogger {
        return SecureLogger(
            subsystem: subsystem,
            category: category,
            includeTimestamps: includeTimestamps
        )
    }
}

/// A logger context that includes additional contextual information
public struct LoggerContext {
    /// The operation being performed
    public let operation: String
    
    /// The component performing the operation
    public let component: String
    
    /// Additional context for the log
    public let context: [String: String]
    
    /// Initialise a new logger context
    /// - Parameters:
    ///   - operation: The operation being performed
    ///   - component: The component performing the operation
    ///   - context: Additional context for the log
    public init(
        operation: String,
        component: String,
        context: [String: String] = [:]
    ) {
        self.operation = operation
        self.component = component
        self.context = context
    }
    
    /// Format the context as a string
    /// - Returns: A formatted string representation of the context
    public func formatted() -> String {
        var result = "[\(component)] Operation: \(operation)"
        
        if !context.isEmpty {
            let contextString = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            result += " {\(contextString)}"
        }
        
        return result
    }
}

/// An extension to make logging with context easier
public extension SecureLogger {
    /// Log a message with context
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level
    ///   - context: The context for the log
    ///   - privacy: The privacy level for the message
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func log(
        _ message: String,
        level: OSLogType,
        context: LoggerContext,
        privacy: LogPrivacyLevel = .public,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let contextMessage = "\(context.formatted()) - \(message)"
        log(contextMessage, level: level, privacy: privacy, file: file, function: function, line: line)
    }
}
