import LoggingTypes
import LoggingInterfaces

/// An actor that implements the PrivacyAwareLoggingProtocol with support for
/// privacy controls and proper isolation for concurrent logging.
public actor PrivacyAwareLogger: PrivacyAwareLoggingProtocol {
    /// The minimum log level to process
    private let minimumLevel: LogLevel
    
    /// The identifier for this logger instance
    private let identifier: String
    
    /// The backend that will actually write the logs
    private let backend: LoggingBackend
    
    /// Creates a new privacy-aware logger
    /// - Parameters:
    ///   - minimumLevel: The minimum log level to process
    ///   - identifier: The identifier for this logger instance
    ///   - backend: The backend that will actually write the logs
    public init(minimumLevel: LogLevel, identifier: String, backend: LoggingBackend) {
        self.minimumLevel = minimumLevel
        self.identifier = identifier
        self.backend = backend
    }
    
    /// Implements the core logging functionality
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - context: Contextual information about the log
    public func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {
        // Check if this log level should be processed
        guard backend.shouldLog(level: level, minimumLevel: minimumLevel) else {
            return
        }
        
        // Write to the backend
        await backend.writeLog(
            level: level,
            message: message,
            context: context,
            subsystem: identifier
        )
    }
    
    // MARK: - LoggingProtocol Methods
    
    /// Log a trace message
    public func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.trace, message, metadata: metadata, source: source)
    }
    
    /// Log a debug message
    public func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.debug, message, metadata: metadata, source: source)
    }
    
    /// Log an info message
    public func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.info, message, metadata: metadata, source: source)
    }
    
    /// Log a warning message
    public func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.warning, message, metadata: metadata, source: source)
    }
    
    /// Log an error message
    public func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.error, message, metadata: metadata, source: source)
    }
    
    /// Log a critical message
    public func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
        await log(.critical, message, metadata: metadata, source: source)
    }
    
    // MARK: - PrivacyAwareLoggingProtocol Methods
    
    /// Log a message with explicit privacy controls
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message with privacy annotations
    ///   - metadata: Additional structured data with privacy annotations
    ///   - source: The component that generated the log
    public func log(
        _ level: LogLevel,
        _ message: PrivacyString,
        metadata: PrivacyMetadata?,
        source: String
    ) async {
        // Check if this log level should be processed
        guard backend.shouldLog(level: level, minimumLevel: minimumLevel) else {
            return
        }
        
        // Process the privacy-annotated string
        let processedMessage = message.processForLogging()
        
        // Create context with metadata
        let context = LogContext(
            source: source,
            metadata: metadata
        )
        
        // Write to the backend
        await backend.writeLog(
            level: level,
            message: processedMessage,
            context: context,
            subsystem: identifier
        )
    }
    
    /// Log sensitive information with appropriate redaction
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The basic message without sensitive content
    ///   - sensitiveValues: Sensitive values that should be automatically handled
    ///   - source: The component that generated the log
    public func logSensitive(
        _ level: LogLevel,
        _ message: String,
        sensitiveValues: [String: Any],
        source: String
    ) async {
        // Convert sensitive values to metadata with privacy annotations
        var privacyMetadata = PrivacyMetadata()
        for (key, value) in sensitiveValues {
            privacyMetadata[key] = PrivacyMetadataValue(value: String(describing: value), privacy: .sensitive)
        }
        
        // Create context with metadata
        let context = LogContext(
            source: source,
            metadata: privacyMetadata
        )
        
        // Write to the backend
        await backend.writeLog(
            level: level,
            message: message,
            context: context,
            subsystem: identifier
        )
    }
    
    /// Log an error with privacy controls
    /// - Parameters:
    ///   - error: The error to log
    ///   - privacyLevel: The privacy level to apply to the error details
    ///   - metadata: Additional structured data with privacy annotations
    ///   - source: The component that generated the log
    public func logError(
        _ error: Error,
        privacyLevel: LogPrivacyLevel,
        metadata: PrivacyMetadata?,
        source: String
    ) async {
        // Create a privacy string with the error description
        let errorMessage = PrivacyString(
            rawValue: "Error occurred: \(error)",
            privacyAnnotations: [
                // Apply privacy level to the entire error description
                // This is a simplification; in a real implementation we might
                // want more granular control over which parts are redacted
                errorRange(for: error): privacyLevel
            ]
        )
        
        // Add error metadata
        var combinedMetadata = metadata ?? PrivacyMetadata()
        combinedMetadata["errorType"] = PrivacyMetadataValue(
            value: String(describing: type(of: error)), 
            privacy: .public
        )
        
        // Log the error with privacy controls
        await log(.error, errorMessage, metadata: combinedMetadata, source: source)
    }
    
    /// Utility method to calculate the range of the error in the error message
    /// - Parameter error: The error to find the range for
    /// - Returns: The range of the error description in the error message
    private func errorRange(for error: Error) -> Range<String.Index> {
        let errorString = "Error occurred: \(error)"
        if let range = errorString.range(of: "\(error)") {
            return range
        }
        // Fallback to the entire range if we can't find the error
        return errorString.startIndex..<errorString.endIndex
    }
}
