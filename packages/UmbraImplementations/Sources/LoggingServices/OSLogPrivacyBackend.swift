#if canImport(OSLog)
import OSLog
#endif
import LoggingTypes
import LoggingInterfaces

/// Logging backend that uses Apple's OSLog system with privacy annotations.
/// This backend applies the privacy controls defined in LogPrivacyLevel
/// to the OSLog privacy annotations.
public struct OSLogPrivacyBackend: LoggingBackend {
    /// The default log subsystem identifier
    private let defaultSubsystem: String
    
    /// Creates a new OSLog backend with the specified subsystem
    /// - Parameter subsystem: The subsystem identifier to use for logs
    public init(subsystem: String) {
        self.defaultSubsystem = subsystem
    }
    
    /// Writes a log message to OSLog with appropriate privacy annotations
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - context: Contextual information about the log
    ///   - subsystem: The subsystem identifier (defaults to the one provided at initialization)
    public func writeLog(
        level: LogLevel,
        message: String,
        context: LogContext,
        subsystem: String
    ) async {
        #if canImport(OSLog)
        let subsystemToUse = subsystem.isEmpty ? defaultSubsystem : subsystem
        let category = context.source
        
        let logger = Logger(subsystem: subsystemToUse, category: category)
        
        // Map LogLevel to OSLogType
        let osLogType: OSLogType
        switch level {
        case .trace: osLogType = .debug
        case .debug: osLogType = .debug
        case .info: osLogType = .info
        case .warning: osLogType = .default
        case .error: osLogType = .error
        case .critical: osLogType = .fault
        }
        
        // Create metadata string if present
        var logMessage = message
        if let metadata = context.metadata, !metadata.isEmpty {
            let metadataString = formatMetadataWithPrivacy(metadata)
            logMessage += " \(metadataString)"
        }
        
        logger.log(level: osLogType, "\(logMessage) [correlation: \(context.correlationId)]")
        #else
        // Fallback for platforms without OSLog
        print("[\(level)] \(message) [source: \(context.source), correlation: \(context.correlationId)]")
        #endif
    }
    
    /// Formats metadata with appropriate privacy annotations for OSLog
    /// - Parameter metadata: The metadata with privacy annotations
    /// - Returns: A formatted string with OSLog privacy qualifiers
    private func formatMetadataWithPrivacy(_ metadata: PrivacyMetadata) -> String {
        var parts: [String] = []
        
        // Iterate through each key-value pair
        for key in metadata.keys {
            guard let value = metadata[key] else { continue }
            
            let privacyAnnotation: String
            let stringValue = value.valueString
            
            // Apply appropriate privacy annotation based on the privacy level
            switch value.privacy {
            case .public:
                privacyAnnotation = "%{public}"
            case .private, .sensitive, .hash, .auto:
                privacyAnnotation = "%{private}"
            }
            
            parts.append("\(key): \(privacyAnnotation)\(stringValue)")
        }
        
        return parts.isEmpty ? "" : "{" + parts.joined(separator: ", ") + "}"
    }
    
    /// Whether the specified log level should be logged given the minimum level
    /// - Parameters:
    ///   - level: The log level to check
    ///   - minimumLevel: The minimum level to log
    /// - Returns: True if the level should be logged
    public func shouldLog(level: LogLevel, minimumLevel: LogLevel) -> Bool {
        let levelValue = logLevelToNumericValue(level)
        let minimumValue = logLevelToNumericValue(minimumLevel)
        return levelValue >= minimumValue
    }
    
    /// Converts a LogLevel to a numeric value for comparison
    /// - Parameter level: The log level to convert
    /// - Returns: A numeric value representing the severity
    private func logLevelToNumericValue(_ level: LogLevel) -> Int {
        switch level {
        case .trace: return 0
        case .debug: return 1
        case .info: return 2
        case .warning: return 3
        case .error: return 4
        case .critical: return 5
        }
    }
}
